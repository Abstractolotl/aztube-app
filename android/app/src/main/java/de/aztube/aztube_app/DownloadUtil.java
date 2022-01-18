package de.aztube.aztube_app;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Environment;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import com.github.kiulian.downloader.model.videos.formats.VideoFormat;
import com.github.kiulian.downloader.model.videos.formats.VideoWithAudioFormat;
import de.aztube.aztube_app.Services.Download.DownloadException;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class DownloadUtil {

    public static String getThumbnailUrl(String videoId) {
        return "https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg";
    }

    public static String downloadThumbnail(Context context, String videoId, int downloadId) {
        String thumbnail = context.getExternalFilesDir(Environment.DIRECTORY_MOVIES) + "/thumbnail_" + downloadId + ".jpg";

        try {
            InputStream input = new java.net.URL(getThumbnailUrl(videoId)).openStream();
            Bitmap bitmap = BitmapFactory.decodeStream(input);

            FileOutputStream out = new FileOutputStream(thumbnail);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out);
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
            return thumbnail = null;
        }

        return thumbnail;
    }

    public static VideoInfo requestVideoInfo(String videoId) {
        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();
        RequestVideoInfo request = new RequestVideoInfo(videoId);
        return youtubeDownloader.getVideoInfo(request).data();
    }

    public static List<Format> pickVideoFormat(VideoInfo videoInfo, String quality) {
        List<VideoWithAudioFormat> videoWithAudioFormats = videoInfo.videoWithAudioFormats();
        List<VideoFormat> videoFormats = videoInfo.videoFormats();
        List<AudioFormat> audioFormats = videoInfo.audioFormats();
        ArrayList<Format> formats = new ArrayList<>();

        boolean isAudio = quality.equals("audio");

        AudioFormat bestAudioFormat = null;
        if(audioFormats.size() <= 0) {
            if(isAudio) throw new DownloadException("No Audio Formats available");
        } else {
            bestAudioFormat = audioFormats.get(0);
            for (AudioFormat af : audioFormats) {
                if (af.averageBitrate() > bestAudioFormat.averageBitrate()) {
                    bestAudioFormat = af;
                }
            }
        }

        if(isAudio){
            formats.add(bestAudioFormat);
            return formats;
        }

        //has exact Video Format with audio?
        for(VideoWithAudioFormat vf : videoWithAudioFormats){
            if (vf.qualityLabel().equals(quality)) {
                formats.add(vf);
                return formats;
            }
        }

        //no format with audio + video, have to merge manually
        formats.add(bestAudioFormat);
        for (VideoFormat vf : videoFormats) {
            if (vf.qualityLabel().equals(quality)) {
                formats.add(vf);
                return formats;
            }
        }

        //Fallback: download best VideoWithAudio Format
        throw new DownloadException("Could not find suitable format");
    }

}
