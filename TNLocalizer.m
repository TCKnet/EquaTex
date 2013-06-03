//
//  TNLocalizer.m
//  EquaTeX
//
//  Created by Thierry Coppey on 30.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import "TNLocalizer.h"


@implementation TNLocalizer

- (id)initWithBundle:(NSBundle *)bundle {
	self = [super init];
	if (self) _bundle = [bundle retain];
	return self;
}

- (void)dealloc { [_bundle release]; [super dealloc]; }

#define LS(X) [_bundle localizedStringForKey:(X) value:@"" table:table]
#define LO(T,G,S) { T* _v=(T*)obj; if ((_s=[_v G])!=nil) [_v S:LS(_s)]; }
#define LV(V,G,S) { if ((_s=[V G])!=nil) [V S:LS(_s)]; }

#define K(X) [obj isKindOfClass:[X class]]

- (void)localize:(NSObject*)obj with:(NSString*)table { [self localize:obj with:table exclude:nil]; }
- (void)localize:(NSObject*)obj with:(NSString*)table exclude:(NSArray*)array {
	if (array!=nil && [array containsObject:obj]) return;
	NSString* _s;
	if (K(NSView)) {
		NSView* view = (NSView*)obj;
		for (NSView* sub in [view subviews]) [self localize:sub with:table];
		if (K(NSPopUpButton)) { // Needs to preceed NSButton
			NSPopUpButton* pop = (NSPopUpButton*)view;
			for(NSMenuItem* item in [pop itemArray]) LV(item,title,setTitle);
		} else if (K(NSButton)) {
			LO(NSButton,title,setTitle);
		} else if (K(NSTextField)) {
			LO(NSTextField,stringValue,setStringValue);
		} else if (K(NSSegmentedControl)) {
			NSSegmentedCell* c = [(NSSegmentedControl*)view cell];
			for (NSUInteger i=0,n=[c segmentCount];i<n;++i) {
				if ((_s=[c labelForSegment:i])!=nil) [c setLabel:LS(_s) forSegment:i];
				if ((_s=[c toolTipForSegment:i])!=nil) [c setToolTip:LS(_s) forSegment:i];
			}
		} else if (K(NSBox)) {
			[self localize:[(NSBox*)view contentView] with:table];
		}
	} else if (K(NSMenu)) {
		NSMenu* m = (NSMenu*)obj;
		m.title = LS(m.title);
		for (NSMenuItem* i in [m itemArray]) {
			NSMenu* s = [i submenu];
			if (s) [self localize:s with:table exclude:array];
			[i setTitle:LS([i title])];
		}
	} else if (K(NSWindow)) {
		NSWindow* win = (NSWindow*)obj;
		LV(win,title,setTitle);
		[self localize:[win toolbar] with:table];
		[self localize:[win contentView] with:table];
	} else if (K(NSToolbar)) {
		for (NSToolbarItem* item in [((NSToolbar*)obj) items]) {
			LV(item,label,setLabel);
			[self localize:[item view] with:table];
		}
	}
}

@end
