package de.aztube.aztube_app.Download;

import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;
import com.github.kiulian.downloader.YoutubeDownloader;
import com.github.kiulian.downloader.downloader.request.RequestVideoInfo;
import com.github.kiulian.downloader.model.videos.VideoInfo;
import com.github.kiulian.downloader.model.videos.formats.AudioFormat;
import com.github.kiulian.downloader.model.videos.formats.Format;
import com.github.kiulian.downloader.model.videos.formats.VideoFormat;
import com.github.kiulian.downloader.model.videos.formats.VideoWithAudioFormat;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

public class DownloadUtil {

    public static String getThumbnailUrl(String videoId) {
        return "https://img.youtube.com/vi/" + videoId + "/hqdefault.jpg";
    }

    public static void downloadThumbnail(Context context, String videoId, int downloadId, String outLocation) {
        try {
            InputStream input = new java.net.URL(getThumbnailUrl(videoId)).openStream();
            Bitmap bitmap = BitmapFactory.decodeStream(input);

            FileOutputStream out = new FileOutputStream(outLocation);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, out);
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void writeToFileDescriptor(Context context, File in, Uri out) throws IOException {
        ParcelFileDescriptor parcelFileDescriptor = context.getContentResolver().openFileDescriptor(out, "w");
        FileOutputStream fileOutputStream = new FileOutputStream(parcelFileDescriptor.getFileDescriptor());
        FileInputStream fileInputStream = new FileInputStream(in);
        byte[] buffer = new byte[1024];
        int length;
        while ((length = fileInputStream.read(buffer)) > 0) {
            fileOutputStream.write(buffer, 0, length);
        }
        fileInputStream.close();
        fileOutputStream.close();
    }

    public static Uri saveToMediaStore(Context context, File toSave, String title, String author, int downloadId) throws IOException {
        String fileExtension = toSave.getName().substring(toSave.getName().lastIndexOf("."));

        ContentValues contentValues = new ContentValues();
        contentValues.put(MediaStore.Audio.Media.TITLE, title);
        contentValues.put(MediaStore.Audio.Media.ARTIST, author);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
            contentValues.put(MediaStore.Audio.Media.ALBUM_ARTIST, author);
        contentValues.put(MediaStore.Audio.Media.DISPLAY_NAME, title + fileExtension);
        contentValues.put(MediaStore.Audio.Media.MIME_TYPE, getMIMEType(toSave.getName()));
        contentValues.put(MediaStore.Audio.Media.RELATIVE_PATH, "Music");
        contentValues.put(MediaStore.Audio.Media.IS_PENDING, 1);

        Uri collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
        Uri uriSaved =  context.getContentResolver().insert(collection, contentValues);

        writeToFileDescriptor(context, toSave, uriSaved);

        contentValues.put(MediaStore.Audio.Media.IS_PENDING, 0);
        context.getContentResolver().update(uriSaved, contentValues, null, null);
        return uriSaved;
    }

    private static String getMIMEType(String url) {
        String mType = null;
        String mExtension = MimeTypeMap.getFileExtensionFromUrl(url);
        if (mExtension != null) {
            mType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(mExtension);
        }
        return mType;
    }

    public static VideoInfo requestVideoInfo(String videoId) {
        YoutubeDownloader youtubeDownloader = new YoutubeDownloader();
        RequestVideoInfo request = new RequestVideoInfo(videoId);
        return youtubeDownloader.getVideoInfo(request).data();
    }


    public static boolean fileExists(Context context, String uri) {
        try {
            InputStream inputStream = context.getContentResolver().openInputStream(Uri.parse(uri));
            inputStream.close();

            return true;
        } catch (IOException e) {
            return false;
        }
    }

    public static void openFile(Context context, String uri) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse(uri));
        context.startActivity(intent);
    }

    public static boolean deleteFile(Context context, String uri) {
        try {
            return context.getContentResolver().delete(Uri.parse(uri), null, null) > 0;
        } catch (SecurityException e) {
            return false;
        }
    }

    public static List<Format> pickVideoFormats(VideoInfo videoInfo, String quality) {
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
