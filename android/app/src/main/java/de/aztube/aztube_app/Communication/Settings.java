package de.aztube.aztube_app.Communication;

import com.google.gson.annotations.SerializedName;

public class Settings {

    @SerializedName("background")
    private boolean settingAutoDownload;
    @SerializedName("device")
    private String deviceToken;

    public Settings() {
    }

    public Settings(boolean settingAutoDownload, String deviceToken) {
        this.settingAutoDownload = settingAutoDownload;
        this.deviceToken = deviceToken;
    }

    public boolean isSettingAutoDownload() {
        return settingAutoDownload;
    }

    public void setSettingAutoDownload(boolean settingAutoDownload) {
        this.settingAutoDownload = settingAutoDownload;
    }

    public String getDeviceToken() {
        return deviceToken;
    }

    public void setDeviceToken(String deviceToken) {
        this.deviceToken = deviceToken;
    }
}
