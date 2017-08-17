package io.rnkit.sensor;

import android.content.Context;

import java.util.List;

/**
 * Created by carlos on 2017/8/17.
 * 用来跑任务的Runnable
 */

class HandleRunnable implements Runnable{

    private Context context;

    HandleRunnable(Context context){
        this.context = context;
    }

    @Override
    public void run() {
        while (true){
            List<DBModel> dbModels = DBManager.getInstance(context).getUnSend();
            if(dbModels.size()>0){
                for(DBModel dbModel:dbModels){
                    //这里发送给后台
                }
            }else {
                break;
            }
        }
    }
}
