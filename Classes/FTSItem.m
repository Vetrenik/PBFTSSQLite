//
//  Item.m
//  TestSQLite
//
//  Created by Anton on 10/10/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import "FTSItem.h"

@implementation FTSItem

-(instancetype) initItemWithType:(NSString *)type
                             ID:(NSString *)ID
                         topics:(NSArray<NSString *> *)topicList
                           desc:(NSString *)desc
                          value:(float)value
                           date:(NSDate *)date
                       currency:(NSString *)currency
                         object:(id)object{
    if (self = [super init]) {
        self.type = type;
        self.ID = ID;
        self.topicList = topicList;
        self.desc = desc;
        self.value = value;
        self.date = date;
        self.currency = currency;
        self.object = object;
    }
    return self;
}



@end
