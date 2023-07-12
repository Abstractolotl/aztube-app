package de.abstractolotl.aztube;

import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;

import java.io.*;
public class MediaStoreUtil {

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

    private static Uri saveToMediaStore(Context context, Uri collection, ContentValues contentValues, File toSave) throws IOException {
        Uri uriSaved =  context.getContentResolver().insert(collection, contentValues);

        writeToFileDescriptor(context, toSave, uriSaved);

        contentValues.put("is_pending", 0);
        context.getContentResolver().update(uriSaved, contentValues, null, null);
        return uriSaved;
    }

    public static Uri saveAudioToMediaStore(Context context, File toSave, String title, String author) throws IOException {
        String fileExtension = toSave.getName().substring(toSave.getName().lastIndexOf("."));

        ContentValues contentValues = new ContentValues();
        contentValues.put(MediaStore.Audio.Media.TITLE, title);
        contentValues.put(MediaStore.Audio.Media.ARTIST, author);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
            contentValues.put(MediaStore.Audio.Media.ALBUM_ARTIST, author);
        contentValues.put(MediaStore.Audio.Media.DISPLAY_NAME, title + fileExtension);
        contentValues.put(MediaStore.Audio.Media.MIME_TYPE, getMIMEType(toSave));
        contentValues.put(MediaStore.Audio.Media.RELATIVE_PATH, "Music");
        contentValues.put(MediaStore.Audio.Media.IS_PENDING, 1);

        Uri collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
        return saveToMediaStore(context, collection, contentValues, toSave);
    }


    public static String getMIMEType(File file) {
        String mType = null;
        String mExtension = MimeTypeMap.getFileExtensionFromUrl(file.getName());
        if (mExtension != null) {
            mType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(mExtension);
        }
        return mType;
    }

}
