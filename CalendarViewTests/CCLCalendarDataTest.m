//
//  CCLCalendarDataTest.m
//  CalendarView
//
//  Created by Christian Tietze on 09.09.14.
//  Copyright (c) 2014 Christian Tietze. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestCalendarSupplier.h"

#import "CCLCalendarData.h"
#import "CCLMonths.h"
#import "CCLMonth.h"

@interface CCLCalendarDataTest : XCTestCase
@end

@implementation CCLCalendarDataTest
{
    TestCalendarSupplier *testCalendarSupplier;
    CCLCalendarData *data;
}

- (void)setUp
{
    [super setUp];
    
    testCalendarSupplier = [[TestCalendarSupplier alloc] init];
    // Unify test results across platforms
    testCalendarSupplier.testCalender = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    [testCalendarSupplier.testCalender setFirstWeekday:2];    [CTWCalendarSupplier setSharedInstance:testCalendarSupplier];
    
    CCLMonth *aug2014 = [CCLMonth monthFromDate:[NSDate dateWithString:@"2014-08-02 12:12:00 +0000"]];
    CCLMonth *sep2014 = [CCLMonth monthFromDate:[NSDate dateWithString:@"2014-09-13 12:12:00 +0000"]];
    CCLMonths *months = [CCLMonths monthsFromArray:@[aug2014, sep2014]];
    data = [CCLCalendarData calendarDataForMonths:months];
}

- (void)tearDown
{
    [CTWCalendarSupplier resetSharedInstance];
    testCalendarSupplier = nil;
    data = nil;
    [super tearDown];
}

- (void)testInsertDetailRow_BelowRow3_ChangesSelectionTo4
{
    [data insertDayDetailRowBelow:3];
    
    XCTAssertEqual(data.detailRow, 4, @"detail row should be row + 1");
}

- (void)testInsertDetailRow_OutOfBounds_Throws
{
    XCTAssertThrows([data insertDayDetailRowBelow:1000], @"inserting out of bounds should throw");
}

#pragma mark -
#pragma mark Translating Row View Types

- (void)testRowViewType_FirstRowOfAugust_ReturnsMonth
{
    CCLRowViewType returnedType = [data rowViewTypeForRow:0];
    
    XCTAssertEqual(returnedType, CCLRowViewTypeMonth, @"first row should be Month type");
}

- (void)testRowViewType_FirstRowOfSeptember_ReturnsMonth
{
    CCLRowViewType returnedType = [data rowViewTypeForRow:6];
    
    XCTAssertEqual(returnedType, CCLRowViewTypeMonth, @"6th row should be Month type");
}

- (void)testRowViewType_FirstRowOfSeptemberWithSelectionInAugust_ReturnsMonth
{
    [data insertDayDetailRowBelow:2];
    CCLRowViewType returnedType = [data rowViewTypeForRow:6 + 1];
    
    XCTAssertEqual(returnedType, CCLRowViewTypeMonth, @"6th row should be Month type");
}

- (void)testRowViewType_ForRowBelowSelection_ReturnsDayDetail
{
    [data insertDayDetailRowBelow:2];
    
    CCLRowViewType returnedType = [data rowViewTypeForRow:3];
    
    XCTAssertEqual(returnedType, CCLRowViewTypeDayDetail, @"row below selection should be DayDetail type");
}

- (void)testRowViewType_ForSelectionRow_ReturnsWeek
{
    [data insertDayDetailRowBelow:2];
    
    CCLRowViewType returnedType = [data rowViewTypeForRow:2];
    
    XCTAssertEqual(returnedType, CCLRowViewTypeWeek, @"usual row should be Week type");
}

- (void)testRowViewType_ForUsualRow_ReturnsWeek
{
    CCLRowViewType returnedType = [data rowViewTypeForRow:8];
    
    XCTAssertEqual(returnedType, CCLRowViewTypeWeek, @"usual row should be Week type");
}

- (void)testRowViewType_RowOutOfBounds_Throws
{
    XCTAssertThrows([data rowViewTypeForRow:100], @"waaaay to high a row index should throw");
}

@end
