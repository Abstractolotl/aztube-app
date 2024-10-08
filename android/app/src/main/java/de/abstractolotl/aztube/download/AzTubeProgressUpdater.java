package de.abstractolotl.aztube.download;

import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import de.abstractolotl.aztube.AzTubeChannel;
import de.abstractolotl.aztube.GenericStageProgressUpdater;

import java.io.File;
import java.util.HashMap;

public class AzTubeProgressUpdater extends GenericStageProgressUpdater<AzTubeProgressUpdater.DownloadStages> implements YoutubeProgressCallback<File> {

    public enum DownloadStages {
        META_DATA,
        DOWNLOAD_FILES,
        CONVERT_FILES,
        OUTPUT
    }

    private static final HashMap<DownloadStages, Double> WEIGHTS = new HashMap<>();
    static {
        WEIGHTS.put(DownloadStages.META_DATA, 0.1);
        WEIGHTS.put(DownloadStages.DOWNLOAD_FILES, 0.4);
        WEIGHTS.put(DownloadStages.CONVERT_FILES, 0.4);
        WEIGHTS.put(DownloadStages.OUTPUT, 0.1);
    }

    private final AzTubeChannel platform;
    private final String downloadId;
    private boolean error;

    public AzTubeProgressUpdater(AzTubeChannel platform, String downloadId) {
        super(WEIGHTS);
        this.platform = platform;
        this.downloadId = downloadId;
    }

    public void markError() {
        error = true;
        platform.sendProgressUpdate(downloadId, -1);
    }

    @Override
    protected void performUpdate() {
        if(error) return;
        double progress = calculateWeightedProgress();
        System.out.println("Sending progress: " + progress);
        platform.sendProgressUpdate(downloadId, progress);
    }

    @Override
    public void onDownloading(int progress) {
        updateStage(DownloadStages.DOWNLOAD_FILES, progress);
    }

    @Override
    public void onFinished(File data) {
        updateStage(DownloadStages.DOWNLOAD_FILES, 100);
    }

    @Override
    public void onError(Throwable throwable) {
        markError();
    }

}
