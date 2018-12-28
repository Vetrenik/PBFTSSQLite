//
//  FTSController.m
//  TestSQLite
//
//  Created by Anton on 10/10/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import "FTSController.h"
#import "FTSItem.h"
#import "sqlite3.h"
#import "FTSQueryItem.h"
#import "FTSPorter.h"
#import "FTSSearchParameters.h"
#import "FTSBufsContainer.h"

int opendb_for_create(const char *filename, sqlite3 **ppDb)
{
    sqlite3_config(SQLITE_CONFIG_MULTITHREAD);
    int res =  sqlite3_open_v2(filename, ppDb, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL);
    return res;
}

int opendb_for_write(const char *filename, sqlite3 **ppDb)
{
    int res =  sqlite3_open_v2(filename, ppDb, SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, NULL);
    return res;
}

int opendb_for_read(const char *filename, sqlite3 **ppDb)
{
    int res =  sqlite3_open_v2(filename, ppDb, SQLITE_OPEN_READONLY|SQLITE_OPEN_FULLMUTEX, NULL);
    return res;
}

@interface FTSController()
{
    NSIndexSet * _hashes;
    NSUInteger _hash;
}
-(BOOL) createDB;

-(BOOL) indexOneRecordWithItem:(FTSItem *)item;

-(NSArray *) searchWithQueryItem:(FTSQueryItem *)query;

-(NSArray *) setListOfTopicsWithArrayTopicList:(NSArray *)list;

-(NSArray<NSDictionary *> *) makeDicts;

-(NSString *)dateReformatWithDate:(NSString *)date;

-(NSString *)dateReformatWithTrueDate:(NSDate *)date;

-(NSDate *)dateBackReformatWithDate:(NSString *)date;

@property (strong, readonly) NSIndexSet * hashes;

@end

@implementation FTSController

-(NSIndexSet *) hashes {
    
    if (_hashes == nil || _hashes.hash != _hash) {
        NSMutableIndexSet * ret;
        
        if (opendb_for_read([self.databasePath UTF8String], &searchdb) != SQLITE_OK) {
            [self errorStatement:@"" withError:""];
        } else {
            NSString * querySt = @"SELECT hash FROM objects;";
            const char * sqlQuery = [querySt UTF8String];
            sqlite3_stmt * stmt = nil;
            if (sqlite3_prepare_v2(searchdb, sqlQuery, -1, &stmt, NULL) != SQLITE_OK) {
                [self errorStatement:@"" withError:""];
            } else {
                while(sqlite3_step(stmt) == SQLITE_ROW) {
                    [ret addIndex:sqlite3_column_int(stmt, 1)];
                }
            }
            sqlite3_finalize(stmt);
        }
        _hash = ret.hash;
        _hashes = ret.copy;
    }
    return _hashes;
}

static sqlite3 * searchdb = nil;

- (void)dealloc
{
    sqlite3_close(searchdb);
    searchdb = nil;
}

+(FTSController *) SharedInstance {
    static FTSController * fts = nil;
    if (fts == nil) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            fts = [[FTSController alloc] init];
        });
    }
    return fts;
}

- (void)initializeWithDBPathString:(NSString *)dbpath {
    
    self.databasePath = dbpath;
    [self createDB];
    self.bufs = [[FTSBufsContainer alloc] initBufsContainerWithIgnoreYear:NO];
    self.parameters = [[FTSSearchParameters alloc] initSearchParametersWithBufs:self.bufs
                                                                        inputed:@""];
    self.stemmer = [[FTSPorter alloc] initStemmer];
    NSArray * buf = [self makeDicts];
    self.topicDict = buf[0];
    self.topicDescDict = buf[1];
}

-(NSArray<NSDictionary *> *) makeDicts{
    NSString * path = [[NSBundle mainBundle] pathForResource:@"TopicList" ofType:@"txt"];
    NSString * file = [NSString stringWithContentsOfFile:path
                                                encoding:NSUTF8StringEncoding
                                                   error:nil];
    NSArray * lines = [file componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableDictionary * topicdict = [NSMutableDictionary new];
    NSMutableDictionary * descdict = [NSMutableDictionary new];
    NSMutableArray<NSDictionary *> * res = [NSMutableArray new];
    
    for (int i = 1; i < [lines count]; i ++) {
        if (![lines[i] isEqualToString:@""]) {
            NSArray * line = [lines[i] componentsSeparatedByString:@"/"];
            NSArray * descs = [line[2] componentsSeparatedByString:@";"];
            NSMutableArray * buf =[NSMutableArray new];
            for (NSString * str in descs) {
                if (![str isEqualToString:@""]) {
                    [buf addObject:str];
                }
            }
            descs = buf.copy;
            
            [descdict setObject:descs forKey:line[0]];
            [topicdict setObject:line[1] forKey:line[0]];
        }
    }
    [res addObject:topicdict];
    [res addObject:descdict];
    return res.copy;
}

-(BOOL) createDB {
    BOOL state = NO;
    NSFileManager * fileMgr = [NSFileManager defaultManager];
    
    //    if ([fileMgr fileExistsAtPath:self.databasePath] == YES) {
    //        [fileMgr removeItemAtPath:self.databasePath error:0];
    //    }
    
    if ([fileMgr fileExistsAtPath:self.databasePath] == NO) {
        [fileMgr createFileAtPath:self.databasePath
                         contents:nil
                       attributes:nil];
        char * errMsg;
        const char * sqlSt;
        sqlSt = "CREATE TABLE objects (\
        type TEXT,\
        id TEXT, \
        object BLOB \
        hash INTEGER);";
        
        if (sqlite3_exec(searchdb, sqlSt, NULL, NULL, &errMsg) != SQLITE_OK) {
            [self errorStatement:@"Create Table \"Objects\"" withError:errMsg];
        } else {
            sqlSt = "CREATE INDEX objects ON tags (id, type);";
            if (sqlite3_exec(searchdb, sqlSt, NULL, NULL, &errMsg) != SQLITE_OK) {
            } else {
                state = YES;
            }
        }
    }
    
    if ([fileMgr fileExistsAtPath:self.databasePath] == YES) {
        if (opendb_for_create([self.databasePath UTF8String], &searchdb) == SQLITE_OK) {
            char * errMsg;
            const char * sqlSt;
            
            if (@available(iOS 11, *)) {
                sqlSt = "CREATE VIRTUAL TABLE  search USING fts5(type, id, desc, value, date, currency, tokenize = \'porter ascii\');";
            } else {
                sqlSt = "CREATE VIRTUAL TABLE  search USING fts3(type, id, desc, value, date, currency, tokenize = porter);";
            }
            
            if (sqlite3_exec(searchdb, sqlSt, NULL, NULL, &errMsg) != SQLITE_OK) {
                [self errorStatement:@"Create FTS" withError:errMsg];
            }
        }
    }
    return state;
}

- (BOOL) deleteEntriesOfType:(NSString* )type {
    if (opendb_for_write([self.databasePath UTF8String], &searchdb) != SQLITE_OK) {
        [self errorStatement:@"" withError:""];
    } else {
        const char * errMsg;
        sqlite3_stmt * stmt = NULL;
        NSString * sqlSt = @"DELETE \
        FROM objects \
        WHERE type = ?";
        int state = sqlite3_prepare_v2(searchdb, sqlSt.UTF8String, -1, &stmt, &errMsg);
        
        if (state != SQLITE_OK) {
            [self errorStatement:@"" withError:""];
        } else {
            if (sqlite3_step(stmt) != SQLITE_DONE) {
                [self errorStatement:@"" withError:""];
            } else {
                return YES;
            }
        }
    }
    
    return NO;
}

- (NSArray *)setListOfTopicsWithArrayTopicList:(NSArray *)list {
    
    NSMutableArray * topics = [NSMutableArray new];
    [topics addObjectsFromArray:list];
    NSString * stopfl = @"";
    NSMutableArray * buffArr = [NSMutableArray new];
    for (NSString * topic in topics) {
        
        NSString * bufTopic = topic;
        while (![stopfl isEqualToString:@"null"])
        {
            NSString * pTopic = [self.topicDict objectForKey:bufTopic];
            NSAssert(pTopic, @"No parent topic for topic %@", bufTopic);
            if (pTopic&&![pTopic isEqualToString:@"null"])
            {
                if (![topics containsObject:pTopic]) [buffArr addObject:pTopic];
                bufTopic = pTopic;
            }
            else stopfl = pTopic;
        }
    }
    
    [topics addObjectsFromArray:buffArr];
    
    return topics.copy;
}

-(BOOL) indexRecordsWithArrayOfItems:(NSArray *)iArray {
    BOOL state = NO;
    NSMutableArray * inserts = [NSMutableArray new];
    
    for (FTSItem * item in iArray) {
        NSUInteger hash = [NSString stringWithFormat:@"%@%@", @(item.hash), @([self serializedDataWithObject:item.object].hash)].hash;
        if (![self.hashes containsIndex:hash]) {
            [inserts addObject:item];
        }
    }
    
    if ([inserts count] > 0) {
        if (opendb_for_write([self.databasePath UTF8String], &searchdb) != SQLITE_OK) {
            [self errorStatement:@"" withError:""];
        } else {
            for (FTSItem * item in inserts) {
                state = [self indexOneRecordWithItem:item];
            }
        }
    }
    return state;
}

-(BOOL) indexOneRecordWithItem:(FTSItem *)item {
    
    BOOL state = NO;
    
    @synchronized (self) {
        
        //reformating the item's date from dd/MM/yyyy mm:HH to yyyyMMddHHmm format
        NSString * date = [self dateReformatWithTrueDate:item.date];
        
        item.desc = [self processItemDesc:item.desc
                             andTopicList:item.topicList];
        
        NSString * value =  [NSString stringWithFormat:@"%015.2f", item.value];
        const char * errMsg;
        
        if (searchdb == nil) {
            [self errorStatement:@"Database open" withError:sqlite3_errmsg(searchdb)];
        } else {
            sqlite3_stmt * stmt = NULL;
            NSString * sqlSt = @"INSERT OR REPLACE INTO search (rowid, type, id, desc, value, date, currency) \
            values ((select rowid from search where id = ? and type = ?),?, ?, ?, ?, ?, ?);";
            int state = sqlite3_prepare_v2(searchdb, sqlSt.UTF8String, -1, &stmt, &errMsg);
            if (state != SQLITE_OK) {
                [self errorStatement:sqlSt withError:errMsg];
            } else {
                NSArray * insArr = [NSArray arrayWithObjects:item.ID, item.type, item.type, item.ID, item.desc, value, date, item.currency, nil];
                [FTSController bindData:insArr
                                 toStmt:stmt];
                
                if (sqlite3_step(stmt) == SQLITE_DONE) {
                    
                    sqlite3_finalize(stmt);
                    stmt = NULL;
                    
                    NSData *objectData = [self serializedDataWithObject:item.object];
                    
                    if (objectData.length) {
                        sqlSt = @"INSERT OR REPLACE INTO objects (rowid, type, id, object, hash) \
                        values ((select rowid from search where id = ? and type = ?),?,?,?,?)";
                        
                        int state = sqlite3_prepare_v2(searchdb, sqlSt.UTF8String, -1, &stmt, &errMsg);
                        if (state != SQLITE_OK) {
                            [self errorStatement:sqlSt withError:errMsg];
                        } else {
                            NSUInteger hash = [NSString stringWithFormat:@"%@%@", @(item.hash), @(objectData.hash)].hash;
                            
                            NSArray * insArr = [NSArray arrayWithObjects:item.ID, item.type, item.type, item.ID, objectData, @(hash),nil];
                            [FTSController bindData:insArr
                                             toStmt:stmt];
                            if (sqlite3_step(stmt) == SQLITE_DONE) {
                                state = YES;
                                
                            }
                        }
                    }
                }
            }
            sqlite3_finalize(stmt);
            stmt = NULL;
        }
    }
    return state;
}

-(NSString *) processItemDesc:(NSString *)desc
                 andTopicList:(NSArray *)topicList{
    NSRegularExpression * spec = [NSRegularExpression regularExpressionWithPattern:@"\\p{P}"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSRegularExpression * spacer = [NSRegularExpression regularExpressionWithPattern:@"\\s+"
                                                                             options:NSRegularExpressionCaseInsensitive
                                                                               error:nil];
    desc = [spec stringByReplacingMatchesInString:desc
                                          options:0
                                            range:NSMakeRange(0, [desc length])
                                     withTemplate:@" "];
    
    desc = [spacer stringByReplacingMatchesInString:desc
                                            options:0
                                              range:NSMakeRange(0, [desc length])
                                       withTemplate:@" "];
    
    
    //stemming of the item's description
    desc = [self.stemmer stemSentenceWithString:desc];
    
    //making the custom set of topics for item in order to it's base topic
    topicList = [self setListOfTopicsWithArrayTopicList:topicList];
    
    //making the custom description based on item's set of topics
    for (NSString * topic in topicList) {
        NSString * buf = @"";
        NSArray * descs = [self.topicDescDict objectForKey:topic];
        for (NSString * desc in descs) {
            buf = [buf stringByAppendingString:[desc stringByAppendingString:@" "]];
        }
        desc = [desc stringByAppendingString:[@" " stringByAppendingString:buf]];
    }
    
    desc = [self LevensteinFilterWithDesc:[desc lowercaseString]];
    
    return [desc lowercaseString];
}

+(void) bindData:(NSArray *)data
          toStmt:(sqlite3_stmt *)stmt {
    for (int i = 0; i < [data count]; i++) {
        id curdata = [data objectAtIndex:i];
        if ([curdata isKindOfClass:[NSString class]]) {
            sqlite3_bind_text(stmt, i+1, [(NSString *)curdata UTF8String], -1, SQLITE_STATIC);
        } else if ([curdata isKindOfClass:[NSData class]]) {
            NSData * objectData = curdata;
            sqlite3_bind_blob(stmt, i+1, objectData.bytes, (int) objectData.length, SQLITE_STATIC);
        } else if ([curdata isKindOfClass:[NSNumber class]]){
            sqlite3_bind_int(stmt, i+1, [(NSNumber *)curdata intValue]);
        }{
            NSLog(@"unsupported class in FtsController.BindDataToStmtWithData \
                  in object of type %@ with id%@ on interation %i", [data objectAtIndex:0], [data objectAtIndex:1], i);
        }
        
    }
}

-(NSString *) LevensteinFilterWithDesc:(NSString *)desc {
    NSArray * descWords = [[desc stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "];
    
    NSMutableArray * bufer = [NSMutableArray new];
    @autoreleasepool {
        
        for (int i = 0; i < [descWords count]; i ++) {
            NSString * w1 = [descWords objectAtIndex:i];
            long l1 = [w1 length];
            float a = [w1 length]*0.33f;
            for (int j = i+1; j<[descWords count];j++) {
                NSString * w2 = [descWords objectAtIndex:j];
                long l2 = [w2 length];
                
                if ((l1 < (l2+2))&&(l1 >(l2-2))) {
                    if ([w1 isEqualToString:w2])  break;
                    if ([self editlistWithString1:w1 String2:w2] < a) break;
                }
                
                if (j == [descWords count] - 1) {
                    [bufer addObject:w1];
                }
            }
        }
    }
    desc = [bufer componentsJoinedByString:@" "];
    
    return desc;
}



-(NSArray<FTSItem *> *) searchWithQueryString:(NSString *)sString {
    if ([sString length]>0) {
        
        sString = [sString stringByReplacingOccurrencesOfString:@"ё" withString:@"е"];
        
        self.parameters = [[FTSSearchParameters alloc] initSearchParametersWithBufs:self.bufs
                                                                            inputed:sString];
        
        NSArray * queryStrBuf = [[[self.stemmer stemSentenceWithString:self.parameters.query] lowercaseString] componentsSeparatedByString:@" "];
        NSString * queryStr;
        
        if ([queryStrBuf count] > 1) {
            queryStr = [queryStrBuf componentsJoinedByString:@"* OR "];
            queryStr = [NSString stringWithFormat:@"(%@)", queryStr];
        } else {
            if ([[queryStrBuf objectAtIndex:0] length] > 0) {
                queryStr = [NSString stringWithFormat:@"%@*", [queryStrBuf objectAtIndex:0]];
            } else {
                queryStr =[queryStrBuf objectAtIndex:0];
            }
        }
        
        FTSQueryItem * qItem = [[FTSQueryItem alloc] initWithDesc:queryStr
                                                       firstValue:[NSString stringWithFormat:@"%015.2f", self.parameters.first_value]
                                                      secondValue:[[NSString stringWithFormat:@"%015.2f", self.parameters.second_value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                                        firstDate:[self dateReformatWithDate:self.parameters.first_date]
                                                       secondDate:[self dateReformatWithDate:self.parameters.second_date]
                                                         currency:self.parameters.currency];
        return [self searchWithQueryItem:qItem];
    } else return @[];
}

-(NSString *)dateReformatWithDate:(NSString *)date {
    
    if (![date isEqualToString:@""]) {
        NSArray * dateSplit = [date componentsSeparatedByString:@" "];
        NSString * time = [dateSplit[1] stringByReplacingOccurrencesOfString:@":"
                                                                  withString:@""];
        NSString * dateS =@"";
        NSArray * dateFromDateSplit = [dateSplit[0] componentsSeparatedByString:@"/"];
        for (int i = (int)[dateFromDateSplit count]-1;i >= 0; i --) {
            dateS = [dateS stringByAppendingString:dateFromDateSplit[i]];
        }
        dateS = [dateS stringByAppendingString:time];
        
        return dateS;
    }
    return date;
}

-(NSString *)dateReformatWithTrueDate:(NSDate *)date {
    NSString * res =  @"";
    if (date != nil) {
        NSDateComponents * components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour |NSCalendarUnitMinute fromDate:date];
        
        NSInteger year = [components year];
        NSInteger month = [components month];
        NSInteger day = [components day];
        NSInteger hour = [components hour];
        NSInteger minute = [components minute];
        
        NSString * monthR = [NSString stringWithFormat:@"%02i", (int)month];
        NSString * dayR = [NSString stringWithFormat:@"%02i", (int)day];
        NSString * hourR = [NSString stringWithFormat:@"%02i", (int)hour];
        NSString * minuteR = [NSString stringWithFormat:@"%02i", (int)minute];
        
        res = [[NSString stringWithFormat:@"%i", (int)year] stringByAppendingString:monthR];
        res = [res stringByAppendingString:dayR];
        res = [res stringByAppendingString:hourR];
        res = [res stringByAppendingString:minuteR];
    }
    return res;
}

-(NSDate *)dateBackReformatWithDate:(NSString *)date {
    NSDate * res = nil;
    if (![date isEqualToString:@""]) {
        NSDateFormatter * formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"yyyyMMddHHmm"];
        res = [formatter dateFromString:date];
        return res;
    }
    return res;
}

-(NSArray<FTSItem *> *) searchWithQueryItem:(FTSQueryItem *)query {
    
    sqlite3_stmt * stmt = NULL;
    NSMutableArray * resArray = @[].mutableCopy;
    
    BOOL hasFirstDate = ![query.first_date isEqualToString:@""];
    BOOL hasSecondDate =![query.second_date isEqualToString:@""];
    BOOL hasDate = hasFirstDate||hasSecondDate;
    BOOL hasFirstValue = ![query.first_value isEqualToString:[NSString stringWithFormat:@"%015.2f", 0.0f]];
    BOOL hasSecondValue = ![query.second_value isEqualToString:@"inf"];
    BOOL hasValue = hasFirstValue||hasSecondValue;
    
    if (!hasSecondValue) query.second_value = @"999999999999999";
    NSString * querySt;
    if (@available(iOS 11, *)) {
        
        
        if (hasValue&&hasDate) {  //if query has both value and date
            querySt = [NSString stringWithFormat:@"\
                       SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, bm25(search) \
                       FROM search as s \
                       WHERE s.desc MATCH \'%@\'\
                       AND s.value BETWEEN \'%@\' AND \'%@\'\
                       AND s.date BETWEEN \'%@\' AND \'%@\'\
                       and s.currency = \'%@\'\
                       ORDER BY bm25(search);", query.desc, query.first_value, query.second_value, query.first_date, query.second_date, query.currency];
        } else if (hasValue&&!hasDate) { //if query has value but not date
            querySt = [NSString stringWithFormat:@"\
                       SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, bm25(search) \
                       FROM search as s \
                       WHERE s.desc MATCH \'%@\'\
                       AND s.value BETWEEN \'%@\' AND \'%@\'\
                       and s.currency = \'%@\'\
                       ORDER BY bm25(search);", query.desc, query.first_value, query.second_value,query.currency];
        } else if (!hasValue&&hasDate) { //if query has date but not value
            querySt =  [NSString stringWithFormat:@"\
                        SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, bm25(search) \
                        FROM search as s, \
                        WHERE s.desc MATCH \'%@\'\
                        AND s.date BETWEEN \'%@\' AND \'%@\'\
                        ORDER BY bm25(search);", query.desc,query.first_date, query.second_date];
        } else { // query if has neither value nor date
            querySt =  [NSString stringWithFormat:@"\
                        SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, bm25(search) \
                        FROM search as s\
                        WHERE s.desc MATCH \'%@\'\
                        ORDER BY bm25(search);", query.desc];
        }
        
    } else {
        if (hasValue&&hasDate) {  //if query has both value and date
            querySt = [NSString stringWithFormat:@"\
                       SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, matchinfo(search) \
                       FROM search as s, \
                       WHERE s.desc MATCH \'%@\'\
                       AND s.value BETWEEN \'%@\' AND \'%@\'\
                       AND s.date BETWEEN \'%@\' AND \'%@\'\
                       AND s.currency = \'%@\';", query.desc, query.first_value, query.second_value, query.first_date, query.second_date, query.currency];
        } else if (hasValue&&!hasDate) { //if query has value but not date
            querySt = [NSString stringWithFormat:@"\
                       SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, matchinfo(search)  \
                       FROM search as s \
                       WHERE s.desc MATCH \'%@\'\
                       AND s.value BETWEEN \'%@\' AND \'%@\'\
                       AND s.currency = \'%@\';", query.desc, query.first_value, query.second_value,query.currency];
        } else if (!hasValue&&hasDate) { //if query has date but not value
            querySt =  [NSString stringWithFormat:@"\
                        SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, matchinfo(search)  \
                        FROM search as s, \
                        WHERE s.desc MATCH \'%@\'\
                        AND s.date BETWEEN \'%@\' AND \'%@\';", query.desc,query.first_date, query.second_date];
        } else { // query if has neither value nor date
            querySt =  [NSString stringWithFormat:@"\
                        SELECT s.type, s.id, s.desc, s.value, s.date, s.currency, matchinfo(search)  \
                        FROM search as s, \
                        WHERE s.desc MATCH \'%@\';", query.desc];
        }
    }
    
    
    const char * sqlQuery = [querySt UTF8String];
    if (opendb_for_read([self.databasePath UTF8String], &searchdb) == SQLITE_OK) {
        if(sqlite3_prepare_v2(searchdb, sqlQuery, -1, &stmt, NULL) == SQLITE_OK) {
            NSString * type;
            NSString * ID;
            NSString * desc;
            NSString * value;
            NSString * date;
            NSString * currency;
            
            while(sqlite3_step(stmt) == SQLITE_ROW) {
                if (![self putDataWithID:0
                                fromStmt:stmt
                              intoString:&type]) {
                    continue;
                }
                if (![self putDataWithID:1
                                fromStmt:stmt
                              intoString:&ID]) {
                    continue;
                }
                if (![self putDataWithID:2
                                fromStmt:stmt
                              intoString:&desc]) {
                    continue;
                }
                if (![self putDataWithID:3
                                fromStmt:stmt
                              intoString:&value]) {
                    continue;
                }
                if (![self putDataWithID:4
                                fromStmt:stmt
                              intoString:&date]) {
                    continue;
                }
                if (![self putDataWithID:5
                                fromStmt:stmt
                              intoString:&currency]) {
                    continue;
                }
                double rank = -1.0f*sqlite3_column_double(stmt, 7);
                id retObj;
                FTSItem * item;
                item = [[FTSItem alloc] initItemWithType:type
                                                      ID:ID
                                                  topics:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%.3f", rank], nil]
                                                    desc:desc
                                                   value:[value floatValue]
                                                    date:[self dateBackReformatWithDate:date]
                                                currency:currency
                                                  object:retObj];
                
                [resArray addObject:item];
            }
            sqlite3_finalize(stmt);
            stmt = NULL;
        }
    }
    return resArray.copy;
}

-(BOOL) putDataWithID:(int)ID
             fromStmt:(sqlite3_stmt *)stmt
           intoString:(NSString **)str {
    
    const char * buf = (const char *) sqlite3_column_text(stmt, ID);
    if (buf != nil) {
        *str = [[NSString alloc] initWithUTF8String:buf];
        return YES;
    }
    
    return NO;
}

-(int ) editlistWithString1:(NSString *)s1
                    String2:(NSString *)s2 {
    
    int res;
    
    @autoreleasepool {
        
        NSInteger m = [s1 length];
        NSInteger n = [s2 length];
        
        NSMutableArray<NSNumber *> * D1 = [NSMutableArray new];
        NSMutableArray<NSNumber *> * D2 = [NSMutableArray arrayWithCapacity:n+1];
        
        for (int i = 0; i <= n; i++) [D2 insertObject:[NSNumber numberWithInt:i] atIndex:i];
        @autoreleasepool {
            for (int i = 1; i <= m; i++) {
                D1 = D2;
                D2 = [NSMutableArray arrayWithCapacity:n+1];
                for (int j = 0; j <= n; j ++) {
                    if (j == 0) {
                        [D2 insertObject:[NSNumber numberWithInt:i] atIndex:j];
                    } else {
                        int cost = ([s1 characterAtIndex:i-1] != [s2 characterAtIndex:j-1] ? 1 : 0);
                        int x1  = [[D2 objectAtIndex:j-1] intValue];
                        int x2 = [[D1 objectAtIndex:j] intValue];
                        int x3 = ([[D1 objectAtIndex:j-1] intValue] + cost);
                        int x4 = ([[D2 objectAtIndex:j-1] intValue] + 1);
                        int x5 = ([[D1 objectAtIndex:j] intValue] + 1);
                        if ((x1 < x2) && (x1 < x3)) {
                            [D2 insertObject:[NSNumber numberWithInt:x4] atIndex:j];
                        } else if (x2 < x3)
                            [D2 insertObject:[NSNumber numberWithInt:x5] atIndex:j];
                        else
                            [D2 insertObject:[NSNumber numberWithInt:x3] atIndex:j];
                    }
                    
                }
            }
        }
        
        res = [[D2 objectAtIndex:n] intValue];
    }
    
    return res;
}

- (void)getObjectWithItem:(FTSItem *)item completion:(void (^)(id object, NSError *error))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id retObj;
        NSData *object = [self objectDataWithID:item.ID andType:item.type];
        if (object.length) {
            retObj = [self unarchiveObjectWithData:object];
        }
        
        item.object = retObj;
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(retObj, nil);
            });
        }
    });
}

- (void)getObjectsWithItems:(NSArray <FTSItem *> *)items completion:(void (^)(NSArray *objects, NSError *error))completion
{
    NSMutableArray *retObjects = @[].mutableCopy;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [items enumerateObjectsUsingBlock:^(FTSItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            NSData *objData = [self objectDataWithID:item.ID andType:item.type];
            id object;
            if (objData.length) {
                object = [self unarchiveObjectWithData:objData];
                if (object) {
                    item.object = object;
                    [retObjects addObject:object];
                }
            }
        }];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(retObjects.copy, nil);
            });
        }
    });
}

#pragma mark - Helpers

- (id)unarchiveObjectWithData:(NSData *)data
{
    id object;
    if (@available(iOS 11.0, *)) {
        object = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class]
                                                   fromData:data
                                                      error:nil];
    } else {
        object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    return object;
}

/**
 Сериализует объект в строку. Класс объекта должен поддерживать протокол NSCoding
 
 @param object экземпляр класс
 @return сериализованный объект
 */
- (NSString *)serializedStringWithObject:(id)object
{
    NSData *objectData;
    if ([object conformsToProtocol:@protocol(NSCoding)]) {
        if (@available(iOS 11.0, *)) {
            objectData = [NSKeyedArchiver archivedDataWithRootObject:object
                                               requiringSecureCoding:YES
                                                               error:nil];
            
        } else {
            objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
        }
    } else {
        NSLog(@"Error on indexing object of class %@, \n Object doesn't conforms to protocol: NSCoding", NSStringFromClass([object class]));
        @throw NSInternalInconsistencyException;
    }
    
    NSString *serialized = [objectData base64EncodedStringWithOptions:0];
    return serialized;
}

- (NSData *)serializedDataWithObject:(id)object
{
    NSData *objectData;
    if ([object conformsToProtocol:@protocol(NSCoding)]) {
        if (@available(iOS 11.0, *)) {
            objectData = [NSKeyedArchiver archivedDataWithRootObject:object
                                               requiringSecureCoding:YES
                                                               error:nil];
            
        } else {
            objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
        }
    } else {
        NSLog(@"Error on indexing object of class %@, \n Object doesn't conforms to protocol: NSCoding", NSStringFromClass([object class]));
        @throw NSInternalInconsistencyException;
    }
    
    return objectData;
}

- (NSData *)objectDataWithID:(NSString *)ID andType:(NSString *)type
{
    sqlite3_stmt * _stmt;
    char * errMsg;
    NSData *object;
    NSString *querySt =  [NSString stringWithFormat:@"\
                          SELECT o.object \
                          FROM objects as o \
                          WHERE o.type = \"%@\" \
                          AND o.id = \"%@\";", type, ID];
    
    const char * sqlQuery = [querySt UTF8String];
    if(sqlite3_prepare_v2(searchdb, sqlQuery, -1, &_stmt, &errMsg) != SQLITE_OK) {
        [self errorStatement:querySt withError:errMsg];
    } else {
        if (sqlite3_step(_stmt) == SQLITE_ROW) {
            object = [NSData dataWithBytes:sqlite3_column_blob(_stmt, 0) length:sqlite3_column_bytes(_stmt, 0)];
        }
    }
    sqlite3_finalize(_stmt);
    _stmt = NULL;
    return object;
}

- (void)errorStatement:(NSString *)statement withError:(const char *)error
{
    NSLog(@"DB statement:<%@> error:<%@>", statement, [[NSString alloc] initWithUTF8String:error? : sqlite3_errmsg(searchdb)]);
}

@end
