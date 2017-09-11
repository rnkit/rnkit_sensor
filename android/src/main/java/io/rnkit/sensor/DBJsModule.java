package io.rnkit.sensor;

import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;

import java.util.List;

/**
 * Created by carlos on 2017/8/17.
 * 供JS调用的接口
 */

public class DBJsModule extends ReactContextBaseJavaModule {

    private SharedPreferences sharedPreferences;

    public DBJsModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNKitSensor";
    }

    /**
     * 存储到本地数据库
     *
     * @param jsonBody   埋点数据
     * @param requestUrl 请求的Url
     * @param priority   这条埋点数据的url
     */
    @ReactMethod
    public void save(String jsonBody, String requestUrl, int priority) {
        //存储进数据库
        DBManager.getInstance(getReactApplicationContext()).save(jsonBody, requestUrl, priority);
    }

    /**
     * 检查本地是否有没有发送的埋点
     */
    @ReactMethod
    public void check() {
        //启动一个线程检查任务
        StaticUtil.singleThreadExecutor.execute(new HandleRunnable(getReactApplicationContext()));
    }

    /**
     * 初始化
     *
     * @param appKey      服务器分配的appKey
     * @param maxVolume   一次最大上传的埋点条数
     * @param repeatTimes 最大尝试次数
     */
    @ReactMethod
    public void initial(String appKey, int maxVolume, int repeatTimes) {
        StaticUtil.appKey = appKey;
        StaticUtil.MAX_VOLUME = maxVolume;
        StaticUtil.REPEAT_TIMES = repeatTimes;
        StaticUtil.deviceId = StaticUtil.getDeviceId(getReactApplicationContext());
        if (StaticUtil.deviceId == null)
            StaticUtil.deviceId = "";
    }

    @Override
    public boolean canOverrideExistingModule() {
        return true;
    }

    @ReactMethod
    public void getAppList(Promise promise) {
        PackageManager pm = getReactApplicationContext().getPackageManager();
        List<PackageInfo> packages = pm.getInstalledPackages(0);
        WritableArray writableArray = Arguments.createArray();
        for (PackageInfo packageInfo : packages) {
            if ((packageInfo.applicationInfo.flags & ApplicationInfo.FLAG_SYSTEM) == 0) {
                writableArray.pushString(pm.getApplicationLabel(packageInfo.applicationInfo).toString());
            }
        }
        if (writableArray.size() <= 0) {
            promise.reject("安装列表为空", "安装列表为空");
        } else {
            promise.resolve(writableArray);
        }
    }

    @ReactMethod
    public void saveValue(String key, int value) {
        if (sharedPreferences == null) {
            sharedPreferences = getReactApplicationContext().getSharedPreferences(this.getClass().getName(), Context.MODE_PRIVATE);
        }
        sharedPreferences.edit().putInt(key, value).apply();
    }

    @ReactMethod
    public void getValue(String key, Promise promise) {
        if (sharedPreferences == null) {
            sharedPreferences = getReactApplicationContext().getSharedPreferences(this.getClass().getName(), Context.MODE_PRIVATE);
        }
        int i = sharedPreferences.getInt(key, 0);
        if (i == 0) {
            promise.resolve(0);
        } else {
            promise.reject("没有这个值", "没有这个值");
        }
    }
}
