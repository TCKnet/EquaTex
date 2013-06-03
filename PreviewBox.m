//
//  PreviewBox.m
//  EquaTeX
//
//  Created by Thierry Coppey on 29.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import "PreviewBox.h"

@interface PreviewBox()
- (void)toggleOptions:(id)sender;
@end


@implementation PreviewBox
@dynamic zoom;

#define ZMAX (sizeof(zoom_level)/sizeof(double)-1)
static const double zoom_level[16]={ 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 3, 3.5, 4, 5, 6, 7, 8 };
static inline int level(double z) { int l=0; while (l<ZMAX && z>zoom_level[l]+0.01) ++l; return l; }

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame]; if (!self) return nil;
	img = nil;
	baseAuto=-1;
	zoom = 1;
	NSSize s = [self frame].size;

	slideZoom = [[NSSlider alloc] initWithFrame:NSMakeRect(16,s.height-13,120,12)];
	[self addSubview:slideZoom]; [slideZoom release]; [[slideZoom cell] setControlSize:NSMiniControlSize];
	[slideZoom setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin]; [slideZoom setAllowsTickMarkValuesOnly:YES];
	[slideZoom setMinValue:0]; [slideZoom setMaxValue:ZMAX]; [slideZoom setIntValue:level(zoom)];
	[slideZoom setTarget:self]; [slideZoom setAction:@selector(setZoomLevel:)];

	slideBase = [[NSSlider alloc] initWithFrame:NSMakeRect(s.width-14,4,12,s.height-20)];
	[self addSubview:slideBase]; [slideBase release]; [[slideBase cell] setControlSize:NSMiniControlSize];
	[slideBase setAutoresizingMask:NSViewMinXMargin|NSViewHeightSizable]; [slideBase setAllowsTickMarkValuesOnly:YES];
	[slideBase setMinValue:0]; [slideBase setMaxValue:100];
	[slideBase setTarget:self]; [slideBase setAction:@selector(setBaseline:)];

	btnOptions = [[NSButton alloc] initWithFrame:NSMakeRect(0,s.height-13,13,13)];
	[self addSubview:btnOptions]; [btnOptions release]; [btnOptions setButtonType:NSPushOnPushOffButton];
	[btnOptions setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
	[btnOptions setBezelStyle:NSDisclosureBezelStyle]; [btnOptions setTitle:@""];
	[btnOptions setTarget:self]; [btnOptions setAction:@selector(toggleOptions:)];

	btnAuto = [[NSButton alloc] initWithFrame:NSMakeRect(s.width-80,s.height-14,80,14)];
	[self addSubview:btnAuto]; [btnAuto release]; [btnAuto setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[btnAuto setButtonType:NSSwitchButton]; [btnAuto setImagePosition:NSImageRight]; [btnAuto setAlignment:NSRightTextAlignment];
	[btnAuto setAutoresizingMask:NSViewMinXMargin|NSViewMinYMargin]; [[btnAuto cell] setControlSize:NSMiniControlSize];
	[btnAuto setTitle:@"Auto"]; [btnAuto setState:0]; [btnAuto setTarget:self]; [btnAuto setAction:@selector(setBaseline:)];

	lblZoom = [[NSTextField alloc] initWithFrame:NSMakeRect(140,s.height-14,40,14)];
	[self addSubview:lblZoom]; [lblZoom release]; [[lblZoom cell] setControlSize:NSMiniControlSize];
	[lblZoom setAutoresizingMask:NSViewMaxXMargin|NSViewMinYMargin];
	[lblZoom setBordered:NO]; [lblZoom setSelectable:NO]; [lblZoom setDrawsBackground:NO];
	[lblZoom setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[lblZoom setStringValue:[NSString stringWithFormat:@"%.0f%%",zoom*100]];
	[self toggleOptions:self];
	return self;
}

- (void)dealloc {
	if (img) [img release];
	[super dealloc];
}

- (void)toggleOptions:(id)sender {
	BOOL h = [btnOptions state]==0;
	[slideBase setHidden:h];
	[btnAuto setHidden:h];
	[slideZoom setHidden:h];
	NSRect f = lblZoom.frame;
	f.origin.x = h ? 14:140;
	[lblZoom setFrame:f];
	[self setNeedsDisplay:YES];
}

- (void)setBaseline:(id)sender {
	if (sender==slideBase) [btnAuto setState:0];
	if ([btnAuto state]) [slideBase setDoubleValue:baseAuto/[img size].height*100];
	[self setNeedsDisplay:YES];
}

- (double)zoom { return zoom; }
- (void)setZoom:(double)z {
	zoom = z;
	[lblZoom setStringValue:[NSString stringWithFormat:@"%.0f%%",zoom*100]];
	[slideZoom setIntValue:level(zoom)];
	[self setBaseline:self];
}

- (void)setZoomLevel:(id)sender { [self setZoom:zoom_level[[slideZoom intValue]]]; }

- (double)baseline { return [img size].height * [slideBase doubleValue]/100; }

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	[super resizeSubviewsWithOldSize:oldSize];
	NSSize s = [self frame].size; // fixes issues with view collapsing
	[slideBase setFrame:NSMakeRect(s.width-14,4,12,s.height-20)];
}

- (void)setData:(NSArray*)data {
	if (img) [img release];
	img = [[data objectAtIndex:0] copy];
	baseAuto = [[data objectAtIndex:1] doubleValue];
	if (baseAuto>=0) { [btnAuto setState:1]; [btnAuto setEnabled:YES]; }
	else { [btnAuto setState:0]; [btnAuto setEnabled:NO]; }
	[self setZoomLevel:self];
}

- (void)drawRect:(NSRect)dirtyRect {
	NSSize s=[self frame].size;
	NSSize is = [img size];
	if (is.width==0 || is.height==0) return;
	is.width *= zoom;
	is.height *= zoom;

	// Baseline
	if ([btnOptions state]) {
		double v = [slideBase doubleValue]/100;
		[[NSColor controlShadowColor] set];
		NSRectFill(NSMakeRect(0, round((s.height-is.height)/2 + is.height*v), s.width-11, 1));
	}

	// Equation
	if (!img) return;
	NSRect ir = NSMakeRect(round(MAX(0,(is.width-s.width)/2)/zoom),
							round(MAX(0,(is.height-s.height)/2)/zoom),
							round(MIN(s.width,is.width)/zoom),
							round(MIN(s.height,is.height)/zoom));
	NSRect dr = NSMakeRect(round(MAX(0,(s.width-is.width)/2)),
							round(MAX(0,(s.height-is.height)/2)),
							round(MIN(s.width,is.width)),
							round(MIN(s.height,is.height)));
	[img drawInRect:dr fromRect:ir operation:NSCompositeSourceOver fraction:1.0];
}

@end
