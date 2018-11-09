//
//  QueryItem.h
//  TestSQLite
//
//  Created by Anton on 10/12/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FTSQueryItem : NSObject


@property (nonatomic, strong) NSString * desc;
@property (nonatomic, strong) NSString * first_value;
@property (nonatomic, strong) NSString * second_value;
@property (nonatomic, strong) NSString * first_date;
@property (nonatomic, strong) NSString * second_date;
@property (nonatomic, strong) NSString * currency;

-(instancetype) initWithDesc:(NSString *)desc
                  firstValue:(NSString *)first_value
                 secondValue:(NSString *)second_value
                   firstDate:(NSString *)first_date
                  secondDate:(NSString *)second_date
                    currency:(NSString *)currency;

@end

NS_ASSUME_NONNULL_END
