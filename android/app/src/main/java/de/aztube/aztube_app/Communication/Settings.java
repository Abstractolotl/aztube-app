package de.aztube.aztube_app.Communication;

import com.google.gson.annotations.SerializedName;

public class Settings {

    @SerializedName("background")
    private boolean settingAutoDownload;
    @SerializedName("device")
    private String deviceToken;
    @SerializedName("notifications")
    private boolean showNotifications;

    public Settings() {
    }

    public Settings(boolean settingAutoDownload, String deviceToken, boolean showNotifications) {
        this.settingAutoDownload = settingAutoDownload;
        this.deviceToken = deviceToken;
        this.showNotifications = showNotifications;
    }

    public boolean isShowNotifications() {
        return showNotifications;
    }

    public void setShowNotifications(boolean showNotifications) {
        this.showNotifications = showNotifications;
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
