package de.abstractolotl.aztube.download;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import com.arthenica.ffmpegkit.FFmpegKit;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import de.abstractolotl.aztube.DownloadRequest;
import de.abstractolotl.aztube.MainActivity;
import de.abstractolotl.aztube.VideoQuality;
import org.jaudiotagger.audio.AudioFile;
import org.jaudiotagger.audio.AudioFileIO;
import org.jaudiotagger.tag.*;
import org.jaudiotagger.tag.images.ArtworkFactory;

import java.io.*;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

public class AzTubeDownload {

    private final YoutubeDownloader ytdl = new YoutubeDownloader();

    public File startDownload(DownloadRequest request, AzTubeProgressUpdater progressUpdater) {
        if(request.getVideoQuality() != VideoQuality.AUDIO) {
            throw new UnsupportedOperationException("Not yet implemented");
        }

        return startAudioOnlyDownload(request, progressUpdater);
    }

    private File startAudioOnlyDownload(DownloadRequest request, AzTubeProgressUpdater progressUpdater) {
        List<File> tmpFiles = new LinkedList<>();
        try {
            // Gather Meta Info
            var info = ytdl.getVideoInfo(new RequestVideoInfo(request.getVideoId())).data();
            var format = info.bestAudioFormat();
            progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.META_DATA, 100);

            // Download Files (video and/or audio files)
            File thumbnailFile = new File(MainActivity.DOWNLOAD_DIR + request.getDownloadId() + "_thumbnail.jpg" );
            tmpFiles.add(thumbnailFile);

            downloadThumbnail(request.getVideoId(), thumbnailFile);
            var ytdlRequest = new RequestVideoFileDownload(format)
                    .saveTo(new File(MainActivity.DOWNLOAD_DIR))
                    .callback(progressUpdater)
                    .renameTo(request.getDownloadId() + "_media");
            File mediaFile = ytdl.downloadVideoFile(ytdlRequest).data();
            tmpFiles.add(mediaFile);

            // Convert Files (if neccessary)
            File outputFile = new File(MainActivity.DOWNLOAD_DIR + request.getDownloadId() + "." + format.extension().value());
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

            progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.CONVERT_FILES, 100);

            // Output (write thumbnail, meta inf, etc)
            writeMetaInfoToAudioFile(outputFile, request.getTitle(), request.getAuthor(), thumbnailFile);
            progressUpdater.updateStage(AzTubeProgressUpdater.DownloadStages.OUTPUT, 100);

            return outputFile;
        } catch (AudioTagException e) {
            e.getMediaFile().delete();
            progressUpdater.markError();
            throw new RuntimeException("Error during download", e);
        } catch (InterruptedException e) {
            progressUpdater.markError();
            throw new RuntimeException("Error during download", e);
        } finally {
            tmpFiles.forEach(f -> Log.d("DEBUG", "Deleting file: " + f.getAbsolutePath()));
            tmpFiles.forEach(File::delete);
        }

    }

    private void writeMetaInfoToAudioFile(File audioFile, String title, String author, File thumbnail) throws AudioTagException {
        try {
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
        } catch (Exception e) {
            throw new AudioTagException(audioFile, e);
        }
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
