package com.reactlibrary;

import android.content.Context;
import android.content.res.Resources;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import org.apache.commons.codec.binary.Hex;
import org.apache.commons.codec.digest.DigestUtils;


import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableNativeMap;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Headers;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okio.BufferedSink;
import okio.BufferedSource;
import okio.Okio;

import static com.facebook.react.modules.network.OkHttpClientProvider.getOkHttpClient;

public class EasyFileSystemModule extends ReactContextBaseJavaModule {

    private static final String NAME = "EasyFileSystem";
    private static final String TAG = "EasyFileSystem";
    private final ReactApplicationContext reactContext;
    private static final String HEADER_KEY = "headers";

    private OkHttpClient mClient;

    public EasyFileSystemModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        try {
        ensureDirExists(this.reactContext.getFilesDir());
        ensureDirExists(this.reactContext.getCacheDir());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Override
    public String getName() {
        return "EasyFileSystem";
    }

    @Override
    public Map<String, Object> getConstants() {
        Map<String, Object> constants = new HashMap<>();
        constants.put("documentDirectory", Uri.fromFile(this.reactContext.getFilesDir()).toString() + "/");
        constants.put("cacheDirectory", Uri.fromFile(this.reactContext.getCacheDir()).toString() + "/");

        return constants;
    }

    private File uriToFile(Uri uri) {
        return new File(uri.getPath());
    }

    private void checkIfFileDirExists(Uri uri) throws IOException {
        File file = uriToFile(uri);
        File dir = file.getParentFile();
        if (!dir.exists()) {
            throw new IOException("Directory for " + file.getPath() + " doesn't exist.");
        }
    }


    @ReactMethod
    public void downloadAsync(String url, final String uriStr, final ReadableMap options, final Promise promise) {
        try {
            final Uri uri = Uri.parse(uriStr);
            checkIfFileDirExists(uri);

            if (!url.contains(":")) {
                Context context = this.reactContext;
                Resources resources = context.getResources();
                String packageName = context.getPackageName();
                int resourceId = resources.getIdentifier(url, "raw", packageName);

                BufferedSource bufferedSource = Okio.buffer(Okio.source(context.getResources().openRawResource(resourceId)));
                File file = uriToFile(uri);
                file.delete();
                BufferedSink sink = Okio.buffer(Okio.sink(file));
                sink.writeAll(bufferedSource);
                sink.close();

                Bundle result = new Bundle();
                result.putString("uri", Uri.fromFile(file).toString());
                if (options != null && options.hasKey("md5") && options.getBoolean("md5")) {
                    result.putString("md5", md5(file));
                }
                promise.resolve(result);
            } else if ("file".equals(uri.getScheme())) {
                Request.Builder requestBuilder = new Request.Builder().url(url);
                if (options != null && options.hasKey(HEADER_KEY)) {
                    final Map<String, Object> headers = (Map<String, Object>) options.getMap(HEADER_KEY);
                    for (String key : headers.keySet()) {
                        requestBuilder.addHeader(key, headers.get(key).toString());
                    }
                }
                getOkHttpClient().newCall(requestBuilder.build()).enqueue(new Callback() {
                    @Override
                    public void onFailure(Call call, IOException e) {
                        Log.e(TAG, e.getMessage());
                        promise.reject(e);
                    }

                    @Override
                    public void onResponse(Call call, Response response) throws IOException {
                        File file = uriToFile(uri);
                        file.delete();
                        BufferedSink sink = Okio.buffer(Okio.sink(file));
                        sink.writeAll(response.body().source());
                        sink.close();

                        WritableNativeMap result = new WritableNativeMap();
                        result.putString("uri", Uri.fromFile(file).toString());
                        if (options != null && options.hasKey("md5") && options.getBoolean("md5")) {
                            result.putString("md5", md5(file));
                        }
                        result.putInt("status", response.code());
                        result.putMap("headers", translateHeaders(response.headers()));
                        promise.resolve(result);
                    }
                });
            } else {
                throw new IOException("Unsupported scheme for location '" + uri + "'.");
            }
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
            promise.reject(e);
        }
    }

    private String md5(File file) throws IOException {
        InputStream is = new FileInputStream(file);
        try {
            byte[] md5bytes = DigestUtils.md5(is);
            return String.valueOf(Hex.encodeHex(md5bytes));
        } finally {
            is.close();
        }
    }

    private void ensureDirExists(File dir) throws IOException {
        if (!(dir.isDirectory() || dir.mkdirs())) {
            throw new IOException("Couldn't create directory '" + dir + "'");
        }
    }

    private static WritableNativeMap translateHeaders(Headers headers) {
        WritableNativeMap responseHeaders = new WritableNativeMap();
        for (int i = 0; i < headers.size(); i++) {
            String headerName = headers.name(i);
            // multiple values for the same header
            if (responseHeaders.hasKey(headerName)) {
                responseHeaders.putString(
                        headerName,
                        responseHeaders.getString(headerName) + ", " + headers.value(i));
            } else {
                responseHeaders.putString(headerName, headers.value(i));
            }
        }
        return responseHeaders;
    }
}
