package de.aztube.aztube_app;

import android.content.ContextWrapper;
import android.os.Environment;

import androidx.annotation.NonNull;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.YoutubeProgressCallback;
import com.github.kiulian.downloader.downloader.request.RequestVideoFileDownload;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import com.github.kiulian.downloader.model.videos.formats.VideoWithAudioFormat;

import java.io.File;
import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    public static final String CHANNEL = "de.aztube.aztube_app/youtube";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("downloadVideo")) {
                        new Async<File>().run(() -> requestVideoInfo(call.argument("videoId"), call.argument("quality")), (data) -> {
                            if (data != null) {
                                result.success(data.getAbsolutePath());
                            }

                            return null;
                        });
                    } else if (call.method.equals("getMediaDir")) {
                        result.success(getMediaDir());
                    }
                });
    }


    public File requestVideoInfo(String videoId, String quality) {
        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        RequestVideoInfo request = new RequestVideoInfo(videoId);

        VideoInfo data = youtubeDownloader.getVideoInfo(request).data();

        String videoTitle = data.details().title();
        List<String> thumbnails = data.details().thumbnails();

        List<VideoWithAudioFormat> videoFormats = data.videoWithAudioFormats();
        List<AudioFormat> audioFormats = data.audioFormats();

        System.out.println(videoTitle);
        System.out.println(videoFormats);
        System.out.println(audioFormats);

        Format format = null;

        if(quality.equals("audio_only")){
            if(audioFormats.size() > 0){
                format = audioFormats.get(0);

                for(AudioFormat audioFormat : audioFormats){
                    if(audioFormat.averageBitrate() > ((AudioFormat) format).averageBitrate()){
                        format = audioFormat;
                    }
                }
            }else{
                System.out.println("No audio formats available!");
                return null;
            }
        }else{
            for(VideoWithAudioFormat videoFormat : videoFormats){
                if(videoFormat.qualityLabel().equals(quality)){
                    format = videoFormat;
                    break;
                }
            }

            if(format == null){
                System.out.println("Could not find video format!");
                return null;
            }
        }

        return downloadVideo(format);
    }

    public File downloadVideo(Format format) {
        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();

        RequestVideoFileDownload request = new RequestVideoFileDownload(format).saveTo(new File(getMediaDir())).overwriteIfExists(true).callback(new YoutubeProgressCallback<File>() {
            @Override
            public void onDownloading(int progress) {
                System.out.println(progress);
            }

            @Override
            public void onFinished(File data) {
                System.out.println("Finished!");
            }

            @Override
            public void onError(Throwable throwable) {
                System.out.println("Error downloading video");
            }
        });

        return youtubeDownloader.downloadVideoFile(request).data();
    }

    public String getMediaDir() {
        ContextWrapper contextWrapper = new ContextWrapper(this);
        return contextWrapper.getExternalFilesDir(Environment.DIRECTORY_MOVIES).toString();
    }
}