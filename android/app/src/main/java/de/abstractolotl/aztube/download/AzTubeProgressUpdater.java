package de.abstractolotl.aztube.download;

import de.abstractolotl.aztube.AzTubePlatform;
import de.abstractolotl.aztube.GenericStageProgressUpdater;

import java.util.HashMap;

public class AzTubeProgressUpdater extends GenericStageProgressUpdater<AzTubeProgressUpdater.DownloadStages> {

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

    private final AzTubePlatform platform;
    private final String downloadId;

    public AzTubeProgressUpdater(AzTubePlatform platform, String downloadId) {
        super(WEIGHTS);
        this.platform = platform;
        this.downloadId = downloadId;
    }

    @Override
    protected void performUpdate() {
        platform.sendProgressUpdate(downloadId, calculateWeightedProgress());
    }

}
