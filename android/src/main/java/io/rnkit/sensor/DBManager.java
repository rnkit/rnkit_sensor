package io.rnkit.sensor;

import android.content.Context;
import android.database.Cursor;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by carlos on 2017/8/17.
 * 数据库管理类
 */

public class DBManager {
    private DBHelper dbHelper;
    private SQLiteDatabase database;

    private static DBManager dbManager;

    private DBManager(Context context) {
        dbHelper = new DBHelper(context);
        database = dbHelper.getWritableDatabase();
    }

    /**
     * 单例
     */
    public static DBManager getInstance(Context context) {
        if (dbManager == null) {
            synchronized (DBManager.class) {
                dbManager = new DBManager(context);
            }
        }
        return dbManager;
    }

    /**
     * 存储
     *
     * @param json       要存储的josn字符串
     * @param requestUrl 接口地址
     */
    public void save(String json, String requestUrl) {
        database.beginTransaction();
        try {
            String sql = "insert into " + DBHelper.TABLE_NAME + " (jsonBody,requestUrl,timeStamp,status,times) values ('" + json + "','" + requestUrl + "'," + System.currentTimeMillis() + ",0,0)";
            database.execSQL(sql);
            database.setTransactionSuccessful();
        } catch (SQLException ignored) {

        } finally {
            database.endTransaction();
        }
    }

    /**
     * @return 返回需要发送到后台的数据，最大30条
     */
    public List<DBModel> getUnSend() {
        String sql = "select * from " + DBHelper.TABLE_NAME + " where status=0 or status=2 limit 0,30";
        Cursor cursor = database.rawQuery(sql, new String[0]);
        List<DBModel> list = null;
        while (cursor.moveToNext()) {
            if (list == null) list = new ArrayList<>(cursor.getCount());
            DBModel dbModel = new DBModel();
            dbModel.id = cursor.getInt(cursor.getColumnIndex("id"));
            dbModel.jsonBody = cursor.getString(cursor.getColumnIndex("jsonBody"));
            dbModel.requestUrl = cursor.getString(cursor.getColumnIndex("requestUrl"));
            dbModel.status = cursor.getInt(cursor.getColumnIndex("status"));
            dbModel.times = cursor.getInt(cursor.getColumnIndex("times"));
            dbModel.timeStamp = cursor.getLong(cursor.getColumnIndex("timeStamp"));
            list.add(dbModel);
        }
        cursor.close();
        if (list == null) list = new ArrayList<>(0);
        return list;
    }

    /**
     * 更新某条数据的状态，请求次数
     *
     * @param id     表id
     * @param status 新的状态
     * @param times  请求次数
     */
    private void update(int id, int status, int times) {
        database.beginTransaction();
        try {
            String sql = "update " + DBHelper.TABLE_NAME + " set status=" + status + " times=" + times + " where id = " + id;
            database.execSQL(sql);
            database.setTransactionSuccessful();
        } catch (SQLException ignored) {

        } finally {
            database.endTransaction();
        }
    }

    /**
     * 删除某条数据
     *
     * @param id 要删除的数据的表id
     */
    private void delete(int id) {
        database.beginTransaction();
        try {
            try {
                String sql = "delete from " + DBHelper.TABLE_NAME + " where id = " + id;
                database.execSQL(sql);
                database.setTransactionSuccessful();
            } catch (Exception e) {
                e.printStackTrace();
            }
        } catch (SQLException ignored) {

        } finally {
            database.endTransaction();
        }
    }

}