#import <Cocoa/Cocoa.h>

@interface ANOpenLastTabPlugin : NSObject {

}

#pragma mark -
#pragma mark SIMBL methods
+(void)load;

#pragma mark -
#pragma mark Open Last Tab methods
-(void)reopenLastTab:(id)sender;

#pragma mark -
#pragma mark Singleton methods

+(ANOpenLastTabPlugin*)sharedInstance;

@end
