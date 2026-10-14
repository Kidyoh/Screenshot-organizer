package com.kidyoh.snapsort.data

import org.junit.Assert.assertEquals
import org.junit.BeforeClass
import org.junit.Test

/** Checks look recognition on the sample screenshots in assets/demo. */
class LookTest {
    companion object {
        private lateinit var looks: Map<String, Look>

        /**
         * The 24 × 52 copies the phone makes (LookStore) of the screenshots in
         * assets/demo, one per line: name, then comma-separated ARGB pixels.
         */
        @BeforeClass @JvmStatic fun load() {
            val text = LookTest::class.java.getResource("/demo_looks.txt")!!.readText()
            looks = text.lines().filter { it.isNotBlank() }.associate { line ->
                val (name, px) = line.split(' ')
                name to Look(px.split(',').map { it.toInt() }.toIntArray())
            }
        }

        private fun appOf(name: String) = (parseAppHint("$name.jpg") as? AppHint.Label)?.label
    }

    @Test fun fingerprintsRecogniseWhatsAppAndNothingElseInTheSamples() {
        for ((name, look) in looks) {
            val expected = if (appOf(name) == "WhatsApp") "WhatsApp" else null
            assertEquals(name, expected, fingerprintApp(look))
        }
    }

    @Test fun theMatcherIsNeverWrongHoldingOneOut() {
        for (held in looks.keys) {
            val matcher = LookMatcher()
            var id = 0L
            for (other in looks.keys) {
                val app = appOf(other) ?: continue
                if (other != held) matcher.add(app, id++, looks.getValue(other))
            }
            // Either the right app or "don't know", never a wrong app.
            matcher.match(looks.getValue(held))?.let { assertEquals(held, appOf(held), it) }
        }
        val chrome = "Screenshot_20261010-143010_Chrome"
        val m = LookMatcher().apply { add("Chrome", 1, looks.getValue(chrome)) }
        assertEquals("Chrome", m.match(looks.getValue(chrome)))
    }

    @Test fun answersIgnoreReferenceOrder() {
        val entries = looks.entries.filter { appOf(it.key) != null }
        fun run(refs: List<Map.Entry<String, Look>>, q: Look): String? {
            val m = LookMatcher()
            refs.forEachIndexed { i, e -> m.add(appOf(e.key)!!, i.toLong(), e.value) }
            return m.match(q)
        }
        for (q in looks.values) assertEquals(run(entries, q), run(entries.reversed(), q))
    }
}
