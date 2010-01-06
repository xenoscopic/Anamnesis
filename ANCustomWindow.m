#import "ANCustomWindow.h"
#import "JRSwizzle.h"
#import "ANClosedTab.h"

//This dictionary acts as a faux-ivar for the ANCustomWindow category.
//We can't initialize it in init and destroy it in dealloc 
//since BrowserWindowController implements dealloc and may later 
//implement init.  Thus we just check that it's globally initialized 
//in the swizzled closeTab and remove the relevant window stack on
//a swizzled windowWillClose.  This dictionary maps the object pointer
//(in an NSNumber) to an NSMutableDictionary that maps strings representing
//ivars to the values for that object.
static NSMutableDictionary* ancw_fakeIvar = nil;

void ancw_checkIvarInit()
{
	if(ancw_fakeIvar == nil)
	{
		ancw_fakeIvar = [[NSMutableDictionary alloc] init];
	}
}

NSMutableDictionary* ancw_ivarDictForObject(id obj)
{
	ancw_checkIvarInit();
	
	NSMutableDictionary* ret = [ancw_fakeIvar objectForKey:[NSNumber numberWithInteger:(NSInteger)obj]];	
	if(ret == nil)
	{
		//There is no entry for this object yet, create it
		ret = [NSMutableDictionary dictionary];
		//This should retain it
		[ancw_fakeIvar setObject:ret forKey:[NSNumber numberWithInteger:(NSInteger)obj]];
	}
	
	return ret;
}

void ancw_deleteIvarDictForObject(id obj)
{
	ancw_checkIvarInit();
	
	[ancw_fakeIvar removeObjectForKey:[NSNumber numberWithInteger:(NSInteger)obj]];
}

//Convenience method for the only actual ivar
NSMutableArray* ancw_closedTabStackForObject(id obj)
{
	NSMutableDictionary* ivars = ancw_ivarDictForObject(obj);
	
	NSMutableArray* ret = [ivars objectForKey:@"closedTabStack"];
	if(ret == nil)
	{
		//Create the ivar
		ret = [NSMutableArray array];
		[ivars setObject:ret forKey:@"closedTabStack"];
	}
	
	return ret;
}

@implementation NSWindowController (ANCustomWindow)

+(void)ANSwizzleANCustomWindow
{
	//Swizzle closeTab
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(_safari_closeTab:) withMethod:@selector(closeTab:) error:NULL];
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(closeTab:) withMethod:@selector(_anamnesis_closeTab:) error:NULL];
	
	//Swizzle close window
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(_safari_windowWillClose:) withMethod:@selector(windowWillClose:) error:NULL];
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(windowWillClose:) withMethod:@selector(_anamnesis_windowWillClose:) error:NULL];
}

-(void)_anamnesis_closeTab:(id)arg1
{
	//arg1 should be a BrowserTabViewItem
	NSMutableArray* tabStack = ancw_closedTabStackForObject(self);
	//Creating this ANClosedTab object will close the tab
	[tabStack addObject:[ANClosedTab closedTabWithTab:arg1]];
	
	//Call the actual "super" method
	[self _safari_closeTab:arg1];
}

-(void)_anamnesis_windowWillClose:(id)arg1
{
	//It should be safe to deallocate here because apparently
	//closeTab isn't called for each individual tab inside a closing
	//window, thus the dictionary being deleted won't have a detremental
	//effect.  In either case it would just be reallocated.  In the future
	//we can have an "isClosing" boolean if we have to so that
	//if something trys to access the dictionary later, it will know not
	//to reallocate it.
	ancw_deleteIvarDictForObject(self);
	[self _safari_windowWillClose:arg1];
}

-(void)ANReopenLastClosedTab
{
	//Grab the tab stack and reopen the last entry
	NSMutableArray* closedTabStack = ancw_closedTabStackForObject(self);
	
	//If it's empty, our work is done
	if([closedTabStack count] == 0)
	{
		return;
	}
	
	ANClosedTab* closedTab = [closedTabStack lastObject];
	[closedTab reinstateTabInWindowController:self];
	
	[closedTabStack removeLastObject];
}

-(BOOL)canReopenLastTab
{
	if([ancw_closedTabStackForObject(self) count] == 0)
	{
		//There are no closed tabs to reopen
		return NO;
	}
	return YES;
}

//Swizzling handles
-(void)_safari_closeTab:(id)arg1{}
-(void)_safari_windowWillClose:(id)arg1{}

@end
