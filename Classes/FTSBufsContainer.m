//
//  BufsContainer.m
//  parserText
//
//  Created by user on 17.10.2018.
//  Copyright © 2018 user. All rights reserved.
//

#import "FTSBufsContainer.h"

@implementation FTSBufsContainer

//Consctuctor
-(instancetype) initBufsContainerWithIgnoreYear:(BOOL)ignoreYear {
    if(self = [super init]) {
        self.ignoreYear = ignoreYear;
        
        self.firstParsedYear = NO;
        self.perIndexes = @[].mutableCopy;

        // termIdent fill
        self.termIdentifier = [[NSMutableDictionary alloc] init];
        [self.termIdentifier setObject:@1 forKey:@"январь"];
        [self.termIdentifier setObject:@1 forKey:@"января"];
        [self.termIdentifier setObject:@1 forKey:@"январе"];
        [self.termIdentifier setObject:@2 forKey:@"февраль"];
        [self.termIdentifier setObject:@2 forKey:@"февраля"];
        [self.termIdentifier setObject:@2 forKey:@"феврале"];
        [self.termIdentifier setObject:@3 forKey:@"март"];
        [self.termIdentifier setObject:@3 forKey:@"марта"];
        [self.termIdentifier setObject:@3 forKey:@"марте"];
        [self.termIdentifier setObject:@4 forKey:@"апрель"];
        [self.termIdentifier setObject:@4 forKey:@"апреля"];
        [self.termIdentifier setObject:@4 forKey:@"апреле"];
        [self.termIdentifier setObject:@5 forKey:@"май"];
        [self.termIdentifier setObject:@5 forKey:@"мая"];
        [self.termIdentifier setObject:@5 forKey:@"мае"];
        [self.termIdentifier setObject:@6 forKey:@"июнь"];
        [self.termIdentifier setObject:@6 forKey:@"июня"];
        [self.termIdentifier setObject:@6 forKey:@"июне"];
        [self.termIdentifier setObject:@7 forKey:@"июль"];
        [self.termIdentifier setObject:@7 forKey:@"июля"];
        [self.termIdentifier setObject:@7 forKey:@"июле"];
        [self.termIdentifier setObject:@8 forKey:@"август"];
        [self.termIdentifier setObject:@8 forKey:@"августа"];
        [self.termIdentifier setObject:@8 forKey:@"августе"];
        [self.termIdentifier setObject:@9 forKey:@"сентябрь"];
        [self.termIdentifier setObject:@9 forKey:@"сентября"];
        [self.termIdentifier setObject:@9 forKey:@"сентябре"];
        [self.termIdentifier setObject:@10 forKey:@"октябрь"];
        [self.termIdentifier setObject:@10 forKey:@"октября"];
        [self.termIdentifier setObject:@10 forKey:@"октябре"];
        [self.termIdentifier setObject:@11 forKey:@"ноябрь"];
        [self.termIdentifier setObject:@11 forKey:@"ноября"];
        [self.termIdentifier setObject:@11 forKey:@"ноябре"];
        [self.termIdentifier setObject:@12 forKey:@"декабрь"];
        [self.termIdentifier setObject:@12 forKey:@"декабря"];
        [self.termIdentifier setObject:@12 forKey:@"декабре"];
        [self.termIdentifier setObject:@13 forKey:@"сутки"];
        [self.termIdentifier setObject:@13 forKey:@"суток"];
        [self.termIdentifier setObject:@14 forKey:@"день"];
        [self.termIdentifier setObject:@14 forKey:@"дня"];
        [self.termIdentifier setObject:@14 forKey:@"дней"];
        [self.termIdentifier setObject:@15 forKey:@"неделя"];
        [self.termIdentifier setObject:@15 forKey:@"неделю"];
        [self.termIdentifier setObject:@15 forKey:@"недель"];
        [self.termIdentifier setObject:@15 forKey:@"недели"];
        [self.termIdentifier setObject:@16 forKey:@"месяц"];
        [self.termIdentifier setObject:@16 forKey:@"месяца"];
        [self.termIdentifier setObject:@16 forKey:@"месяцев"];
        [self.termIdentifier setObject:@17 forKey:@"год"];
        [self.termIdentifier setObject:@17 forKey:@"года"];
        [self.termIdentifier setObject:@17 forKey:@"лет"];
        [self.termIdentifier setObject:@18 forKey:@"сегодня"];
        [self.termIdentifier setObject:@18 forKey:@"сегодняшний"];
        [self.termIdentifier setObject:@18 forKey:@"сегодняшнее"];
        [self.termIdentifier setObject:@19 forKey:@"вчера"];
        [self.termIdentifier setObject:@19 forKey:@"вчерашний"];
        [self.termIdentifier setObject:@19 forKey:@"вчерашнее"];
        [self.termIdentifier setObject:@20 forKey:@"позавчера"];
        [self.termIdentifier setObject:@20 forKey:@"позавчерашний"];
        [self.termIdentifier setObject:@21 forKey:@"понедельник"];
        [self.termIdentifier setObject:@21 forKey:@"понедельника"];
        [self.termIdentifier setObject:@22 forKey:@"вторник"];
        [self.termIdentifier setObject:@22 forKey:@"вторника"];
        [self.termIdentifier setObject:@23 forKey:@"среда"];
        [self.termIdentifier setObject:@23 forKey:@"среды"];
        [self.termIdentifier setObject:@23 forKey:@"среду"];
        [self.termIdentifier setObject:@24 forKey:@"четверг"];
        [self.termIdentifier setObject:@24 forKey:@"четверга"];
        [self.termIdentifier setObject:@25 forKey:@"пятница"];
        [self.termIdentifier setObject:@25 forKey:@"пятницы"];
        [self.termIdentifier setObject:@25 forKey:@"пятницу"];
        [self.termIdentifier setObject:@26 forKey:@"суббота"];
        [self.termIdentifier setObject:@26 forKey:@"субботы"];
        [self.termIdentifier setObject:@26 forKey:@"субботу"];
        [self.termIdentifier setObject:@27 forKey:@"воскресенье"];
        [self.termIdentifier setObject:@27 forKey:@"воскресенья"];
        
        // currencyTrigger fill
        self.currencyTrigger = @[].mutableCopy;
        [self.currencyTrigger addObject:@"рублей"];
        [self.currencyTrigger addObject:@"рубля"];
        [self.currencyTrigger addObject:@"рубль"];
        [self.currencyTrigger addObject:@"руб."];
        [self.currencyTrigger addObject:@"руб"];
        [self.currencyTrigger addObject:@"копейка"];
        [self.currencyTrigger addObject:@"копейки"];
        [self.currencyTrigger addObject:@"копеек"];
        [self.currencyTrigger addObject:@"коп."];
        [self.currencyTrigger addObject:@"коп"];
        [self.currencyTrigger addObject:@"доллар"];
        [self.currencyTrigger addObject:@"доллара"];
        [self.currencyTrigger addObject:@"долларов"];
        [self.currencyTrigger addObject:@"дол."];
        [self.currencyTrigger addObject:@"дол"];
        [self.currencyTrigger addObject:@"евро"];
        [self.currencyTrigger addObject:@"евр."];
        [self.currencyTrigger addObject:@"евр"];
        [self.currencyTrigger addObject:@"цент"];
        [self.currencyTrigger addObject:@"цента"];
        [self.currencyTrigger addObject:@"центов"];
        [self.currencyTrigger addObject:@"цен."];
        [self.currencyTrigger addObject:@"цен"];
        
        // datePartTrigger fill
        self.datePartTrigger = @[].mutableCopy;
        [self.datePartTrigger addObject:@"январь"];
        [self.datePartTrigger addObject:@"января"];
        [self.datePartTrigger addObject:@"январе"];
        [self.datePartTrigger addObject:@"февраль"];
        [self.datePartTrigger addObject:@"февраля"];
        [self.datePartTrigger addObject:@"фервале"];
        [self.datePartTrigger addObject:@"март"];
        [self.datePartTrigger addObject:@"марта"];
        [self.datePartTrigger addObject:@"марте"];
        [self.datePartTrigger addObject:@"апрель"];
        [self.datePartTrigger addObject:@"апреля"];
        [self.datePartTrigger addObject:@"апреле"];
        [self.datePartTrigger addObject:@"май"];
        [self.datePartTrigger addObject:@"мая"];
        [self.datePartTrigger addObject:@"мае"];
        [self.datePartTrigger addObject:@"июнь"];
        [self.datePartTrigger addObject:@"июня"];
        [self.datePartTrigger addObject:@"июне"];
        [self.datePartTrigger addObject:@"июль"];
        [self.datePartTrigger addObject:@"июля"];
        [self.datePartTrigger addObject:@"июле"];
        [self.datePartTrigger addObject:@"август"];
        [self.datePartTrigger addObject:@"августа"];
        [self.datePartTrigger addObject:@"августе"];
        [self.datePartTrigger addObject:@"сентябрь"];
        [self.datePartTrigger addObject:@"сентября"];
        [self.datePartTrigger addObject:@"сентябре"];
        [self.datePartTrigger addObject:@"октябрь"];
        [self.datePartTrigger addObject:@"октября"];
        [self.datePartTrigger addObject:@"октябре"];
        [self.datePartTrigger addObject:@"ноябрь"];
        [self.datePartTrigger addObject:@"ноября"];
        [self.datePartTrigger addObject:@"ноябре"];
        [self.datePartTrigger addObject:@"декабрь"];
        [self.datePartTrigger addObject:@"декабря"];
        [self.datePartTrigger addObject:@"декабре"];
        [self.datePartTrigger addObject:@"сутки"];
        [self.datePartTrigger addObject:@"суток"];
        [self.datePartTrigger addObject:@"день"];
        [self.datePartTrigger addObject:@"дня"];
        [self.datePartTrigger addObject:@"дней"];
        [self.datePartTrigger addObject:@"неделя"];
        [self.datePartTrigger addObject:@"неделю"];
        [self.datePartTrigger addObject:@"недель"];
        [self.datePartTrigger addObject:@"месяц"];
        [self.datePartTrigger addObject:@"месяца"];
        [self.datePartTrigger addObject:@"месяцев"];
        [self.datePartTrigger addObject:@"год"];
        [self.datePartTrigger addObject:@"года"];
        [self.datePartTrigger addObject:@"лет"];
        [self.datePartTrigger addObject:@"сегодня"];
        [self.datePartTrigger addObject:@"сегодняшний"];
        [self.datePartTrigger addObject:@"сегодняшнее"];
        [self.datePartTrigger addObject:@"вчера"];
        [self.datePartTrigger addObject:@"вчерашний"];
        [self.datePartTrigger addObject:@"вчерашнее"];
        [self.datePartTrigger addObject:@"позавчера"];
        [self.datePartTrigger addObject:@"позавчерашний"];
        [self.datePartTrigger addObject:@"понедельник"];
        [self.datePartTrigger addObject:@"понедельника"];
        [self.datePartTrigger addObject:@"вторник"];
        [self.datePartTrigger addObject:@"вторника"];
        [self.datePartTrigger addObject:@"среда"];
        [self.datePartTrigger addObject:@"среды"];
        [self.datePartTrigger addObject:@"среду"];
        [self.datePartTrigger addObject:@"четверг"];
        [self.datePartTrigger addObject:@"четверга"];
        [self.datePartTrigger addObject:@"пятница"];
        [self.datePartTrigger addObject:@"пятницы"];
        [self.datePartTrigger addObject:@"пятницу"];
        [self.datePartTrigger addObject:@"суббота"];
        [self.datePartTrigger addObject:@"субботы"];
        [self.datePartTrigger addObject:@"субботу"];
        [self.datePartTrigger addObject:@"воскресенье"];
        [self.datePartTrigger addObject:@"воскресенья"];
    }
    return self;
}

-(BOOL) isTermCurrencyWithTerm:(NSString *)term {
    return [self.currencyTrigger containsObject:term];
}

-(BOOL) isTermDateKeywordWithTerm:(NSString *)term {
    return [self.datePartTrigger containsObject:term];
}

-(void) cleanUpWordsWithIndex:(int)index {
    [self.perIndexes addObject:[NSNumber numberWithInt:index]];
}

-(void) cleanUpWordsWithFInd:(int)find
                      SecInd:(int)secind {
    for(int i = find; i <= secind; i++){
        [self.perIndexes addObject:[NSNumber numberWithInt:i]];
    }
}

-(void) clear {
    self.ignoreYear = NO;
    self.firstParsedYear = NO;
}

@end

