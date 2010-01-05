#import <Cocoa/Cocoa.h>

@class WebBackForwardList;

/*
 * Class representing a single closed tab in a window.  Instantiating
 * this class will not actually close the tab.  Rather this class acts
 * to "scrape" the tab for all information needed to reconstruct it.
 */
@interface ANClosedTab : NSObject
{
	BOOL isValid;
	
	//Have to hold onto this here because we can't get it in time laster
	NSTabView* tabView;
	NSInteger tabIndex;
	BOOL wasFocused;
	NSMutableArray* history;
	NSUInteger currentHistoryIndex;
}

-(id)initWithTab:(NSTabViewItem*)tab;
+(id)closedTabWithTab:(NSTabViewItem*)tab;

//windowController should be a BrowserWindowController
-(void)reinstateTabInWindowController:(id)windowController;

@end
