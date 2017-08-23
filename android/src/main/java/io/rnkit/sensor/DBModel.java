package io.rnkit.sensor;

/**
 * Created by carlos on 2017/8/17.
 * 数据库中表存储的实体类
 */

class DBModel {
    /**
     * 表id
     */
    public int id;
    /**
     * 一个json字符串
     */
    public String jsonBody;
    /**
     * 接口地址
     */
    public String requestUrl;
    /**
     * 存储进数据库的时间戳
     */
    public long timeStamp;
    /**
     * 这条数据的状态，0表示初始状态，1表示成功，2表示失败
     */
    public int status;
    /**
     * 这个事件的优先级
     */
    public int priority;
    /**
     * 向后台发送的次数
     */
    public int times;
}
