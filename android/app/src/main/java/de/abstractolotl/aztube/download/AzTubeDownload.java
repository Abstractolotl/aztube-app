package de.abstractolotl.aztube.download;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import com.arthenica.ffmpegkit.FFmpegKit;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import de.abstractolotl.aztube.DownloadRequest;
import de.abstractolotl.aztube.MainActivity;
import de.abstractolotl.aztube.VideoQuality;
import org.jaudiotagger.audio.AudioFile;
import org.jaudiotagger.audio.AudioFileIO;
import org.jaudiotagger.audio.exceptions.CannotReadException;
import org.jaudiotagger.audio.exceptions.InvalidAudioFrameException;
import org.jaudiotagger.audio.exceptions.ReadOnlyFileException;
import org.jaudiotagger.tag.*;
import org.jaudiotagger.tag.images.ArtworkFactory;

import java.io.*;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class AzTubeDownload {

    private static final YoutubeDownloader ytdl = new YoutubeDownloader();

    private final DownloadRequest request;
    private final AzTubeProgressUpdater progressUpdater;

    private final List<File> tmpFiles = new LinkedList<>();

    private AzTubeDownload(DownloadRequest request, AzTubeProgressUpdater progressUpdater) {
        this.request = request;
        this.progressUpdater = progressUpdater;
    }

    public static File startDownload(DownloadRequest request, AzTubeProgressUpdater progressUpdater) throws Exception {
        if(request.getVideoQuality() != VideoQuality.AUDIO) {
            throw new UnsupportedOperationException("Not yet implemented");
        }

        var download = new AzTubeDownload(request, progressUpdater);
        try {
            return download.startAudioOnlyDownload();
        } finally {
            download.tmpFiles.forEach(f -> Log.d("DEBUG", "Deleting file: " + f.getAbsolutePath()));
            download.tmpFiles.forEach(File::delete);
        }
    }

    private VideoInfo getVideoInfo() throws Exception {
        var infoResponse = ytdl.getVideoInfo(new RequestVideoInfo(request.getVideoId()));
        if (infoResponse == null || !infoResponse.ok()) {
            throw new Exception("Could not get VideoInfo", infoResponse != null ? infoResponse.error() : null);
        }
        return infoResponse.data();
    }

    private File getMedia(Format format) throws Exception {
        var ytdlRequest = new RequestVideoFileDownload(format)
                .saveTo(new File(MainActivity.DOWNLOAD_DIR))
                .callback(progressUpdater)
                .renameTo(request.getDownloadId() + "_media");

        var ytdlResponse = ytdl.downloadVideoFile(ytdlRequest);
        if (ytdlResponse == null || !ytdlResponse.ok()) {
            throw new Exception("Could not download video", ytdlResponse != null ? ytdlResponse.error() : null);
        }

        return ytdlResponse.data();
    }

    private void convertMedia(Format format, File mediaFile, File outputFile) throws Exception {
        AtomicBoolean done = new AtomicBoolean();
        FFmpegKit.executeAsync("-i \"" + mediaFile.getAbsolutePath() + "\" \"" + outputFile.getAbsolutePath() + "\"",
                (session) -> {
                    synchronized (done) {
                        done.set(true);
                        done.notify();
                    }
                },
                null,
                (statistics) -> {
                    double progress = 100 * (statistics.getTime() / (float) format.duration());
                    progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.CONVERT_FILES, progress);
                });

        synchronized (done) {
            while(!done.get()) {
                done.wait();
            }
        }
    }

    private String thumbnailFilePath() {
        return MainActivity.DOWNLOAD_DIR + request.getDownloadId() + "_thumbnail.jpg";
    }

    private String outputFilePath(Format format) {
        return MainActivity.DOWNLOAD_DIR + request.getDownloadId() + "." + format.extension().value();
    }

    private File startAudioOnlyDownload() throws Exception {
        var info = getVideoInfo();

        AudioFormat format = info.bestAudioFormat();
        progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.META_DATA, 100);

        File thumbnailFile = new File(thumbnailFilePath());
        tmpFiles.add(thumbnailFile);
        downloadThumbnail(request.getVideoId(), thumbnailFile);

        File mediaFile = getMedia(format);
        tmpFiles.add(mediaFile);

        File outputFile = new File(outputFilePath(format));
        tmpFiles.add(outputFile);

        convertMedia(format, mediaFile, outputFile);
        progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.CONVERT_FILES, 100);

        writeMetaInfoToAudioFile(outputFile, request.getTitle(), request.getAuthor(), thumbnailFile);
        progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.OUTPUT, 100);

        tmpFiles.remove(outputFile);
        return outputFile;
    }

    private void writeMetaInfoToAudioFile(File audioFile, String title, String author, File thumbnail) throws Exception {
        TagOptionSingleton.getInstance().setAndroid(true);
        AudioFile f = AudioFileIO.read(audioFile);
        Tag tag = f.getTag();
        tag.setField(FieldKey.TITLE, title);
        tag.setField(FieldKey.ARTIST, author);
        tag.setField(FieldKey.ALBUM_ARTIST, author);
        tag.setField(FieldKey.ALBUM, author + " - " + title);
        tag.setField(FieldKey.TRACK, "0");
        tag.setField(ArtworkFactory.createArtworkFromFile(thumbnail));
        AudioFileIO.write(f);
    }

    private void downloadThumbnail(String videoId, File outLocation) {
        try {
            InputStream input = new java.net.URL("https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg").openStream();
            Bitmap bitmap = BitmapFactory.decodeStream(input);

            FileOutputStream out = new FileOutputStream(outLocation);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out);
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }



}
