//
//  PrefsController.m
//  EquaTeX
//
//  Created by Thierry Coppey on 31.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import "PrefsController.h"

@implementation PrefsController
@synthesize pane;

- (id)init {
	self = [super init];
	if (self) { _defs=[[NSUserDefaults standardUserDefaults] retain]; }
	return self;
}

- (void)dealloc { [_defs release]; [super dealloc]; }

- (void)sheetDidEnd:(NSWindow *)sheet code:(NSInteger)returnCode info:(void *)contextInfo {
	if (returnCode==1 && _target && [_target respondsToSelector:_action]) [_target performSelector:_action];
	[pane orderOut:self];
}

- (NSArray*)getPaths {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:[[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"]];
	[task setArguments:[NSArray arrayWithObjects:@"-c",@"echo $PATH", nil]];
	NSPipe* p=[NSPipe pipe]; [task setStandardOutput:p]; [task launch]; [[p fileHandleForWriting] closeFile];
	NSMutableData* data = [[NSMutableData alloc] init];
	while ([task isRunning]) [data appendData:[[p fileHandleForReading] availableData]];
	[data appendData:[[p fileHandleForReading] readDataToEndOfFile]];
	[[p fileHandleForReading] closeFile];
	int status = [task terminationStatus]; [task release];
	NSArray* res = nil;
	if (!status) {
		NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		res = [[[str componentsSeparatedByString:@"\n"] objectAtIndex:0] componentsSeparatedByString:@":"];
		[str release];
	}
	[data release];
	return [res arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:@"/usr/texbin",@"/usr/local/bin",nil]];
}

- (void)open:(NSWindow*)window target:(id)target action:(SEL)action {
	_target = target; _action = action;
	NSString* pla = [_defs stringForKey:@"path_la"];
	NSString* pxe = [_defs stringForKey:@"path_xe"];
	NSString* pgs = [_defs stringForKey:@"path_gs"];
	if (!pla||!pxe||!pgs) {
		NSFileManager* fm = [NSFileManager defaultManager];
		NSString* bin;
		for (NSString* p in [self getPaths]) {
			#define PATHOF(VAL,BIN) bin=[p stringByAppendingPathComponent:@BIN]; if (!VAL && [fm fileExistsAtPath:bin]) VAL=bin;
			PATHOF(pla,"pdflatex") PATHOF(pxe,"xelatex") PATHOF(pgs,"gs")
		}
	}
	if (pla) [pathLa setStringValue:pla];
	if (pxe) [pathXe setStringValue:pxe];
	if (pgs) [pathGs setStringValue:pgs];
	BOOL xe=[_defs boolForKey:@"xelatex"]; [useLa setState:!xe]; [useXe setState:xe];
	[chkHighlight setState:[_defs boolForKey:@"highlight"]];

	// XXX: load preferences

	[NSApp beginSheet:pane modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:code:info:) contextInfo:nil];
}

- (IBAction)cancel:(id)sender { [NSApp endSheet:pane returnCode:0]; }
- (IBAction)apply:(id)sender {
	[_defs setObject:[pathLa stringValue] forKey:@"path_la"];
	[_defs setObject:[pathXe stringValue] forKey:@"path_xe"];
	[_defs setObject:[pathGs stringValue] forKey:@"path_gs"];
	[_defs setBool:[useXe state] forKey:@"xelatex"];
	[_defs setBool:[chkHighlight state] forKey:@"highlight"];

	// XXX: save preferences

	[_defs synchronize];
	[NSApp endSheet:pane returnCode:1];
}

- (IBAction)download:(id)sender { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.tug.org/mactex/"]]; }

- (IBAction)setProcessor:(id)sender {
	BOOL xe=NO;
	if (sender==useLa) xe=NO;
	if (sender==useXe) xe=YES;
	if ([[pathLa stringValue] length]==0) xe=YES;
	if ([[pathXe stringValue] length]==0) xe=NO;
	[useLa setState:!xe];
	[useXe setState:xe];
}

- (void)setFont:(id)sender {
	NSLog(@"Set font");
}

- (IBAction)openFont:(id)sender {
	[[NSFontManager sharedFontManager] orderFrontFontPanel:self];

	// XXX: then what ?

}

- (IBAction)browse:(id)sender {
	#define PATH_TRY(S,T) if ([fm fileExistsAtPath:(bin=[path stringByAppendingPathComponent:@S])]) [T setStringValue:bin];
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	panel.canChooseFiles=NO; panel.canChooseDirectories=YES;
	panel.resolvesAliases=YES; panel.allowsMultipleSelection=NO;
	[panel beginSheetModalForWindow:pane completionHandler:^(NSInteger result) {
		if (result == NSOKButton) {
			[panel orderOut:self];
			NSString *bin, *path=[[panel URL] path];
			NSFileManager* fm = [NSFileManager defaultManager];
			PATH_TRY("pdflatex",pathLa) else PATH_TRY("x86_64-darwin/pdflatex",pathLa)
			else PATH_TRY("bin/x86_64-darwin/pdflatex",pathLa)
			PATH_TRY("xelatex",pathXe) else PATH_TRY("x86_64-darwin/xelatex",pathXe)
			else PATH_TRY("bin/x86_64-darwin/xelatex",pathXe)
			PATH_TRY("gs",pathGs) else PATH_TRY("bin/gs",pathGs)
			else { path=[path stringByDeletingLastPathComponent]; PATH_TRY("gs",pathGs) }
		}
	}];
	[self setProcessor:self];
}

@end
