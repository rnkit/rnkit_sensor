//
//  DataBaseHandle.m
//  RNKitSensor
//
//  Created by Snow on 2017/8/17.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import "DataBaseHandle.h"
#import <sqlite3.h>
#import "DataBaseModel.h"

static DataBaseHandle *handle = nil;

static sqlite3 *db = nil;


#ifdef DEBUG
#define YXLog(fmt, ...)  NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)//打印【类名、方法名、行数】
#else
#define YXLog(...)
#endif


#define kDBpath @"rnkit-sensor.sqlite"

@implementation DataBaseHandle

+(instancetype)shareDataBase {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handle = [[DataBaseHandle alloc] init];
    });
    return handle;
}

#pragma mark 打开数据库
-(void)openDB {
    if (db != nil) {
        YXLog(@"数据库已经打开");
        return;
    }
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath = [docPath stringByAppendingPathComponent:kDBpath];
    YXLog(@"数据库路径:%@",dbPath);
    
    int result = sqlite3_open(dbPath.UTF8String, &db);
    if (result == SQLITE_OK) {
        YXLog(@"数据库打开成功");
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"existTable"] intValue] == 0) {
            [self createTable];
        }                
    } else {
        YXLog(@"数据库打开失败result=%d",result);
    }
}


#pragma mark 关闭数据库
-(void)closeDB {
    int result = sqlite3_close(db);
    if (result == SQLITE_OK) {
        YXLog(@"数据库关闭成功");
        db = nil;
    } else {
        YXLog(@"数据库关闭失败result=%d",result);
    }

}


#pragma mark 建表
-(void)createTable {
    
    NSString *sqlStr = @"CREATE TABLE IF NOT EXISTS RNKitSensor (mid INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL ,jsonBody TEXT,requestUrl VARCHAR(254),timeStamp BIGINT,times INTEGER,status INTEGER,priority INTEGER)";
    
    int result = sqlite3_exec(db, sqlStr.UTF8String, NULL, NULL, NULL);
    
    if (result == SQLITE_OK) {
        YXLog(@"建表成功");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(1) forKey:@"existTable"];
        [defaults synchronize];
    }else{
        YXLog(@"建表失败result=%d",result);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(0) forKey:@"existTable"];
        [defaults synchronize];
    }
}


#pragma mark 插入数据(增)
-(void)insertModel:(DataBaseModel *)dbModel {
    
    @try {
        NSString *insertSql = [NSString stringWithFormat:@"INSERT INTO RNKitSensor (jsonBody,requestUrl,timeStamp,times,status,priority) VALUES ('%@','%@','%lu','%ld','%ld','%ld')",dbModel.jsonBody,dbModel.requestUrl,dbModel.timeStamp,dbModel.times,dbModel.status,dbModel.priority];

        int result = sqlite3_exec(db, insertSql.UTF8String, NULL, NULL, NULL);
        if (result == SQLITE_OK) {
            YXLog(@"添加成功");
        }else{
            YXLog(@"添加失败result=%d",result);
        }

    } @catch (NSException *exception) {
        YXLog(@"错误===%@",exception.description);
    } @finally {
        YXLog(@"finally");
    }
    
    
}


#pragma mark  修改数据(改)
-(void)updateWithID:(NSInteger)mid status:(NSInteger)status times:(NSInteger)times {
    
    NSString *updateSql = [NSString stringWithFormat:@"UPDATE RNKitSensor SET status = '%ld', times = '%ld' WHERE mid = '%ld'",status,times,mid];
    
    int result = sqlite3_exec(db, updateSql.UTF8String, NULL, NULL, NULL);
    
    if (result == SQLITE_OK) {
        YXLog(@"修改成功");
    }else{
        YXLog(@"修改失败result=%d",result);
    }

}

#pragma mark - 批量更新
- (void)batchUpdeate:(NSArray *)modelArray {

    NSMutableString *str = [NSMutableString string];
    for (DataBaseModel *model in modelArray) {
        
        [str appendFormat:@"(%ld,'%@','%@','%lu','%ld','%ld','%ld'),",(unsigned long)model.mid,model.jsonBody,model.requestUrl,(unsigned long)model.timeStamp,(long)model.times,(long)model.status,(long)model.priority];
    }
    //切记最后一个参数木有逗号
    str = ([str substringToIndex:str.length - 1]).mutableCopy;

    NSString *updateSql = [NSString stringWithFormat:@"REPLACE INTO RNKitSensor (mid,jsonBody,requestUrl,timeStamp,times,status,priority) values %@",str];
    
    int result = sqlite3_exec(db, updateSql.UTF8String, NULL, NULL, NULL);
    if (result == SQLITE_OK) {
        YXLog(@"修改成功");
    }else{
        YXLog(@"修改失败result=%d",result);
    }

    
}

#pragma mark 删除数据(删)
-(void)deleteWithStatus:(NSInteger)status repeatCount:(NSInteger)repeatCount {
    
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM RNKitSensor WHERE status = '%ld' OR (times > '%ld' AND priority > 0)",status,repeatCount];
    
    int result = sqlite3_exec(db, deleteSql.UTF8String, NULL, NULL, NULL);
    
    if (result == SQLITE_OK) {
        YXLog(@"删除成功");
    }else{
        YXLog(@"删除失败result=%d",result);
    }

}

#pragma mark - 状态为1(成功)删除
-(void)deleteWithStatus:(NSInteger)status {
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM RNKitSensor WHERE status = '%ld'",status];
    
    int result = sqlite3_exec(db, deleteSql.UTF8String, NULL, NULL, NULL);
    
    if (result == SQLITE_OK) {
        YXLog(@"删除成功");
    }else{
        YXLog(@"删除失败result=%d",result);
    }
}


#pragma mark  全查
-(NSArray *)selectAll {
    
    NSString *selectSql = @"SELECT * FROM RNKitSensor";
    
    return [self selectResults:selectSql];
    
    
}


#pragma mark 条件查
-(NSArray *)selectWithLimit:(NSInteger)limit {
    
    NSInteger limitNum = limit ? limit : 30;
    
    NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM RNKitSensor WHERE status = 0 OR status = 2 ORDER BY priority LIMIT %ld",(long)limitNum];
    
    return [self selectResults:selectSql];
    
}

#pragma mark - 查询达到最大失败次数
-(NSArray *)selectWithRepeatCount:(NSInteger)repeatCount {
    
    NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM RNKitSensor WHERE times > '%ld' AND priority > 0 ORDER BY priority",repeatCount];
    
    return [self selectResults:selectSql];
}




- (NSArray *)selectResults:(NSString *)selectSql{
    
    @try {
        NSMutableArray *modelArray = nil;
        
        sqlite3_stmt *stmt = nil;
        
        int result = sqlite3_prepare_v2(db, selectSql.UTF8String, -1, &stmt, NULL);
        
        if (result == SQLITE_OK) {
            modelArray = [NSMutableArray array];
            
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                NSInteger mid = sqlite3_column_int(stmt, 0);
                NSString *jsonBody = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, 1)];
                NSString *requestUrl = [NSString stringWithUTF8String:(const char *) sqlite3_column_text(stmt, 2)];
                NSUInteger timeStamp = sqlite3_column_double(stmt, 3);
                NSInteger times = sqlite3_column_int(stmt, 4);
                NSInteger status = sqlite3_column_int(stmt, 5);
                NSInteger priority = sqlite3_column_int(stmt, 6);
                
                DataBaseModel *model = [DataBaseModel new];
                model.mid = mid;
                model.jsonBody = jsonBody;
                model.requestUrl = requestUrl;
                model.timeStamp = timeStamp;
                model.times = times;
                model.status = status;
                model.priority = priority;
                
                [modelArray addObject:model];
                
            }
            YXLog(@"查询成功");
        } else{
            YXLog(@"查询失败result=%d",result);
        }
        
        sqlite3_finalize(stmt);
        
        for (DataBaseModel *model in modelArray) {
            YXLog(@"mid:%ld,jsonBody:%@,requestUrl:%@,timeStamp:%lu,times:%ld,status:%ld,priority:%ld",model.mid,model.jsonBody,model.requestUrl,model.timeStamp,model.times,model.status,model.priority);
        }
        
        return modelArray;
        
    } @catch (NSException *exception) {
        YXLog(@"错误===%@",exception.description);
    } @finally {
        YXLog(@"finally");
    }

}

#pragma mark - 重置id
-(void)resetId {
    
    NSString *resetSql = @"TRUNCATE TABLE RNKitSensor";
    
    int result = sqlite3_exec(db, resetSql.UTF8String, NULL, NULL, NULL);
    YXLog(@"result值:%d",result);
    if (result == SQLITE_OK) {
        YXLog(@"重制id成功");
    }else{
        YXLog(@"重置id失败result=%d",result);
    }
}

@end
