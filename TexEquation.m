//
//  TexEquation.m
//  EquaTeX
//
//  Created by Thierry Coppey on 25.05.11.
//  Copyright 2011 TCKnetwork. All rights reserved.
//

#import "TexEquation.h"
#define PBPages09Obj @"SFVNativePBObject09"

// -----------------------------------------------------------------------------------
// Pages09 pasteboard template

static const char* Pages09Template = "<?xml version=\"1.0\"?>"
"<sl:copied-data xmlns:sfa=\"http://developer.apple.com/namespaces/sfa\" xmlns:sf=\"http://developer.apple.com/namespaces/sf\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:sl=\"http://developer.apple.com/namespaces/sl\" sl:version=\"92008102400\" sfa:ID=\"SFVPasteboardObject-0\" sf:application-name=\"Pages\" sf:text-primary=\"true\">"
	"<sf:stylesheets sfa:ID=\"NSArray-0\">"
		"<sf:stylesheet sfa:ID=\"SFSStylesheet-0\">"
			"<sf:styles>"
				"<sf:graphic-style sfa:ID=\"SFDGraphicStyle-0\" sf:name=\"graphic-image-style-default\" sf:ident=\"graphic-image-style-default\">"
					"<sf:property-map><sf:opacity><sf:number sfa:number=\"1\" sfa:type=\"f\"/></sf:opacity></sf:property-map>"
				"</sf:graphic-style>"
			"</sf:styles>"
			"<sf:anon-styles>"
				"<sf:characterstyle sfa:ID=\"SFWPCharacterStyle-1\">"
					"<sf:property-map>"
						//"<sf:atsuFontFeatures><sf:mdata sfa:ID=\"NSMutableData-0\" sl:b64data=\"%%DATA%%\"/></sf:atsuFontFeatures>"
						//"<sf:fontName><sf:string sfa:string=\"%%DATA%%\"/></sf:fontName>-->"
						"<sf:baselineShift><sf:decimal-number sfa:number=\"%%BASE%%\" sfa:type=\"d\"/></sf:baselineShift>"
					"</sf:property-map>"
				"</sf:characterstyle>"
			"</sf:anon-styles>"
		"</sf:stylesheet>"
	"</sf:stylesheets>"
	"<sf:drawables sfa:ID=\"NSMutableArray-0\">"
		"<sf:media sfa:ID=\"SFDImageInfoDowngrader-0\">"
			"<sf:geometry sfa:ID=\"SFDAffineGeometry-0\" sf:aspectRatioLocked=\"true\">"
				"<sf:naturalSize sfa:w=\"%%WIDTH%%\" sfa:h=\"%%HEIGHT%%\"/>"
				"<sf:size sfa:w=\"%%WIDTH%%\" sfa:h=\"%%HEIGHT%%\"/>"
				"<sf:position sfa:x=\"0\" sfa:y=\"0\"/>"
			"</sf:geometry>"
			"<sf:style><sf:graphic-style-ref sfa:IDREF=\"SFDGraphicStyle-0\"/></sf:style>"
			"<sf:content>"
				"<sf:image-media sfa:ID=\"SFDImageMedia-0\">"
				"<sf:filtered-image sfa:ID=\"SFRFilteredImage-0\">"
					"<sf:unfiltered sfa:ID=\"SFRImageBinary-0\">"
						"<sf:size sfa:w=\"%%WIDTH%%\" sfa:h=\"%%HEIGHT%%\"/>"
						"<sf:data sfa:ID=\"SFEData-0\" sf:path=\"%%PATH%%\" sf:displayname=\"%%FILE%%\" sf:size=\"%%SIZE%%\">"
							"<sf:original-alias sfa:ID=\"SFEFileAlias-0\" sf:file-alias=\"%%ALIAS%%\"/>"
						"</sf:data>"
					"</sf:unfiltered>"
				"</sf:filtered-image>"
			"</sf:image-media>"
			"</sf:content>"
		"</sf:media>"
	"</sf:drawables>"
	"<sf:text sfa:ID=\"SFWPStorage-0\" sf:kind=\"body\" sf:class=\"text-storage\">"
		"<sf:stylesheet-ref sfa:IDREF=\"SFSStylesheet-0\"/>"
		"<sf:attachments>"
			"<sf:attachment sfa:ID=\"SFDDrawableAttachment-0\" sf:kind=\"drawable-attachment\">"
				"<sf:media-ref sfa:IDREF=\"SFDImageInfoDowngrader-0\"/>"
			"</sf:attachment>"
		"</sf:attachments>"
		"<sf:text-body><sf:section><sf:layout><sf:p><sf:span sf:style=\"SFWPCharacterStyle-1\">"
			"<sf:bookmark sf:name=\"%%DATA%%\" sf:ranged=\"true\" sf:page=\"1\" sfa:ID=\"SFWPBookmarkField-0\">"
			//"<sf:link href=\"latex://%%DATA%%\">"
				"<sf:attachment sfa:ID=\"SFDDrawableAttachment-0\" sf:kind=\"drawable-attachment\">"
					"<sf:media-ref sfa:IDREF=\"SFDImageInfoDowngrader-0\"/>"
				"</sf:attachment>"
			//"</sf:link>"
			"</sf:bookmark>"
		"</sf:span></sf:p></sf:layout></sf:section></sf:text-body>"
	"</sf:text>"
	"<sl:app-native-object sfa:ID=\"SLPasteboardObject-0\" sl:text-primary=\"true\" sf:class=\"sl-native-pasteboard-object\"><sf:stylesheet-ref sfa:IDREF=\"SFSStylesheet-0\"/></sl:app-native-object>"
"</sl:copied-data>";

// -----------------------------------------------------------------------------------

@implementation TexEquation
@synthesize color=_col;

- (id)init {
	self = [super init];
	if (self) { _xetex=NO; _la=_xe=_gs=nil; }
	return self;
}

- (void)dealloc {
	if (_la) [_la release];
	if (_xe) [_xe release];
	if (_gs) [_gs release];
	if (_eq) [_eq release];
	if (_data) [_data release];
	[super dealloc];
}

- (void)setProcessor:(BOOL)xetex latex:(NSString*)laPath xetex:(NSString*)xePath gs:(NSString*)gsPath {
	NSFileManager* fm = [NSFileManager defaultManager];
	if (laPath && ![laPath isEqualToString:@""] && [fm isExecutableFileAtPath:laPath]) { if (_la) [_la release]; _la=[laPath retain]; }
	if (xePath && ![xePath isEqualToString:@""] && [fm isExecutableFileAtPath:xePath]) { if (_xe) [_xe release]; _xe=[xePath retain]; }
	if (gsPath && ![gsPath isEqualToString:@""] && [fm isExecutableFileAtPath:gsPath]) { if (_gs) [_gs release]; _gs=[gsPath retain]; }
	_xetex = xetex && _xe!=nil;
}

- (BOOL)hasProcessor { return _la && _gs; }

// -----------------------------------------------------------------------------------

- (NSString*)base64Encode:(NSData*)data {
	const unsigned char a[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",*d=(const unsigned char*)[data bytes];
	size_t i,n = [data length]; unsigned long s; char *r,*p; if (!(r=(char*)malloc(4*(n/3+(n%3?1:0))+1))) return NULL; r[0]=0; p=r;
	for(i=0;i+2<n;i+=3,p+=4) { s=(d[i]<<16)+(d[i+1]<<8)+d[i+2]; snprintf(p,5,"%c%c%c%c",a[(s>>18)&0x3f],a[(s>>12)&0x3f],a[(s>>6)&0x3f],a[s&0x3f]); }
	if (i<n) { s=(d[i]<<16)+(i+1<n?d[i+1]<<8:0); snprintf(p,5,"%c%c%c%c",a[(s>>18)&0x3f],a[(s>>12)&0x3f],i+1<n?a[(s>>6)&0x3f]:'=','='); }
	NSString* res = [NSString stringWithUTF8String:r]; free(r); return res;
}

- (NSData*)base64Decode:(NSString*)str {
	const char* text = [str UTF8String];
	unsigned char* r; unsigned long s=0,v; size_t i,l=strlen(text),n,o=0; if (!l) return 0;
	n=l/4*3-(text[l-1]=='=')-(text[l-2]=='='); if (!(r=(unsigned char*)malloc(n))) return 0;
	for (i=0;i<l&&o<n;i++) {
		v=text[i]; if (v>='A'&&v<='Z') v-='A'; else if (v>='a'&&v<='z') v-='a'-26; else if (v>='0'&&v<='9') v-='0'-52; else if (v=='+') v=62; else if (v=='/') v=63; else v=0; s=(s<<6)+v;
		if (i%4==3) { r[o++]=(unsigned char)(s>>16); if (o<n) r[o++]=(unsigned char)(s>>8); if (o<n) r[o++]=(unsigned char)s; s=0; }
	}
	NSData* res = [NSData dataWithBytes:r length:n]; free(r); return res;
}

// -----------------------------------------------------------------------------------

- (NSData*)dataPages09:(NSString*)path size:(NSSize)size base:(int)base {
	NSString* file = [path lastPathComponent];
	NSString* doc = [NSString stringWithUTF8String:Pages09Template];
	//NSString* doc = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Pages09" ofType:@"xml"] encoding:NSUTF8StringEncoding error:nil];
	doc = [doc stringByReplacingOccurrencesOfString:@"%%BASE%%" withString:[NSString stringWithFormat:@"%d",base]];
	doc = [doc stringByReplacingOccurrencesOfString:@"%%WIDTH%%" withString:[NSString stringWithFormat:@"%.0f",size.width]];
	doc = [doc stringByReplacingOccurrencesOfString:@"%%HEIGHT%%" withString:[NSString stringWithFormat:@"%.0f",size.height]];
	NSString* eq_enc = [NSString stringWithFormat:@"EQ_%@_EQ",[self base64Encode:[_eq dataUsingEncoding:NSUTF8StringEncoding]]];
	doc = [doc stringByReplacingOccurrencesOfString:@"%%DATA%%" withString:eq_enc];
	doc = [doc stringByReplacingOccurrencesOfString:@"%%PATH%%" withString:path];
	doc = [doc stringByReplacingOccurrencesOfString:@"%%FILE%%" withString:file];
	NSDictionary* info = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
	doc = [doc stringByReplacingOccurrencesOfString:@"%%SIZE%%" withString:[NSString stringWithFormat:@"%lld",[info fileSize]]];

	// Hex encode data
	NSMutableString* data = [NSMutableString string];
	Boolean isDir = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	AliasHandle alias; FSNewAliasFromPath(NULL, [path UTF8String], 0, &alias, &isDir);
	const unsigned char* b=(const unsigned char*)*alias; unsigned char ch[2];
	for (size_t i=0,n=GetAliasSizeFromPtr(*alias);i<n;++i) {
#pragma clang diagnostic pop
		ch[0]=b[i]/16; ch[0]+=(ch[0]>9)?'a'-10:'0';
		ch[1]=b[i]%16; ch[1]+=(ch[1]>9)?'a'-10:'0';
		[data appendFormat:@"%c%c",ch[0],ch[1]];
	}
	return [[doc stringByReplacingOccurrencesOfString:@"%%ALIAS%%" withString:data] dataUsingEncoding:NSUTF8StringEncoding];
}

- (int)exec:(NSString*)path args:(NSArray*)args dir:(NSString*)dir output:(NSString**)str {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:path]; [task setArguments:args]; [task setCurrentDirectoryPath:dir];
	if (_xetex) { // xelatex invokes an utility in its own folder
		NSString* mypath = [NSString stringWithFormat:@"%s:%@",getenv("PATH"),[path stringByDeletingLastPathComponent]];
		[task setEnvironment:[NSDictionary dictionaryWithObject:mypath forKey:@"PATH"]];
	}

	NSString* res = nil;
	NSPipe* p = nil; if (str) p=[NSPipe pipe];
	NSFileHandle* fn = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];
	[task setStandardInput:fn];
	[task setStandardOutput:str ? p : fn];
	[task setStandardError:str ? p : fn];
	[task launch];
	if (p) {
		[[p fileHandleForWriting] closeFile];
		NSMutableData* data = [[NSMutableData alloc] init];
		while ([task isRunning]) [data appendData:[[p fileHandleForReading] availableData]];
		[data appendData:[[p fileHandleForReading] readDataToEndOfFile]];
		[[p fileHandleForReading] closeFile];
		res = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (res) [res autorelease]; [data release];
	} else while ([task isRunning]) usleep(10000);
	int status = [task terminationStatus];
	//if (status) NSLog(@"task %@ failed with %d",[task launchPath],[task terminationStatus]);
	[task release];
	if (str) *str=res;
	return status;
}

// -----------------------------------------------------------------------------------

- (void)generate:(NSString*)eq mode:(TexMode)mode size:(double)size { [self generate:eq mode:mode size:size block:nil]; }
- (void)generate:(NSString*)eq mode:(TexMode)mode size:(double)size block:(void (^)(NSData*,NSArray*))block {
	if (!_gs || !_la) return;
	char tmp_dir[32] = "/tmp/eq.XXXXXX"; if (!mkdtemp(tmp_dir)) return;
	NSString* tmp=[NSString stringWithUTF8String:tmp_dir];

	// -----------------------------------------
	// 1. Write tex file
	NSString* eq_pre,*eq_post;
	switch (mode) {
		case TexModeDisplay: eq_pre=@"\\["; eq_post=@"\\]"; break;
		case TexModeInline : eq_pre=@"$"; eq_post=@"$"; break;
		case TexModeArray  : eq_pre=@"\\begin{eqnarray*}"; eq_post=@"\\end{eqnarray*}"; break;
		case TexModeAlign  : eq_pre=@"\\begin{align*}"; eq_post=@"\\end{align*}"; break;
		case TexModeAlgo   : eq_pre=@"\\begin{algorithmic}[1]"; eq_post=@"\\end{algorithmic}"; break;
		default            : eq_pre=@""; eq_post=@""; break;
	}

	BOOL stdSize = (fabs(size-10)<0.01 || fabs(size-11)<0.01 || fabs(size-12)<0.01);
	NSString* proc = _xetex ? _xe : _la;
	NSString* head = [NSString stringWithFormat:@"\\documentclass[%fpt]{article}\n%@\\usepackage[usenames]{color}\n\\usepackage{algorithm,algorithmic}\n\\usepackage[normalem]{ulem}\n\\usepackage{cancel}\n\\usepackage{esint}\n",stdSize ? size : 10,
							_xetex ? @"\\usepackage{fontspec}\n\\usepackage{amsmath}\n" : @"\\usepackage{amssymb,amsmath}\n\\usepackage[utf8]{inputenc}\n"];
	
	if (_col!=nil) {
		CGFloat c[4]; [_col getRed:c+0 green:c+1 blue:c+2 alpha:c+3];
		eq_pre = [NSString stringWithFormat:@"\\definecolor{myequationcolor}{rgb}{%f,%f,%f}\n\\color{myequationcolor}\n%@",c[0],c[1],c[2],eq_pre];
	}
		
	NSString* text = [NSString stringWithFormat:@"%@\\usepackage[papersize={2000pt,1000pt},margin=0pt]{geometry}\n\\pagestyle{empty}\n\\begin{document}\n%@%@%@\n\\end{document}\n",head,eq_pre,eq,eq_post];
	if (!stdSize && (mode==TexModeInline || mode==TexModeText)) { // Special font sizes
		head = [head stringByAppendingString:@"\\usepackage{graphicx}\n"];
		text = [NSString stringWithFormat:@"%@\\usepackage[papersize={10000pt,10000pt},margin=0pt]{geometry}\n\\pagestyle{empty}\n\\begin{document}\n\\scalebox{%f}{%@%@%@}\n\\end{document}\n",head,size/10,eq_pre,eq,eq_post];
	}
	NSString* path = [tmp stringByAppendingPathComponent:@"eq.tex"];
	if (![text writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil]) goto cleanup;

	// -----------------------------------------
	// 2. Process tex file
	if ([self exec:proc args:[NSArray arrayWithObjects:@"-file-line-error", @"-interaction", @"nonstopmode", @"eq.tex",nil] dir:tmp output:&text]) {
		NSMutableArray* err=[NSMutableArray array];
		const char*s=[text UTF8String],*p,*q=s;
		while((p=strchr(q,':'))) {
			++p;
			while (*p>='0'&&*p<='9') ++p;
			if (*p==':') {
				++p; while(*p==' ') ++p;
				q=strchr(p,'\n');
				if (q) {
					NSString* e = [[NSString alloc] initWithBytes:p length:q-p encoding:NSUTF8StringEncoding];
					[err addObject:e];
					[e release];
				}
			} else q=p;
		}
		if (block) block(nil,err);
		return;
	}

	// -----------------------------------------
	// 3. Compute bounding box
	#define BBOX_ADJUST 0.5 // adjust height
	[self exec:_gs args:[NSArray arrayWithObjects:@"-dNOPAUSE",@"-dSAFER",@"-dNOPLATFONTS",@"-sDEVICE=bbox",@"-dBATCH",@"-q",@"eq.pdf",nil] dir:tmp output:&text];
	char *q,*p=strstr([text UTF8String],"%%HiResBoundingBox: "); if (!p) return; p+=20; double bbox[4];
	bbox[0] = strtod(p,&q); if (!q||p==q) return; while (*q==' ') ++q;
	bbox[1] = strtod(q,&p)-BBOX_ADJUST; if (!p||p==q) return; while (*p==' ') ++p;
	bbox[2] = strtod(p,&q); if (!q||p==q) return; while (*q==' ') ++q;
	bbox[3] = strtod(q,&p)+BBOX_ADJUST*2; if (!p||p==q) return;
	//NSLog(@"BBox = %f %f %f %f",bbox[0],bbox[1],bbox[2],bbox[3]);

	// -----------------------------------------
	// 4. Baseline detection (might fail if equation format is not suitable)
	double base = -1; // baseline
	if (mode==TexModeInline || mode==TexModeText) {
		text = [NSString stringWithFormat:@"%@\\newsavebox{\\eqbox}\\newlength{\\baseline}\\normalfont\\begin{lrbox}{\\eqbox}\n"
					"%@%@%@\n\\end{lrbox}\\settodepth{\\baseline}{\\usebox{\\eqbox}}\\newwrite\\foo\\immediate\\openout\\foo=\\jobname.size\n"
					"\\immediate\\write\\foo{\\the\\baseline}\\closeout\\foo\\begin{document}.\\end{document}",head,eq_pre,eq,eq_post];
		path = [tmp stringByAppendingPathComponent:@"base.tex"];
		if (![text writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil]) goto cleanup;
		if (![self exec:proc args:[NSArray arrayWithObject:@"base.tex"] dir:tmp output:nil]) {
			base = [[NSString stringWithContentsOfFile:[tmp stringByAppendingPathComponent:@"base.size"] encoding:NSUTF8StringEncoding error:nil] doubleValue]+BBOX_ADJUST;
		}
	}

	// -----------------------------------------
	// 5. Create XML metadata to be attached
	NSString* enc = [self base64Encode:[eq dataUsingEncoding:NSUTF8StringEncoding]];
	text = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><latex encoding=\"base64\">%@</latex>",enc];
	path=[tmp stringByAppendingPathComponent:@"eq.xml"];
	if (![text writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil]) goto cleanup;

	// -----------------------------------------
	// 6. Create wrapper
	NSSize sz = NSMakeSize(ceil(bbox[2]-bbox[0]), ceil(bbox[3]-bbox[1]));
	text = [NSString stringWithFormat:@"\\pdfoutput=1\\pdfcompresslevel=9\\csname pdfmapfile\\endcsname{}\n"
			"\\def\\page #1 [#2 #3 #4 #5]{\n\\setbox0=\\hbox{\\pdfximage page 1{eq.pdf}\\pdfrefximage\\pdflastximage}\n"
			"  \\pdfhorigin=-#2\\pdfvorigin=#3\\pdfpagewidth=#4\\advance\\pdfpagewidth by -#2\n"
			"  \\pdfpageheight=#5\\advance\\pdfpageheight by -#3\\ht0=\\pdfpageheight\\shipout\\box0\\relax\n}\n"
			"\\def\\pageclip #1 [#2 #3 #4 #5]{\n"
			"  \\dimen0=#4\\advance\\dimen0 by -#2\\edef\\imagewidth{\\the\\dimen0}\n"
			"  \\dimen0=#5\\advance\\dimen0 by -#3\\edef\\imageheight{\\the\\dimen0}\n"
			"  \\pdfximage page 1{eq.pdf}\n"
			"  \\setbox0=\\hbox{\n\\kern -#2\n\\lower #3\\hbox{\\pdfrefximage\\pdflastximage}\n}\n"
			"  \\wd0=\\imagewidth\\ht0=\\imageheight\\dp0=0pt\n"
			"  \\pdfhorigin=0pt\\pdfvorigin=0bp\\pdfpagewidth=\\imagewidth\\pdfpageheight=\\imageheight\n"
			"  \\pdfxform0\\relax\\shipout\\hbox{\\pdfrefxform\\pdflastxform}\n}\n"
			"\\begingroup\\pdfcompresslevel=0\\immediate\n"
			"\\pdfobj stream attr {/Type /Metadata /Subtype /XML}file{eq.xml}\n"
			"\\pdfcatalog{/Metadata \\the\\pdflastobj\\space 0 R}\\endgroup\n"
			"\\pageclip 1 [%fbp %fbp %fbp %fbp]\n"
			"\\csname @@end\\endcsname\n\\end\n",bbox[0],bbox[1],bbox[2],bbox[3]];
	path = [tmp stringByAppendingPathComponent:@"wrap.tex"];
	if (![text writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil]) goto cleanup;

	// -----------------------------------------
	// 7. Compile wrapper, requires to be processed with pdflatex
	[self exec:_la args:[NSArray arrayWithObject:@"wrap.tex"] dir:tmp output:nil];

	// -----------------------------------------
	// 8. Store in memory
	NSData* data = [[NSData alloc] initWithContentsOfFile:[tmp stringByAppendingPathComponent:@"wrap.pdf"]];
	@synchronized(self) {
		if (_eq) [_eq release];
		_eq = [eq copy];
		if (_data) [_data release];
		_data = data;
		_size = NSMakeRect(0,base,sz.width,sz.height);
		if (block) block(_data,nil);
	}
cleanup:
	[[NSFileManager defaultManager] removeItemAtPath:tmp error:nil];
}

// -----------------------------------------------------------------------------------

- (double)baseline { return _size.origin.y; }
- (NSImage*)image { NSImage* img; @synchronized(self) { img=[[NSImage alloc] initWithData:_data]; } return [img autorelease]; }

- (void)copy:(double)baseline {
	NSString* cache = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:cache]) [fm createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
	NSString* pdfFile=[cache stringByAppendingPathComponent:@"EquaTeX.pdf"];
	@synchronized(self) {
		if (_data==nil) return; [_data writeToFile:pdfFile atomically:YES];
		NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
		[pb declareTypes:[NSArray arrayWithObjects:PBPages09Obj, NSPDFPboardType, NSStringPboardType, nil] owner:nil];
		[pb setData:_data forType:NSPDFPboardType];
		[pb setString:_eq forType:NSStringPboardType];
		[pb setData:[self dataPages09:pdfFile size:_size.size base:-ceil(baseline)] forType:PBPages09Obj];
	}
}

- (NSString*)metaFromPDF:(NSData*)data {
	if (data==nil) return nil;
	size_t i,n = [data length];
	
	// XXX: parse XML document instead (?)
	const char *b=(const char*)[data bytes],*s=NULL,*e=NULL;
	for (i=0;i<n-8;i++) if (b[i]=='<') {
		if (!strncasecmp(b+i, "<latex", 6)) { i+=6; while(i<n&&b[i]!='>') ++i; s=b+i+1; }
		else if (!strncasecmp(b+i, "</latex>", 8)) { e=b+i; if (s) break; }
	}
	if (!s||!e) return nil;
	NSString* enc = [[NSString alloc] initWithBytes:s length:e-s encoding:NSUTF8StringEncoding];
	NSString* eq = [[NSString alloc] initWithData:[self base64Decode:enc] encoding:NSUTF8StringEncoding];
	[enc release]; return [eq autorelease];
}

- (NSString*)paste {
	NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	// -----------------------------------------
	// 1. Decode Pages09 XML (hidden in the font)
	NSString* str=[pb stringForType:PBPages09Obj];
	if (str!=nil) {
		// XXX: parse XML document instead (?)
		NSString* eqs = nil;
		do {
			NSRange r1 = [str rangeOfString:@"=\"EQ_" /*@"sfa:string=\"EQ_"*/]; if (r1.length==0) break;
			NSString* sub = [str substringFromIndex:r1.location+r1.length];
			NSRange r2 = [sub rangeOfString:@"_EQ\""]; if (r2.length==0) break;
			NSString* eq_enc = [sub substringToIndex:r2.location];
			NSString* eq = [[NSString alloc] initWithData:[self base64Decode:eq_enc] encoding:NSUTF8StringEncoding];
			if (!eqs) eqs=[[eq retain] autorelease];
			else eqs = [eqs stringByAppendingFormat:@"\n%@",eq];
			[eq release];
			str = [sub substringFromIndex:r2.location+r2.length];
		} while(true);
		if (eqs) return eqs;
	}

	// -----------------------------------------
	// 2. Decode PDF metafile
	return [self metaFromPDF:[pb dataForType:NSPDFPboardType]];
}

- (void)saveAs:(NSString*)file {
	@synchronized(self) { if (_data==nil) return; [_data writeToFile:file atomically:YES]; }
}

- (NSString*)load:(NSString*)file {
	return [self metaFromPDF:[NSData dataWithContentsOfFile:file]];
}


@end
