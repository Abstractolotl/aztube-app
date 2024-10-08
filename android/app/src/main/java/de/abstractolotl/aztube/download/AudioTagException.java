package de.abstractolotl.aztube.download;

import lombok.Data;
import lombok.experimental.StandardException;

import java.io.File;

@Data
@StandardException
public class AudioTagException extends Exception {

    private File mediaFile;

}
