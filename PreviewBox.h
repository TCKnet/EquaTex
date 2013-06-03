//
//  PreviewBox.h
//  EquaTeX
//
//  Created by Thierry Coppey on 29.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PreviewBox : NSView {
@private
	NSImage* img;
	NSButton* btnOptions;
	NSButton* btnAuto;
	NSTextField* lblZoom;
	NSSlider* slideZoom;
	NSSlider* slideBase;

	// baseline computations
	double zoom;
	double baseAuto;
}

@property(assign)double zoom;

- (void)setData:(NSArray*)data; // pair (image, baseline)
- (double)baseline;

@end
