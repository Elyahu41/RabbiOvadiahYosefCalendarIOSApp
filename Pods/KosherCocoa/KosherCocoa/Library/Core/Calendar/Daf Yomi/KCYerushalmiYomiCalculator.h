//
//  KCYerushalmiYomiCalculator.h
//  KosherCocoa
//
//  Created by Elyahu on 2/14/23.
//

@import Foundation;
#import "KCDaf.h"
#import "KCJewishCalendar.h"

/**
 This class calculates the current Daf Yomi being studied.
 */
NS_SWIFT_NAME(YerushalmiYomiCalculator)
@interface KCYerushalmiYomiCalculator : NSObject

// MARK: - Properties
/**
 *  The reference date used by the calculator.
 */

@property (nonatomic, strong, nonnull) NSDate * workingDate;

// MARK: - Initializers

/**
 *  This method instantiates a new KCDafYomiCalculator.
 *
 *  @param date The default reference date for the calculator to use.
 *  @return an instance of KCDafYomiCalculator
 */

- (nonnull instancetype)initWithDate:(nonnull NSDate *)date;


// MARK: - Getting "the Daf"

/**
 *  This method returns a KCDaf object representing
 *  the page of talmud bavli being studied today.
 *
 *  @return a KCDaf object.
 */

/**
 *  This method returns a KCDaf object representing
 *  the page of talmud bavli being studied on the
 *  supplied date.
 *
 *  @param date A reference date to calculate with.
 *
 *  @return a KCDaf object.
 */

- (nonnull KCDaf *)dafYomiYerushalmi:(nonnull NSDate *)date calendar:(KCJewishCalendar*_Nonnull)calendar;

@end
