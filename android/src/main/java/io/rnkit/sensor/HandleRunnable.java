package io.rnkit.sensor;

import android.content.Context;

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

    HandleRunnable(Context context) {
        this.context = context;
    }

    @Override
    public void run() {
        StaticUtil.allowAllSSL();
        while (true) {
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
                    if (dbModel.times > StaticUtil.REPEAT_TIMES) {
                        DBManager.getInstance(context).delete(dbModel.id);
                        continue;
                    }
                    //这里发送给后台
                    try {
                        JSONObject jsonObject = new JSONObject();
                        long timeStamp = System.currentTimeMillis();
                        jsonObject.put("timestamp", timeStamp);
                        jsonObject.put("distinct_id", StaticUtil.deviceId);
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
