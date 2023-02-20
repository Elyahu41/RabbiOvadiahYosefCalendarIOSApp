//
//  KCNOAACalculator.h
//  KosherCocoa
//
//  Created by Elyahu on 1/23/23.
//

@import Foundation;
#import "KCGeoLocation.h"
#import "KCConstants.h"
#import "KCAstronomicalCalculator.h"

/** A class that uses the US National Oceanicnand Atmospheric Administration Algorithm to calculate sunrise and sunset. */

NS_SWIFT_NAME(NOAACalculator)
@interface KCNOAACalculator : KCAstronomicalCalculator

/**
 *
 *
 *  A string representing the name of the calculator
 */

@property (nonatomic, strong, nullable) NSString *calculatorName;

/**
 *  The location of the user.
 */

@property (nonatomic, strong, nonnull) KCGeoLocation *geoLocation;

/**
 *  This method instantiates a new KCNOAACalculator
 *  using the supplied KCGeolocation.
 *
 *  @param geolocation A Geolocation object.
 *  @return An instance of KCNOAACalculator.
 */

- (nonnull instancetype)initWithGeoLocation:(nonnull KCGeoLocation *)geolocation;


@end
