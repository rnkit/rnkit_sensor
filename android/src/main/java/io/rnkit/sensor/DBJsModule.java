package io.rnkit.sensor;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

/**
 * Created by carlos on 2017/8/17.
 * 供JS调用的接口
 */

public class DBJsModule extends ReactContextBaseJavaModule {

    public DBJsModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNKitSENSOR";
    }

    @ReactMethod
    public void save(String jsonBody,String requestUrl){
        DBManager.getInstance(getReactApplicationContext()).save(jsonBody,requestUrl);
    }

    @ReactMethod
    public void check(){
        StaticUtil.singleThreadExecutor.execute(new HandleRunnable(getReactApplicationContext()));
    }
}
