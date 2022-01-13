package de.aztube.aztube_app.Communication;

public class DownloadRequest {

    private int downloadId;
    private String videoId;
    private String title;
    private String author;
    private String quality;

    public DownloadRequest() {
    }

    public DownloadRequest(int downloadId, String videoId, String title, String author, String quality) {
        this.downloadId = downloadId;
        this.videoId = videoId;
        this.title = title;
        this.author = author;
        this.quality = quality;
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

    public String getQuality() {
        return quality;
    }

    public void setQuality(String quality) {
        this.quality = quality;
    }
}
