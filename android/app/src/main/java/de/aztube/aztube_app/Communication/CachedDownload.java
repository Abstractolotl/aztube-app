package de.aztube.aztube_app.Communication;

public class CachedDownload {

    private int downloadId;
    private String videoId;
    private String quality;
    private String title;
    private String author;
    private boolean downloaded;
    private String savedTo;
    private String fileName;

    public CachedDownload(int downloadId, String videoId, String quality, String title, String author, boolean downloaded, String savedTo, String fileName) {
        this.downloadId = downloadId;
        this.videoId = videoId;
        this.quality = quality;
        this.title = title;
        this.author = author;
        this.downloaded = downloaded;
        this.savedTo = savedTo;
        this.fileName = fileName;
    }

    public CachedDownload() {
    }

    public int getDownloadId() {
        return downloadId;
    }

    public void setDownloadId(int downloadId) {
        this.downloadId = downloadId;
    }

    public String getVideoId() {
        return videoId;
    }

    public void setVideoId(String videoId) {
        this.videoId = videoId;
    }

    public String getQuality() {
        return quality;
    }

    public void setQuality(String quality) {
        this.quality = quality;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public boolean isDownloaded() {
        return downloaded;
    }

    public void setDownloaded(boolean downloaded) {
        this.downloaded = downloaded;
    }

    public String getSavedTo() {
        return savedTo;
    }

    public void setSavedTo(String savedTo) {
        this.savedTo = savedTo;
    }

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }
}
