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

@interface FTSController()

-(BOOL) createDB;

-(BOOL) indexOneRecordWithItem:(FTSItem *)item;

-(NSArray *) searchWithQueryItem:(FTSQueryItem *)query;

-(NSArray *) setListOfTopicsWithArrayTopicList:(NSArray *)list;

-(NSArray<NSDictionary *> *) makeDicts;

-(NSString *)dateReformatWithDate:(NSString *)date;

-(NSString *)dateReformatWithTrueDate:(NSDate *)date;

-(NSDate *)dateBackReformatWithDate:(NSString *)date;

@end

@implementation FTSController

static sqlite3 * searchdb = nil;
static sqlite3_stmt * stmt = nil;

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
    
    if ([fileMgr fileExistsAtPath:self.databasePath] == YES) {
        [fileMgr removeItemAtPath:self.databasePath error:nil];
    }
    
    if ([fileMgr fileExistsAtPath:self.databasePath] == NO) {
        
        if (sqlite3_open([self.databasePath UTF8String], &searchdb) == SQLITE_OK) {
            char * errMsg;
            const char * sqlSt = "CREATE VIRTUAL TABLE  search USING fts5(type, id, desc, value, date, currency, object UNINDEXED, tokenize = \'porter ascii\');";
            
            if (sqlite3_exec(searchdb, sqlSt, NULL, NULL, &errMsg) == SQLITE_OK) {
                state = YES;
                return state;
            } else {
                NSLog(@"Error on creating fts5 table");
                return state;
            }
            
        } else {
            NSLog(@"Error on open/create db");
        }
    }
    return state;
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


-(BOOL) indexOneRecordWithItem:(FTSItem *)item {
    BOOL state = NO;
    
    NSRegularExpression * spec = [NSRegularExpression regularExpressionWithPattern:@"\\p{P}"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSRegularExpression * spacer = [NSRegularExpression regularExpressionWithPattern:@"\\s+"
                                                                             options:NSRegularExpressionCaseInsensitive
                                                                               error:nil];
    item.desc = [spec stringByReplacingMatchesInString:item.desc
                                               options:0
                                                 range:NSMakeRange(0, [item.desc length])
                                          withTemplate:@" "];
    
    item.desc = [spacer stringByReplacingMatchesInString:item.desc
                                                 options:0
                                                   range:NSMakeRange(0, [item.desc length])
                                            withTemplate:@" "];
    
    
    //stemming of the item's description
    item.desc = [self.stemmer stemSentenceWithString:item.desc];
    
    //reformating the item's date from dd/MM/yyyy mm:HH to yyyyMMddHHmm format
    NSString * date = [self dateReformatWithTrueDate:item.date];
    
    //making the custom set of topics for item in order to it's base topic
    item.topicList = [self setListOfTopicsWithArrayTopicList:item.topicList];
    
    //making the custom description based on item's set of topics
    for (NSString * topic in item.topicList) {
        NSString * buf = @"";
        NSArray * descs = [self.topicDescDict objectForKey:topic];
        for (NSString * desc in descs) {
            buf = [buf stringByAppendingString:[desc stringByAppendingString:@" "]];
        }
        item.desc = [item.desc stringByAppendingString:[@" " stringByAppendingString:buf]];
    }
    
    item.desc = [item.desc lowercaseString];
    
    NSString * object= @"";
    
    if ([item.object conformsToProtocol:@protocol(NSCoding)]) {
        if (@available(iOS 11.0, *)) {
            NSData * objectData = [NSKeyedArchiver archivedDataWithRootObject:item.object
                                                        requiringSecureCoding:YES
                                                                        error:nil];
            object = [objectData base64EncodedStringWithOptions:0];
        } else {
            NSData * objectData = [NSKeyedArchiver archivedDataWithRootObject:item.object];
            object = [objectData base64EncodedStringWithOptions:0];
        }
    } else {
        NSLog(@"Error on indexing object of class %@ with type: %@ with id: %@, \n Object doesn't conforms to protocol: NSCoding", NSStringFromClass([item.object class]),item.type, item.ID);
        @throw NSInternalInconsistencyException;
    }
    
    
    
    
    NSString * value =  [NSString stringWithFormat:@"%015.2f", item.value];
    NSString * sqlSt = [NSString stringWithFormat:@"INSERT OR REPLACE INTO search (rowid, type, id, desc, value, date, currency, object) values ((select rowid from search where id = \'%@\' and type = \'%@\'),\"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\", \"%@\")",item.ID, item.type, item.type, item.ID, item.desc, value, date, item.currency, object];
    const char * sqlInsert = [sqlSt UTF8String];
    const char * errMsg;
    
    if (sqlite3_open([self.databasePath UTF8String], &searchdb) == SQLITE_OK) {
        sqlite3_prepare_v2(searchdb, sqlInsert, -1, &stmt, &errMsg);
        
        if (sqlite3_step(stmt) ==SQLITE_DONE) {
            state = YES;
            sqlite3_close(searchdb);
            return state;
        }
        sqlite3_reset(stmt);
        
    } else {
        NSLog(@"Error on inserting into search table");
    }
    
    return state;
}

-(BOOL) indexRecordsWithArrayOfItems:(NSArray *)iArray {
    BOOL state = NO;
    for (FTSItem * item in iArray) {
        state = [self indexOneRecordWithItem:item];
    }
    return state;
}

-(NSArray<FTSItem *> *) searchWithQueryString:(NSString *)sString {
    self.parameters = [[FTSSearchParameters alloc] initSearchParametersWithBufs:self.bufs
                                                                        inputed:sString];
    
    self.parameters.query = [[self.stemmer stemSentenceWithString:self.parameters.query] lowercaseString];
    
    NSArray * buf = [self.parameters.query componentsSeparatedByString:@" "];
    NSString * buf1 = @"(";
    
    if ([buf count] > 1) {
        buf1 = [NSString stringWithFormat:@"(%@*", [buf objectAtIndex:0]];
        for (int i = 1; i < [buf count]; i++) {
            if (i != [buf count]-1) {
                buf1 = [NSString stringWithFormat:@"%@ OR %@*", buf1, [buf objectAtIndex:i]];
            } else {
                buf1 = [NSString stringWithFormat:@"%@ OR %@*)", buf1, [buf objectAtIndex:i]];
            }
        }
    } else {
        if ([[buf objectAtIndex:0] length] > 0) {
            buf1 = [NSString stringWithFormat:@"%@*", [buf objectAtIndex:0]];
        } else {
            buf1 =[buf objectAtIndex:0];
        }
    }
    
    
    FTSQueryItem * qItem = [[FTSQueryItem alloc] initWithDesc:buf1
                                                   firstValue:[NSString stringWithFormat:@"%015.2f", self.parameters.first_value]
                                                  secondValue:[[NSString stringWithFormat:@"%015.2f", self.parameters.second_value] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                                    firstDate:[self dateReformatWithDate:self.parameters.first_date]
                                                   secondDate:[self dateReformatWithDate:self.parameters.second_date]
                                                     currency:self.parameters.currency];
    return [self searchWithQueryItem:qItem];
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
    if (!date) {
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
        
        NSString * res = [[NSString stringWithFormat:@"%i", (int)year] stringByAppendingString:monthR];
        res = [res stringByAppendingString:dayR];
        res = [res stringByAppendingString:hourR];
        res = [res stringByAppendingString:minuteR];
    }
    return res;
}

-(NSDate *)dateBackReformatWithDate:(NSString *)date {
    NSDateFormatter * formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyyMMddHHmm"];
    NSDate * res = [formatter dateFromString:date];
    return res;
}

-(NSArray<FTSItem *> *) searchWithQueryItem:(FTSQueryItem *)query {
    
    NSMutableArray * resArray = @[].mutableCopy;
    
    BOOL hasFirstDate = ![query.first_date isEqualToString:@""];
    BOOL hasSecondDate =![query.second_date isEqualToString:@""];
    BOOL hasDate = hasFirstDate&&hasSecondDate;
    BOOL hasFirstValue = ![query.first_value isEqualToString:[NSString stringWithFormat:@"%015.2f", 0.0f]];
    BOOL hasSecondValue = ![query.second_value isEqualToString:@"inf"];
    BOOL hasValue = hasFirstValue&&hasSecondValue;
    
    if (!hasSecondValue) query.second_value = @"999999999999999";
    NSString * querySt;
    if (hasValue&&hasDate) {  //if query has both value and date
        querySt = [NSString stringWithFormat:@"\
                   SELECT type, id, desc, value, date, currency, object \
                   FROM search as s \
                   WHERE s.desc MATCH \'%@\'\
                   AND s.value BETWEEN \'%@\' AND \'%@\'\
                   AND s.date BETWEEN \'%@\' AND \'%@\'\
                   and s.currency = \'%@\'\
                   ORDER BY bm25(search);", query.desc, query.first_value, query.second_value, query.first_date, query.second_date, query.currency];
    } else if (hasValue&&!hasDate) { //if query has value but not date
        querySt = [NSString stringWithFormat:@"\
                   SELECT type, id, desc, value, date, currency, object \
                   FROM search as s \
                   WHERE s.desc MATCH \'%@\'\
                   AND s.value BETWEEN \'%@\' AND \'%@\'\
                   and s.currency = \'%@\'\
                   ORDER BY bm25(search);", query.desc, query.first_value, query.second_value,query.currency];
    } else if (!hasValue&&hasDate) { //if query has date but not value
        querySt =  [NSString stringWithFormat:@"\
                    SELECT type, id, desc, value, date, currency, object \
                    FROM search as s \
                    WHERE s.desc MATCH \'%@\'\
                    AND s.date BETWEEN \'%@\' AND \'%@\'\
                    ORDER BY bm25(search);", query.desc,query.first_date, query.second_date];
    } else { // query if has neither value nor date
        querySt =  [NSString stringWithFormat:@"\
                    SELECT type, id, desc, value, date, currency, object \
                    FROM search as s \
                    WHERE s.desc MATCH \'%@\'\
                    ORDER BY bm25(search);", query.desc];
    }
    
    
    const char * sqlQuery = [querySt UTF8String];
    if (sqlite3_open([self.databasePath UTF8String], &searchdb) == SQLITE_OK) {
        if(sqlite3_prepare_v2(searchdb, sqlQuery, -1, &stmt, NULL) == SQLITE_OK) {
            NSString * type;
            NSString * ID;
            NSString * desc;
            NSString * value;
            NSString * date;
            NSString * currency;
            NSData * object;
            while(sqlite3_step(stmt) == SQLITE_ROW) {
                type = [[NSString alloc] initWithUTF8String:
                        (const char *) sqlite3_column_text(stmt, 0)];
                
                ID = [[NSString alloc] initWithUTF8String:
                      (const char *) sqlite3_column_text(stmt, 1)];
                
                desc = [[NSString alloc] initWithUTF8String:
                        (const char *) sqlite3_column_text(stmt, 2)];
                
                value = [[NSString alloc] initWithUTF8String:
                         (const char *) sqlite3_column_text(stmt, 3)];
                
                date = [[NSString alloc] initWithUTF8String:
                        (const char *) sqlite3_column_text(stmt, 4)];
                
                currency = [[NSString alloc] initWithUTF8String:
                            (const char *) sqlite3_column_text(stmt, 5)];
                
                object = [[NSData alloc] initWithBase64EncodedString:[[NSString alloc] initWithUTF8String:
                                                                      (const char *) sqlite3_column_text(stmt, 6)]
                                                             options:0 ];
                
                id retObj;
                
                if (@available(iOS 11.0, *)) {
                    retObj = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class]
                                                               fromData:object
                                                                  error:nil];
                } else {
                    retObj = [NSKeyedUnarchiver unarchiveObjectWithData:object];
                }
                FTSItem * item;
                item = [[FTSItem alloc] initItemWithType:type
                                                      ID:ID
                                                  topics:[NSArray new]
                                                    desc:desc
                                                   value:[value floatValue]
                                                    date:[self dateBackReformatWithDate:date]
                                                currency:currency
                                                  object:retObj];
                
                [resArray addObject:item];
            }
            sqlite3_reset(stmt);
        }}
    sqlite3_close(searchdb);
    return resArray.copy;
}


@end
