//
//  QueryItem.m
//  TestSQLite
//
//  Created by Anton on 10/12/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import "FTSQueryItem.h"

@implementation FTSQueryItem

-(instancetype) initWithDesc:(NSString *)desc
                  firstValue:(NSString *)first_value
                 secondValue:(NSString *)second_value
                   firstDate:(NSString *)first_date
                  secondDate:(NSString *)second_date
                    currency:(NSString *)currency {
    if (self = [super init]) {

        self.desc = desc;
        self.first_value = first_value;
        self.second_value = second_value;
        self.first_date = first_date;
        self.second_date = second_date;
        self.currency = currency;
    }
    return self;
}


@end
