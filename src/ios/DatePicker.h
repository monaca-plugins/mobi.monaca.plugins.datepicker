//	Phonegap DatePicker Plugin
//	Copyright (c) Greg Allen 2011
//	MIT Licensed

#import <Foundation/Foundation.h>
#ifdef CORDOVA_FRAMEWORK
#import <Cordova/CDVPlugin.h>
#else
#import <Cordova/CDVPlugin.h>
#endif

#ifndef k_DATEPICKER_DATETIME_FORMAT
#define k_DATEPICKER_DATETIME_FORMAT @"yyyy-MM-dd'T'HH:mm:ss'Z'"
#endif

@interface DatePicker : CDVPlugin <UIActionSheetDelegate, UIPopoverControllerDelegate> {
	UIActionSheet *_datePickerSheet;
	UIDatePicker *_datePicker;
	NSDateFormatter *_isoDateFormatter;
	BOOL isVisible;
}

@property (nonatomic, retain) UIActionSheet* datePickerSheet;
@property (nonatomic, retain) UIDatePicker* datePicker;
@property (nonatomic, retain) NSDateFormatter* isoDateFormatter;
@property (nonatomic, retain) UIPopoverController *datePickerPopover;

- (void) show:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

// for cordova 3.0 ~
- (void) show: (CDVInvokedUrlCommand*)command;

@end
