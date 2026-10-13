# WorkManager (LabelWorker) creates these by reflection when the app starts.
# Without them R8 strips the constructors and the app crashes on launch:
#   InitializationProvider -> WorkManagerInitializer -> NoSuchMethodException: <init> []
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * implements androidx.startup.Initializer { <init>(); }
