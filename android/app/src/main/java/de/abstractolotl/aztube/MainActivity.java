package de.abstractolotl.aztube;

import androidx.annotation.NonNull;
import de.abstractolotl.aztube.download.AzTubeProgressUpdater;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import org.jetbrains.annotations.NotNull;

public class MainActivity extends FlutterActivity implements AzTubePlatform.PlatformImpl {

    private AzTubePlatform platform;

    @Override
    public void configureFlutterEngine(@NonNull @NotNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        platform = new AzTubePlatform(flutterEngine, this);
    }

    @Override
    public void downloadVideo(DownloadRequest request) {
        var progressUpdater = new AzTubeProgressUpdater(platform, request.getDownloadId());
    }
}
