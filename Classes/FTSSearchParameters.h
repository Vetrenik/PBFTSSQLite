//
//  SearchParameters.h
//  parserText
//
//  Created by user on 17.10.2018.
//  Copyright © 2018 user. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FTSBufsContainer.h"

@interface FTSSearchParameters : NSObject
@property (nonatomic, strong) NSString* query;
@property (nonatomic, strong) NSString* currency;
@property (nonatomic, strong) NSString* first_date;
@property (nonatomic, assign) float first_value;
@property (nonatomic, assign) float second_value;
@property (nonatomic, strong) NSString* second_date;

-(instancetype)  initSearchParametersWithBufs:(FTSBufsContainer*)bufs
                                      inputed:(NSString*)inputed;

+(NSMutableString*) normalizeCurrencyWithQuery:(NSString*)query
                                      smallCur:(NSString*)smallCur
                                       mainCur:(NSString*)mainCur
                                          bufs:(FTSBufsContainer*)bufs;

+(NSMutableArray*) normalizeValuesWithWords:(NSMutableArray*)words
                                   smallCur:(NSString*)smallCur
                                   mainCurs:(NSArray*)mainCurs
                                       bufs:(FTSBufsContainer*)bufs;

+(void) weekDayprocWithI:(int)i
                   words:(NSMutableArray*)words
               dayNumber:(int)dayNumber
                    bufs:(FTSBufsContainer*)bufs
      isSingleTermPeriod:(BOOL)isSingleTermPeriod
                 isFirst:(BOOL)isFirst;

+(void) specificDayprocWithI:(int)i
                       words:(NSMutableArray*)words
                   dayNumber:(int)dayNumber
                        bufs:(FTSBufsContainer*)bufs
          isSingleTermPeriod:(BOOL)isSingleTermPeriod
                     isFirst:(BOOL)isFirst;

+(void) monthProcWithI:(int)i
                 words:(NSMutableArray*)words
                     k:(int)k
                    MM:(NSString*)MM
                  bufs:(FTSBufsContainer*)bufs
    isSingleTermPeriod:(BOOL)isSingleTermPeriod
               isFirst:(BOOL)isFirst;

+(BOOL) checkForYearWithItem:(NSString*)item;

+(int) validDayWithMonth:(int)month
                    year:(int)year
                     num:(int)num;

+(int) getMonthsEndDateWithMonth:(int)month
                            year:(int)year;

+(int) howManyDaysWithDay:(int)day
                  isFirst:(BOOL)isFirst;

+(NSMutableString*) getDatePeriodWithyWords:(NSMutableArray*)words
                                       bufs:(FTSBufsContainer*)bufs;

+(BOOL) partialEqualsWith:(NSArray*)target
                      obj:(NSString*)obj;

+(int) getNearestFloatIndexWithWords:(NSMutableArray*)words
                                   j:(int)j;

+(NSString*) getSumWithWords:(NSMutableArray*)words
                        bufs:(FTSBufsContainer*)bufs;

-(NSString*) testprint;

@end

