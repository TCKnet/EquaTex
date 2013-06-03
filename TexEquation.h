//
//  TexEquation.h
//  EquaTeX
//
//  Created by Thierry Coppey on 25.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum { TexModeDisplay, TexModeInline, TexModeArray, TexModeAlign, TexModeAlgo, TexModeText } TexMode;

@interface TexEquation : NSObject {
@private
	NSString* _eq; // equation
	NSData* _data; // PDF data
	NSRect _size;  // PDF size

	BOOL _xetex;
	NSString* _la; // LaTeX path
	NSString* _xe; // XeTeX path
	NSString* _gs; // GhostScript path
	
	NSColor* _col; // default color
}

@property (retain)IBOutlet NSColor* color;

- (void)setProcessor:(BOOL)xetex latex:(NSString*)laPath xetex:(NSString*)xePath gs:(NSString*)gsPath;
- (BOOL)hasProcessor;

// Multiple processing can be run on the same TexEquation
// and the data is kept coherent during block(pdf data, error strings array)
- (void)generate:(NSString*)equation mode:(TexMode)mode size:(double)size;
- (void)generate:(NSString*)equation mode:(TexMode)mode size:(double)size block:(void (^)(NSData*,NSArray*))block;

- (double)baseline;
- (void)copy:(double)baseline;
- (NSString*)paste; // nil if there is no equation data (from either PDF or Pages pasteboard)
- (NSImage*)image;

- (NSString*)load:(NSString*)file;
- (void)saveAs:(NSString*)file;

@end
