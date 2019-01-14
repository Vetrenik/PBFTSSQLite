//
//  Item.h
//  TestSQLite
//
//  Created by Anton on 10/10/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTSItem : NSObject

@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSString * ID;

/**
 В topic передаётся одна из тем из первого столбца файла TopicList.txt, в соответсвии с тематикой объекта
 */
@property (nonatomic, strong) NSArray<NSString *> * topicList;
@property (nonatomic, strong) NSString * desc;
@property (nonatomic, assign) float value;
@property (nonatomic, strong) NSDate * date ;
@property (nonatomic, strong) NSString * currency;
@property (nonatomic, strong) id object;
@property (nonatomic, assign) double rank;

-(instancetype) initItemWithType:(NSString *)type
                              ID:(NSString *)ID
                          topics:(NSArray<NSString *> * _Nullable)topicList
                            desc:(NSString *)desc
                           value:(float)value
                            date:(NSDate * _Nullable)date
                        currency:(NSString *)currency
                          object:(id _Nullable)object;

@end

NS_ASSUME_NONNULL_END
