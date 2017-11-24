package io.rnkit.sensor;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;

/**
 * Created by carlos on 2017/8/17.
 * 用来跑任务的Runnable
 */

class HandleRunnable implements Runnable {

    private Context context;
    private SharedPreferences sharedPreferences;

    HandleRunnable(Context context) {
        this.context = context;
        sharedPreferences = context.getSharedPreferences(DBJsModule.class.getName(), Context.MODE_PRIVATE);
    }

    @Override
    public void run() {
        StaticUtil.allowAllSSL();
        //一次最多循环5次
        int loopTimes = 0;
        while (true) {
            if (loopTimes > 4) {
                break;
            }
            loopTimes++;
            //如果没有初始化，就终止循环
            if (StaticUtil.appKey.equals("")) {
                break;
            }
            //如果没有网络，就终止循环
            if (!StaticUtil.isNetworkAvailable(context)) {
                break;
            }
            List<DBModel> dbModels = DBManager.getInstance(context).getUnSend();
            if (dbModels.size() > 0) {
                for (DBModel dbModel : dbModels) {
                    if (dbModel.times > StaticUtil.REPEAT_TIMES && dbModel.priority > 0) {
                        DBManager.getInstance(context).delete(dbModel.id);
                        String eventType = StaticUtil.getEventType(dbModel.jsonBody);
                        if (eventType != null && !eventType.equals(StaticUtil.logEvent)) {
                            DBManager.getInstance(context).save(StaticUtil.addLog(dbModel.jsonBody,"事件因为失败次数过多而删除"), dbModel.requestUrl, 0);
                        }
                        int failTimes = sharedPreferences.getInt(StaticUtil.KEY_FAIL_TIMES, 0);
                        sharedPreferences.edit().putInt(StaticUtil.KEY_FAIL_TIMES, ++failTimes).apply();
                        continue;
                    }
                    //这里发送给后台
                    try {
                        JSONObject jsonObject = new JSONObject();
                        long timeStamp = System.currentTimeMillis();
                        jsonObject.put("timestamp", timeStamp);
                        jsonObject.put("distinct_id", StaticUtil.deviceId);
                        jsonObject.put("bizType", "B005");
                        JSONArray jsonArray = new JSONArray();
                        jsonArray.put(new JSONObject(dbModel.jsonBody));
                        jsonObject.put("events", jsonArray);
                        String result = StaticUtil.sendPost(dbModel.requestUrl, jsonObject.toString(), timeStamp);
                        if (result.contains("Exception") || result.length() <= 0) {
                            //发送失败
                            DBManager.getInstance(context).update(dbModel.id, 2, ++dbModel.times);
                        } else {
                            JSONObject resultJSON = new JSONObject(result);
                            if (resultJSON.optString("flag") != null && resultJSON.optString("flag").equals("S")) {
                                //说明发送成功
                                DBManager.getInstance(context).delete(dbModel.id);
                                String eventType = StaticUtil.getEventType(dbModel.jsonBody);
                                if (eventType != null && !eventType.equals(StaticUtil.logEvent)) {
                                    DBManager.getInstance(context).save(StaticUtil.addLog(dbModel.jsonBody,"事件发送到服务器成功"), dbModel.requestUrl, 0);
                                }
                            } else {
                                //发送失败
                                DBManager.getInstance(context).update(dbModel.id, 2, ++dbModel.times);
                            }
                        }
                    } catch (JSONException e) {
                        e.printStackTrace();
                        DBManager.getInstance(context).update(dbModel.id, 2, ++dbModel.times);
                    }
                }
            } else {
                break;
            }
        }
    }
}
