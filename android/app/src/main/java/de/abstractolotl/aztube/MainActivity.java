package de.abstractolotl.aztube;

import android.os.Environment;
import android.util.Log;
import androidx.annotation.NonNull;
import de.abstractolotl.aztube.download.AzTubeDownload;
import de.abstractolotl.aztube.download.AzTubeProgressUpdater;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends FlutterActivity implements AzTubePlatform.PlatformImpl {

    public static String DOWNLOAD_DIR;
    private final static ExecutorService executorService = Executors.newCachedThreadPool();

    private AzTubePlatform platform;

    @Override
    public void configureFlutterEngine(@NonNull @NotNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        DOWNLOAD_DIR = getExternalFilesDir(Environment.DIRECTORY_MOVIES) + "/";
        platform = new AzTubePlatform(flutterEngine, this);
    }

    @Override
    public void downloadVideo(DownloadRequest request) {
        Log.d("DEBUG", "GOT DOWNLOAD VIDEO");
        executorService.submit(() -> {
            var progressUpdater = new AzTubeProgressUpdater(platform, request.getDownloadId());
            File output = new AzTubeDownload().startDownload(request, progressUpdater);
            try {
                MediaStoreUtil.saveAudioToMediaStore(this, output, request.getTitle(), request.getAuthor());
            } catch (IOException e) {
                progressUpdater.markError();
                throw new RuntimeException(e);
            } finally {
                output.delete();
            }
        });
    }


}
