//
//  FTSPorter.h
//  FTSPorter
//
//  Created by Anton on 10/30/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTSPorter : NSObject

@property (strong, nonatomic) NSRegularExpression * PERFECTIVEGROUND;
@property (strong, nonatomic) NSRegularExpression * REFLEXIVE;
@property (strong, nonatomic) NSRegularExpression * ADJECTIVE;
@property (strong, nonatomic) NSRegularExpression * PARTICIPLE;
@property (strong, nonatomic) NSRegularExpression * VERB;
@property (strong, nonatomic) NSRegularExpression * NOUN;
@property (strong, nonatomic) NSRegularExpression * RVRE;
@property (strong, nonatomic) NSRegularExpression * DERIVATIONAL;
@property (strong, nonatomic) NSRegularExpression * DER;
@property (strong, nonatomic) NSRegularExpression * SUPERLATIVE;
@property (strong, nonatomic) NSRegularExpression * I;
@property (strong, nonatomic) NSRegularExpression * P;
@property (strong, nonatomic) NSRegularExpression * NN;
@property (strong, nonatomic) NSSet * pr;

-(instancetype) initStemmer;

+(instancetype) sharedStemmer;

-(NSString *) stemWordWithString:(NSString *)word;

-(NSString *) stemSentenceWitrhString:(NSString *)sentence;

-(NSString *) replaceFirstMatchWithRegexp:(NSRegularExpression *)reg
                                 inString:(NSString *)inStr
                               withString:(NSString *)repStr;

@end
