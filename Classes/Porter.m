//
//  Porter.m
//  Porter
//
//  Created by Anton on 10/30/18.
//  Copyright © 2018 Anton. All rights reserved.
//

#import "Porter.h"

@implementation Porter

+(instancetype) sharedStemmer {
    static Porter * stemmer = nil;
    if (stemmer == nil) {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            stemmer = [[Porter alloc] initStemmer];
        });
    }
    return stemmer;
}

-(instancetype) initStemmer {
    if (self = [super init]) {
        NSError * error;
        self.PERFECTIVEGROUND = [NSRegularExpression regularExpressionWithPattern:@"((ив|ивши|ившись|ыв|ывши|ывшись)|((?<=[ая])(в|вши|вшись)))$"
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:&error];
        self.REFLEXIVE = [NSRegularExpression regularExpressionWithPattern:@"(с[яь])$"
                                                                   options:NSRegularExpressionCaseInsensitive
                                                                     error:&error];
        self.ADJECTIVE = [NSRegularExpression regularExpressionWithPattern:@"(ее|ие|ые|ое|ими|ыми|ей|ий|ый|ой|ем|им|ым|ом|его|ого|ему|ому|их|ых|ую|юю|ая|яя|ою|ею)$"
                                                                   options:NSRegularExpressionCaseInsensitive
                                                                     error:&error];
        self.PARTICIPLE = [NSRegularExpression regularExpressionWithPattern:@"((ивш|ывш|ующ)|((?<=[ая])(ем|нн|вш|ющ|щ)))$"
                                                                    options:NSRegularExpressionCaseInsensitive
                                                                      error:&error];
        self.VERB = [NSRegularExpression regularExpressionWithPattern:@"((ила|ыла|ена|ейте|уйте|ите|или|ыли|ей|уй|ил|ыл|им|ым|ен|ило|ыло|ено|ят|ует|уют|ит|ыт|ены|ить|ыть|ишь|ую|ю)|((?<=[ая])(ла|на|ете|йте|ли|й|л|ем|н|ло|но|ет|ют|ны|ть|ешь|нно)))$"
                                                              options:NSRegularExpressionCaseInsensitive
                                                                error:&error];
        self.NOUN = [NSRegularExpression regularExpressionWithPattern:@"(а|ев|ов|ие|ье|е|иями|ями|ами|еи|ии|и|ией|ей|ой|ий|й|иям|ям|ием|ем|ам|ом|о|у|ах|иях|ях|ы|ь|ию|ью|ю|ия|ья|я)$"
                                                              options:NSRegularExpressionCaseInsensitive
                                                                error:&error];
        self.RVRE = [NSRegularExpression regularExpressionWithPattern:@"^(.*?[аеиоуыэюя])(.*)$"
                                                              options:NSRegularExpressionCaseInsensitive
                                                                error:&error];
        self.DERIVATIONAL = [NSRegularExpression regularExpressionWithPattern:@"*[^аеиоуыэюя]+[аеиоуыэюя].*ость?$"
                                                                      options:NSRegularExpressionCaseInsensitive
                                                                        error:&error];
        self.DER = [NSRegularExpression regularExpressionWithPattern:@"ость?$"
                                                             options:NSRegularExpressionCaseInsensitive
                                                               error:&error];
        self.SUPERLATIVE = [NSRegularExpression regularExpressionWithPattern:@"(ейше|ейш)$"
                                                                     options:NSRegularExpressionCaseInsensitive
                                                                       error:&error];
        self.I = [NSRegularExpression regularExpressionWithPattern:@"и$"
                                                           options:NSRegularExpressionCaseInsensitive
                                                             error:&error];
        self.P = [NSRegularExpression regularExpressionWithPattern:@"ь$"
                                                           options:NSRegularExpressionCaseInsensitive
                                                             error:&error];
        self.NN = [NSRegularExpression regularExpressionWithPattern:@"нн$"
                                                            options:NSRegularExpressionCaseInsensitive
                                                              error:&error];
        self.pr = [NSSet setWithArray:@[@"без",@"в",@"до",@"для",@"за",@"из",@"к",@"на",@"над",@"о",@"об",@"от",@"по",@"под",@"с",@"у",@"через",@"и",@"у",@"до",@"но",@"перед",@"то",@"ни",@"да"]];
        
    }
    return self;
}

- (NSString *) stemWordWithString:(NSString *)word {
    
    word = [word stringByReplacingOccurrencesOfString:@"ё" withString:@"е"];
    NSArray * matches = [self.RVRE matchesInString:word
                                           options:0
                                             range:NSMakeRange(0, [word length])];
    
    if ([matches count] > 0) {
        NSRange matchR = [matches[0] rangeAtIndex:1];
        NSString * pre = [word substringWithRange:matchR];
        matchR = [matches[0] rangeAtIndex:2];
        NSString * rv = [word substringWithRange:matchR];
        
        NSString * temp = [self replaceFirstMatchWithRegexp:self.PERFECTIVEGROUND
                                                   inString:rv
                           withString:@""];
        
        if ([temp isEqualToString:rv]) {
            rv = [self replaceFirstMatchWithRegexp:self.REFLEXIVE
                                          inString:rv
                                        withString:@""];
            temp = [self replaceFirstMatchWithRegexp:self.ADJECTIVE
                                            inString:rv
                                          withString:@""];
            
            if(![temp isEqualToString:rv]) {
                rv = temp;
                rv = [self replaceFirstMatchWithRegexp:self.PARTICIPLE
                                              inString:rv
                                            withString:@""];
            } else {
                temp = [self replaceFirstMatchWithRegexp:self.VERB
                                                inString:rv
                                              withString:@""];
                if([temp isEqualToString:rv]) {
                    rv = [self replaceFirstMatchWithRegexp:self.NOUN
                                                  inString:rv
                                                withString:@""];
                } else {
                    rv = temp;
                }
            }
        }else {
            rv = temp;
        }
        
        rv = [self replaceFirstMatchWithRegexp:self.I
                                      inString:rv
                                    withString:@""];
        
        matches = [self.DERIVATIONAL matchesInString:rv
                                             options:0
                                               range:NSMakeRange(0, [rv length])];
        
        if ([matches count] > 0) {
            rv = [self replaceFirstMatchWithRegexp:self.DER
                                          inString:rv
                                        withString:@""];
        }
        
        temp = [self replaceFirstMatchWithRegexp:self.P
                                        inString:rv
                                      withString:@""];
        if ([temp isEqualToString:rv]) {
        rv = [self replaceFirstMatchWithRegexp:self.SUPERLATIVE
                                      inString:rv
                                    withString:@""];
            rv = [self replaceFirstMatchWithRegexp:self.NN
                                          inString:rv
                                        withString:@"н"];
        } else {
            rv = temp;
        }
        word = [pre stringByAppendingString:rv];
    }
    return word;
}

- (NSString *) stemSentenceWitrhString:(NSString *)sentence {
    NSString *res = @"";
    NSArray * wordArr = [sentence componentsSeparatedByString:@" "];
    
    for (NSString * str in wordArr) {
        res = [res stringByAppendingString:[self stemWordWithString:str]];
        if (str != [wordArr objectAtIndex:[wordArr count]-1]){
            res = [res stringByAppendingString:@" "];
        }
    }
    
    return res;
}

-(NSString *) replaceFirstMatchWithRegexp:(NSRegularExpression *)reg
                                 inString:(NSString *)inStr
withString:(NSString *)repStr
{
    NSString * res = @"";
    NSRange r = [reg rangeOfFirstMatchInString:inStr
                                       options:0
                                         range:NSMakeRange(0, [inStr length])];
    if (r.length > 0) {
        res = [inStr stringByReplacingCharactersInRange:r
                                             withString:repStr];
        return res;
    } else {
        return inStr;
    }
    
    return res;
}

@end
