package de.aztube.aztube_app.Communication;

import java.util.ArrayList;
import java.util.List;

public class Cache {

    private List<CachedDownload> queue;
    private List<CachedDownload> downloaded;

    public Cache(List<CachedDownload> queue, List<CachedDownload> downloaded) {
        this.queue = queue;
        this.downloaded = downloaded;
    }

    public Cache() {
        this.queue = new ArrayList<>();
        this.downloaded = new ArrayList<>();
    }

    public List<CachedDownload> getQueue() {
        return queue;
    }

    public void setQueue(List<CachedDownload> queue) {
        this.queue = queue;
    }

    public List<CachedDownload> getDownloaded() {
        return downloaded;
    }

    public void setDownloaded(List<CachedDownload> downloaded) {
        this.downloaded = downloaded;
    }
}
