package de.aztube.aztube_app;

import android.content.ContextWrapper;
import android.os.Environment;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

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
import kotlin.Unit;
import kotlin.coroutines.Continuation;

public class MainActivity extends FlutterActivity {
    public static final String CHANNEL = "de.aztube.aztube_app/youtube";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine){
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if(call.method.equals("downloadVideo")){
                        AsyncTask async = new AsyncTask<File>(){
                            @Nullable
                            @Override
                            public Object publishProgress(File value, @NonNull Continuation<? super Unit> $completion) {
                                if(value != null){
                                    result.success(value.getAbsolutePath());
                                }

                                return null;
                            }

                            @Nullable
                            @Override
                            public Object background(@NonNull Continuation<? super Unit> $completion) {
                                updateProgress(requestVideoInfo(call.argument("videoId")));
                                return null;
                            }
                        };

                        async.execute();
                    }else if(call.method.equals("getMediaDir")){
                        result.success(getMediaDir());
                    }
                });
    }



    public File requestVideoInfo(String videoId){
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

        return downloadVideo(videoFormats.get(2));
    }

    public File downloadVideo(Format format){
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

    public String getMediaDir(){
        ContextWrapper contextWrapper = new ContextWrapper(this);
        return contextWrapper.getExternalFilesDir(Environment.DIRECTORY_MOVIES).toString();
    }
}