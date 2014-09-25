//
//  CCLDayLocator.m
//  CalendarView
//
//  Created by Christian Tietze on 23.09.14.
//  Copyright (c) 2014 Christian Tietze. All rights reserved.
//

#import "CCLDayLocator.h"
#import "CCLMonth.h"
#import "CTWCalendarSupplier.h"

@implementation CCLDayLocator
+ (instancetype)dayLocatorInMonth:(CCLMonth *)month week:(NSUInteger)week weekday:(NSUInteger)weekday
{
    return [[self alloc] initWithMonth:month week:week weekday:weekday];
}

- (instancetype)initWithMonth:(CCLMonth *)month week:(NSUInteger)week weekday:(NSUInteger)weekday
{
    self = [super init];
    
    if (self)
    {
        _month = month;
        _week = week;
        _weekday = weekday;
    }
    
    return self;
}

- (NSCalendar *)calendar
{
    return [[CTWCalendarSupplier calendarSupplier] autoupdatingCalendar];
}


#pragma mark -
#pragma mark Weekday in Range of Month

- (BOOL)isOutsideDayRange
{
    if ([self isDuringFirstWeekOfMonth])
    {
        return [self isBeforeBeginningOfMonth];
    }
    
    if ([self isDuringLastWeekOfMonth])
    {
        return [self isAfterEndOfMonth];
    }
    
    return NO;
}

- (BOOL)isDuringFirstWeekOfMonth
{
    NSUInteger week = self.week;
    
    return week == 1;
}

- (BOOL)isBeforeBeginningOfMonth
{
    NSDate *day = [self day];
    NSDate *firstDay = [self firstDayOfMonth];
    
    if ([firstDay isEqualToDate:day])
    {
        return NO;
    }
    
    return [firstDay earlierDate:day] == day;
}

- (BOOL)isDuringLastWeekOfMonth
{
    CCLMonth *month = self.month;
    NSUInteger week = self.week;
    
    return week == month.weekCount;
}

- (BOOL)isAfterEndOfMonth
{
    NSDate *day = [self day];
    NSDate *lastDay = [self lastDayOfMonth];
    
    if ([lastDay isEqualToDate:day])
    {
        return NO;
    }
    
    return [day laterDate:lastDay] == day;
}

- (NSDate *)day
{
    CCLMonth *month = self.month;
    NSUInteger week = self.week;
    NSUInteger weekday = self.weekday;
    
    return [self dateForWeek:week weekday:weekday month:month];
}

- (NSDate *)firstDayOfMonth
{
    return self.month.firstOfMonth;
}

- (NSDate *)lastDayOfMonth
{
    return self.month.lastOfMonth;
}

- (NSDate *)dateForWeek:(NSUInteger)week weekday:(NSUInteger)weekday month:(CCLMonth *)month
{
    NSCalendar *calendar = [self calendar];
    NSDate *firstOfMonth = month.firstOfMonth;

    NSDateComponents *weeksToAdd = [[NSDateComponents alloc] init];
    weeksToAdd.week = week - 1;

    NSDate *date = [calendar dateByAddingComponents:weeksToAdd toDate:firstOfMonth options:0];
    NSDateComponents *dayComponents = [calendar components:NSYearForWeekOfYearCalendarUnit | NSWeekOfYearCalendarUnit | NSWeekdayCalendarUnit fromDate:date];
    dayComponents.weekday = weekday;
    
    return [calendar dateFromComponents:dayComponents];
}


#pragma mark Weekend

- (BOOL)isWeekend
{
    NSCalendar *calendar = self.calendar;
    
    if (![[calendar calendarIdentifier] isEqualTo:NSGregorianCalendar])
    {
        return NO;
    }
    
    return [self isWeekendInGregorianCalendar];
}

- (BOOL)isWeekendInGregorianCalendar
{
    NSUInteger weekday = self.weekday;
    
    if (weekday == 1  || weekday == 7)
    {
        return YES;
    }
    
    // For locales starting on Monday, Sunday becomes 8
    if (weekday > 7 && (weekday - 7) == 1)
    {
        return YES;
    }
    
    return NO;
}


#pragma mark Date Component

- (NSDateComponents *)dateComponents
{
    NSDate *day = [self day];
    NSCalendar *calendar = [self calendar];
    NSCalendarUnit components = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekOfYearCalendarUnit;
    
    return [calendar components:components fromDate:day];
}

@end
