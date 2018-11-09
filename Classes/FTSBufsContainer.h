//
//  BufsContainer.h
//  parserText
//
//  Created by user on 17.10.2018.
//  Copyright © 2018 user. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTSBufsContainer : NSObject

@property (nonatomic, strong) NSMutableString* buff;
@property (nonatomic, strong) NSMutableString* buft;
@property (nonatomic, assign) BOOL ignoreYear;
@property (nonatomic, assign) BOOL firstParsedYear;
@property (nonatomic, strong) NSMutableDictionary* termIdentifier;
@property (nonatomic, strong) NSMutableArray* perIndexes;
@property (nonatomic, strong) NSMutableArray* currencyTrigger;
@property (nonatomic, strong) NSMutableArray* datePartTrigger;

-(instancetype)  initBufsContainerWithBuff:(NSString*)buff
                                      buft:(NSString*)buft
                                ignoreYear:(BOOL)ignoreYear;

-(BOOL) isTermCurrencyWithTerm:(NSString*)term;

-(BOOL) isTermDateKeywordWithTerm:(NSString*)term;

-(void) cleanUpWordsWithFInd:(int)find
                      SecInd:(int)secind;

-(void) cleanUpWordsWithIndex:(int)index;

-(void) clear;

@end
