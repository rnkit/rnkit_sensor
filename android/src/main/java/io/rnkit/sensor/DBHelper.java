package io.rnkit.sensor;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

/**
 * Created by carlos on 2017/8/17.
 * 数据库类
 */

class DBHelper extends SQLiteOpenHelper{
    /**
     * 数据库名字
     */
    private static final String DB_NAME = "rnkit_sensor_db";
    /**
     * 表名
     */
    public static final String TABLE_NAME = "rnkit_sensor";
    /**
     * 版本号
     */
    private static final int DB_VERSION = 1;

    DBHelper(Context context) {
        super(context, DB_NAME,null,DB_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase sqLiteDatabase) {
        String sql = "CREATE TABLE IF NOT EXISTS " + TABLE_NAME + "("
                + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                + "jsonBody TEXT,"
                + "requestUrl TEXT,"
                + "timeStamp LONG,"
                + "status INTEGER,"
                + "priority INTEGER,"
                + "times INTEGER"
                + ")";
        sqLiteDatabase.execSQL(sql);
    }

    @Override
    public void onUpgrade(SQLiteDatabase sqLiteDatabase, int i, int i1) {

    }
}
