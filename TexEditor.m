//
//  TexEditor.m
//  EquaTeX
//
//  Created by Thierry Coppey on 31.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import "TexEditor.h"

#define KEY_Y 6
#define KEY_C 8

@implementation TexEditor
@synthesize delegate;
@dynamic highlight;

- (void)awakeFromNib {
	highlight = YES;
	_aCom = [[NSDictionary alloc] initWithObjectsAndKeys:
				[NSNumber numberWithFloat:0.25], NSObliquenessAttributeName,
				[NSColor colorWithCalibratedWhite:0.0 alpha:0.1], NSBackgroundColorAttributeName,
				[NSColor colorWithCalibratedWhite:0.0 alpha:0.6], NSForegroundColorAttributeName, nil];
	_aBrk = [[NSDictionary alloc] initWithObjectsAndKeys:
				[NSColor colorWithCalibratedRed:0.0 green:0.6 blue:0.0 alpha:1.0], NSForegroundColorAttributeName, nil];
	_aCmd = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, nil];
	_aKey = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor redColor], NSForegroundColorAttributeName,
				[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.15], NSBackgroundColorAttributeName, nil];
	_aMat = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor purpleColor], NSForegroundColorAttributeName, nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange) name:NSTextDidChangeNotification object:self];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_aCom release];
	[_aCmd release];
	[_aBrk release];
	[_aKey release];
	[_aMat release];
	[super dealloc];
}


- (void)changeFont:(id)sender {
	[self setFont:[sender convertFont:[self font]]];
}

- (void)changeColor:(id)sender {
	NSLog(@"Color");
	// XXX
	[super changeColor:sender];
}

- (void)colorize:(NSRange)range {
	NSString* str = [self string];
	range = [str lineRangeForRange:range];
	unichar* buf = malloc(range.length*sizeof(unichar)+1);
	if (!buf) return; [str getCharacters:buf range:range];
	buf[range.length]=0;

	unichar *end=buf+range.location+range.length;
	unichar *p=buf+range.location,*q=end;
	while (p>buf && p[-1]!='\n') --p; // start at beginning of line to catch comments properly

	NSLayoutManager* lm = [self layoutManager];
#define COL(C) [lm setTemporaryAttributes:C forCharacterRange:NSMakeRange(range.location+p-buf, q-p)];
	for(;p<end;p=q) switch (p[0]) {
		case '%': q=p+1; while(q<end && *q!='\n') ++q; COL(_aCom); break;
		case '{': case '}': q=p+1; COL(_aBrk); break;
		case '$': q=p+1; COL(_aKey); break;
		case '(': case ')': case '[': case ']': case '_': case '^': q=p+1; COL(_aMat); break;
		case '\\':
			switch(p[1]) {
				case '\\': case '[': case ']': q=p+2; COL(_aKey); break;
				case '{': case '}': case '%': q=p+2; COL(_aMat); break;
				default: q=p+1; while (q<end && ((*q>='0'&&*q<='9') || (*q>='a'&&*q<='z') || (*q>='A'&&*q<='Z'))) ++q; COL(_aCmd); break;
			}
			break;
		default: q=p+1; COL(nil); // XXX: lookup to next char
	}
	free(buf);
}

- (void)colorize {
	if (!highlight) return;
	NSRect vr = [[[self enclosingScrollView] contentView] documentVisibleRect];
	NSRange r = [[self layoutManager] glyphRangeForBoundingRect:vr inTextContainer:[self textContainer]];
	[self colorize:r];
}

- (void)timed {
	timer = nil;
	if (delegate && [delegate respondsToSelector:@selector(texPreview:)]) [delegate texPreview:self];
}

- (void)textDidChange {
	[self colorize]; if (timer!=nil) [timer invalidate];
	timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timed) userInfo:nil repeats:NO];
}

- (BOOL)highlight { return highlight; }
- (void)setHighlight:(BOOL)h {
	highlight=h;
	if (!h) [[self layoutManager] setTemporaryAttributes:nil forCharacterRange:NSMakeRange(0,[[self string] length])];
	else [self colorize];
}

- (void)paste:(id)sender {
	NSString* str = nil;
	if (delegate && [delegate respondsToSelector:@selector(texPaste:)]) str=[delegate texPaste:self];
	if (str!=nil) { [self setString:str]; [self textDidChange]; }
	else [super paste:sender];
}

// Copy equation when selection is empty (otherwise default text-copy)
- (void)keyDown:(NSEvent *)evt {
	if ([evt modifierFlags]&NSCommandKeyMask) switch([evt keyCode]) {
		case KEY_C:
			if (delegate && [delegate respondsToSelector:@selector(texCopy:)]) {
				[delegate texCopy:self];
			}
			return;
		//case KEY_Y: [self colorize]; break; // FOR DEBUGGING HIGHLIGHT
		//default: NSLog(@"%@",evt);
	}
	[super keyDown:evt];
}

@end
