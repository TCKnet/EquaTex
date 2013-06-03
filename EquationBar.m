//
//  EquationBar.m
//  EquaTeX
//
//  Created by Thierry Coppey on 28.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import "EquationBar.h"

#define _WHITE   " \r\n\t"
#define _COMMENT '%'
#define _SPLIT   "%%"
#define _EMPTY   "-X-"

#define RRect(F,X0,Y0,X1,Y1) ({ int _x=round(F.width*(X0)),_y=round(F.height*(Y0)); NSMakeRect(_x,_y,round(F.width*(X1))-_x-1, round(F.height*(Y1))-_y-1); })
#define DMenu(R,C) ((_mcol*R+C>=[_mnu count])?nil:[_mnu objectAtIndex:_mcol*R+C])
#define DBtn(R,C) ((_btn==nil || _bcol*R+C>=[_btn count])?nil:[_btn objectAtIndex:_bcol*R+C])

// -----------------------------------------------------------------------------------

@interface EquationBar()
-(void)setRows:(int)rows colums:(int)cols menusRows:(int)menu_rows menusColumns:(int)menu_cols;
-(void)setBtn:(NSArray*)btn;
-(void)select:(int)row col:(int)col;
@end

// -----------------------------------------------------------------------------------

@interface EquationPopup : NSWindow
@end
@implementation EquationPopup
-(id)init {
	if (!(self=[super initWithContentRect:NSMakeRect(100,100,100,100) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES])) return nil;
	[self setReleasedWhenClosed:NO]; [self setExcludedFromWindowsMenu:YES]; [self setLevel:NSPopUpMenuWindowLevel];
	[self setBackgroundColor:[NSColor controlShadowColor]];
	[self setHasShadow:YES];
	EquationBar* bar = [[EquationBar alloc] initWithFrame:NSMakeRect(0,0,1,1)];
	[[self contentView] addSubview:bar]; [bar release];
	return self;
}

-(void)select:(int)row col:(int)col { [[[[self contentView] subviews] objectAtIndex:0] select:row col:col]; }
-(void)popupAt:(NSPoint)pt unit:(int)unit dict:(NSDictionary*)dict {
	int rows = [[dict objectForKey:@"rows"] intValue];
	int cols = [[dict objectForKey:@"cols"] intValue];
	NSRect f = NSMakeRect(pt.x, round(pt.y-unit*rows), round(unit*cols)+1, round(unit*rows)+1);
	EquationBar* bar = [[[self contentView] subviews] objectAtIndex:0];
	bar.frame = NSMakeRect(0,1,f.size.width,f.size.height-1);
	[bar setRows:rows colums:cols menusRows:0 menusColumns:0];
	[bar setBtn:[dict objectForKey:@"data"]];
	[self setFrame:f display:YES];
	[self orderFront:self];
}
@end

// -----------------------------------------------------------------------------------

@implementation EquationBar
@synthesize delegate;

-(void)select:(int)row col:(int)col { _scol=col; _srow=row; _stype=EBSelButton; [self setNeedsDisplay:YES]; }
-(void)setBtn:(NSArray*)btn { _btn=btn; _scol=-1; _srow=-1; _stype=EBSelNone; [self setNeedsDisplay:YES]; }
-(void)setRows:(int)rows colums:(int)cols menusRows:(int)menu_rows menusColumns:(int)menu_cols {
#define LIM(V,MIN,MAX) if (V<MIN) V=MIN; if (V>MAX) V=MAX;
	LIM(cols,1,50) LIM(menu_cols,1,50)
	LIM(rows,0,20) LIM(menu_rows,0,20)
	if (rows+menu_rows<1) menu_rows=1;
	_brow=rows; _bcol=cols; _mrow=menu_rows; _mcol=menu_cols;
	[self setNeedsDisplay:YES];
}

- (void)getImage:(NSString*)title dict:(NSMutableDictionary*)dict {
	NSString* path = [NSString stringWithFormat:@"%@/%lu.pdf",_path,(long)[title hash]];
	[dict setObject:path forKey:@"path"];
	NSImage* img = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		img = [[NSImage alloc] initWithContentsOfFile:path];
		if (img) { [dict setObject:img forKey:@"image"]; [img release]; }
	}
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame]; if (!self) return nil;
	_mnu = [[NSMutableArray alloc] init];
	_set = [[NSMutableArray alloc] init];
	_bg=[[NSGradient alloc] initWithColorsAndLocations:
			[NSColor colorWithCalibratedWhite:0.95 alpha:1.0], 0.0,
			[NSColor colorWithCalibratedWhite:0.90 alpha:1.0], 0.5,
			[NSColor colorWithCalibratedWhite:0.95 alpha:1.0], 0.5,
			[NSColor colorWithCalibratedWhite:0.99 alpha:1.0], 1.0, nil];
	_bgs=[[NSGradient alloc] initWithColorsAndLocations:
			[NSColor colorWithCalibratedWhite:0.77 alpha:1.0], 0.0,
			[NSColor colorWithCalibratedWhite:0.70 alpha:1.0], 0.5,
			[NSColor colorWithCalibratedWhite:0.77 alpha:1.0], 0.5,
			[NSColor colorWithCalibratedWhite:0.87 alpha:1.0], 1.0, nil];
	[self setRows:1 colums:1 menusRows:0 menusColumns:1];

	// Popup case: only create a display stub
	if (frame.size.width==1&&frame.size.height==1) return self;
	_pop = [[EquationPopup alloc] init];

	// Resource path
    
    NSFileManager* fm = [NSFileManager defaultManager];
    _path = [NSString stringWithFormat:@"%@/Library/Application Support/EquaTex",NSHomeDirectory()];
    if (![fm fileExistsAtPath:_path]) [fm createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:nil];

/*
	_path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Symbols"] retain];
#ifdef DEBUG
	// From .../build/Debug/EquaTeX.app/Contents/Resources/Symbols
	// to   .../temp
	NSArray* pa = [_path componentsSeparatedByString:@"/"];
	pa = [pa subarrayWithRange:NSMakeRange(0, [pa count]-6)];
	_path = [NSString stringWithFormat:@"%@/temp",[pa componentsJoinedByString:@"/"]];
#endif
	[[NSFileManager defaultManager] createDirectoryAtPath:_path withIntermediateDirectories:YES attributes:nil error:nil];
*/
 
	// Load and parse configuration file
	pthread_mutex_init(&_mutex,NULL);
	FILE* f = fopen([[[NSBundle mainBundle] pathForResource:@"Toolbar" ofType:@"conf"] UTF8String], "r");
	NSMutableArray* data = nil;
	if (f) {
		char buf[2048],*p,*q,*r;
		while (fgets(buf,2048,f)) {
			p=buf; while(*p&&strchr(_WHITE, *p)) ++p; if (!*p) continue;
			q=p+strlen(p)-1; while(*q&&strchr(_WHITE, *q)) { *q=0; --q; }
			if (*p==_COMMENT||!strncmp(p,_SPLIT,strlen(_SPLIT))) continue;

			NSString* title=nil;
			NSMutableDictionary* dict;
			if (!strncmp(p,"LAYOUT ",7)) {
				p+=7;
				int n1=(int)strtol(p,&r,10); if (!r||*r!='x') continue; p=r+1;
				int n2=(int)strtol(p,&r,10); if (!r||*r!=' ') continue; p=r+1;
				int n3=(int)strtol(p,&r,10); if (!r||*r!='x') continue; p=r+1;
				[self setRows:n1 colums:n2 menusRows:n3 menusColumns:(int)strtol(p,&r,10)];
			} else if (!strncmp(p,"MENU ",5)) {
				int n1=(int)strtol(p+5,&r,10); if (!r||*r!='x') continue; p=r+1;
				int n2=(int)strtol(p,&r,10); if (!r||*r!=' ') continue; p=r+1;
				data = [NSMutableArray array];
				title = [NSString stringWithUTF8String:p];
				dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:title, @"title",
						[NSNumber numberWithInt:n1], @"rows", [NSNumber numberWithInt:n2], @"cols", data, @"data", nil];
				[_mnu addObject:dict];
				
				[self getImage:title dict:dict];
				
			} else if (!strncmp(p,"SET ",4)) {
				data = [NSMutableArray array];
				dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:p+4], @"title", data, @"data", nil];
				[_set addObject:dict];
			} else if (data!=nil) {
				char *t=p-1;
				do {
					p=t+1;
					if ((t=strchr(p,'\t'))) { *t=0; q=t-1; while(*q&&strchr(_WHITE,*q)) { *q=0; --q; } }

					if ((q=strstr(p,_SPLIT))) {
						*q=0; r=q-1; while(*r&&strchr(_WHITE, *r)) { *r=0; --r; }
						q+=strlen(_SPLIT); while(*q&&strchr(_WHITE, *q)) ++q;
					}
					if (!*p) continue;
					title = [NSString stringWithUTF8String:p];
					NSString* value = q ? [NSString stringWithUTF8String:q] : title;
					dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:title, @"title", value, @"value", nil];
					[data addObject:dict];
					[self getImage:title dict:dict];
				} while (t);
				
				/*
				if ((q=strstr(p,_SPLIT))) {
					*q=0; r=q-1; while(*r&&strchr(_WHITE, *r)) { *r=0; --r; }
					q+=strlen(_SPLIT); while(*q&&strchr(_WHITE, *q)) ++q;
				}
				if (!*p) continue;
				title = [NSString stringWithUTF8String:p];
				NSString* value = q ? [NSString stringWithUTF8String:q] : title;
				dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:title, @"title", value, @"value", nil];
				[data addObject:dict];
				*/
			}
			
			/*
			// Load display image if present
			if (title) {
				NSString* path = [NSString stringWithFormat:@"%@/%lu.pdf",_path,[title hash]];
				[dict setObject:path forKey:@"path"];
				NSImage* img = nil;
				if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
					img = [[NSImage alloc] initWithContentsOfFile:path];
					if (img) { [dict setObject:img forKey:@"image"]; [img release]; }
				}
			}
			*/
		}
		fclose(f);
	}
	return self;
}

- (void)dealloc {
	[_gen release];
	[_pop release];
	[_mnu release];
	[_set release];
	[_bg release];
	[_bgs release];
	[_path release];
	pthread_mutex_destroy(&_mutex);
	[super dealloc];
}

// -----------------------------------------------------------------------------------
// Asynchrous generation of PDF files for display images

- (void)inc { if (_pb) [_pb setDoubleValue:[_pb doubleValue]+1]; }

#define GEN_IMG ++n; if (_pb) [_pb setMaxValue:n]; if ([dict objectForKey:@"image"] || [[dict objectForKey:@"title"] isEqualToString:@_EMPTY]) { ++g; if (_pb) [self inc]; } \
else [NSThread detachNewThreadSelector:@selector(genThread:) toTarget:self withObject:dict]; \
if (g<n && !_pb) { _pb = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(-3,-3,[self frame].size.width+6,12)]; \
[_pb setAutoresizingMask:NSViewMaxYMargin|NSViewWidthSizable]; [_pb setStyle:NSProgressIndicatorBarStyle]; [_pb setMinValue:0]; \
[_pb setMaxValue:n]; [_pb setDoubleValue:g]; [_pb setIndeterminate:NO]; [_pb startAnimation:self]; [self addSubview:_pb]; [_pb release]; } \

- (void)generateSymbols:(TexEquation*)generator {
	TexEquation* old = _gen; _gen=[generator retain]; if (old) [old release];
	_ncpu = (int)[[NSProcessInfo processInfo] processorCount]; int n=0,g=0;
	NSMutableDictionary* dict;
	for (NSMutableDictionary* m in _mnu) { dict=m; GEN_IMG; for (dict in [m objectForKey:@"data"]) { GEN_IMG } }
	for (NSMutableDictionary* s in _set) for (dict in [s objectForKey:@"data"]) { GEN_IMG }
	if (_pb && [_pb doubleValue]==n) { [_pb stopAnimation:self]; [_pb removeFromSuperview]; _pb=nil; }
	[self setNeedsDisplay:YES];
}

#define LOAD_IMG if (![dict objectForKey:@"image"]) { NSString* path=[dict objectForKey:@"path"]; if (![[NSFileManager defaultManager] fileExistsAtPath:path]) continue; \
NSImage* img=[[NSImage alloc] initWithContentsOfFile:path]; if (img) { [dict setObject:img forKey:@"image"]; [img release]; } }
- (void)postGen {
	NSMutableDictionary* dict;
	for (NSMutableDictionary* m in _mnu) { dict=m; LOAD_IMG; for (dict in [m objectForKey:@"data"]) { LOAD_IMG } }
	for (NSMutableDictionary* s in _set) for (dict in [s objectForKey:@"data"]) { LOAD_IMG }
	if (_pb) { [_pb stopAnimation:self]; [_pb removeFromSuperview]; _pb=nil; }
	[self setNeedsDisplay:YES];
}

- (void)genThread:(NSDictionary*)dict {
	pthread_mutex_lock(&_mutex); ++_pending;
	while(_running>_ncpu) { pthread_mutex_unlock(&_mutex); usleep(10000); pthread_mutex_lock(&_mutex); }
	++_running; pthread_mutex_unlock(&_mutex);

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSString* path = [dict objectForKey:@"path"];
	NSString* title = [dict objectForKey:@"title"]; //NSLog(@"Building: %@",title);
	[_gen generate:title mode:TexModeInline size:11 block:^(NSData* data,NSArray* err){
		if (data) [data writeToFile:path atomically:YES];
	}];
	pthread_mutex_lock(&_mutex); --_running; int p=--_pending; pthread_mutex_unlock(&_mutex);
	if (p==0) [self performSelectorOnMainThread:@selector(postGen) withObject:nil waitUntilDone:NO];
	else [self performSelectorOnMainThread:@selector(inc) withObject:nil waitUntilDone:NO];
	[pool release];
}

// -----------------------------------------------------------------------------------
// Symbols set selection

- (NSArray*)sets {
	NSMutableArray* a = [NSMutableArray array];
	for (NSDictionary* d in _set) [a addObject:[d objectForKey:@"title"]];
	return a;
}

- (void)selectSet:(NSUInteger)idx {
	if (idx>=[_set count]) return;
	_btn = [[_set objectAtIndex:idx] objectForKey:@"data"];
	[self setNeedsDisplay:YES];
}

// -----------------------------------------------------------------------------------
// Mouse interations

- (void)mouseOver:(NSEvent*)evt {
	NSPoint p = [self convertPoint:evt.locationInWindow fromView:nil];
	int r,c,srow=-1,scol=-1; EBSel t=EBSelNone;
	NSSize fs = self.frame.size;
	NSSize ms = NSMakeSize((fs.width+1)/_mcol,(fs.height+1)/(_mrow+_brow));
	NSSize bs = NSMakeSize((fs.width+1)/_bcol,(fs.height+1)/(_mrow+_brow));
	double unit = round(fs.height/(_brow+_mrow));

	// If we are within submenu, ignore and pass selection to submenu
	if (_stype==EBSelMenu) {
		NSDictionary* dict = DMenu(_srow,_scol);
		int rows = [[dict objectForKey:@"rows"] intValue];
		int cols = [[dict objectForKey:@"cols"] intValue];
		NSRect sub = NSMakeRect(_scol*ms.width, fs.height-(_srow+1)*ms.height-round(unit*rows)+1, round(unit*cols)+1, round(unit*rows)+1);
		if (NSPointInRect(p, sub)) {
			r = (sub.origin.y+sub.size.height-p.y)/unit;
			c = (p.x-sub.origin.x)/unit;
			// Ensure we select only valid cells
			_ssub = r*cols+c;
			
			NSArray* data = [dict objectForKey:@"data"];
			if (_ssub>=[data count] || [[[data objectAtIndex:_ssub] objectForKey:@"title"] isEqualToString:@_EMPTY]) { _ssub=-1; r=-1; c=-1; }
			[_pop select:r col:c]; return;
		}
	}

	// Detect in which cell is the pointer and set it as selected
	for (r=0;r<_mrow&&t==EBSelNone;++r) for (c=0;c<_mcol&&t==EBSelNone;++c) {
		if (NSPointInRect(p, RRect(ms,c,_mrow+_brow-1-r,c+1,_mrow+_brow-r))) { srow=r; scol=c; t=EBSelMenu; }
	}
	for (r=0;r<_brow&&t==EBSelNone;++r) for (c=0;c<_bcol&&t==EBSelNone;++c) {
		if (NSPointInRect(p, RRect(bs,c,_brow-1-r,c+1,_brow-r))) { srow=r; scol=c; t=EBSelButton; }
	}
	switch (t) {
		case EBSelMenu: if (_mcol*srow+scol>=[_mnu count]) t=EBSelNone; break;
		case EBSelButton: if (!_btn || _bcol*srow+scol>=[_btn count]) t=EBSelNone; break;
		default: return;
	}

	// If seletion changed, take appropriate action
	if (_stype==EBSelMenu) { _ssub=-1; [_pop select:-1 col:-1]; }
	if (_stype==t && _scol==scol && _srow==srow) return;
	if (_stype==EBSelMenu) [_pop close];
	_stype=t; _scol=scol; _srow=srow;
	if (_stype==EBSelMenu) {
		NSDictionary* dict = DMenu(_srow,_scol);
		NSPoint pt = self.frame.origin;
		pt.x+= _scol==0?0:round(_scol*(fs.width+1)/_mcol);
		pt.y+= fs.height-(_srow+1)*unit-1;
		[_pop popupAt:[self.window convertBaseToScreen:pt] unit:unit dict:dict];
	}
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)evt { [self mouseOver:evt]; }
- (void)mouseDragged:(NSEvent *)evt { [self mouseOver:evt]; }
- (void)mouseUp:(NSEvent *)evt {
	NSDictionary* dict = nil;
	if (_stype==EBSelMenu) { if (_ssub!=-1) dict = [[DMenu(_srow,_scol) objectForKey:@"data"] objectAtIndex:_ssub]; [_pop close];	}
	if (_stype == EBSelButton) dict = DBtn(_srow,_scol);
	if (dict && delegate && [delegate respondsToSelector:@selector(bar:insert:)]) {
		[delegate performSelector:@selector(bar:insert:) withObject:self withObject:[dict objectForKey:@"value"]];
	}
	_stype = EBSelNone; _scol=-1; _srow=-1; _ssub=-1;
	[self setNeedsDisplay:YES];
}

// -----------------------------------------------------------------------------------
// Drawing methods

#define CELL_FAC 1.5
#define CELL_CONTENT NSImage* img = [dict objectForKey:@"image"]; if (!img) [[dict objectForKey:@"title"] drawInRect:br withAttributes:nil]; \
else { NSRect r=NSMakeRect(0,0,img.size.width,img.size.height), dr=NSInsetRect(br,1,1); \
if (br.size.width>=r.size.width*CELL_FAC && br.size.height>=r.size.height*CELL_FAC) { double w=r.size.width*CELL_FAC,h=r.size.height*CELL_FAC; \
	dr.origin.x+=(dr.size.width-w)/2.0; dr.size.width=w; dr.origin.y+=(dr.size.height-h)/2.0; dr.size.height=h; \
} else { \
	if (br.size.width/r.size.width>br.size.height/r.size.height) { double w=dr.size.height/r.size.height*r.size.width; dr.origin.x+=(dr.size.width-w)/2.0; dr.size.width=w; } \
	else { double h=dr.size.width/r.size.width*r.size.height; dr.origin.y+=(dr.size.height-h)/2.0; dr.size.height=h; } \
} [img drawInRect:dr fromRect:r operation:NSCompositeSourceOver fraction:1.0]; [img drawInRect:dr fromRect:r operation:NSCompositeSourceOver fraction:1.0]; }

- (void)drawRect:(NSRect)dirtyRect {
	int r,c;
	NSSize fs = self.frame.size;
	[[NSColor controlShadowColor] setFill];
	NSRectFill(NSMakeRect(0,0,fs.width,fs.height));
	NSRect br;
	NSDictionary* dict;
	// Menus
	NSSize ms = NSMakeSize((fs.width+1)/_mcol,(fs.height+1)/(_mrow+_brow));
	for (r=0;r<_mrow;++r) {
		for (c=0;c<_mcol;++c) {
			br = RRect(ms,c,_mrow+_brow-1-r,c+1,_mrow+_brow-r);
			[((_stype==EBSelMenu && _srow==r && _scol==c) ? _bgs: _bg) drawInRect:br angle:90];
			if ((dict = DMenu(r,c))) { CELL_CONTENT }
		}
	}
	// Buttons
	NSSize bs = NSMakeSize((fs.width+1)/_bcol,(fs.height+1)/(_mrow+_brow));
	for (r=0;r<_brow;++r) {
		for (c=0;c<_bcol;++c) {
			br = RRect(bs,c,_brow-1-r,c+1,_brow-r);
			[((_stype==EBSelButton && _srow==r && _scol==c) ? _bgs: _bg) drawInRect:br angle:90];
			if ((dict = DBtn(r,c)) && ![[dict objectForKey:@"title"] isEqualToString:@_EMPTY]) { CELL_CONTENT }
		}
	}
}

@end
