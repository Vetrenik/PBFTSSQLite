//
//  SearchParameters.m
//  parserText
//
//  Created by user on 17.10.2018.
//  Copyright © 2018 user. All rights reserved.
//
//

#import "FTSSearchParameters.h"

@implementation FTSSearchParameters

-(instancetype)  initSearchParametersWithBufs:(FTSBufsContainer *)bufs
                                      inputed:(NSString *)inputed {
    if([inputed isEqualToString:@""]){
        _query = @"";
        _currency = @"";
        _first_value = 0.0f;
        _second_value = INFINITY;
        _first_date = @"".mutableCopy;
        _second_date = @"".mutableCopy;
        
    } else {
        _first_date = @"".mutableCopy;
        _second_date = @"".mutableCopy;
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        nf.numberStyle = NSNumberFormatterNoStyle;
        
        NSMutableString* norm = [self normalizeCurrencyWithQuery:inputed smallCur:@"коп" mainCur:@"руб" bufs:bufs];
        norm = [self normalizeCurrencyWithQuery:norm smallCur:@"цен" mainCur:@"дол" bufs:bufs];
        norm = [self normalizeCurrencyWithQuery:norm smallCur:@"цен" mainCur:@"евр" bufs:bufs];
        
        NSMutableArray* normalized = [self normalizeValuesWithWords:[norm componentsSeparatedByString: @" "].mutableCopy smallCur:@"коп" mainCurs:[NSArray arrayWithObjects:@"руб",nil].mutableCopy bufs:bufs];
        
        normalized = [self normalizeValuesWithWords:normalized
                                           smallCur:@"цен"
                                           mainCurs:[NSArray arrayWithObjects:@"дол", @"евр",nil].mutableCopy
                                               bufs:bufs];
        NSMutableString* buf = [self getSumWithWords:normalized
                                                bufs:bufs].mutableCopy;
        
        
        if (![buf isEqualToString:@""]) {
            NSRange range = NSMakeRange([buf rangeOfString:@"["].location + 1, [buf rangeOfString:@"-"].location - 1);
            NSMutableString* bufSubstr = [buf substringWithRange:NSMakeRange(range.location, range.length - range.location)].mutableCopy;
            
            float ff;
            NSScanner* sc;
            sc = [NSScanner scannerWithString:bufSubstr];
            
            if ([sc scanFloat:&ff]) {
                
                _first_value = [bufSubstr doubleValue];
                NSRange range = NSMakeRange([buf rangeOfString:@"-"].location + 2, [buf rangeOfString:@"]"].location);
                bufSubstr = [buf substringWithRange:NSMakeRange(range.location, range.length - range.location)].mutableCopy;
                
                if (![bufSubstr isEqualToString:@"inf"]) {
                    _second_value = [[buf substringWithRange:NSMakeRange(range.location, range.length - range.location)].mutableCopy doubleValue];
                } else {
                    _second_value = INFINITY;
                }
                _currency = [buf substringFromIndex:[buf rangeOfString:@"]"].location + 1];
            }
        } else {
            _second_value = INFINITY;
            _currency = @"";
        }
        
        // Дунно пока, мб не norm а inputed
        buf = [self getDatePeriodWithWords:normalized bufs:bufs];
        
        if ([buf isEqualToString:@"[ - ]; "]) {
            _first_date = @"".mutableCopy;
            _second_date = @"".mutableCopy;
        } else {
            NSRange range = NSMakeRange([buf rangeOfString:@"["].location + 1, [buf rangeOfString:@"-"].location);
            _first_date = [buf substringWithRange:NSMakeRange(range.location, range.length - range.location - 1)].mutableCopy;
            range = NSMakeRange([buf rangeOfString:@"-"].location + 2, [buf rangeOfString:@"]"].location);
            _second_date = [buf substringWithRange:NSMakeRange(range.location, range.length - range.location)].mutableCopy;
        }
        
        for (NSNumber* j in bufs.perIndexes) {
            [normalized replaceObjectAtIndex:[j intValue] withObject:@""];
        }
        [bufs.perIndexes removeAllObjects];
        
        NSMutableString* result = @"".mutableCopy;
        
        NSArray* deleting = [NSArray arrayWithObjects:@"последних", @"период", @"с", @"от", @"до", @"по", @"после", @"перед", @"за", @"на", @"и", @"от", @"ранее", @"раньше", @"позднее", @"позже", @"больше", @"меньше", @"более", @"менее", @"чем",nil].mutableCopy; //"за", "и", "до", "от", "на", "с", "по"
        for (int i = 0; i < [normalized count]; i++) {
            for (NSString* item in deleting) {
                if ([normalized[i] isEqualToString:item]) {
                    [normalized replaceObjectAtIndex:i withObject:@""];
                }
            }
        }
        
        for (NSString* item in normalized) {
            [result appendString:item];
            [result appendString:@" "];
        }
        
        [bufs clear];
        _query = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return self;
}

-(NSMutableString*) normalizeCurrencyWithQuery:(NSString *)query
                                      smallCur:(NSString *)smallCur
                                       mainCur:(NSString *)mainCur
                                          bufs:(FTSBufsContainer *)bufs {
    
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setUsesGroupingSeparator:YES];
    [numFormatter setDecimalSeparator:@"."];
    [numFormatter setMinimumSignificantDigits:2];
    
    NSScanner* sc;
    
    NSMutableString* result = @"".mutableCopy;
    int b = 0;
    NSMutableString* buf = [query stringByReplacingOccurrencesOfString:@" млн " withString: @"000000 "].mutableCopy;
    [buf replaceOccurrencesOfString:@" миллиона " withString:@" 1000000 " options:0 range:NSMakeRange(0, [buf length])];
    [buf replaceOccurrencesOfString:@" миллиарда " withString:@" 1000000000 " options:0 range:NSMakeRange(0, [buf length])];
    [buf replaceOccurrencesOfString:@" млрд " withString:@"000000000 " options:0 range:NSMakeRange(0, [buf length])];
    
    if(query != nil && ![query isEqualToString:@""]){
        NSMutableArray* words = [buf componentsSeparatedByString:@" "].mutableCopy;
        
        int kopcounter = 0;
        for (int i = 0; i < [words count]; i++) {
            if ([words[i] length] > 2 && [smallCur isEqualToString:[words[i] substringToIndex:3]] && [bufs isTermCurrencyWithTerm: words[i]]) {
                kopcounter++;
            }
        }
        
        if (kopcounter == 0) {
            return buf;
        }
        
        // Убираем копейки и центы в рубли 10 рублей 50 копеек = 10,5 рублей
        for (int i = 0; i < [words count]; i++) {
            
            if ([words[i] length] > 2 && [smallCur isEqualToString:[words[i] substringToIndex:3]] && [bufs isTermCurrencyWithTerm: words[i]]) {
                if (i > 2 && [words[i - 2] length] > 2 && [mainCur isEqualToString:[words[i - 2] substringToIndex:3]]) {
                    
                    sc = [NSScanner scannerWithString:words[i - 3]]; // старшая валюта
                    NSScanner* sc1 = [NSScanner scannerWithString:words[i - 1]]; // младшая валюта
                    double r;
                    double k;
                    if([sc scanDouble:&r] && [sc1 scanDouble:&k]) {
                        
                        r = [words[i - 3] doubleValue];
                        k = [words[i - 1] doubleValue];
                        r = r + k / 100;
                        
                        // Первая валюта и нужно преобразований для обоих случаев (от начала до текущего), сейчас первый участок интервала и нашли старшую
                        if ([result isEqualToString:@""] && kopcounter > 1) {
                            for (int j = 0; j < i; j++) {
                                if (j == i - 1) {
                                    continue;
                                } else if (j == i - 3) {
                                    [result appendString:@" "];
                                    [result appendString:[numFormatter stringFromNumber:@(r)]];
                                } else {
                                    [result appendString:@" "];
                                    [result appendString:words[j]];
                                }
                            }
                            b = i + 1;
                            
                            // Вторая валюта и нужно преобразований для обоих случаев (после текущего до конца), сейчас второй участок интервала и нашли старшую
                        } else if (![result isEqualToString:@""] && kopcounter > 1) {
                            for (int j = b; j < [words count]; j++) {
                                if (j == i || j == i - 1) {
                                    continue;
                                } else if (j == i - 3) {
                                    [result appendString:@" "];
                                    [result appendString:[numFormatter stringFromNumber:@(r)]];
                                } else {
                                    [result appendString:@" "];
                                    [result appendString:words[j]];
                                }
                            }
                            
                            // Нужно одно преобразование
                        } else {
                            for (int j = 0; j < [words count]; j++) {
                                if (j == i || j == i - 1) {
                                    continue;
                                } else if (j == i - 3) {
                                    [result appendString:@" "];
                                    [result appendString:[numFormatter stringFromNumber:@(r)]];
                                } else {
                                    [result appendString:@" "];
                                    [result appendString:words[j]];
                                }
                            }
                            return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].mutableCopy;
                        }
                        
                    }   else {
                        return buf;
                    }
                } else { // Случаи, когда нашли младшую валюту но не нашли старшую (просто копейки, центы и т.д.)
                    sc = [NSScanner scannerWithString:words[i - 1]]; // младшая валюта
                    double k;
                    if([sc scanDouble:&k]) {
                        k = [words[i - 1] doubleValue] / 100.0; // младшая валюта
                    }
                    // Первая валюта и нужно преобразований для обоих случаев (после текущего до конца), сейчас первый участок интервала и не нашли старшую
                    if ([result isEqualToString:@""] && kopcounter > 1) {
                        for (int j = 0; j < i; j++) {
                            if (j == i) {
                                [result appendString:@" "];
                                [result appendString:mainCur];
                                [result appendString:@"."];
                            } else if (j == i - 1) {
                                [result appendString:@" "];
                                [result appendString:[numFormatter stringFromNumber:@(k)]];
                            } else {
                                [result appendString:@" "];
                                [result appendString:words[j]];
                            }
                        }
                        b = i + 1;
                        
                        // Вторая валюта и нужно преобразований для обоих случаев (после текущего до конца), сейчас второй участок интервала и не нашли старшую
                    } else if (![result isEqualToString:@""] && kopcounter > 1) {
                        for (int j = b; j < [words count]; j++) {
                            if (j == i) {
                                [result appendString:@" "];
                                [result appendString:mainCur];
                                [result appendString:@"."];
                            } else if (j == i - 1) {
                                [result appendString:@" "];
                                [result appendString:[numFormatter stringFromNumber:@(k)]];
                            } else {
                                [result appendString:@" "];
                                [result appendString:words[j]];
                            }
                        }
                        
                        // Нужно одно преобразование на i позиции не нашли старшую
                    } else {
                        for (int j = 0; j < [words count]; j++) {
                            if (j == i) {
                                [result appendString:@" "];
                                [result appendString:mainCur];
                                [result appendString:@"."];
                            } else if (j == i - 1) {
                                [result appendString:@" "];
                                [result appendString:[numFormatter stringFromNumber:@(k)]];
                            } else {
                                [result appendString:@" "];
                                [result appendString:words[j]];
                            }
                        }
                        return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].mutableCopy;
                    }
                    
                }
            }
        }
        
    } else {
        return buf;
    }
    return [result isEqualToString:@""] ? buf : [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].mutableCopy;
}

-(NSMutableArray*) normalizeValuesWithWords:(NSMutableArray*)words
                                   smallCur:(NSString*)smallCur
                                   mainCurs:(NSArray*)mainCurs
                                       bufs:(FTSBufsContainer *)bufs {
    
    int rubcounter = 0;
    for (int i = 0; i < [words count]; i++) {
        if ([words[i] length] > 2 && [bufs isTermCurrencyWithTerm:words[i]] && [self partialEqualsWithTarget:mainCurs obj:[words[i] substringToIndex:3]]) {
            rubcounter++;
        }
    }
    if (rubcounter == 2) {
        int k = -1;
        for (int i = 0; i < [words count]; i++) {
            if ([words[i] length] > 2 && [self partialEqualsWithTarget:mainCurs obj:[words[i] substringToIndex:3]]) {
                k = i;
                break;
            }
        }
        if (k != -1) {
            [words removeObjectAtIndex:k];
        }
    }
    return words;
}

-(void) weekDayprocWithI:(int)i
                   words:(NSMutableArray*)words
               dayNumber:(int)dayNumber
                    bufs:(FTSBufsContainer *)bufs
      isSingleTermPeriod:(BOOL)isSingleTermPeriod
                 isFirst:(BOOL)isFirst {
    
    [bufs cleanUpWordsWithIndex:i];
    int b = [self howManyDaysWithDay:dayNumber isFirst:isFirst];
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MM/yyyy"];
    NSDateComponents* components = [NSDateComponents new];
    components.day = b;
    NSString* timef = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
    components.day = 1;
    NSString* timet = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
    components.day = 0;
    if(isSingleTermPeriod){
        
        if(isFirst && i > 0) {
            if (([@[@"до", @"ранее", @"раньше"] containsObject:words[i - 1]]) || (i > 1 && [@[@"до", @"ранее", @"раньше"] containsObject:words[i - 2]])) {
                [_first_date appendString:@"01/01/1970 00:00"];
                [_second_date appendString:timet];
                [_second_date appendString:@" 00:00"];
                return;
            }
            if (([@[@"после", @"позже", @"позднее", @"от"] containsObject:words[i - 1]]) || (i > 1 && [@[@"после", @"позже", @"позднее", @"от"] containsObject:words[i - 2]])) {
                [_first_date appendString:timet];
                [_first_date appendString:@" 00:00"];
                components.day = 1;
                [_second_date setString:[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]]];
                [_second_date appendString:@" 00:00"];
                return;
            }
        }
        [_first_date appendString:timef];
        [_first_date appendString:@" 00:00"];
        [_second_date appendString:timet];
        [_second_date appendString:@" 00:00"];
    } else {
        if(isFirst){
            [_first_date appendString:timef];
            [_first_date appendString:@" 00:00"];
        } else {
            [_second_date appendString:timet];
            [_second_date appendString:@" 00:00"];
        }
    }
}

-(void) specificDayprocWithI:(int)i
                       words:(NSMutableArray*)words
                   dayNumber:(int)dayNumber
                        bufs:(FTSBufsContainer*)bufs
          isSingleTermPeriod:(BOOL)isSingleTermPeriod
                     isFirst:(BOOL)isFirst {
    
    [bufs cleanUpWordsWithIndex:i];
    
    for(int j = 0; j < [words count]; j++){
        if([words[j] isEqualToString:@"день"]) {
            [words replaceObjectAtIndex:j withObject:@""];
        }
    }
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MM/yyyy"];
    NSDateComponents* components = [NSDateComponents new];
    components.day = dayNumber;
    NSString* timef = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
    components.day = 1;
    NSString* timet = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
    components.day = 0;
    
    if(isSingleTermPeriod) {
        if (([@[@"до", @"ранее", @"раньше"] containsObject:words[i - 1]]) || (i > 1 && [@[@"до", @"ранее", @"раньше"] containsObject:words[i - 2]])) {
            [_first_date appendString:@"01/01/1970 00:00"];
            [_second_date appendString:timet];
            [_second_date appendString:@" 00:00"];
            return;
        } else if (([@[@"после", @"позже", @"позднее", @"от"] containsObject:words[i - 1]]) || (i > 1 && [@[@"после", @"позже", @"позднее", @"от"] containsObject:words[i - 2]])) {
            [_first_date appendString:timet];
            [_first_date appendString:@" 00:00"];
            components.day = 1;
            [_second_date setString:[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]]];
            [_second_date appendString:@" 00:00"];
            return;
        } else { //за на
            [_first_date appendString:timef];
            [_first_date appendString:@" 00:00"];
            [_second_date appendString:timet];
            [_second_date appendString:@" 00:00"];
        }
        
    } else {
        if(isFirst){
            [_first_date appendString:timef];
            [_first_date appendString:@" 00:00"];
        } else {
            [_second_date appendString:timet];
            [_second_date appendString:@" 00:00"];
        }
    }
}

-(void) monthProcWithI:(int)i
                 words:(NSMutableArray *)words
                     k:(int)k
                    MM:(NSString *)MM
                  bufs:(FTSBufsContainer *)bufs
    isSingleTermPeriod:(BOOL)isSingleTermPeriod
               isFirst:(BOOL)isFirst {
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    
    [bufs cleanUpWordsWithIndex:i];
    
    for (int j = 0; j < [words count]; j++) {
        if ([self checkForYearWithItem:words[j]]) {
            [bufs cleanUpWordsWithIndex:j];
            [words replaceObjectAtIndex:j withObject:@""];
        }
        if ([words[j] isEqualToString:@"месяц"]) {
            [bufs cleanUpWordsWithIndex:j];
            [words replaceObjectAtIndex:j withObject:@""];
            if (j + 1 < [words count]) {
                int YEAR = 0;
                NSNumber* checker = [nf numberFromString:words[j + 1]];
                if(checker != nil) {
                    if (j < [words count]) {
                        YEAR = [checker intValue];
                        [words replaceObjectAtIndex:j withObject:words[j + 1]];
                        [words replaceObjectAtIndex:j + 1 withObject:@""];
                        [bufs cleanUpWordsWithIndex:j + 1];
                    }
                }
            }
        }
    }
    
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd/MM/yyyy"];
    NSDateComponents *componentsToday = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    int todayDay = (int)[componentsToday day];
    int todayMonth = (int)[componentsToday month];
    int todayYear = (int)[componentsToday year];
    
    int todayYear1 = todayYear;
    int dayFirst = 1;
    int daySecond = 1;
    int yearFirst = todayYear;
    int yearSecond = todayYear;
    NSMutableString* dateFrom = @"".mutableCopy;
    NSMutableString* dateTo = @"".mutableCopy;
    BOOL IncludingTrigger = NO;
    BOOL KostylTrigger = NO;
    
    NSInteger mm = 0;
    NSNumber* checker = [nf numberFromString:MM];
    if(checker != nil) {
        mm = [checker integerValue];
    }
    
    if (i > 0) {
        int num = 1;
        
        // Парсим Год
        BOOL isParsedYear = YES;
        if (i + 1 < [words count]) {
            checker = [nf numberFromString:words[i + 1]];
            if(checker != nil) {
                num = [checker intValue]; // предположительно год
                [bufs cleanUpWordsWithIndex:i + 1];
                if (num > 1900 && num <= todayYear) {
                    if (num < todayYear % 100) {
                        // сказали 14-й год, например
                        todayYear = todayYear - todayYear % 100 + num;
                    } else if (num > todayYear % 100 && num < 100) {
                        todayYear = 1900 + num;
                    } else {
                        todayYear = num;
                    }
                } else {
                    todayYear = todayYear1;
                }
                
            } else {
                isParsedYear = NO;
                yearFirst = todayYear;
                yearSecond = todayYear;
                if ([@[@"прошлого", @"прошедшего", @"предыдущего"] containsObject:words[i + 1]]) {
                    todayYear--;
                    [bufs cleanUpWordsWithIndex:i + 1];
                }
                if ([words[i + 1] isEqualToString:@"позапрошлого"]) {
                    todayYear -= 2;
                    [bufs cleanUpWordsWithIndex:i + 1];
                }
            }
        } else {
            isParsedYear = NO;
            yearFirst = todayYear;
            yearSecond = todayYear;
        }
        BOOL isParsedDay = YES;
        // Парсим число
        checker = [nf numberFromString:words[i - 1]];
        if(checker != nil) {
            num = [checker intValue]; // предположительно число месяца
            [bufs cleanUpWordsWithIndex:i - 1];
            num = [self validDayWithMonth:k year:todayYear num:num];
            
        } else {
            num = 1;
            isParsedDay = NO;
        }
        
        if (isFirst) {  // Первый из периода
            dayFirst = num;
            if (!isParsedYear) {
                if (todayMonth < k || (todayMonth == k && dayFirst > todayDay)) {
                    yearFirst = todayYear - 1;
                }
            } else {
                yearFirst = todayYear;
            }
            
            if (isSingleTermPeriod && ([@[@"до", @"по", @"ранее", @"раньше", @"перед"] containsObject:words[i - 1]] || (i > 1 && (isParsedDay && ([@[@"до", @"по", @"ранее", @"раньше", @"перед"] containsObject:words[i - 2]]))))) {
                
                if (i > 3 && [@[@"с", @"за", @"на"] containsObject:words[i - 4]]) { // Если есть с 15 по 20 января
                    checker = [nf numberFromString:words[i - 3]];
                    if(checker != nil) {
                        NSInteger daybuf = [checker integerValue];
                        if (daybuf < 10) {
                            [_first_date appendString:@"0"];
                        }
                        [_first_date appendString:words[i - 3]];
                        [_first_date appendString:@"/"];
                        [_first_date appendString:MM];
                        [_first_date appendString:@"/"];
                        [_first_date appendString:[NSString stringWithFormat:@"%d", yearFirst]];
                        [_first_date appendString:@" 00:00"];
                        [bufs cleanUpWordsWithFInd:i - 4 SecInd:i - 3];
                    }
                    if ([words[i - 1] isEqualToString:@"по"] || (i > 1 && [words[i - 2] isEqualToString:@"по"])) {
                        if ([words[i - 1] isEqualToString:@"по"]) {
                            [bufs cleanUpWordsWithIndex:i - 1];
                        } else {
                            [bufs cleanUpWordsWithIndex:i - 2];
                        }
                        
                        NSDateComponents *comps = [[NSDateComponents alloc] init];
                        [comps setYear:yearFirst];
                        [comps setMonth:mm];
                        [comps setDay:dayFirst + 1];
                        NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        
                        NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"dd/MM/yyyy"];
                        [_second_date setString:[dateFormat stringFromDate:date]];
                        [_second_date appendString:@" 00:00"];
                        return;
                    }
                    if (dayFirst < 10) {
                        [_first_date appendString:@"0"];
                    }
                    [_first_date appendString:[NSString stringWithFormat:@"%d", dayFirst]];
                    [_first_date appendString:@"/"];
                    [_first_date appendString:MM];
                    [_first_date appendString:@"/"];
                    [_first_date appendString:[NSString stringWithFormat:@"%d", yearFirst]];
                    [_first_date appendString:@" 00:00"];
                    return;
                } else {    // просто до 15 января (день распарсили)
                    if ([words[i - 1] isEqualToString:@"по"] || (i > 1 && [words[i - 2] isEqualToString:@"по"])) {
                        if ([words[i - 1] isEqualToString:@"по"]) {
                            [bufs cleanUpWordsWithIndex:i - 1];
                        } else {
                            [bufs cleanUpWordsWithIndex:i - 2];
                        }
                        
                        NSDateComponents *comps = [[NSDateComponents alloc] init];
                        [comps setYear:yearFirst];
                        [comps setMonth:mm];
                        [comps setDay:dayFirst + 1];
                        NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"dd/MM/yyyy"];
                        
                        [_first_date appendString:@"01/01/1970 00:00"];
                        [_second_date setString:[dateFormat stringFromDate:date]];
                        [_second_date appendString:@" 00:00"];
                        return;
                    }
                    [_first_date appendString:@"01/01/1970 00:00"];
                    if (dayFirst < 10) {
                        [_second_date appendString:@"0"];
                    }
                    
                    [_second_date appendString:[NSString stringWithFormat:@"%d", dayFirst]];
                    [_second_date appendString:@"/"];
                    [_second_date appendString:MM];
                    [_second_date appendString:@"/"];
                    [_second_date appendString:[NSString stringWithFormat:@"%d", yearFirst]];
                    [_second_date appendString:@" 00:00"];
                    return;
                }
            }
            
            if (isSingleTermPeriod && ([@[@"после", @"позже", @"позднее", @"от", @"с"] containsObject:words[i - 1]] || (i > 1 && (isParsedDay && [@[@"после", @"позже", @"позднее", @"от", @"с"] containsObject:words[i - 2]])))) {
                // просто после 15 января (день распарсили)
                if (dayFirst < 10) {
                    [_first_date appendString:@"0"];
                }
                
                [_first_date appendString:[NSString stringWithFormat:@"%d", dayFirst]];
                [_first_date appendString:@"/"];
                [_first_date appendString:MM];
                [_first_date appendString:@"/"];
                [_first_date appendString:[NSString stringWithFormat:@"%d", yearFirst]];
                [_first_date appendString:@" 00:00"];
                NSDateComponents *comps = [NSDateComponents new];
                comps.day = 1;
                //NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                NSDate* date = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0];
                NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"dd/MM/yyyy"];
                [_second_date setString:[dateFormat stringFromDate:date]];
                [_second_date appendString:@" 00:00"];
                return;
            }
            
        } else { // Второе слово из периода
            if ([words[i - 1] isEqualToString:@"по"] || (isParsedDay && [words[i - 2] isEqualToString:@"по"])) {
                IncludingTrigger = YES;
            }
            if (!isParsedDay) {
                if ([@[@"до", @"ранее", @"раньше"] containsObject:words[i - 1]]) {
                    MM = [NSString stringWithFormat:@"%d", (int)(mm - 1)];
                } else {
                    daySecond = num;
                }
            } else {
                daySecond = num + 1;
            }
            if ((todayMonth <= k && dayFirst <= todayDay) && !isParsedYear) {
                yearSecond = todayYear - 1;
            } else {
                yearSecond = todayYear;
            }
        }
        
        if (isSingleTermPeriod) {
            
            // в январе
            if (i > 0 && [words[i - 1] isEqualToString:@"в"]) {
                [bufs cleanUpWordsWithIndex:i - 1];
                [_first_date appendString:@"01/"];
                [_first_date appendString:MM];
                [_first_date appendString:@"/"];
                [_first_date appendString:[NSString stringWithFormat:@"%d", yearFirst]];
                [_first_date appendString:@" 00:00"];
                
                NSDateComponents *comps = [[NSDateComponents alloc] init];
                [comps setYear:yearFirst];
                [comps setMonth:k];
                [comps setDay: 1 + [self getMonthsEndDateWithMonth:k year:yearFirst]];
                NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"dd/MM/yyyy"];
                [_second_date setString:[dateFormat stringFromDate:date]];
                [_second_date appendString:@" 00:00"];
                return;
            }
            
            // с 15 по 20 января
            if (i > 3 && [words[i - 2] isEqualToString:@"по"] && ([@[@"с", @"за", @"на"] containsObject:words[i - 4]])) {
                checker = [nf numberFromString:words[i - 3]];
                if(checker != nil) {
                    daySecond = dayFirst;
                    dayFirst = [self validDayWithMonth:k year:yearFirst num:(int)[checker integerValue]];
                    [bufs cleanUpWordsWithFInd:i - 4 SecInd:i - 2];
                } else {
                    daySecond = [self validDayWithMonth:k year:yearFirst num:dayFirst];
                }
                if (dayFirst < 10) {
                    [dateFrom appendString:@"0"];
                }
                
                [dateFrom appendString:[NSString stringWithFormat:@"%d", dayFirst]];
                [dateFrom appendString:@"/"];
                [dateFrom appendString:MM];
                [dateFrom appendString:@"/"];
                [dateFrom appendString:[NSString stringWithFormat:@"%d", yearFirst]];
                
                
                NSDateComponents *comps = [[NSDateComponents alloc] init];
                [comps setYear:yearFirst];
                [comps setMonth:k];
                [comps setDay: 1 + daySecond];
                NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"dd/MM/yyyy"];
                [dateTo setString:[dateFormat stringFromDate:date]];
                
            } else {
                if ([dateFrom isEqualToString:@""] || [dateFrom isEqualToString:@"0"]) {
                    if (dayFirst < 10) {
                        [dateFrom appendString:@"0"];
                    }
                    if (daySecond < 10) {
                        [dateTo appendString:@"0"];
                    }
                    
                    [dateFrom appendString:[NSString stringWithFormat:@"%d", dayFirst]];
                    [dateFrom appendString:@"/"];
                    [dateFrom appendString:MM];
                    [dateFrom appendString:@"/"];
                    [dateFrom appendString:[NSString stringWithFormat:@"%d", yearFirst]];
                }
                
                
                // с 5 января
                if ([@[@"на", @"за", @"с", @"от", @"после", @"позже", @"позднее"] containsObject:words[i - 1]] || (isParsedDay && ([@[@"позже", @"позднее"] containsObject:words[i - 1]] || (i > 1 && [@[@"на", @"за", @"с", @"от", @"после"] containsObject:words[i - 2]])))) {
                    if ([@[@"на", @"за", @"с", @"от", @"после", @"позже", @"позднее"] containsObject:words[i - 1]]) {
                        [bufs cleanUpWordsWithIndex:i - 1];
                    } else {
                        [bufs cleanUpWordsWithIndex:i - 2];
                    }
                    int bufindex = -1;
                    if (i + 1 < [words count] && [words[i + 1] isEqualToString:@"по"]) {
                        bufindex = i + 2;
                    } else if (i + 2 < [words count] && [words[i + 2] isEqualToString:@"по"]) {
                        BOOL yearflag = YES;
                        checker = [nf numberFromString:words[i + 1]];
                        yearflag = (checker != nil) ? YES : NO;
                        if (yearflag) {
                            bufindex = i + 3;
                        }
                    } else if (i + 3 < [words count] && [words[i + 3] isEqualToString:@"по"]) {
                        BOOL yearflag = YES;
                        checker = [nf numberFromString:words[i + 1]];
                        yearflag = (checker != nil) ? YES : NO;
                        if (yearflag && [words[i + 2] isEqualToString:@""]) {
                            bufindex = i + 4;
                        }
                    }
                    NSDateComponents *comps = [[NSDateComponents alloc] init];
                    
                    if (bufindex > 0 && bufindex < words.count) {
                        checker = [nf numberFromString:words[bufindex]];
                        if (checker != nil) {
                            [comps setYear:yearFirst];
                            [comps setMonth:k];
                            [comps setDay: 1 + [checker intValue]];
                            
                            NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                            NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                            [dateFormat setDateFormat:@"dd/MM/yyyy"];
                            [dateTo setString:[dateFormat stringFromDate:date]];
                            [bufs cleanUpWordsWithFInd:i - 1 SecInd:bufindex];
                        }
                    } else {
                        if ((i > 1 && [@[@"на", @"за"] containsObject:words[i - 2]])) { // one day
                            
                            [comps setYear:yearFirst];
                            [comps setMonth:mm];
                            [comps setDay: 1 + dayFirst];
                            NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                            NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                            [dateFormat setDateFormat:@"dd/MM/yyyy"];
                            [dateTo setString:[dateFormat stringFromDate:date]];
                        } else { // to our days
                            if (i > 0 && [@[@"на", @"за"] containsObject:words[i - 1]]) {
                                [comps setYear:yearFirst];
                                [comps setMonth:mm + 1];
                                [comps setDay: dayFirst];
                                
                                NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                                NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                                [dateFormat setDateFormat:@"dd/MM/yyyy"];
                                [dateTo setString:[dateFormat stringFromDate:date]];
                            } else {
                                comps.day = 1;
                                [dateTo setString:[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:[NSDate date] options:0]]];
                            }
                        }
                        [comps setYear:yearFirst];
                        [comps setMonth:k];
                        [comps setDay: dayFirst];
                        NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        [dateFrom setString:[dateFormat stringFromDate:date]];
                    }
                } else if ([@[@"на", @"за"] containsObject:words[i - 1]] || (i > 1 && isParsedDay && ([@[@"на", @"за"] containsObject:words[i - 2]]))) {
                    NSDateComponents *comps = [[NSDateComponents alloc] init];
                    if (i + 1 < [words count] && [words[i + 1] isEqualToString:@"по"]) {
                        checker = [nf numberFromString:words[i + 2]];
                        if (checker != nil) {
                            
                            [comps setYear:yearFirst];
                            [comps setMonth:k];
                            [comps setDay: 1 + [checker intValue]];
                            NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                            NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                            [dateFormat setDateFormat:@"dd/MM/yyyy"];
                            [dateTo setString:[dateFormat stringFromDate:date]];
                            
                            [bufs cleanUpWordsWithFInd:i - 1 SecInd:i + 2];
                        }
                    } else {
                        [comps setYear:yearFirst];
                        [comps setMonth:k];
                        [comps setDay: dayFirst];
                        if (isParsedDay) {
                            comps.day += 1;
                        } else {
                            comps.month += 1;
                        }
                        
                        NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"dd/MM/yyyy"];
                        [dateTo setString:[dateFormat stringFromDate:date]];
                        if (!isParsedDay) {
                            comps.month -= 1;
                            NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                            [dateTo setString:[dateFormat stringFromDate:date]];
                        }
                    }
                } else {
                    NSDateComponents *comps = [[NSDateComponents alloc] init];
                    [comps setYear:yearFirst];
                    [comps setMonth:k];
                    [comps setDay: dayFirst];
                    comps.day += 1;
                    NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"dd/MM/yyyy"];
                    [dateTo setString:[dateFormat stringFromDate:date]];
                    if ([dateTo isEqualToString:@""] || [dateTo isEqualToString:@"0"]) {
                        [dateTo setString:[dateFormat stringFromDate:[NSDate date]]];
                    }
                }
            }
        } else {
            if (isFirst) {
                if (!isParsedDay || dayFirst < 10) {
                    
                    dateFrom = @"0".mutableCopy;
                }
                [dateFrom appendString:[NSString stringWithFormat:@"%d", dayFirst]];
                [dateFrom appendString:@"/"];
                [dateFrom appendString:MM];
                [dateFrom appendString:@"/"];
                [dateFrom appendString:[NSString stringWithFormat:@"%d", yearFirst]];
            } else {
                // Если в августе набирают с января до декабрь (декабря еще не было)
                // Январь подразумевается текущего года, а декабрь(не наступивший месяц) по умолчанию предыдущего поэтому к году прибавим единицу
                if (!bufs.firstParsedYear && !isParsedYear) {   // - -
                    checker = [nf numberFromString:[_first_date substringWithRange:NSMakeRange(3, 2)]];
                    if(checker != nil) {
                        if ([checker intValue] < mm) {
                            yearSecond++;
                        }
                    }
                }
                
                // Аналогичный случай (см. выше)
                if (bufs.firstParsedYear && !isParsedYear) {    // + -
                    checker = [nf numberFromString:[_first_date substringWithRange:NSMakeRange(3, 2)]];
                    if(checker != nil) {
                        int yr = [[nf numberFromString:[_first_date substringWithRange:NSMakeRange(6, 4)]] intValue];
                        if ([checker intValue] > mm) {
                            yearSecond = 1 + yr;
                        } else {
                            yearSecond = yr;
                        }
                    }
                    
                    // Год в первом случае,
                    if (!isParsedDay) {
                        if (mm == 12) {
                            mm = 1;
                            yearSecond++;
                            daySecond = 1;
                        } else {
                            mm++;
                        }
                    }
                }
                
                if (!bufs.firstParsedYear && isParsedYear) {   // - +
                    checker = [nf numberFromString:[_first_date substringWithRange:NSMakeRange(3, 2)]];
                    if(checker != nil) {
                        if ([checker intValue] > mm) {
                            NSString* ending = [_first_date substringFromIndex:11];
                            [_first_date setString:[_first_date substringToIndex:6]];
                            [_first_date appendString:[NSString stringWithFormat:@"%d", yearSecond - 1]];
                            [_first_date appendString:@" "];
                            [_first_date appendString:ending];
                            KostylTrigger = YES;
                        }
                    }
                }
                
                if (!isParsedDay || daySecond < 10) {
                    dateTo = @"0".mutableCopy;
                }
                
                if (mm < 10) {
                    [dateTo appendString:[NSString stringWithFormat:@"%d", daySecond]];
                    [dateTo appendString:@"/0"];
                    [dateTo appendString:[NSString stringWithFormat:@"%d", (int)mm]];
                    [dateTo appendString:@"/"];
                    [dateTo appendString:[NSString stringWithFormat:@"%d", yearSecond]];
                } else {
                    [dateTo appendString:[NSString stringWithFormat:@"%d", daySecond]];
                    [dateTo appendString:@"/"];
                    [dateTo appendString:[NSString stringWithFormat:@"%d", (int)mm]];
                    [dateTo appendString:@"/"];
                    [dateTo appendString:[NSString stringWithFormat:@"%d", yearSecond]];
                }
            }
        }
        
        if (isSingleTermPeriod) {
            [_first_date appendString:dateFrom];
            [_first_date appendString:@" 00:00"];
            [_second_date appendString:dateTo];
            [_second_date appendString:@" 00:00"];
        } else {
            if (isFirst) {
                bufs.firstParsedYear = isParsedYear;
                [_first_date appendString:dateFrom];
                [_first_date appendString:@" 00:00"];
            } else {
                if (!bufs.firstParsedYear && isParsedYear) {   // - +
                    if (!KostylTrigger) {
                        if (![MM isEqualToString:@"12"]) {
                            [_first_date setString:[_first_date substringToIndex:6]];
                            [_first_date appendString:[dateTo substringFromIndex:6]];
                            [_first_date appendString:@" 00:00"];
                        } else {
                            if (IncludingTrigger) {
                                [_first_date setString:[_first_date substringToIndex:6]];
                                [_first_date appendString:[NSString stringWithFormat:@"%d", yearSecond]];
                                [_first_date appendString:@" 00:00"];
                            } else {
                                [_first_date setString:[_first_date substringToIndex:6]];
                                [_first_date appendString:[NSString stringWithFormat:@"%d", yearSecond - 1]];
                                [_first_date appendString:@" 00:00"];
                            }
                        }
                    }
                    
                    if (IncludingTrigger) {
                        
                        NSDateComponents *comps = [[NSDateComponents alloc] init];
                        [comps setYear:yearSecond];
                        [comps setMonth:mm];
                        [comps setDay: daySecond];
                        comps.month += 1;
                        NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"dd/MM/yyyy"];
                        [dateTo setString:[dateFormat stringFromDate:date]];
                        
                        [_second_date setString:[dateFormat stringFromDate:date]];
                        [_second_date appendString:@" 00:00"];
                    } else {
                        [_second_date appendString:dateTo];
                        [_second_date appendString:@" 00:00"];
                    }
                } else if (bufs.firstParsedYear && !isParsedYear) { // + -
                    [_second_date setString:[dateTo substringToIndex:6]];
                    [_second_date appendString:[NSString stringWithFormat:@"%d", yearSecond]];
                    [_second_date appendString:@" 00:00"];
                } else { // - -
                    NSDateComponents *comps = [[NSDateComponents alloc] init];
                    [comps setYear:yearSecond];
                    [comps setMonth:mm];
                    [comps setDay: daySecond];
                    
                    if (IncludingTrigger) {
                        NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
                        [dateFormat setDateFormat:@"dd/MM/yyyy"];
                        if (!isParsedDay) {
                            [comps setMonth:mm + 1];
                        }
                        // java это про календарь повыше
                        NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        
                        [_second_date setString:[dateFormat stringFromDate:date]];
                        [_second_date appendString:@" 00:00"];
                    } else {
                        if (isParsedDay) {
                            comps.day = -1;
                        }
                        NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:comps];
                        [_second_date setString:[dateFormat stringFromDate:date]];
                        [_second_date appendString:@" 00:00"];
                    }
                    
                }
                bufs.firstParsedYear = NO;
            }
        }
    }
}

-(BOOL) checkForYearWithItem:(NSString*)item {
    NSArray* identifiers;
    identifiers = [[NSArray alloc] initWithObjects:@"год", @"года", nil];
    for(NSString* unit in identifiers) {
        if([unit isEqualToString:item]) {
            return YES;
        }
    }
    return NO;
}

-(int) validDayWithMonth:(int)month
                    year:(int)year
                     num:(int)num {
    int res = [self getMonthsEndDateWithMonth:month year:year];
    return (num > res) ? res : num;
}

-(int) getMonthsEndDateWithMonth:(int)month
                            year:(int)year {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
        return 31;
    }
    if (month == 4 || month == 6 || month == 9 || month == 11) {
        return 30;
    }
    if (month == 2) {
        if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
            return 29;
        } else {
            return 28;
        }
    }
    return 0;
}

-(int) howManyDaysWithDay:(int)day
                  isFirst:(BOOL)isFirst {
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"EEE"];
    NSString* today = [dateFormat stringFromDate:[NSDate date]];
    int tod = 0;
    if([today isEqualToString:@"Mon"]){
        tod = 1;
    }
    if([today isEqualToString:@"Tue"]){
        tod = 2;
    }
    if([today isEqualToString:@"Wed"]){
        tod = 3;
    }
    if([today isEqualToString:@"Thu"]){
        tod = 4;
    }
    if([today isEqualToString:@"Fri"]){
        tod = 5;
    }
    if([today isEqualToString:@"Sat"]){
        tod = 6;
    }
    if([today isEqualToString:@"Sun"]){
        tod = 7;
    }
    if (tod == day) {
        if (isFirst) {
            return -7;
        } else {
            return 0;
        }
    }
    if (tod > day) {
        return -(tod - day);
    } else {
        return -7 + (day - tod);
    }
}

-(NSMutableString*) getDatePeriodWithWords:(NSMutableArray *)words
                                      bufs:(FTSBufsContainer *)bufs {
    int multipleTerms = 0;
    int firstIndex = 0;
    BOOL isSingleTermPeriod = NO;
    int k = -1;
    for (int i = 0; i < [words count]; i++) {
        
        id termValue = [self objectForNearlyKey:words[i] withDictionary:bufs.termIdentifier];
        if(termValue != nil) {
            k = [termValue intValue];
            if (k <= 12 || k >=18) {
                multipleTerms++;
                if (firstIndex == 0) {
                    firstIndex = i;
                }
            }
        } else {
            k = -1;
        }
    }
    
    // processor of non-period
    if (multipleTerms < 2) {
        isSingleTermPeriod = YES;
    }
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    
    
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm"];
    NSString* curtime = [dateFormat stringFromDate:[NSDate date]];
    [dateFormat setDateFormat:@"dd/MM/yyyy"];
    NSDateComponents* components = [NSDateComponents new];
    [components setDay:0];
    [components setMonth:0];
    [components setYear:0];
    
    for (int i = 0; i < [words count]; i++) {
        id termValue = [self objectForNearlyKey:words[i] withDictionary:bufs.termIdentifier];
        if(termValue != nil) {
            k = [termValue intValue];
        } else {
            k = -1;
        }
        if(k == -1){
            continue;
        }
        if(k < 13) {
            NSMutableString* monthStr = @"".mutableCopy;
            if(k < 10){
                [monthStr appendString:@"0"];
            }
            [monthStr appendString:[NSString stringWithFormat:@"%d", k]];
            [self monthProcWithI:i
                           words:words
                               k:k
                              MM:monthStr
                            bufs:bufs
              isSingleTermPeriod:isSingleTermPeriod
                         isFirst:firstIndex == i];
            continue;
        }
        
        switch (k) {
            case 13: { // сутки +
                [bufs cleanUpWordsWithIndex:i];
                
                if ([words[i] isEqualToString:@"сутки"]) { // Единственное
                    
                    components.day = -1;
                    NSString* dateyesterday = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                    NSString* datetoday = [dateFormat stringFromDate:[NSDate date]];
                    [_first_date appendString:dateyesterday];
                    [_first_date appendString:@" "];
                    [_first_date appendString:curtime];
                    
                    [_second_date appendString:datetoday];
                    [_second_date appendString:@" "];
                    [_second_date appendString:curtime];
                } else { // Множественное
                    if (i > 0) {
                        int num;
                        
                        if([nf numberFromString:words[i - 1]] != nil) {
                            num = [words[i - 1] intValue];
                            [bufs cleanUpWordsWithIndex:i - 1];
                        } else {
                            if ([words[i - 1] isEqualToString:@"двое"]) {
                                num = 2;
                            } else if ([words[i - 1] isEqualToString:@"трое"]) {
                                num = 3;
                            } else if ([words[i - 1] isEqualToString:@"четверо"]) {
                                num = 4;
                            } else if ([words[i - 1] isEqualToString:@"пятеро"]) {
                                num = 5;
                            } else if ([words[i - 1] isEqualToString:@"шестеро"]) {
                                num = 6;
                            } else if ([words[i - 1] isEqualToString:@"семеро"]) {
                                num = 7;
                            } else {
                                continue;
                            }
                            
                            components.day = -num;
                            NSString* timeFrom = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                            NSString* timeTo = [dateFormat stringFromDate:[NSDate date]];
                            components.day = 0;
                            [_first_date appendString:timeFrom];
                            [_first_date appendString:@" "];
                            [_first_date appendString:curtime];
                            
                            [_second_date appendString:timeTo];
                            [_second_date appendString:@" "];
                            [_second_date appendString:curtime];
                            [bufs cleanUpWordsWithIndex:i - 1];
                        }
                    }
                }
                break;
            }
            case 14: { // день +
                [bufs cleanUpWordsWithIndex:i];
                
                components.day = 1;
                NSString* todayTomorrow = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                if ([words[i] isEqualToString:@"день"]) { // единственное число
                    if ([@[@"предыдущий", @"прошлый", @"прошедший", @"последний"] containsObject:words[i - 1]]) {
                        
                        [_second_date setString:[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]]];
                        [_second_date appendString:@" 00:00"];
                        components.day = 0;
                        [_first_date setString:[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]]];
                        [_first_date appendString:@" 00:00"];
                        
                    } else { // Этот, текущий
                        [_first_date setString:[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]]];
                        [_first_date appendString:@" 00:00"];
                        
                        [_second_date appendString:todayTomorrow];
                        [_second_date appendString:@" 00:00"];
                    }
                } else { // Множественное число
                    if (i > 0) { // Надо взять число которое стоит перед ключевым словом
                        int num = 0;
                        if([nf numberFromString:words[i - 2]] != nil) {
                            num = [words[i - 2] intValue];
                        } else {
                            num = [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 2]];
                        }
                        if ([@[@"предыдущих", @"прошлых", @"прошедших", @"последних"] containsObject:words[i - 1]]) {
                            components.day = -num;
                            [bufs cleanUpWordsWithIndex:i - 2];
                            [_second_date appendString:todayTomorrow];
                            [_second_date appendString:@" 00:00"];
                        } else {
                            [bufs cleanUpWordsWithIndex:i - 1];
                            if([nf numberFromString:words[i - 1]] != nil) {
                                num = [words[i - 1] intValue];
                            } else {
                                num = 2;
                            }
                            components.day = -num;
                            [_second_date appendString:todayTomorrow];
                            [_second_date appendString:@" 00:00"];
                        }
                        [_first_date setString:[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]]];
                        [_first_date appendString:@" 00:00"];
                        components.day = 0;
                    }
                }
                break;
            }
            case 15: { // неделя +
                [bufs cleanUpWordsWithIndex:i];
                components.day = 1;
                NSString* timeTo = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                components.day = 0;
                if ([words[i] isEqualToString:@"неделю"]) { // Единственное
                    components.weekOfMonth = -1;
                    NSString* timeFrom = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                    [_first_date appendString:timeFrom];
                    [_first_date appendString:@" 00:00"];
                    
                    [_second_date appendString:timeTo];
                    [_second_date appendString:@" 00:00"];
                    components.weekOfMonth = 0;
                } else { // Множественное
                    if (i > 0) { // Надо взять число которое стоит перед ключевым словом
                        int num = 0;
                        if((i > 1 && ([nf numberFromString:words[i - 2]] != nil || [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 2]]))
                           || [nf numberFromString:words[i - 1]] != nil
                           || [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 1]]) {
                            if ([@[@"предыдущих", @"прошлых", @"прошедших", @"последних", @"прошедшие", @"последние", @"предыдущие", @"прошлые"] containsObject:words[i - 1]]) {
                                if(i > 1 && [nf numberFromString:words[i - 2]] != nil) {
                                    num = [words[i - 2] intValue];
                                } else {
                                    num = [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 2]];
                                }
                            } else {
                                if([nf numberFromString:words[i - 1]] != nil) {
                                    num = [words[i - 1] intValue];
                                } else {
                                    num = [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 1]];
                                }
                            }
                            
                            components.weekOfMonth = -num;
                            NSString* timeFrom = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                            [_first_date appendString:timeFrom];
                            [_first_date appendString:@" 00:00"];
                            
                            [_second_date appendString:timeTo];
                            [_second_date appendString:@" 00:00"];
                            [bufs cleanUpWordsWithIndex:i - 1];
                            components.weekOfMonth = 0;
                        } else {
                            continue;
                        }
                    }
                }
                break;
            }
            case 16: { // месяц ++
                [bufs cleanUpWordsWithIndex:i];
                if ([words[i] isEqualToString:@"месяц"]) { // Единственное
                    NSString* dateToday = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                    components.day = 1;
                    NSMutableString* tomorrow = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]].mutableCopy;
                    components.day = 0;
                    NSMutableString* dateFrom = @"".mutableCopy;
                    if (i > 0) {
                        int num;
                        if([nf numberFromString:words[i - 1]] != nil) {
                            num = [words[i - 1] intValue];
                            [words replaceObjectAtIndex:i withObject:@"месяца"];
                            i = i - 1;
                            [bufs cleanUpWordsWithIndex:i - 1];
                            continue;
                        } else {
                            [bufs cleanUpWordsWithIndex:i - 1];
                            if ([@[@"текущий", @"этот", @"прошедший", @"последний"] containsObject:words[i - 1]]) {
                                [dateFrom appendString:@"01/"];
                                [dateFrom appendString:[dateToday substringFromIndex:3]];
                            }
                            if ([@[@"за", @"на"] containsObject:words[i - 1]]) {
                                components.month = -1;
                                dateFrom = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]].mutableCopy;
                                components.month = 0;
                            }
                            if ([@[@"прошлый", @"предыдущий"] containsObject:words[i - 1]]) {
                                components.month = -1;
                                [dateFrom appendString:@"01/"];
                                [dateFrom appendString:[[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]] substringFromIndex:3]];
                                
                                tomorrow = @"01/".mutableCopy;
                                [tomorrow appendString:[dateToday substringFromIndex:3]];
                                components.month = 0;
                            }
                            if ([@[@"позапрошлый", @"предпоследний"] containsObject:words[i - 1]]) {
                                components.month = -2;
                                dateFrom = @"01/".mutableCopy;
                                tomorrow = @"01/".mutableCopy;
                                [dateFrom appendString:[[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]] substringFromIndex:3]];
                                components.month = -1;
                                [tomorrow appendString:[[dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]] substringFromIndex:3]];
                                components.month = 0;
                            }
                        }
                    }
                    
                    [_first_date appendString:dateFrom];
                    [_first_date appendString:@" 00:00"];
                    
                    [_second_date appendString:tomorrow];
                    [_second_date appendString:@" 00:00"];
                    
                } else { // Множественное
                    if (i > 0) { // Надо взять число которое стоит перед ключевым словом
                        int num = 0;
                        if((i > 1 && ([nf numberFromString:words[i - 2]] != nil || [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 2]]))
                           || [nf numberFromString:words[i - 1]] != nil
                           || [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 1]] > 0) {
                            if ([@[@"предыдущих", @"прошлых", @"прошедших", @"последних"] containsObject:words[i - 1]]) {
                                if([nf numberFromString:words[i - 2]] != nil) {
                                    num = [words[i - 2] intValue];
                                } else {
                                    num = [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 2]];
                                }
                            } else {
                                if([nf numberFromString:words[i - 1]] != nil) {
                                    num = [words[i - 1] intValue];
                                } else {
                                    num = [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 1]];
                                }
                            }
                            components.day = 1;
                            
                            NSString* timeTo = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                            components.day = 0;
                            components.month = -num;
                            
                            NSString* timeFrom = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]];
                            components.month = 0;
                            [bufs cleanUpWordsWithIndex:i - 1];
                            
                            [_first_date appendString:timeFrom];
                            [_first_date appendString:@" 00:00"];
                            
                            [_second_date appendString:timeTo];
                            [_second_date appendString:@" 00:00"];
                        } else {
                            break;
                        }
                    }
                }
                break;
            }
                
            case 17: { // лет ++
                [bufs cleanUpWordsWithIndex:i];
                
                NSMutableString* datetoday = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]].mutableCopy;
                components.day = 1;
                NSMutableString* tomorrow = [dateFormat stringFromDate:[[NSCalendar currentCalendar] dateByAddingComponents:components toDate:[NSDate date] options:0]].mutableCopy;
                components.day = 0;
                NSMutableString* dateFrom;
                NSDateComponents* todayComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
                
                if ([words[i] isEqualToString:@"год"]) { // Единственное
                    if (i > 0) {
                        int num;
                        if([nf numberFromString:words[i - 1]] != nil) {
                            num = [words[i - 1] intValue];
                            [bufs cleanUpWordsWithIndex:i - 1];
                            dateFrom = @"01/01/".mutableCopy;
                            [dateFrom appendString:words[i - 1]];
                            //dateFrom = "01/01/" + Integer.toString(num);
                            if (num < todayComps.year) {
                                datetoday = @"01/01/".mutableCopy;
                                [datetoday appendString:[NSString stringWithFormat:@"%d", num + 1]];
                            }
                        } else {
                            if ([@[@"текущий", @"этот"] containsObject:words[i - 1]]) {
                                [bufs cleanUpWordsWithIndex:i - 1];
                                dateFrom = @"01/01/".mutableCopy;
                                [dateFrom appendString:[datetoday substringFromIndex:6]];
                                datetoday = tomorrow;
                            }
                            if ([words[i - 1] isEqualToString:@"за"]) {
                                dateFrom = [datetoday substringToIndex:6].mutableCopy;
                                [dateFrom appendString:[NSString stringWithFormat:@"%ld", todayComps.year - 1]];
                                datetoday = tomorrow;
                            }
                            if ([@[@"прошедший", @"последний"] containsObject:words[i - 1]]) {
                                [bufs cleanUpWordsWithIndex:i - 1];
                                dateFrom = [datetoday substringToIndex:6].mutableCopy;
                                [dateFrom appendString:[NSString stringWithFormat:@"%ld", todayComps.year - 1]];
                                datetoday = tomorrow;
                            }
                            if ([@[@"предыдущий", @"прошлый"] containsObject:words[i - 1]]) {
                                [bufs cleanUpWordsWithIndex:i - 1];
                                dateFrom = @"01/01/".mutableCopy;
                                datetoday = @"01/01/".mutableCopy;
                                [dateFrom appendString:[NSString stringWithFormat:@"%ld", todayComps.year - 1]];
                                [datetoday appendString:[NSString stringWithFormat:@"%ld", todayComps.year]];
                            }
                            if ([words[i - 1] isEqualToString:@"позапрошлый"]) {
                                [bufs cleanUpWordsWithIndex:i - 1];
                                dateFrom = @"01/01/".mutableCopy;
                                datetoday = @"01/01/".mutableCopy;
                                [dateFrom appendString:[NSString stringWithFormat:@"%ld", todayComps.year - 2]];
                                [datetoday appendString:[NSString stringWithFormat:@"%ld", todayComps.year - 1]];
                            }
                        }
                    }
                    [_first_date appendString:dateFrom];
                    [_first_date appendString:@" 00:00"];
                    
                    [_second_date appendString:datetoday];
                    [_second_date appendString:@" 00:00"];
                    
                } else { // Множественное
                    if (i > 0) { // Надо взять число которое стоит перед ключевым словом
                        
                        int num;
                        if ([nf numberFromString:words[i - 1]] || [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 1]] > 0) {
                            if([nf numberFromString:words[i - 1]]) {
                                num = [words[i - 1] intValue];
                            } else {
                                num = [self tryParseIntFromStringNumberLessThanTenWithNumber:words[i - 1]];
                            }
                            dateFrom = [datetoday substringToIndex:6].mutableCopy;
                            [dateFrom appendString:[NSString stringWithFormat:@"%ld", todayComps.year - num]];
                            [bufs cleanUpWordsWithIndex:i - 1];
                            
                            [_first_date appendString:dateFrom];
                            [_first_date appendString:@" 00:00"];
                            
                            [_second_date appendString:tomorrow];
                            [_second_date appendString:@" 00:00"];
                            
                        } else {
                            
                            dateFrom = [datetoday substringToIndex:6].mutableCopy;
                            [dateFrom appendString:[NSString stringWithFormat:@"%ld", todayComps.year - 1]];
                            
                            [_first_date appendString:dateFrom];
                            [_first_date appendString:@" 00:00"];
                            
                            [_second_date appendString:tomorrow];
                            [_second_date appendString:@" 00:00"];
                            break;
                        }
                    }
                }
                break;
            }
            case 18: { // сегодня +
                [self specificDayprocWithI:i
                                     words:words
                                 dayNumber:0
                                      bufs:bufs
                        isSingleTermPeriod:isSingleTermPeriod
                                   isFirst:firstIndex == i];
                break;
            }
            case 19: { // вчера +
                [self specificDayprocWithI:i
                                     words:words
                                 dayNumber:-1
                                      bufs:bufs
                        isSingleTermPeriod:isSingleTermPeriod
                                   isFirst:firstIndex == i];
                break;
            }
            case 20: { // позавчера +
                [self specificDayprocWithI:i
                                     words:words
                                 dayNumber:-2
                                      bufs:bufs
                        isSingleTermPeriod:isSingleTermPeriod
                                   isFirst:firstIndex == i];
                break;
            }
            case 21: { // пн +
                [self weekDayprocWithI:i
                                 words:words
                             dayNumber:k - 20
                                  bufs:bufs
                    isSingleTermPeriod:isSingleTermPeriod
                               isFirst:firstIndex == i];
                break;
            }
            case 22: { // вт +
                [self weekDayprocWithI:i
                                 words:words
                             dayNumber:k - 20
                                  bufs:bufs
                    isSingleTermPeriod:isSingleTermPeriod
                               isFirst:firstIndex == i];
                break;
            }
            case 23: { // ср +
                [self weekDayprocWithI:i
                                 words:words
                             dayNumber:k - 20
                                  bufs:bufs
                    isSingleTermPeriod:isSingleTermPeriod
                               isFirst:firstIndex == i];
                break;
            }
            case 24: { // чт +
                [self weekDayprocWithI:i
                                 words:words
                             dayNumber:k - 20
                                  bufs:bufs
                    isSingleTermPeriod:isSingleTermPeriod
                               isFirst:firstIndex == i];
                break;
            }
            case 25: { // пт +
                [self weekDayprocWithI:i
                                 words:words
                             dayNumber:k - 20
                                  bufs:bufs
                    isSingleTermPeriod:isSingleTermPeriod
                               isFirst:firstIndex == i];
                break;
            }
            case 26: { // сб +
                [self weekDayprocWithI:i
                                 words:words
                             dayNumber:k - 20
                                  bufs:bufs
                    isSingleTermPeriod:isSingleTermPeriod
                               isFirst:firstIndex == i];
                break;
            }
            case 27: { // вс +
                [self weekDayprocWithI:i
                                 words:words
                             dayNumber:k - 20
                                  bufs:bufs
                    isSingleTermPeriod:isSingleTermPeriod
                               isFirst:firstIndex == i];
                break;
            }
            default:
                continue;
        }
    }
    NSMutableString* result = @"[".mutableCopy;
    [result appendString:_first_date];
    [result appendString:@" - "];
    [result appendString:_second_date];
    [result appendString:@"]; "];
    
    return result;
}

-(BOOL) partialEqualsWithTarget:(NSArray*)target
                            obj:(NSString*)obj {
    if([target containsObject:obj])
        return YES;
    return NO;
}

-(int) getNearestFloatIndexWithWords:(NSMutableArray *)words
                                   j:(int)j {
    NSScanner* sc;
    float ff;
    for(int i = j; i < [words count]; i++) {
        sc = [NSScanner scannerWithString:words[i]];
        if([sc scanFloat:&ff])
            return i;
    }
    return -1;
}

-(NSString*) getSumWithWords:(NSMutableArray *)words
                        bufs:(FTSBufsContainer *)bufs {
    
    float ff;
    
    NSArray *identifiers = [NSArray arrayWithObjects:@"руб", @"дол", @"коп", @"евр", @"цен", nil];
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    NSMutableString* buf = @"".mutableCopy;
    
    int ftobuf = 0;
    for (int i = 0; i < [words count]; i++) {
        for (NSString* item in identifiers) {
            if ([words[i] length] > 2 && [item isEqualToString:[words[i] substringToIndex:3]] && [bufs isTermCurrencyWithTerm:words[i]]) {
                if (i > 0) {
                    
                    double firstvalue;
                    
                    NSScanner* sc = [NSScanner scannerWithString:words[i - 1]];
                    if([sc scanFloat:&ff]) {
                        firstvalue = [words[i - 1] doubleValue];
                    } else {
                        if ([@[@"больше", @"более", @"от"] containsObject:words[i - 1]]) {
                            [buf appendString:@"[1 - inf]"];
                            [buf appendString:item];
                            [bufs cleanUpWordsWithFInd:i - 1 SecInd:i];
                            break;
                        } else if ([@[@"меньше", @"менее", @"до"] containsObject:words[i - 1]]) {
                            [buf appendString:@"[0 - 1]"];
                            [buf appendString:item];
                            [bufs cleanUpWordsWithFInd:i - 1 SecInd:i];
                            break;
                        } else {
                            if (i > 1) {
                                if ([words[i - 1] isEqualToString:@"одного"] && ([@[@"больше", @"более", @"от"] containsObject:words[i - 2]])) {
                                    [buf appendString:@"[1 - inf]"];
                                    [buf appendString:item];
                                    [bufs cleanUpWordsWithFInd:i - 2 SecInd:i];
                                    break;
                                } else if ([words[i - 1] isEqualToString:@"одного"] && [@[@"меньше", @"менее", @"до"] containsObject:words[i - 2]]) {
                                    [buf appendString:@"[0 - 1]"];
                                    [buf appendString:item];
                                    [bufs cleanUpWordsWithFInd:i - 2 SecInd:i];
                                    break;
                                } else if ([words[i - 1] isEqualToString:@"один"]) {
                                    [buf appendString:@"[1 - 1]"];
                                    [buf appendString:item]; // рубль
                                }
                            } else {
                                [buf appendString:@"[1 - 1]"];
                                [buf appendString:item]; // рубль
                            }
                        }
                        [bufs cleanUpWordsWithFInd:i - 1 SecInd:i];
                        break;
                    }
                    
                    // Если мы тут значит распарсили число перед "руб"
                    // Случай от 100 рублей до 300;
                    if (i + 1 < [words count] && [@[@"по", @"до"] containsObject:words[i + 1]]) {
                        NSScanner* sc = [NSScanner scannerWithString:words[i + 2]];
                        if([sc scanFloat:&ff]) {
                            int cleanind = ([words[i - 2] isEqualToString:@"от"] || [words[i - 1] isEqualToString:@"с"]) ? i - 2 : i - 1;
                            [bufs cleanUpWordsWithFInd:cleanind SecInd:i + 1];
                            [buf appendString:@"["];
                            [buf appendString:[NSString stringWithFormat:@"%f", [words[i + 2] doubleValue]]];
                            [buf appendString:@" - "];
                            [buf appendString:words[i + 2]];
                            [buf appendString:@"]"];
                            [buf appendString:item];
                            break;
                        }
                    }
                    
                    // Мы тут если удалось распарсить цифру перед валютой (условно 100 рублей)
                    // Необходимо посмотреть вглубь и найти случаи
                    if (i > 1) {
                        
                        // Индексы чисел рядом с ключевыми словами и ключевыми предлогами
                        int find = 0;
                        int sind = 0;
                        
                        // Флаг единственности найденых чисел (одно ключевое слово)
                        BOOL isFBottomline = NO;
                        
                        for (int j = i - 1; j >= 0; j--) {
                            if ([bufs isTermDateKeywordWithTerm:words[j]]) {
                                break;
                            }
                            
                            if ([@[@"больше", @"более", @"от", @"с", @"со", @"после"] containsObject:words[j]]) {
                                ftobuf = j;
                                if (sind > 0) {
                                    find = [self getNearestFloatIndexWithWords:words j:j];
                                } else {
                                    isFBottomline = YES;
                                    sind = [self getNearestFloatIndexWithWords:words j:j];
                                }
                            }
                            if ([@[@"меньше", @"менее", @"до", @"по"] containsObject:words[j]]) {
                                ftobuf = j;
                                if (sind > 0) {
                                    find = [self getNearestFloatIndexWithWords:words j:j];
                                } else {
                                    sind = [self getNearestFloatIndexWithWords:words j:j];
                                }
                            }
                        }
                        
                        int buff = find;
                        find = sind;
                        sind = buff;
                        
                        // ОКОЛО
                        if ([words[i - 2] isEqualToString:@"около"]) {
                            NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
                            [numFormatter setUsesGroupingSeparator:YES];
                            [numFormatter setDecimalSeparator:@","];
                            [numFormatter setMinimumSignificantDigits:0];
                            
                            double s = [words[i - 1] doubleValue];
                            [buf appendString:@"["];
                            [buf appendString:[numFormatter stringFromNumber:@(s - s / 10.0f)]];
                            [buf appendString:@" - "];
                            [buf appendString:[numFormatter stringFromNumber:@(s + s / 10.0f)]];
                            [buf appendString:@"]"];
                            [buf appendString:item];
                            [bufs cleanUpWordsWithFInd:i - 2 SecInd:i];
                            break;
                        }
                        
                        if (find > 0) {
                            if (sind == 0) {
                                // Только одно слово
                                if (isFBottomline) { // до бесконечности
                                    [buf appendString:@"["];
                                    [buf appendString:words[find]];
                                    [buf appendString:@" - inf]"];
                                    [buf appendString:item];
                                } else {
                                    [buf appendString:@"[0 - "];
                                    [buf appendString:words[find]];
                                    [buf appendString:@"]"];
                                    [buf appendString:item];
                                }
                                [bufs cleanUpWordsWithFInd:ftobuf SecInd:i];
                                break;
                            } else {
                                // промежуток
                                if (isFBottomline) {
                                    [buf appendString:@"["];
                                    [buf appendString:words[find]];
                                    [buf appendString:@" - "];
                                    [buf appendString:words[sind]];
                                    [buf appendString:@"]"];
                                    [buf appendString:item];
                                } else {
                                    [buf appendString:@"["];
                                    [buf appendString:words[sind]];
                                    [buf appendString:@" - "];
                                    [buf appendString:words[find]];
                                    [buf appendString:@"]"];
                                    [buf appendString:item];
                                }
                                [bufs cleanUpWordsWithFInd:ftobuf SecInd:i];
                                break;
                            }
                        }
                        
                    }
                    double val;
                    sc = [NSScanner scannerWithString:words[i - 2]];
                    if([sc scanFloat:&ff]) {
                        val = [words[i - 2] doubleValue];
                    } else {
                        val = 0;
                    }
                    [buf appendString:@"["];
                    [buf appendString:[NSString stringWithFormat:@"%f", val]];
                    [buf appendString:@" - "];
                    [buf appendString:[NSString stringWithFormat:@"%f", val]];
                    [buf appendString:@"]"];
                    [buf appendString:item];
                    [bufs cleanUpWordsWithFInd:i - 1 SecInd:i];
                }
            }
        }
    }
    return [buf stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(NSString*) testprint {
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@",
            @"vals + currency: [", [[NSNumber numberWithFloat:_first_value] stringValue], @" - ", [[NSNumber numberWithFloat:_second_value] stringValue], @"] ",
            _currency, @" period: [", _first_date, @" - ", _second_date, @"]"];
}

-(int) tryParseIntFromStringNumberLessThanTenWithNumber:(NSString*)inputNumber {
    if([@[@"один", @"одну", @"одного", @"одной"] containsObject:inputNumber]) {
        return 1;
    }
    if([@[@"два", @"две", @"двух"] containsObject:inputNumber]) {
        return 2;
    }
    if([@[@"три", @"трех"] containsObject:inputNumber]) {
        return 3;
    }
    if([@[@"четыре", @"четырех"] containsObject:inputNumber]) {
        return 4;
    }
    if([@[@"пять", @"пяти"] containsObject:inputNumber]) {
        return 5;
    }
    if([@[@"шесть", @"шести"] containsObject:inputNumber]) {
        return 6;
    }
    if([@[@"семь", @"семи"] containsObject:inputNumber]) {
        return 7;
    }
    if([@[@"восемь", @"восьми"] containsObject:inputNumber]) {
        return 8;
    }
    if([@[@"девять", @"девяти"] containsObject:inputNumber]) {
        return 9;
    }
    return 0;
}

- (id)objectForNearlyKey:(NSString *)string withDictionary:(NSDictionary *)dic
{
    __block id retObj;
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (string.length > 2 && [key hasPrefix:string]) {
            retObj = obj;
        }
        *stop = retObj != nil;
    }];
    return retObj;
}

@end
