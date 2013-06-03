//
//  TexEditor.h
//  EquaTeX
//
//  Created by Thierry Coppey on 31.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TexEquation.h"

@protocol TexEditorDelegate;
@interface TexEditor : NSTextView {
@private
	BOOL highlight;
	NSDictionary* _aCom; // Single-line comments "%[^\n]\n"
	NSDictionary* _aBrk; // "{", "}"
	NSDictionary* _aKey; // tokens: $, \[, \]
	NSDictionary* _aCmd; // commands \[a-z0-9]+
	NSDictionary* _aMat; // (), [] \{ \} _ ^

	NSTimer* timer;
	NSObject<TexEditorDelegate>* delegate;
}

@property (retain) NSObject<TexEditorDelegate>* delegate;
@property (assign)BOOL highlight;
@end

@protocol TexEditorDelegate <NSObject>
@optional
- (void)texPreview:(TexEditor*)editor;
- (void)texCopy:(TexEditor*)editor;
- (NSString*)texPaste:(TexEditor*)editor; // return nil if there is nothing to paste
@end
