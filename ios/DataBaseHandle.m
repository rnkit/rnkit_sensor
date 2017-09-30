//
//  DataBaseHandle.m
//  RNKitSensor
//
//  Created by Snow on 2017/8/17.
//  Copyright © 2017年 SnowYang. All rights reserved.
//

#import "DataBaseHandle.h"
#import "FMDB.h"
#import "DataBaseModel.h"

static DataBaseHandle *handle = nil;

//static sqlite3 *db = nil;


#ifdef DEBUG
#define YXLog(fmt, ...)  NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)//打印【类名、方法名、行数】
#else
#define YXLog(...)
#endif


#define kDBpath @"rnkit-sensor.sqlite"

@interface DataBaseHandle ()

@property (nonatomic, strong) FMDatabaseQueue *queue;

@end


@implementation DataBaseHandle

+(instancetype)shareDataBase {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handle = [[DataBaseHandle alloc] init];
        [handle createTable];
    });
    return handle;
}

#pragma mark - 建表
- (void)createTable {
    NSString *createTableSql = @"CREATE TABLE IF NOT EXISTS RNKitSensor (mid INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL ,jsonBody TEXT,requestUrl VARCHAR(254),timeStamp BIGINT,times INTEGER,status INTEGER,priority INTEGER)";
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL result = [self executeUpdateWithSQLString:createTableSql db:db];
        
        if (result) {
            YXLog(@"建表成功");
        }else{
            YXLog(@"建表失败");
        }
        
    }];
    
}

#pragma mark - 插入数据
-(void)insertModel:(DataBaseModel *)dbModel {
     NSString *insertSql = [NSString stringWithFormat:@"INSERT INTO RNKitSensor (jsonBody,requestUrl,timeStamp,times,status,priority) VALUES ('%@','%@','%lu','%ld','%ld','%ld')",dbModel.jsonBody,dbModel.requestUrl,dbModel.timeStamp,dbModel.times,dbModel.status,dbModel.priority];
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL result = [self executeUpdateWithSQLString:insertSql db:db];
        
        if (result) {
            YXLog(@"增加数据成功");
        }else{
            YXLog(@"增加数据失败");
        }
        
    }];
    
    
    
}


#pragma mark - 删除status=1并超过最大上传数的数据
-(void)deleteWithStatus:(NSInteger)status repeatCount:(NSInteger)repeatCount {
    
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM RNKitSensor WHERE status = '%ld' OR (times > '%ld' AND priority > 0)",status,repeatCount];
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL result = [self executeUpdateWithSQLString:deleteSql db:db];
        
        if (result) {
            YXLog(@"删除数据成功");
        }else{
            YXLog(@"删除数据失败");
        }
    }];
    
    
    
}
#pragma mark - 删除status=1
-(void)deleteWithStatus:(NSInteger)status {
    NSString *deleteSql = [NSString stringWithFormat:@"DELETE FROM RNKitSensor WHERE status = '%ld'",status];
    
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL result = [self executeUpdateWithSQLString:deleteSql db:db];
        
        if (result) {
            YXLog(@"删除数据成功");
        }else{
            YXLog(@"删除数据失败");
        }
    }];
    
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
    
    
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        BOOL result = [self executeUpdateWithSQLString:updateSql db:db];
        
        if (result) {
            YXLog(@"批量更新成功");
        }else{
            YXLog(@"批量更新失败");
        }
        
    }];
    
    
    
}



#pragma mark - 更新语句
- (BOOL)executeUpdateWithSQLString:(NSString *)sql db:(FMDatabase *)db
{
    if ([db open]) {
        [db beginTransaction];
        @try {
            BOOL result = [db executeUpdate:sql];
            [db commit];
            [db close];
            return result;
        } @catch (NSException *exception) {
            YXLog(@"错误===%@",exception.description);
            [db commit];
            [db close];
            return NO;
        } @finally {
            YXLog(@"finally");
        }
    }else {
        if([db hadError])
        {
            YXLog(@"Error %d : %@",[db lastErrorCode],[db lastErrorMessage]);
        }
        YXLog(@"数据库打开失败");
        return NO;
    }
}

#pragma mark - 限制条数的查询
-(NSArray *)selectWithLimit:(NSInteger)limit {
    NSInteger limitNum = limit ? limit : 30;
    
    NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM RNKitSensor WHERE status = 0 OR status = 2 ORDER BY priority LIMIT %ld",(long)limitNum];
    __block NSArray *backArr;
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSArray *resultArr = (NSArray *)[self executeSelectSQLWithSQLString:selectSql db:db];
        backArr = resultArr != nil && resultArr.count > 0 ? resultArr : @[];
    }];
    
    return backArr;
}

#pragma mark 查询超过最大上传次数的数据
-(NSArray *)selectWithRepeatCount:(NSInteger)repeatCount {
    
    NSString *selectSql = [NSString stringWithFormat:@"SELECT * FROM RNKitSensor WHERE times > '%ld' AND priority > 0 ORDER BY priority",repeatCount];
    __block NSArray *backArr;
    [self.queue inDatabase:^(FMDatabase * _Nonnull db) {
        NSArray *resultArr = (NSArray *)[self executeSelectSQLWithSQLString:selectSql db:db];
        backArr = resultArr != nil && resultArr.count > 0 ? resultArr : @[];
    }];

    return backArr;
}

#pragma mark -查询数据
- (NSMutableArray *)executeSelectSQLWithSQLString:(NSString *)sql db:(FMDatabase *)db
{
    NSMutableArray *modelArray = nil;
    
    if ([db open]) {
        [db beginTransaction];
        @try {
            FMResultSet *result = [db executeQuery:sql];
            modelArray = [NSMutableArray array];
            while ([result next]) {
                NSInteger mid = [result intForColumn:@"mid"];
                NSString *jsonBody = [result stringForColumn:@"jsonBody"];
                NSString *requestUrl = [result stringForColumn:@"requestUrl"];
                NSUInteger timeStamp = [result doubleForColumn:@"timeStamp"];
                NSInteger times = [result intForColumn:@"times"];
                NSInteger status = [result intForColumn:@"status"];
                NSInteger priority = [result intForColumn:@"priority"];
                
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
            
            [db commit];
            [db close];
            return modelArray;
        } @catch (NSException *exception) {
            YXLog(@"错误===%@",exception.description);
            [db commit];
            [db close];
            return modelArray;
        } @finally {
            YXLog(@"finally");
        }
    }else {
        if([db hadError])
        {
            YXLog(@"Error %d : %@",[db lastErrorCode],[db lastErrorMessage]);
        }
        YXLog(@"数据库打开失败");
        
        return modelArray;
    }
}

#pragma mark - 懒加载
- (FMDatabaseQueue *)queue {
    if (!_queue) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *dbPath = [docPath stringByAppendingPathComponent:kDBpath];
        YXLog(@"数据库路径:%@",dbPath);
        _queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return _queue;
}


@end
