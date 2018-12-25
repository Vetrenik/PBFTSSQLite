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
                            date:(NSDate * _Nullable)date
                        currency:(NSString *)currency
                          object:(id _Nullable)object{
    if (self = [super init]) {
        self.type = type;
        self.ID = ID;
        self.topicList = topicList;
        self.desc = desc;
        if (value < 0.0f) {
            self.value = value*(-1.0f);
        } else {
            self.value = value;
        }
        
        self.date = date;
        self.currency = currency;
        self.object = object;
    }
    return self;
}

#pragma mark - <Equals>
- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    
    if ([object isKindOfClass:self.class]) {
        FTSItem *otherObject = (FTSItem *)object;
        if ([otherObject.ID isEqualToString:self.ID] && [otherObject.type isEqualToString:self.type]) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash
{
    return [NSString stringWithFormat:@"%@%@", self.ID, self.type].hash;
}


@end
