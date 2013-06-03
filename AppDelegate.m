//
//  EquaTeXAppDelegate.m
//  EquaTeX
//
//  Created by Thierry Coppey on 22.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import "AppDelegate.h"
#import "TNLocalizer.h"

int main(int argc, char *argv[]) {
	return NSApplicationMain(argc, (const char **)argv);
}

@implementation AppDelegate

- (id)init {
	self = [super init]; if (!self) return nil;
	NSShadow* sh = [[NSShadow alloc] init];
	[sh setShadowOffset:NSMakeSize(0.0, -1.0)];
	[sh setShadowBlurRadius:1.0];
	[sh setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
	_attr = [[NSDictionary alloc] initWithObjectsAndKeys:sh, NSShadowAttributeName,
				[NSColor colorWithCalibratedWhite:0.2 alpha:1.0], NSForegroundColorAttributeName, nil];
	_teq = [[TexEquation alloc] init];
	_pending = NO;
	return self;
}

- (void)dealloc {
	if (saveFile) [saveFile release];
	[_teq release];
	[_attr release];
	[super dealloc];
}

// ---------------------------------------------------------------------------
#pragma mark -
#pragma mark Preferences

- (void)loadPrefs {
	NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
	// Special default values
	if (![def objectForKey:@"mode"]) [def setInteger:1 forKey:@"mode"];
	if (![def objectForKey:@"size"]) [def setDouble:11.0 forKey:@"size"];
	if (![def objectForKey:@"zoom"]) [def setDouble:2.0 forKey:@"zoom"];
	if (![def objectForKey:@"highlight"]) [def setBool:YES forKey:@"highlight"];

	// Load preferences
	[_teq setProcessor:[def boolForKey:@"xelatex"] latex:[def stringForKey:@"path_la"]
					xetex:[def stringForKey:@"path_xe"] gs:[def stringForKey:@"path_gs"]];
	[editor setHighlight:[def boolForKey:@"highlight"]];
	[popMode selectItemAtIndex:[def integerForKey:@"mode"]];
	NSUInteger set = [def integerForKey:@"bar_set"]; [popSymbols selectItemAtIndex:set]; [bar selectSet:set];
	[txtSize setStringValue:[NSString stringWithFormat:@"%.fpt",[def doubleForKey:@"size"]]];
	[boxPreview setZoom:[def doubleForKey:@"zoom"]];

	if ([_teq hasProcessor]) {
		[self performSelector:@selector(preview:) withObject:self];
		[bar generateSymbols:_teq];
	}

	// XXX: load more
	// - font face

}

- (void)savePrefs {
	NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
	[def setInteger:[popMode indexOfSelectedItem] forKey:@"mode"];
	[def setInteger:[popSymbols indexOfSelectedItem] forKey:@"bar_set"];
	[def setDouble:[txtSize doubleValue] forKey:@"size"];
	[def setDouble:[boxPreview zoom]forKey:@"zoom"];
	[def synchronize];
}

// ---------------------------------------------------------------------------
#pragma mark -
#define STATUS_HEIGHT 22.0

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// ---------- Toolbar
	[popSymbols removeAllItems]; for (NSString* s in [bar sets]) [popSymbols addItemWithTitle:s];
	for (NSUInteger i=0,n=[btnOptions segmentCount];i<n;++i) [[btnOptions imageForSegment:i] setTemplate:YES]; // Blue glow for selection
	NSNumberFormatter* fmt = [[NSNumberFormatter alloc] init]; [fmt setRoundingIncrement:[NSNumber numberWithDouble:0.1]];
	[fmt setDecimalSeparator:@"."]; [fmt setMaximumFractionDigits:1]; [fmt setMinimum:[NSNumber numberWithDouble:0.1]];
	[fmt setFormat:@"#.#pt"]; [txtSize setFormatter:fmt]; [fmt release];
	// ---------- Window content
	[window setContentBorderThickness:STATUS_HEIGHT forEdge:NSMinYEdge];
	NSSize ws = [[window contentView] frame].size;
	double bh = [bar frame].size.height;
	[bar setFrame:NSMakeRect(0,ws.height-bh, ws.width, bh)];
	[mainView setFrame:NSMakeRect(0,STATUS_HEIGHT,ws.width,ws.height-STATUS_HEIGHT-bh)]; [mainView setDelegate:self];
	[txtStatus setFrame:NSMakeRect(6, (STATUS_HEIGHT-14)/2.0, ws.width-30, 14)]; [self setStatus:@""];
	// ---------- Localize
	TNLocalizer* loc = [[TNLocalizer alloc] initWithBundle:[NSBundle mainBundle]];
	[loc localize:[NSApp mainMenu] with:nil];
	[loc localize:window with:nil];
	[loc localize:[prefs pane] with:nil];
	[loc release];

	// XXX: rework symbols palettes
	// XXX: preamble/equation display
	// XXX: color selection
	// XXX: better insertion with displacement of the cursor+selection
	// XXX: setup keyboard shortcuts for equations / for calling application at frontmost (?)

	// Insert code here to initialize your application
	[editor setFont:[NSFont fontWithName:@"Courier" size:13]]; // @"Courier Bold Oblique"

	// XXX: [editor setInsertionPointColor:[NSColor redColor]];
	
	
	editor.string = @"%Some sample equation\nx^2=3 \\models \\sum_{i=0}^{\\infty^{3^{3^{3^{3}}}}}\\sin(f(x))";
	//editor.string = @"Some {\\fontspec{STSong} 你好} Chinese.";

	
	
	
	// {\color[rgb]{%1.3f,%1.3f,%1.3f} text foo}

	// Load preferences and open panel if no TeX processor
	[self loadPrefs];
	if (![_teq hasProcessor]) [prefs open:window target:self action:@selector(loadPrefs)];
}

- (void)applicationWillTerminate:(NSNotification *)notification { [self savePrefs]; }

- (IBAction)openPrefs:(id)sender { [prefs open:window target:self action:@selector(loadPrefs)]; }

- (void)setStatus:(NSString*)status {
	NSAttributedString* str = [[NSAttributedString alloc] initWithString:status attributes:_attr];
	[txtStatus setAttributedStringValue:str]; [str release];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)pos ofSubviewAt:(NSInteger)dividerIndex {
	double h = [splitView frame].size.height; return (pos<50) ? 1 : (pos>h-50 ? h : pos);
}

// ---------------------------------------------------------------------------
#pragma mark -
#pragma mark Equation update

- (void)genThread:(NSArray*)a {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[_teq generate:[a objectAtIndex:0] mode:[[a objectAtIndex:1] intValue] size:[[a objectAtIndex:2] doubleValue] block:^(NSData* data, NSArray* errs) {
		NSArray* a = [NSArray arrayWithObjects:[_teq image], [NSNumber numberWithDouble:[_teq baseline]], nil];
		if ([errs count]) {
			[self performSelectorOnMainThread:@selector(setStatus:) withObject:[errs componentsJoinedByString:@" "] waitUntilDone:NO];
		} else {
			[self performSelectorOnMainThread:@selector(setStatus:) withObject:Str(@"StatusDone") waitUntilDone:NO];
			[boxPreview performSelectorOnMainThread:@selector(setData:) withObject:a waitUntilDone:NO];
		}
	}];
	[pool release];
}

- (IBAction)preview:(id)sender {
	TexMode m; switch ([popMode indexOfSelectedItem]) {
		case 0: m=TexModeDisplay; break;
		case 1: m=TexModeInline; break;
		case 2: m=TexModeArray; break;
		case 3: m=TexModeAlign; break;
		case 4: m=TexModeAlgo; break;
		default: m=TexModeText; break;
	}
	NSArray* a = [NSArray arrayWithObjects:editor.string, [NSNumber numberWithInt:m], [NSNumber numberWithDouble:[txtSize doubleValue]], nil];
	[NSThread detachNewThreadSelector:@selector(genThread:) toTarget:self withObject:a];
}

// ---------------------------------------------------------------------------
#pragma mark -

- (void)texPreview:(TexEditor*)ed { [self preview:ed]; }
- (void)texCopy:(TexEditor*)ed { [_teq copy:[boxPreview baseline]]; }
- (NSString*)texPaste:(TexEditor*)ed { return [_teq paste]; }

- (IBAction)setSymbols:(id)sender { [bar selectSet:[popSymbols indexOfSelectedItem]]; }
- (IBAction)setOption:(NSSegmentedControl*)options {
	[window setLevel:[options isSelectedForSegment:0]?NSModalPanelWindowLevel:NSNormalWindowLevel];
	if ([options isSelectedForSegment:1]) {
		// XXX: Toggle header/formula
	}
	if ([options isSelectedForSegment:2]) { [options setSelected:NO forSegment:2]; [self preview:options]; } // Refresh
	if ([options isSelectedForSegment:3]) { [options setSelected:NO forSegment:3]; [self texCopy:editor]; } // Copy
	if ([options isSelectedForSegment:4]) { [options setSelected:NO forSegment:4];
		NSString* str = [_teq paste]; if (str) editor.string=str; // XXX: fix Paste
	}
}

- (void)bar:(EquationBar*)bar insert:(NSString*)str {
	// XXX: improve => better handling of cursor
	[editor insertText:str];
}

// ---------------------------------------------------------------------------
#pragma mark -

- (void)newDoc:(NSAlert *)alert ret:(NSInteger)ret ctx:(void *)ctx { if (ret==1) editor.string=@""; }
- (void)newDocument:(id)sender {
	NSAlert* alert = [NSAlert alertWithMessageText:Str(@"New equation") defaultButton:Str(@"OK") alternateButton:Str(@"Cancel")
												  otherButton:nil informativeTextWithFormat:Str(@"ConfirmNew"), nil];
	[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(newDoc:ret:ctx:) contextInfo:nil];
}

- (void)openDocument:(id)sender {

	// XXX: save if unsaved ?
	
	NSOpenPanel *open=[NSOpenPanel openPanel];
	open.treatsFilePackagesAsDirectories=NO;
	open.allowsMultipleSelection=NO;
	open.canChooseDirectories=NO;
	open.canChooseFiles=YES;
	open.allowedFileTypes=[NSArray arrayWithObject:@"pdf"];
	[open beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result != NSOKButton) return; [open orderOut:self];
		NSString* eq = [_teq load:[[open URL] path]]; if (eq!=nil) editor.string=eq;
		// XXX: recolorize
	}];
}

- (void)saveDocumentAs:(id)sender {
	NSSavePanel *save=[NSSavePanel savePanel];
	save.allowedFileTypes=[NSArray arrayWithObject:@"pdf"];
	[save beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
		if (result != NSOKButton) return; [save orderOut:self];
		if (saveFile) [saveFile release]; saveFile=[[[save URL] path] retain];
		[_teq saveAs:saveFile];
	}];
}

- (void)saveDocument:(id)sender {
	if (saveFile==nil) [self saveDocumentAs:sender];
	else [_teq saveAs:saveFile];
}

@end
