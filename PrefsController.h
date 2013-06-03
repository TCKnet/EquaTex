//
//  PrefsController.h
//  EquaTeX
//
//  Created by Thierry Coppey on 31.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PrefsController : NSObject {
@private
	NSUserDefaults* _defs;
	NSObject* _target;
	SEL _action;
	IBOutlet NSWindow *pane;

	// Paths
	IBOutlet NSButton *useLa;
	IBOutlet NSButton *useXe;
	IBOutlet NSTextField *pathLa;
	IBOutlet NSTextField *pathXe;
	IBOutlet NSTextField *pathGs;

	// Margins
	IBOutlet NSTextField *mTop;
	IBOutlet NSTextField *mLeft;
	IBOutlet NSTextField *mRight;
	IBOutlet NSTextField *mBot;

	// Syntax highlighting
	IBOutlet NSButton *chkHighlight;
}

- (void)open:(NSWindow*)window target:(NSObject*)target action:(SEL)action;
@property (readonly) NSWindow *pane;

- (IBAction)apply:(id)sender;
- (IBAction)browse:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)download:(id)sender;
- (IBAction)setProcessor:(id)sender;

@end
