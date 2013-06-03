//
//  EquationBar.h
//  EquaTeX
//
//  Created by Thierry Coppey on 28.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TexEquation.h"
#include <pthread.h>

typedef enum { EBSelNone, EBSelMenu, EBSelButton } EBSel;

@class EquationBar, EquationPopup;
@protocol EquationBarDelegate
@optional
- (void)bar:(EquationBar*)bar insert:(NSString*)str;
@end

@interface EquationBar : NSView {
@private
	TexEquation* _gen;
	EquationPopup* _pop;
	NSObject<EquationBarDelegate>* delegate;
	// also have a parent to cancel mouse event
	NSGradient *_bg,*_bgs;
	int _mrow,_mcol; // menu
	int _brow,_bcol; // button
	int _srow,_scol,_ssub; // selection
	EBSel _stype;
	NSMutableArray* _mnu;
	NSMutableArray* _set;
	__weak NSArray* _btn; // current selected set

	// Labels generation
	NSProgressIndicator* _pb;
	NSString* _path;
	pthread_mutex_t _mutex;
	int _pending;
	int _running;
	int _ncpu;
}

@property (retain)IBOutlet NSObject<EquationBarDelegate>* delegate;
- (void)generateSymbols:(TexEquation*)generator; // Generates all missing symbols

- (NSArray*)sets; // symbols sets name
- (void)selectSet:(NSUInteger)idx;


@end

