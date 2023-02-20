//
//  KCYerushalmiYomiCalculator.m
//  KosherCocoa
//
//  Created by Elyahu on 2/14/23.
//

#import "KCYerushalmiYomiCalculator.h"

@interface KCYerushalmiYomiCalculator ()

//Calculate the Julian Day
- (NSInteger) julianDayForDate:(NSDate *)date;

//Convenience method for making a gregorian date
- (NSDate *)gregorianDateForYear:(NSInteger)year month:(NSInteger)month andDay:(NSInteger)day;

@end

@implementation KCYerushalmiYomiCalculator

#define kNumberOfMasechtos 40

- (id) initWithDate:(NSDate *)date
{
    
    self = [super init];
    
    if (self)
    {
        self.workingDate = date;
    }
    
    return self;
}

- (KCDaf *)dafYomiYerushalmi:(NSDate *)date calendar:(KCJewishCalendar *)calendar
{
    NSDate *dafYomiStartDay = [self gregorianDateForYear:1980 month:2 andDay:2];
    const int WHOLE_SHAS_DAFS = 1554;
    const int BLATT_PER_MASSECTA[] = {
    68, 37, 34, 44, 31, 59, 26, 33, 28, 20, 13, 92, 65, 71, 22, 22, 42, 26, 26, 33, 34, 22,
    19, 85, 72, 47, 40, 47, 54, 48, 44, 37, 34, 44, 9, 57, 37, 19, 13
    };
    int length = sizeof(BLATT_PER_MASSECTA) / sizeof(BLATT_PER_MASSECTA[0]);
    
    NSCalendar *dateCreator = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *nextCycle = [[NSDateComponents alloc] init];
    NSCalendar *c = [NSCalendar currentCalendar];
    NSDateComponents *prevCycle = [c components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[NSDate date]];

    int masechta = 0;
    KCDaf *dafYomi = nil;

    // There isn't Daf Yomi on Yom Kippur or Tisha B'Av.
    if ([calendar yomTovIndex] == kYomKippur || [calendar yomTovIndex] == kTishaBeav) {
        return nil;
    }

    if ([date compare:dafYomiStartDay] == NSOrderedAscending) {
        return nil;
    }
    
    [nextCycle setYear:1980];
    [nextCycle setMonth:2];
    [nextCycle setDay:2];

    // Go cycle by cycle, until we get the next cycle
    while ([date compare: [dateCreator dateFromComponents:nextCycle]] == NSOrderedDescending) {
        prevCycle = nextCycle.copy;
                
        [nextCycle setDay:WHOLE_SHAS_DAFS + [nextCycle day]];
        [nextCycle setDay:[self getNumOfSpecialDays:[dateCreator dateFromComponents: prevCycle] endDate:[dateCreator dateFromComponents: nextCycle]] + [nextCycle day]];
    }

    // Get the number of days from cycle start until request.
    NSInteger dafNo = [self getDiffBetweenDays:[dateCreator dateFromComponents: prevCycle] endDate:date];

    // Get the number of special day to subtract
    int specialDays = [self getNumOfSpecialDays:[dateCreator dateFromComponents: prevCycle] endDate:date];
    NSInteger total = dafNo - specialDays;

    // Finally find the daf.
    for (int j = 0; j < length; j++) {
        if (total <= BLATT_PER_MASSECTA[j]) {
            dafYomi = [[KCDaf alloc] initWithTractateIndex:masechta andPageNumber:total + 1];
            break;
        }
        total -= BLATT_PER_MASSECTA[j];
        masechta++;
    }

    return dafYomi;
}

- (int)getNumOfSpecialDays:(NSDate *)startDate endDate:(NSDate *)endDate {
    KCJewishCalendar *startCalendar = [[KCJewishCalendar alloc] init];
    startCalendar.workingDate = startDate;
    KCJewishCalendar *endCalendar = [[KCJewishCalendar alloc] init];
    endCalendar.workingDate = endDate;
    
    NSInteger startYear = startCalendar.currentHebrewYear;
    NSInteger endYear = endCalendar.currentHebrewYear;

    int specialDays = 0;
    
    NSCalendar *dateCreator = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierHebrew];

    //create a hebrew calendar set to the date 7/10/5770
    NSDateComponents *yomKippurComponents = [[NSDateComponents alloc] init];
    yomKippurComponents.year = 5770;
    yomKippurComponents.month = 7;
    yomKippurComponents.day = 10;
    
    NSDateComponents *tishaBeavComponents = [[NSDateComponents alloc] init];
    tishaBeavComponents.year = 5770;
    tishaBeavComponents.month = 5;
    tishaBeavComponents.day = 9;
    
    for (NSInteger i = startYear; i <= endYear; i++) {
        yomKippurComponents.year = i;
        tishaBeavComponents.year = i;
        
        if ([self isBetween:startDate date:[dateCreator dateFromComponents:yomKippurComponents] endDate:endDate]) {
            specialDays++;
        }
        
        if ([self isBetween:startDate date:[dateCreator dateFromComponents:tishaBeavComponents] endDate:endDate]) {
            specialDays++;
        }
    }

    return specialDays;
}

- (BOOL)isBetween:(NSDate *)start date:(NSDate *)date endDate:(NSDate *)end {
    return ([start compare:date] == NSOrderedAscending) && ([end compare:date] == NSOrderedDescending);
}

- (NSInteger)getDiffBetweenDays:(NSDate *)start endDate:(NSDate *)end {
    const NSInteger DAY_MILIS = 24 * 60 * 60;
    NSInteger s = (end.timeIntervalSince1970 - start.timeIntervalSince1970);
    return s / DAY_MILIS;
}

#pragma mark - Date convenience methods

- (NSInteger) julianDayForDate:(NSDate *)date
{
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSInteger year = [[gregorianCalendar components:NSCalendarUnitYear fromDate:date] year];
    NSInteger month = [[gregorianCalendar components:NSCalendarUnitMonth fromDate:date] month];
    NSInteger day = [[gregorianCalendar components:NSCalendarUnitDay fromDate:date] day];
    
    
    if (month <= 2)
    {
        year -= 1;
        month += 12;
    }
    
    NSInteger a = year / 100;
    NSInteger b = 2 - a + a / 4;
    
    return (NSInteger) (floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + day + b - 1524.5);
}

- (NSDate *)gregorianDateForYear:(NSInteger)year month:(NSInteger)month andDay:(NSInteger)day
{
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:year];
    [dateComponents setMonth:month];
    [dateComponents setDay:day];
    
    NSDate *returnDate = [gregorianCalendar dateFromComponents:dateComponents];
    
    return returnDate;
}

@end

