package de.abstractolotl.java;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.downloader.response.Response;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.yausername.youtubedl_android.YoutubeDL;
import com.yausername.youtubedl_android.YoutubeDLException;
import com.yausername.youtubedl_android.YoutubeDLRequest;
import org.junit.Test;

import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

public class SomeTest {

    @Test
    public void someTest() throws YoutubeDLException, YoutubeDL.CanceledException, InterruptedException {
        YoutubeDownloader downloader = new YoutubeDownloader();
        Response<VideoInfo> response = downloader.getVideoInfo(new RequestVideoInfo("88VEBN7QIoo"));
        assertTrue(response.ok());
        VideoInfo video = response.data();
        assertTrue(video != null);
        System.out.println(video.formats().size());
    }

}
