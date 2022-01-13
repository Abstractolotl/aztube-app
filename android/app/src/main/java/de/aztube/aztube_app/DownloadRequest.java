package de.aztube.aztube_app;

public class DownloadRequest {

    private int downloadID;
    private String videoID;
    private String title;
    private String author;
    private String quality;

    public DownloadRequest() {
    }

    public DownloadRequest(int downloadID, String videoID, String title, String author, String quality) {
        this.downloadID = downloadID;
        this.videoID = videoID;
        this.title = title;
        this.author = author;
        this.quality = quality;
    }

    public int getDownloadID() {
        return downloadID;
    }

    public void setDownloadID(int downloadID) {
        this.downloadID = downloadID;
    }

    public String getVideoID() {
        return videoID;
    }

    public void setVideoID(String videoID) {
        this.videoID = videoID;
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
