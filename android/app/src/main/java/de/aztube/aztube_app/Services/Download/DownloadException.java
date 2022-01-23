package de.aztube.aztube_app.Services.Download;

public class DownloadException extends RuntimeException{

    public DownloadException(String message) {
        super(message);
    }

    public DownloadException(String message, Throwable cause) {
        super(message, cause);
    }
}
