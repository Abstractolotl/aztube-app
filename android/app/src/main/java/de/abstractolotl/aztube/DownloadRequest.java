package de.abstractolotl.aztube;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class DownloadRequest {

    private String videoId;
    private String downloadId;
    private VideoQuality videoQuality;
    private String title;
    private String author;

}
