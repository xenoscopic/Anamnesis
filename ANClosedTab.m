#import "ANClosedTab.h"
#import <WebKit/WebKit.h>


@interface ANClosedTab ()

-(void)scrapeTab:(NSTabViewItem*)tab;
-(void)recreateTabInWebView:(WebView*)webView andTab:(NSTabViewItem*)tab;

@end


@implementation ANClosedTab

-(id)init
{
	return [self initWithTab:nil];
}

-(id)initWithTab:(NSTabViewItem*)tab
{
	isValid = NO;
	if((self = [super init]) && tab != nil) //if tab == nil, just leave ivars initialized to nil
	{
		history = [[NSMutableArray alloc] init];
		[self scrapeTab:tab];
		isValid = YES;
	}
	return self;
}

-(void)dealloc
{
	[history release];
	[super dealloc];
}

+(id)closedTabWithTab:(NSTabViewItem*)tab
{
	return [[[ANClosedTab alloc] initWithTab:tab] autorelease];
}

-(void)reinstateTabInWindowController:(id)windowController;
{
	if(!isValid)
	{
		return;
	}
	
	//We have to grab this BEFORE creating the new tab because
	//the new tab is automatically selected
	NSTabViewItem* selected = [tabView selectedTabViewItem];
	NSInteger currentTabCount = [tabView numberOfTabViewItems];
	
	//Create the new tab.  This call returns a BrowserWebView
	//which inherits from WebView.
	WebView* webView = [windowController createTab];
	
	//Find the actual BrowserTabViewItem.  This guy inherits from
	//NSTabViewItem.
	NSArray* orderedWebViews = [windowController orderedTabs];
	NSUInteger newTabIndex = NSNotFound, i = 0;
	for(WebView* wv in orderedWebViews)
	{
		if(wv == webView)
		{
			newTabIndex = i;
			break;
		}
		i++;
	}
	if(newTabIndex == NSNotFound)
	{
		//This probably shouldn't happen, but worst case
		//we'll create an empty tab.
		return;
	}
	//Otherwise we found the tab view item
	NSTabViewItem* tab = [[windowController orderedTabViewItems] objectAtIndex:newTabIndex];
	
	//Recreate the tab as best as possible
	[self recreateTabInWebView:webView andTab:tab];
	
	//Try to reinstate the tab at the index it was at.  If this isn't possible,
	//then leave it at the end.  You might think intuitively that it wouldn't
	//be possible for the index to be out of range, but if a tab is dragged out
	//of a window, it's a very real possibility.
	if(tabIndex <= currentTabCount)
	{
		[tab retain];
		[tabView removeTabViewItem:tab];
		[tabView insertTabViewItem:tab atIndex:tabIndex];
		[tab release];
	}
	
	//Switch to the reinstated tab to trigger a tab bar redraw.  If it was
	//focused when closed, keep it that way.
	[tabView selectTabViewItem:tab];
	if(!wasFocused)
	{
		[tabView selectTabViewItem:selected];
	}
}

-(void)scrapeTab:(NSTabViewItem*)tab
{
	//tab is actually a BrowserTabViewItem
	//webView is actually a BrowserWebView
	WebView* webView = [tab webView];
	
	//Grab location and focus information
	tabView = [tab tabView];
	tabIndex = [tabView indexOfTabViewItem:tab];
	wasFocused = (tab == [tabView selectedTabViewItem]);
	
	//Grab history
	WebBackForwardList* bfl = [[webView backForwardList] retain];
	NSInteger i;
	for(i=-[bfl backListCount];i<=[bfl forwardListCount];i++)
	{
		WebHistoryItem* oldItem = [bfl itemAtIndex:i];
		//Don't add empty WebHistoryItems (i.e. newly created ones)
		if([oldItem URLString] == nil)
		{
			continue;
		}
		WebHistoryItem* newItem = [[WebHistoryItem alloc] initWithURLString:[oldItem URLString] title:[oldItem title] lastVisitedTimeInterval:[oldItem lastVisitedTimeInterval]];
		[history addObject:newItem];
		[newItem release]; //history will retain it for us
		if(i == 0)
		{
			currentHistoryItem = newItem;
		}
	}
}

-(void)recreateTabInWebView:(WebView*)webView andTab:(NSTabViewItem*)tab
{
	//Recreate history
	WebBackForwardList* newHistory = [webView backForwardList];
	
	for(WebHistoryItem* whi in history)
	{
		//NSLog(@"Adding history item %p for %@", whi, [whi URLString]);
		[newHistory addItem:whi];
	}
	
	if(currentHistoryItem != nil)
	{
		//NSLog(@"Going to item %p for %@", currentHistoryItem, [currentHistoryItem URLString]);
		[webView goToBackForwardItem:currentHistoryItem];
	}
}

@end
