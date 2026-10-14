package com.kidyoh.snapsort.data

import android.os.Build
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AppGroup(val name: String, val shots: List<Shot>) {
    val totalSize: Long = shots.sumOf { it.size }
}

enum class PhotoAccess { All, Limited, Denied, NotAsked }

/** Things only the activity can do: system dialogs and permissions. */
interface Host {
    fun photoAccess(): PhotoAccess
    suspend fun requestPhotos()

    /** Recycle bin (Android 11+) or delete (older). False if the person said no. */
    suspend fun trash(ids: List<Long>): Boolean
    fun share(ids: List<Long>)
    fun openWith(id: Long)
    fun shareText(text: String)
    fun openUsageAccess()
    fun openAppSettings()
}

/**
 * All the app's state: the screenshots, how they're grouped, albums,
 * favourites and the duplicate scan. Everything the UI reads is snapshot state.
 */
class Library(private val media: Media, private val store: Store) {
    lateinit var host: Host
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    var access by mutableStateOf<PhotoAccess?>(null)
        private set
    val sdkInt = Build.VERSION.SDK_INT
    var loading by mutableStateOf(false)
        private set
    var loadedOnce by mutableStateOf(false)
        private set
    var error by mutableStateOf<String?>(null)
        private set

    var shots by mutableStateOf<List<Shot>>(emptyList())
        private set
    private var byId: Map<Long, Shot> = emptyMap()
    var apps by mutableStateOf<List<AppGroup>>(emptyList())
        private set

    var favorites by mutableStateOf(store.favorites)
        private set

    /** Screenshots the person chose to keep in Swipe to clean. */
    var reviewed by mutableStateOf(store.reviewed)
        private set
    var albums by mutableStateOf(store.albums)
        private set

    /** Apps the person picked by hand; these always win. */
    var appOverrides by mutableStateOf(store.appOverrides)
        private set

    /** Usage access is on, so untagged screenshots get their app from history. */
    var usageAccess by mutableStateOf(false)
        private set

    /** The person said "Not now" to the usage access card. */
    var usageCardDismissed by mutableStateOf(store.usageCardDismissed)
        private set

    /** The one-time usage access prompt has been shown. */
    var usagePromptShown by mutableStateOf(store.usagePromptShown)
        private set

    var scanningDuplicates by mutableStateOf(false)
        private set
    var duplicateProgress by mutableFloatStateOf(0f)
        private set
    private var duplicateIds by mutableStateOf<List<List<Long>>?>(null)

    /** The background look-up is still working through screenshots. */
    var recognising by mutableStateOf(false)
        private set

    var themeMode by mutableStateOf(store.themeMode)
        private set

    private val labelCache = HashMap<String, String>()
    private var hashLabels: Map<String, String>? = null

    /** Tiny copies of screenshots, for recognising apps by look. */
    private val looks = HashMap<Long, Look>()
    private var lookPass = 0

    val hasAccess get() = access == PhotoAccess.All || access == PhotoAccess.Limited
    val isLimited get() = access == PhotoAccess.Limited

    /**
     * Android 11+ asks for confirmation itself and keeps deleted files in the
     * recycle bin for 30 days; older versions delete straight away.
     */
    val trashGoesToBin get() = sdkInt >= 30
    val totalSize get() = shots.sumOf { it.size }
    fun byId(id: Long): Shot? = byId[id]

    fun setTheme(mode: Int) {
        themeMode = mode
        store.themeMode = mode
    }

    /** Re-checks photo access (on launch and whenever the app comes back) and reloads. */
    fun checkAccess() {
        val now = host.photoAccess()
        access = if (now == PhotoAccess.Denied && !store.askedForPhotos) PhotoAccess.NotAsked else now
        if (hasAccess) refresh()
    }

    fun askForAccess() = scope.launch {
        host.requestPhotos()
        store.askedForPhotos = true
        checkAccess()
    }

    fun refresh() {
        if (loading) return
        loading = true
        scope.launch {
            try {
                val list = withContext(Dispatchers.IO) { assignApps(media.query()) }
                    .sortedByDescending { it.date }
                publish(recognise(list)) // instant, from tiny copies already made
                error = null
            } catch (e: Exception) {
                error = "Could not read screenshots: $e"
            } finally {
                loading = false
                loadedOnce = true
            }
            recogniseInBackground()
        }
    }

    private fun publish(list: List<Shot>) {
        shots = list
        byId = list.associateBy { it.id }
        apps = groupByApp(list)
    }

    /** Screenshots with a known app, used as references: the newest few per app. */
    private fun references(list: List<Shot>): List<Shot> {
        val perApp = LinkedHashMap<String, MutableList<Shot>>()
        for (s in list) {
            if (s.appSource == AppSource.Unknown || s.appSource == AppSource.Looks) continue
            val l = perApp.getOrPut(s.app) { ArrayList() }
            if (l.size < 25) l += s
        }
        return perApp.values.flatten()
    }

    /** Labels unknown screenshots from their looks, using only tiny copies already fetched. */
    private fun recognise(list: List<Shot>): List<Shot> {
        if (looks.isEmpty() || list.none { it.appSource == AppSource.Unknown }) return list
        val matcher = LookMatcher()
        for (r in references(list)) looks[r.id]?.let { matcher.add(r.app, r.id, it) }
        val names = HashMap<String, String>()
        for (s in list) names.putIfAbsent(s.app.lowercase(), s.app)
        return list.map { s ->
            if (s.appSource != AppSource.Unknown) return@map s
            val look = looks[s.id] ?: return@map s
            val app = fingerprintApp(look) ?: matcher.match(look) ?: return@map s
            s.copy(app = names.getOrPut(app.lowercase()) { app }, appSource = AppSource.Looks)
        }
    }

    /**
     * Makes tiny copies for unknown screenshots and their references, a batch
     * at a time (slow on budget phones the first time, then cached for good).
     */
    private suspend fun recogniseInBackground() {
        val pass = ++lookPass
        val unknown = shots.filter { it.appSource == AppSource.Unknown }.map { it.id }
        val wanted = (references(shots).map { it.id } + unknown).filter { it !in looks }
        if (wanted.isEmpty()) return
        recognising = true
        try {
            for (batch in wanted.chunked(40)) {
                val got = withContext(Dispatchers.IO) { media.looks(batch) }
                if (pass != lookPass) return // a newer refresh took over
                for ((id, px) in got) if (px.size == LOOK_W * LOOK_H) looks[id] = Look(px)
                val next = recognise(shots)
                if (next != shots) publish(next)
            }
        } catch (e: Throwable) {
            Log.w("SnapSort", "Could not recognise screenshots by look", e)
        } finally {
            if (pass == lookPass) recognising = false
        }
    }

    /** Runs on a background thread. */
    private fun assignApps(list: List<Shot>): List<Shot> {
        val hints = list.map { parseAppHint(it.name, it.folder) }
        val unknownPackages = hints.filterIsInstance<AppHint.Package>().map { it.pkg }
            .filter { it !in labelCache }.toSet()
        if (unknownPackages.isNotEmpty()) {
            val labels = runCatching { media.appLabels(unknownPackages) }.getOrDefault(emptyMap())
            for (p in unknownPackages) labelCache[p] = labels[p] ?: prettifyPackage(p)
        }
        if (hashLabels == null && hints.any { it is AppHint.Hash }) {
            hashLabels = runCatching { media.hashLabels() }.getOrDefault(emptyMap())
        }

        fun fromName(hint: AppHint?): String? = when (hint) {
            is AppHint.Label -> hint.label
            is AppHint.Package -> labelCache[hint.pkg]
            is AppHint.Hash -> hashLabels?.get(hint.md5)
            null -> null
        }

        // Screenshots the name doesn't explain: ask Android's usage history.
        val access = runCatching { media.usageAccess() }.getOrDefault(false)
        scope.launch { usageAccess = access }
        val overrides = appOverrides
        val untagged = HashMap<Long, Long>()
        list.forEachIndexed { i, s ->
            if (fromName(hints[i]) == null && s.id !in overrides) untagged[s.id] = s.date
        }
        val used = runCatching { media.appsAt(untagged) }.getOrDefault(emptyMap())
        val usedPackages = used.values.filter { it !in labelCache }.toSet()
        if (usedPackages.isNotEmpty()) {
            val labels = runCatching { media.appLabels(usedPackages) }.getOrDefault(emptyMap())
            for (p in usedPackages) labelCache[p] = labels[p] ?: prettifyPackage(p)
        }

        // Merge spellings that only differ by case ("Chrome" / "chrome").
        val canonical = HashMap<String, String>()
        return list.mapIndexed { i, shot ->
            val manual = overrides[shot.id]
            val named = fromName(hints[i])
            val usage = used[shot.id]?.let { labelCache[it] }
            val (name, source) = when {
                manual != null -> manual to AppSource.Manual
                named != null -> named to AppSource.FileName
                usage != null -> usage to AppSource.Usage
                else -> Shot.OTHER to AppSource.Unknown
            }
            shot.copy(app = canonical.getOrPut(name.lowercase()) { name }, appSource = source)
        }
    }

    /** Screenshots still filed under Other. */
    val unknownCount get() = shots.count { it.appSource == AppSource.Unknown }

    fun markUsagePromptShown() {
        usagePromptShown = true
        store.usagePromptShown = true
    }

    fun dismissUsageCard() {
        usageCardDismissed = true
        store.usageCardDismissed = true
    }

    /** The last crash report, once. */
    suspend fun takeCrashReport(): String? = withContext(Dispatchers.IO) { runCatching { media.lastCrash() }.getOrNull() }

    /** Files screenshots under [app] by hand, or back to automatic with null. */
    fun setApp(items: Collection<Shot>, app: String?) {
        val name = app?.trim()
        val next = appOverrides.toMutableMap()
        for (s in items) {
            if (name.isNullOrEmpty()) next.remove(s.id) else next[s.id] = name
        }
        appOverrides = next
        store.appOverrides = next
        refresh()
    }

    fun resolve(ids: Collection<Long>): List<Shot> = ids.mapNotNull { byId[it] }.sortedByDescending { it.date }

    fun search(query: String): List<Shot> {
        val q = query.trim().lowercase()
        if (q.isEmpty()) return shots
        return shots.filter {
            it.app.lowercase().contains(q) || it.name.lowercase().contains(q) ||
                monthYear(it.date).lowercase().contains(q)
        }
    }

    fun olderThan(days: Int): List<Shot> {
        val cutoff = System.currentTimeMillis() - days * 86_400_000L
        return shots.filter { it.date < cutoff }
    }

    fun largest(count: Int): List<Shot> = shots.sortedByDescending { it.size }.take(count)

    // ---- Deleting / sharing ----

    /** Bins screenshots. Returns false if the person cancelled or it failed. */
    suspend fun trash(items: Collection<Shot>): Boolean {
        val ids = items.map { it.id }
        val removed = ArrayList<Long>()
        var ok = true
        for (chunk in ids.chunked(500)) {
            if (!host.trash(chunk)) {
                ok = false
                break
            }
            removed += chunk
        }
        if (removed.isNotEmpty()) {
            val gone = removed.toSet()
            updateFavorites(favorites - gone)
            updateReviewed(reviewed - gone)
            appOverrides = (appOverrides - gone).also { store.appOverrides = it }
            updateAlbums(albums.mapValues { (_, l) -> l.filter { it !in gone } })
            refresh()
        }
        return ok
    }

    fun share(items: Collection<Shot>) = host.share(items.map { it.id })
    fun openWith(shot: Shot) = host.openWith(shot.id)
    fun shareText(text: String) = host.shareText(text)
    fun openUsageAccess() = host.openUsageAccess()
    fun openAppSettings() = host.openAppSettings()

    // ---- Favourites & albums ----

    fun isFavorite(s: Shot) = s.id in favorites

    fun setFavorite(items: Collection<Shot>, value: Boolean) {
        val ids = items.map { it.id }
        updateFavorites(if (value) favorites + ids else favorites - ids.toSet())
    }

    val favoriteShots get() = resolve(favorites)
    fun albumShots(name: String) = resolve(albums[name].orEmpty())

    fun createAlbum(raw: String): Boolean {
        val name = raw.trim()
        if (name.isEmpty() || name in albums) return false
        updateAlbums(albums + (name to emptyList()))
        return true
    }

    fun addToAlbum(name: String, items: Collection<Shot>) {
        val list = albums[name].orEmpty().toMutableList()
        for (s in items) if (s.id !in list) list += s.id
        updateAlbums(LinkedHashMap(albums).apply { put(name, list) })
    }

    fun removeFromAlbum(name: String, items: Collection<Shot>) {
        val ids = items.map { it.id }.toSet()
        updateAlbums(albums.mapValues { (k, l) -> if (k == name) l.filter { it !in ids } else l })
    }

    fun renameAlbum(from: String, raw: String): Boolean {
        val to = raw.trim()
        if (to.isEmpty() || from == to || to in albums) return false
        val next = LinkedHashMap<String, List<Long>>()
        for ((k, v) in albums) next[if (k == from) to else k] = v
        updateAlbums(next)
        return true
    }

    fun deleteAlbum(name: String) = updateAlbums(albums - name)

    private fun updateFavorites(v: Set<Long>) {
        favorites = v
        store.favorites = v
    }

    private fun updateReviewed(v: Set<Long>) {
        reviewed = v
        store.reviewed = v
    }

    private fun updateAlbums(v: Map<String, List<Long>>) {
        albums = v
        store.albums = v
    }

    // ---- Swipe to clean ----

    /** Screenshots not yet kept in Swipe to clean, oldest first. */
    val unreviewed get() = shots.filter { it.id !in reviewed }.reversed()

    fun setReviewed(shot: Shot, value: Boolean) =
        updateReviewed(if (value) reviewed + shot.id else reviewed - shot.id)

    fun resetReviewed() = updateReviewed(emptySet())

    // ---- Duplicates ----

    /** Groups of byte-identical screenshots, oldest first in each group. */
    val duplicateGroups: List<List<Shot>>?
        get() = duplicateIds?.map { g -> g.mapNotNull { byId[it] }.sortedBy { it.date } }?.filter { it.size > 1 }

    fun scanDuplicates() {
        if (scanningDuplicates) return
        scanningDuplicates = true
        duplicateProgress = 0f
        scope.launch {
            try {
                // Only files with the exact same size can be identical, so hash just those.
                val candidates = shots.filter { it.size > 0 }.groupBy { it.size }.values
                    .filter { it.size > 1 }.flatten().map { it.id }
                val hashes = HashMap<Long, String>()
                var done = 0
                for (batch in candidates.chunked(40)) {
                    hashes += withContext(Dispatchers.IO) { media.md5(batch) }
                    done += batch.size
                    duplicateProgress = done.toFloat() / candidates.size
                }
                val byHash = LinkedHashMap<String, MutableList<Long>>()
                for ((id, h) in hashes) byHash.getOrPut("${byId[id]?.size ?: 0}:$h") { ArrayList() } += id
                duplicateIds = byHash.values.filter { it.size > 1 }
                    .sortedByDescending { g -> g.maxOf { byId[it]?.date ?: 0L } }
            } catch (e: Exception) {
                error = "Duplicate scan failed: $e"
            } finally {
                scanningDuplicates = false
            }
        }
    }

    companion object {
        fun groupByApp(list: List<Shot>): List<AppGroup> {
            val map = LinkedHashMap<String, MutableList<Shot>>()
            for (s in list) map.getOrPut(s.app) { ArrayList() } += s
            return map.map { AppGroup(it.key, it.value) }.sortedWith { a, b ->
                when {
                    a.name == Shot.OTHER -> 1
                    b.name == Shot.OTHER -> -1
                    b.shots.size != a.shots.size -> b.shots.size - a.shots.size
                    else -> a.name.lowercase().compareTo(b.name.lowercase())
                }
            }
        }
    }
}
