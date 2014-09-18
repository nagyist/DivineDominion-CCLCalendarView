//
//  CCLCalendarTableModelTranslatorTest.m
//  CalendarView
//
//  Created by Christian Tietze on 01.09.14.
//  Copyright (c) 2014 Christian Tietze. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CCLCalendarTableModelTranslator.h"
#import "TestObjectProvider.h"

#import "CCLProvidesCalendarObjects.h"
#import "CCLMonths.h"
#import "CCLMonth.h"
#import "CCLMonthsFactory.h"
#import "CCLDateRange.h"


@interface TestMonths : NSObject
@property (assign) NSUInteger count;
@property (strong) CCLMonth *lastMonth;
- (void)enumerateMonthsUsingBlock:(void (^)(id month, NSUInteger index, BOOL *stop))block;
@end
@implementation TestMonths
- (void)enumerateMonthsUsingBlock:(void (^)(id, NSUInteger, BOOL *))block
{
    // no-op
}
@end


@interface TestMonthsFactory : CCLMonthsFactory
@property (strong) CCLDateRange *dateRangeProvided;
@end
@implementation TestMonthsFactory
- (id)monthsInDateRange:(CCLDateRange *)dateRange
{
    self.dateRangeProvided = dateRange;
    return [[TestMonths alloc] init];
}
@end

@interface CCLCalendarTableModelTranslatorTest : XCTestCase
@end

@implementation CCLCalendarTableModelTranslatorTest
{
    CCLCalendarTableModelTranslator *translator;
}

- (void)setUp
{
    [super setUp];
    // Initialize with dumb object provider to satisfy checks
    translator = [CCLCalendarTableModelTranslator calendarTableModelTranslatorFrom:[[TestObjectProvider alloc] init]];
}

- (void)tearDown
{
    translator = nil;
    [super tearDown];
}

- (void)testInitially_ComesWithAMonthsFactory
{
    XCTAssertNotNil(translator.monthsFactory, @"should have a default MonthsFactory");
}

- (void)testInitialization_GenerateMonthsFromObjectProvider
{
    TestObjectProvider *objectProvider = [[TestObjectProvider alloc] init];
    objectProvider.dateRange = [self dateRangeWithAMonthIn1970];
    
    translator = [CCLCalendarTableModelTranslator calendarTableModelTranslatorFrom:objectProvider];

    XCTAssertNotNil(translator.calendarData, @"should have set up data");
    XCTAssertEqual(translator.calendarData.months.firstMonth.year, 1970, @"should have adopted the month");
}

- (void)testSettingObjectProvider_UpdatesMonths
{
    TestMonthsFactory *factory = [[TestMonthsFactory alloc] init];
    translator.monthsFactory = factory;
    
    TestObjectProvider *objectProvider = [[TestObjectProvider alloc] init];
    id dateRangeDouble = [[NSObject alloc] init];
    objectProvider.dateRange = dateRangeDouble;
    
    [translator setObjectProvider:objectProvider];
    
    XCTAssertEqual(factory.dateRangeProvided, dateRangeDouble, @"should delegate creation of months from dateRange");
}

- (void)setupObjectProviderFor1970
{
    TestObjectProvider *objectProvider = [[TestObjectProvider alloc] init];
    CCLDateRange *sometimeIn1970 = [self dateRangeWithAMonthIn1970];
    objectProvider.dateRange = sometimeIn1970;
    translator.objectProvider = objectProvider;
}

- (CCLDateRange *)dateRangeWithAMonthIn1970
{
    return [CCLDateRange dateRangeFrom:[NSDate dateWithTimeIntervalSince1970:-100] until:[NSDate dateWithTimeIntervalSince1970:100]];
}
@end
