//
//  CCLCalendarViewController.m
//  CalendarView
//
//  Created by Christian Tietze on 26.08.14.
//  Copyright (c) 2014 Christian Tietze. All rights reserved.
//

#import "CCLCalendarViewController.h"

// Collaborators
#import "CCLHandlesDaySelection.h"
#import "CCLProvidesCalendarObjects.h"
#import "CCLCalendarTableModelTranslator.h"

// Components
#import "CCLDayCellSelection.h"
#import "CCLCalendarView.h"
#import "CCLWeekRowView.h"
#import "CCLDayDetailRowView.h"
#import "CCLDayCellView.h"

NSString * const kCCLCalendarViewControllerNibName = @"CCLCalendarViewController";

@interface CCLCalendarViewController ()
@property (nonatomic, strong, readwrite) CCLCalendarTableModelTranslator *tableModelTranslator;
@end

@implementation CCLCalendarViewController

+ (instancetype)calendarViewController
{
    return [[self alloc] initWithNibName:kCCLCalendarViewControllerNibName
                                  bundle:[NSBundle mainBundle]];
}

- (void)setObjectProvider:(id<CCLProvidesCalendarObjects>)objectProvider
{
    if (_objectProvider == objectProvider)
    {
        return;
    }
    
    _objectProvider = objectProvider;
    
    [self updateTableModelTranslator];
}

- (void)updateTableModelTranslator
{
    id<CCLProvidesCalendarObjects> objectProvider = self.objectProvider;
    
    if (objectProvider == nil)
    {
        self.tableModelTranslator = nil;
        return;
    }
    
    CCLCalendarTableModelTranslator *translator = [CCLCalendarTableModelTranslator calendarTableModelTranslatorFrom:objectProvider];
    self.tableModelTranslator = translator;
    self.selectionDelegate = translator;
}

#pragma mark -
#pragma mark View Setup

- (void)awakeFromNib
{
    [self.calendarTableView setIntercellSpacing:NSMakeSize(0, 0)];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.tableModelTranslator numberOfRows];
}


#pragma mark Row Views

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    CCLRowViewType rowViewType = [self.tableModelTranslator rowViewTypeForRow:row];
    NSTableRowView *rowView = [self tableView:tableView rowViewForRowViewType:rowViewType];
    
    return rowView;
}

/// @returns Returns @p nil when @p rowViewType is not supported.
- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRowViewType:(CCLRowViewType)rowViewType
{
    [self guardRowViewTypeValidity:rowViewType];
    
    if (rowViewType == CCLRowViewTypeMonth)
    {
        return [tableView makeViewWithIdentifier:@"MonthRow" owner:self];
    }
    
    if (rowViewType == CCLRowViewTypeDayDetail)
    {
        return [tableView makeViewWithIdentifier:@"DayDetailRow" owner:self];
    }
    
    if (rowViewType == CCLRowViewTypeWeek)
    {
        return [tableView makeViewWithIdentifier:@"WeekRow" owner:self];
    }
    
    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    CCLRowViewType rowViewType = [self.tableModelTranslator rowViewTypeForRow:row];
    
    if (rowViewType == CCLRowViewTypeMonth)
    {
        return YES;
    }
    
    return NO;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    CCLRowViewType rowViewType = [self.tableModelTranslator rowViewTypeForRow:row];
    CGFloat height = [self tableView:tableView heightOfRowViewType:rowViewType];
    
    return height;
}

- (CGFloat)tableView:(NSTableView *)tableview heightOfRowViewType:(CCLRowViewType)rowViewType
{
    [self guardRowViewTypeValidity:rowViewType];
    
    if (rowViewType == CCLRowViewTypeMonth)
    {
        return 20.;
    }
    
    if (rowViewType == CCLRowViewTypeDayDetail)
    {
        return 140.;
    }
    
    return 80.;
}

- (void)guardRowViewTypeValidity:(CCLRowViewType)rowViewType
{
    NSAssert(rowViewType != CCLRowViewTypeUndefined, @"rowViewType should never become Undefined");
}


#pragma mark Cell Views

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    CCLRowViewType rowViewType = [self.tableModelTranslator rowViewTypeForRow:row];
    [self guardRowViewTypeValidity:rowViewType];
    
    if (rowViewType == CCLRowViewTypeMonth)
    {
        return [tableView makeViewWithIdentifier:@"MonthCell" owner:self];
    }
    
    if (rowViewType == CCLRowViewTypeDayDetail)
    {
        return nil;
    }
    
    if (rowViewType != CCLRowViewTypeWeek)
    {
        return nil;
    }
    
    NSInteger columnIndex = [[tableView tableColumns] indexOfObject:tableColumn];
    BOOL isLastColumn = (columnIndex == tableView.tableColumns.count - 1);

    // TODO if outside of month day range, return something else
//    if (row == 1 && columnIndex < 3)
//    {
//        return nil;
//    }
    
    if (isLastColumn)
    {
        NSTableRowView *row = [tableView makeViewWithIdentifier:@"WeekTotalCell" owner:self];
        row.backgroundColor = [NSColor grayColor];
        return row;
    }
    
    return [tableView makeViewWithIdentifier:@"WeekdayCell" owner:self];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    NSInteger columnIndex = [[tableView tableColumns] indexOfObject:tableColumn];
    
    return [self.tableModelTranslator objectValueForTableView:self.calendarTableView column:columnIndex row:rowIndex];
}


#pragma mark Table Change Callbacks

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    if (![rowView.identifier isEqualToString:@"DayDetailRow"])
    {
        return;
    }
    
    self.dayDetailRowView = (CCLDayDetailRowView *)rowView;
}


#pragma mark -
#pragma mark Cell Selection

- (void)tableView:(NSTableView *)tableView didSelectCellViewAtRow:(NSInteger)row column:(NSInteger)column
{
    NSTableRowView *selectedRow = [tableView rowViewAtRow:row makeIfNecessary:YES];
    if (![selectedRow.identifier isEqualToString:@"WeekRow"])
    {
        return;
    }
    
    NSTableCellView *selectedCell = [tableView viewAtColumn:column row:row makeIfNecessary:YES];
    BOOL newSelectionIsOnSameRow = NO;
    if ([self hasSelectedDayCell])
    {
        NSInteger oldSelectionRow = [self cellSelectionRow];
        if (oldSelectionRow == row)
        {
            newSelectionIsOnSameRow = YES;
        }
        
        if (!newSelectionIsOnSameRow || [selectedCell.identifier isEqualToString:@"WeekTotalCell"])
        {
            [self removeDetailRow];
        }
        
        [self deselectDayCell];
        
        if (oldSelectionRow < row)
        {
            row--;
        }
    }
    
    if ([selectedCell.identifier isEqualToString:@"WeekTotalCell"])
    {
        return;
    }
    
    CCLDayCellView *dayCellView = (CCLDayCellView *)selectedCell;
    [self selectDayCell:dayCellView row:row column:column];
    
    if (newSelectionIsOnSameRow)
    {
        return;
    }
    
    [self insertDetailRow];
}

- (BOOL)hasSelectedDayCell
{
    return [self.selectionDelegate hasCellSelection];
}

- (NSUInteger)cellSelectionRow
{
    return [self.selectionDelegate cellSelectionRow];
}

- (void)deselectDayCell
{
    [self.selectionDelegate controllerDidDeselectCell];
}

- (void)removeDetailRow
{
    if (self.dayDetailRowView == nil)
    {
        return;
    }
    
    NSInteger rowBelow = [self.calendarTableView rowForView:self.dayDetailRowView];
    NSIndexSet *rowBelowIndexSet = [NSIndexSet indexSetWithIndex:rowBelow];
    [self.calendarTableView removeRowsAtIndexes:rowBelowIndexSet withAnimation:NSTableViewAnimationSlideUp];
}

- (void)selectDayCell:(CCLDayCellView *)selectedView row:(NSUInteger)row column:(NSUInteger)column
{
    CCLDayCellSelection *selection = [CCLDayCellSelection dayCellSelection:selectedView atRow:row column:column];
    [self.selectionDelegate controllerDidSelectCell:selection];
    
    id objectValue = selectedView.objectValue;
    NSView *detailView = [self.eventHandler detailViewForObjectValue:objectValue];
    // TODO display view in detail row
    
    [self.eventHandler calendarViewController:self
                 didSelectCellWithObjectValue:objectValue];
}

- (void)insertDetailRow
{
    NSUInteger selectionRow = [self.selectionDelegate cellSelectionRow];
    NSInteger rowBelow = selectionRow + 1;
    NSIndexSet *rowBelowIndexSet = [NSIndexSet indexSetWithIndex:rowBelow];
    [self.calendarTableView insertRowsAtIndexes:rowBelowIndexSet withAnimation:NSTableViewAnimationSlideDown];
}

@end
