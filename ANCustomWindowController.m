/*
 * Copyright (c) 2010 Jacob Howard
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ANCustomWindowController.h"
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
static NSMutableDictionary* ancwc_fakeIvar = nil;

void ancwc_checkIvarInit()
{
	if(ancwc_fakeIvar == nil)
	{
		ancwc_fakeIvar = [[NSMutableDictionary alloc] init];
	}
}

NSMutableDictionary* ancwc_ivarDictForObject(id obj)
{
	ancwc_checkIvarInit();
	
	NSMutableDictionary* ret = [ancwc_fakeIvar objectForKey:[NSNumber numberWithInteger:(NSInteger)obj]];	
	if(ret == nil)
	{
		//There is no entry for this object yet, create it
		ret = [NSMutableDictionary dictionary];
		//This should retain it
		[ancwc_fakeIvar setObject:ret forKey:[NSNumber numberWithInteger:(NSInteger)obj]];
	}
	
	return ret;
}

void ancwc_deleteIvarDictForObject(id obj)
{
	ancwc_checkIvarInit();
	
	[ancwc_fakeIvar removeObjectForKey:[NSNumber numberWithInteger:(NSInteger)obj]];
}

//Convenience method for the only actual ivar
NSMutableArray* ancwc_closedTabStackForObject(id obj)
{
	NSMutableDictionary* ivars = ancwc_ivarDictForObject(obj);
	
	NSMutableArray* ret = [ivars objectForKey:@"closedTabStack"];
	if(ret == nil)
	{
		//Create the ivar
		ret = [NSMutableArray array];
		[ivars setObject:ret forKey:@"closedTabStack"];
	}
	
	return ret;
}

@implementation NSWindowController (ANCustomWindowController)

+(void)ANSwizzleANCustomWindowController
{
	//Swizzle closeTab
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(_AN_safari_closeTab:) withMethod:@selector(closeTab:) error:NULL];
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(closeTab:) withMethod:@selector(_anamnesis_closeTab:) error:NULL];
	
	//Swizzle close window
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(_AN_safari_windowWillClose:) withMethod:@selector(windowWillClose:) error:NULL];
	[NSClassFromString(@"BrowserWindowController") jr_swizzleMethod:@selector(windowWillClose:) withMethod:@selector(_anamnesis_windowWillClose:) error:NULL];
}

-(void)_anamnesis_closeTab:(id)arg1
{
	//arg1 should be a BrowserTabViewItem
	NSMutableArray* tabStack = ancwc_closedTabStackForObject(self);
	//Creating this ANClosedTab object will close the tab
	[tabStack addObject:[ANClosedTab closedTabWithTab:arg1]];
	
	//Call the actual "super" method
	[self _AN_safari_closeTab:arg1];
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
	ancwc_deleteIvarDictForObject(self);
	[self _AN_safari_windowWillClose:arg1];
}

-(void)ANReopenLastClosedTab
{
	//Grab the tab stack and reopen the last entry
	NSMutableArray* closedTabStack = ancwc_closedTabStackForObject(self);
	
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
	if([ancwc_closedTabStackForObject(self) count] == 0)
	{
		//There are no closed tabs to reopen
		return NO;
	}
	return YES;
}

//Swizzling handles
-(void)_AN_safari_closeTab:(id)arg1{}
-(void)_AN_safari_windowWillClose:(id)arg1{}

@end
