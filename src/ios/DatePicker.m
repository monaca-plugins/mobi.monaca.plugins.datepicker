//	Phonegap DatePicker Plugin
//	Copyright (c) Greg Allen 2011
//	MIT Licensed
//
//  Additional refactoring by Sam de Freyssinet

#import "DatePicker.h"

@interface DatePicker (Private)

// Initialize the UIActionSheet with ID <UIActionSheetDelegate> delegate UIDatePicker datePicker (UISegmentedControl)closeButton
- (void)initActionSheet:(id <UIActionSheetDelegate>)delegateOrNil datePicker:(UIDatePicker *)datePicker closeButton:(UISegmentedControl *)closeButton;

// Creates the NSDateFormatter with NSString format and NSTimeZone timezone
- (NSDateFormatter *)createISODateFormatter:(NSString *)format timezone:(NSTimeZone *)timezone;

// Creates the UIDatePicker with NSMutableDictionary options
- (UIDatePicker *)createDatePicker:(CGRect)pickerFrame;

// Creates the UISegmentedControl with UIView parentView, NSString title, ID target and SEL action
- (UISegmentedControl *)createActionSheetCloseButton:(NSString *)title target:(id)target action:(SEL)action;

// Configures the UIDatePicker with the NSMutableDictionary options
- (void)configureDatePicker:(NSMutableDictionary *)optionsOrNil;

@end

@implementation DatePicker

@synthesize datePickerSheet = _datePickerSheet;
@synthesize datePicker = _datePicker;
@synthesize isoDateFormatter = _isoDateFormatter;
@synthesize datePickerPopover;

#pragma mark - Public Methods

- (CDVPlugin *)initWithWebView:(UIWebView *)theWebView
{
	self = (DatePicker *)[super initWithWebView:theWebView];

	if (self)
	{
		UIDatePicker *userDatePicker = [self createDatePicker:CGRectMake(0, 40, 0, 0)];
		UISegmentedControl *datePickerCloseButton = [self createActionSheetCloseButton:@"Close" target:self action:@selector(dismissActionSheet:)];
		NSDateFormatter *isoTimeFormatter = [self createISODateFormatter:k_DATEPICKER_DATETIME_FORMAT timezone:[NSTimeZone defaultTimeZone]];

		self.datePicker = userDatePicker;
		self.isoDateFormatter = isoTimeFormatter;

		[self initActionSheet:self datePicker:userDatePicker closeButton:datePickerCloseButton];        
	}

	return self;
}

- (void)show:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	if (isVisible) {
		return;        
	}

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self configureDatePicker:options];
        [self.datePickerSheet showInView:[[super webView] superview]];
        [self.datePickerSheet setBounds:CGRectMake(0, 0, 320, 485)];
        isVisible = YES;
    } else {
        [self showForPad: options];
    }
}

// for cordova 3.0 ~
- (void) show: (CDVInvokedUrlCommand*)command
{
    if (isVisible) {
		return;
	}
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self configureDatePicker:[command.arguments objectAtIndex:0]];
        [self.datePickerSheet showInView:[[super webView] superview]];
        [self.datePickerSheet setBounds:CGRectMake(0, 0, 320, 485)];
        isVisible = YES;
    } else {
        [self showForPad: [command.arguments objectAtIndex:0]
         ];
    }
}

// for iPad
- (BOOL)showForPad:(NSMutableDictionary *)options {
    if(!isVisible){
        self.datePickerPopover = [self createPopover:options];
        isVisible = TRUE;
    }
    return true;
}

- (UIPopoverController *)createPopover:(NSMutableDictionary *)options {
    
    CGFloat pickerViewWidth = 320.0f;
    CGFloat pickerViewHeight = 216.0f;
    UIView *datePickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerViewWidth, pickerViewHeight)];
    
    CGRect frame = CGRectMake(0, 0, 0, 0);
    self.datePicker = [self createDatePicker:options frame:frame];
    [self.datePicker addTarget:self action:@selector(dateChangedAction:) forControlEvents:UIControlEventValueChanged];
    [self updateDatePicker:options];
    [datePickerView addSubview:self.datePicker];
    
    UIViewController *datePickerViewController = [[UIViewController alloc] init];
    datePickerViewController.view = datePickerView;
    [datePickerView release];
    
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:datePickerViewController];
    [datePickerViewController release];
    
    popover.delegate = self;
    [popover setPopoverContentSize:CGSizeMake(pickerViewWidth, pickerViewHeight) animated:NO];
    
    CGFloat x = [[options objectForKey:@"x"] intValue];
    CGFloat y = [[options objectForKey:@"y"] intValue];
    CGRect anchor = CGRectMake(x, y, 1, 1);
    [popover presentPopoverFromRect:anchor inView:self.webView.superview  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    return popover;
}

- (UIDatePicker *)createDatePicker:(NSMutableDictionary *)options frame:(CGRect)frame {
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:frame];
    return [datePicker autorelease];
}

- (void)dateChangedAction:(id)sender {
    [self jsDateSelected];
}

- (void)jsDateSelected {
    NSString* jsCallback = [NSString stringWithFormat:@"window.plugins.datePicker._dateSelected(\"%i\");", (int)[self.datePicker.date timeIntervalSince1970]];
    [super writeJavascript:jsCallback];
}

- (void)updateDatePicker:(NSMutableDictionary *)options {
    NSDateFormatter *formatter = [self createISODateFormatter:k_DATEPICKER_DATETIME_FORMAT timezone:[NSTimeZone defaultTimeZone]];

    [self setUpDatePicker:options withFormatter:formatter];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    isVisible = FALSE;
}
//


- (void)dismissActionSheet:(id)sender {
	[self.datePickerSheet dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)onMemoryWarning
{
	// It could be better to close the datepicker before the system
	// clears memory. But in reality, other non-visible plugins should
	// be tidying themselves at this point. This could cause a fatal
	// at runtime.
	if (isVisible) {
		return;
	}

	[self release];
}

- (void)dealloc
{
	[_datePicker release];
	[_datePickerSheet release];
	[_isoDateFormatter release];

	[super dealloc];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSString* jsCallback = [NSString stringWithFormat:@"window.plugins.datePicker._dateSelected(\"%i\");", (int)[self.datePicker.date timeIntervalSince1970]];
	[super writeJavascript:jsCallback];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	isVisible = NO;
}

#pragma mark - Private Methods

- (void)initActionSheet:(id <UIActionSheetDelegate>)delegateOrNil datePicker:(UIDatePicker *)datePicker closeButton:(UISegmentedControl *)closeButton
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:delegateOrNil 
													cancelButtonTitle:nil 
											   destructiveButtonTitle:nil 
													otherButtonTitles:nil];

	[actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];

	[actionSheet addSubview:datePicker];
	[actionSheet addSubview:closeButton];

	self.datePickerSheet = actionSheet;

	[actionSheet release];
}

- (UIDatePicker *)createDatePicker:(CGRect)pickerFrame
{
	UIDatePicker *datePickerControl = [[UIDatePicker alloc] initWithFrame:pickerFrame];
	return [datePickerControl autorelease];
}

- (NSDateFormatter *)createISODateFormatter:(NSString *)format timezone:(NSTimeZone *)timezone;
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:timezone];
	[dateFormatter setDateFormat:format];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];

	return [dateFormatter autorelease];
}

- (UISegmentedControl *)createActionSheetCloseButton:(NSString *)title target:(id)target action:(SEL)action
{
	UISegmentedControl *closeButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:title]];

	closeButton.momentary = YES; 
	closeButton.frame = CGRectMake(260, 7.0f, 50.0f, 30.0f);
	closeButton.segmentedControlStyle = UISegmentedControlStyleBar;
	closeButton.tintColor = [UIColor blackColor];

	[closeButton addTarget:target action:action forControlEvents:UIControlEventValueChanged];

	return [closeButton autorelease];
}

- (void)configureDatePicker:(NSMutableDictionary *)optionsOrNil;
{
    [self setUpDatePicker:optionsOrNil withFormatter:self.isoDateFormatter];
}

// private helper
     - (void)setUpDatePicker:(NSMutableDictionary *)options withFormatter:(NSDateFormatter *)formatter
    {
        NSString *mode = [options objectForKey:@"mode"];
        NSString *dateString = [options objectForKey:@"date"];
        NSString *minDateString = [options objectForKey:@"minDate"];
        NSString *maxDateString = [options objectForKey:@"maxDate"];
        BOOL allowOldDates = NO;
        BOOL allowFutureDates = YES;
        
        if ([[options objectForKey:@"allowOldDates"] intValue] == 1) {
            allowOldDates = YES;
        }
        
        if ( ! allowOldDates) {
            self.datePicker.minimumDate = [NSDate date];
        }
        
        if ([[options objectForKey:@"allowFutureDates"] intValue] == 0) {
            allowFutureDates = NO;
        }
        
        if ( ! allowFutureDates) {
            self.datePicker.maximumDate = [NSDate date];
        }
        
        if(minDateString){
            self.datePicker.minimumDate = [formatter dateFromString:minDateString];
        }
        
        if(maxDateString){
            self.datePicker.maximumDate = [formatter dateFromString:maxDateString];
        }
        
        if (dateString.length == 0) {
            dateString = @"2000-1-2T3:4:00Z"; // default
        }
        self.datePicker.date = ([formatter dateFromString:dateString]==nil) ? [NSDate date]:[formatter dateFromString:dateString];
        
        if ([mode isEqualToString:@"date"]) {
            self.datePicker.datePickerMode = UIDatePickerModeDate;
        }
        else if ([mode isEqualToString:@"time"])
        {
            self.datePicker.datePickerMode = UIDatePickerModeTime;
        }
        else
        {
            self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        }
    }

@end
