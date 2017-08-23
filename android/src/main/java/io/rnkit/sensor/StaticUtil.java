package io.rnkit.sensor;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.ProtocolException;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Created by carlos on 2017/8/17.
 *  网络请求方法
 */

class StaticUtil {

    static ExecutorService singleThreadExecutor = Executors.newSingleThreadExecutor();

    /**
     * 一次从数据库中取的最大数量
     */
    static int MAX_VOLUME = 20;
    /**
     *  服务器分配的appKey
     */
    static String appKey = "";

    public static String sendPost(String url,  String hashString ) {
        //输入请求网络日志
        System.out.println("post_url="+url);
        System.out.println("post_param="+hashString);

        BufferedReader in = null;
        String result = "";
        HttpURLConnection conn = null;

        try {
            URL realUrl = new URL(url);
            // 打开和URL之间的连接
            conn = (HttpURLConnection) realUrl.openConnection();
            // 设置通用的请求属性
            conn.setDoInput(true);
            conn.setDoOutput(true);
            conn.setUseCaches(false);
            conn.setConnectTimeout(10000);//设置连接超时
            conn.setReadTimeout(10000);//设置读取超时
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            //上传文件 content_type
//          conn.setRequestProperty("Content-Type", "multipart/form-data; boudary= 89alskd&&&ajslkjdflkjalskjdlfja;lksdf");
            conn.connect();
            OutputStreamWriter osw = new OutputStreamWriter(conn.getOutputStream(), "utf-8");
            osw.write(hashString);
            osw.flush();
            osw.close();
            if (conn.getResponseCode() == 200) {
                in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                String inputLine;
                while ((inputLine = in.readLine()) != null) {
                    result += inputLine;
                }
                System.out.println("post_result="+result);
                in.close();
            }

        } catch (SocketTimeoutException e ) {
            //连接超时、读取超时
            e.printStackTrace();
            return "POST_Exception";
        }catch (ProtocolException e){
            e.printStackTrace();
            return "POST_Exception";
        } catch (IOException e) {
            e.printStackTrace();
            System.out.println("发送 POST 请求出现异常！"+e.getMessage()+"//URL="+url);
            e.printStackTrace();
            return "POST_Exception";
        }
        //使用finally块来关闭输出流、输入流
        finally{
            try{
                if (conn != null) conn.disconnect();
                if(in!=null){
                    in.close();
                }
            }
            catch(IOException ex){
                ex.printStackTrace();
            }
        }
        return result;
    }

    /**
     * 检测当的网络（WLAN、3G/2G）状态
     * @param context Context
     * @return true 表示网络可用
     */
    public static boolean isNetworkAvailable(Context context) {
        ConnectivityManager connectivity = (ConnectivityManager) context
                .getSystemService(Context.CONNECTIVITY_SERVICE);
        if (connectivity != null) {
            NetworkInfo info = connectivity.getActiveNetworkInfo();
            if (info != null && info.isConnected())
            {
                // 当前网络是连接的
                if (info.getState() == NetworkInfo.State.CONNECTED)
                {
                    // 当前所连接的网络可用
                    return true;
                }
            }
        }
        return false;
    }
}
