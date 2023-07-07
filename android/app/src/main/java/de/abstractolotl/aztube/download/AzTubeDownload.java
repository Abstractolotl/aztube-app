package de.abstractolotl.aztube.download;

import de.abstractolotl.aztube.DownloadRequest;

public class AzTubeDownload {

    public void startDownload(DownloadRequest request, AzTubeProgressUpdater progressUpdater) {
        // Gather Meta Info
        progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.META_DATA, 100);
        // Download Files (video and/or audio files)
        progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.DOWNLOAD_FILES, 100);
        // Convert Files (if neccessary)
        progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.CONVERT_FILES, 100);
        // Output (write thumbnail, meta inf, etc)
        progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.OUTPUT, 100);
    }


}
