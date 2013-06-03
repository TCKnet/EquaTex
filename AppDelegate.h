//
//  EquaTeXAppDelegate.h
//  EquaTeX
//
//  Created by Thierry Coppey on 22.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TexEquation.h"
#import "EquationBar.h"
#import "PreviewBox.h"
#import "PrefsController.h"
#import "TexEditor.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTextFieldDelegate,EquationBarDelegate,NSSplitViewDelegate,TexEditorDelegate> {
@private
	NSString* saveFile; // current file
	NSDictionary* _attr; // Status attributes
	TexEquation* _teq; // Equation generator
	BOOL _pending;

	// Toolbar
	IBOutlet NSPopUpButton *popMode;
	IBOutlet NSPopUpButton *popSymbols;
	IBOutlet NSTextField *txtSize;
	IBOutlet NSSegmentedControl *btnOptions;
	// Window
	IBOutlet EquationBar* bar;
	IBOutlet TexEditor *editor;
	IBOutlet NSTextField *txtStatus;
	IBOutlet PreviewBox *boxPreview;
	IBOutlet NSSplitView *mainView;
	IBOutlet NSWindow *window;

	// Preferences
	IBOutlet PrefsController* prefs;
}

- (void)setStatus:(NSString*)status;
- (IBAction)openPrefs:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)setSymbols:(id)sender;
- (IBAction)setOption:(NSSegmentedControl*)options;

- (IBAction)copyEquation:(id)sender;

@end
