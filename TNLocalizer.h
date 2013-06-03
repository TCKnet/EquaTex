//
//  TNLocalizer.h
//  EquaTeX
//
//  Created by Thierry Coppey on 30.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define Str(X) [[NSBundle mainBundle] localizedStringForKey:(X) value:@"" table:nil]


@interface TNLocalizer : NSObject {
@private
	NSBundle* _bundle;
}

- (id)initWithBundle:(NSBundle*)bundle;
- (void)localize:(NSObject*)obj with:(NSString*)table;
- (void)localize:(NSObject*)obj with:(NSString*)table exclude:(NSArray*)array;

@end
