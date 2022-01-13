package de.aztube.aztube_app.Communication;

import java.util.List;

public class PollResponse {

    private boolean success;
    private String error;

    private List<DownloadRequest> downloads;


    public PollResponse() {
    }

    public PollResponse(boolean success, String error, List<DownloadRequest> downloads) {
        this.success = success;
        this.error = error;
        this.downloads = downloads;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public List<DownloadRequest> getDownloads() {
        return downloads;
    }

    public void setDownloads(List<DownloadRequest> downloads) {
        this.downloads = downloads;
    }
}
