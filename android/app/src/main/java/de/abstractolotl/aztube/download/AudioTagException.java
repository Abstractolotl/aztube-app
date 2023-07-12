package de.abstractolotl.aztube.download;

import java.io.File;

public class AudioTagException extends Exception {

    private File mediaFile;

    public AudioTagException(File mediaFile, Throwable cause) {
        super(cause);
        this.mediaFile = mediaFile;
    }

    public File getMediaFile() {
        return mediaFile;
    }
}
