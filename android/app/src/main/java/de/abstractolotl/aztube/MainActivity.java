package de.abstractolotl.aztube;

import android.os.Environment;
import android.util.Log;
import androidx.annotation.NonNull;
import de.abstractolotl.aztube.download.AzTubeDownload;
import de.abstractolotl.aztube.download.AzTubeProgressUpdater;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends FlutterActivity implements AzTubeChannel.Calls {

    public static String DOWNLOAD_DIR;

    private AzTubeChannel platform;

    @Override
    public void configureFlutterEngine(@NonNull @NotNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        DOWNLOAD_DIR = getExternalFilesDir(Environment.DIRECTORY_MOVIES) + "/";
        platform = new AzTubeChannel(new MethodChannel(flutterEngine.getDartExecutor(), AzTubeChannel.CHANNEL), this);
    }

    @Override
    public void downloadVideo(DownloadRequest request) throws Exception {
        var progressUpdater = new AzTubeProgressUpdater(platform, request.getDownloadId());
        File output = null;
        try {
            output = AzTubeDownload.startDownload(request, progressUpdater);
            MediaStoreUtil.saveAudioToMediaStore(this, output, request.getTitle(), request.getAuthor());
        } catch (Exception e) {
            progressUpdater.markError();
            throw e;
        } finally {
            if (output != null) {
                output.delete();
            }
        }
    }


}
