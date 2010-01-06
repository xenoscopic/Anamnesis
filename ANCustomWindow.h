#import <Cocoa/Cocoa.h>

@interface NSWindowController (ANCustomWindow)

+(void)ANSwizzleANCustomWindow;

//_safari_ methods are not actually implemented, I just use them as handles for swizzling.
//_anamnesis_ methods are swizzling wrappers.

-(void)_safari_closeTab:(id)arg1;
-(void)_anamnesis_closeTab:(id)arg1;

-(void)_safari_windowWillClose:(id)arg1;
-(void)_anamnesis_windowWillClose:(id)arg1;

-(BOOL)canReopenLastTab;

-(void)ANReopenLastClosedTab;

@end
