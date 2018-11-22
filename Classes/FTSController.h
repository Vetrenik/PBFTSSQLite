//
//  FTSController.h
//  TestSQLite
//
//  Created by Anton on 10/10/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FTSItem;
@class FTSQueryItem;
@class FTSBufsContainer;
@class FTSSearchParameters;
@class FTSPorter;

@interface FTSController : NSObject

@property (nonatomic, strong) NSString *databasePath;
@property (nonatomic, strong) FTSBufsContainer * bufs;
@property (nonatomic, strong) FTSSearchParameters * parameters;
@property (nonatomic, strong) FTSPorter * stemmer;
@property (nonatomic, strong) NSDictionary * topicDict;
@property (nonatomic, strong) NSDictionary * topicDescDict;



+(FTSController *) SharedInstance;

/**
 Инициализация движка поисковика, необходимо вызвать при первом обращении к SharedInstance
 
 @param dbpath Путь к фолдеру, в котором требуется создать БД с поисковиком
 */
-(void) initializeWithDBPathString:(NSString *)dbpath;

-(BOOL) indexRecordsWithArrayOfItems:(NSArray *)iArray;

-(NSArray<FTSItem *> *) searchWithQueryString:(NSString *)sString;

@end

NS_ASSUME_NONNULL_END
