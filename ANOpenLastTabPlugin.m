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

#import "ANOpenLastTabPlugin.h"
#import "ANCustomWindowController.h"
#import "ANCustomTabView.h"

static ANOpenLastTabPlugin *sharedInstance = nil;

@interface ANOpenLastTabPlugin ()

//Utility method for finding menu items.
+(NSMenu*)getMenuAndItemIndex:(NSInteger*)itemIndex forMenuName:(NSString*)menuName forItemName:(NSString*)itemName;
//Reassigns the binding on Hide/Show Tab Bar to be
//Command-Option-Shift-T instead of Command-Shift-T
+(BOOL)reassignShowTabBar;
//Installs the Reopen Last Closed Tab menu item in the
//history menu.
+(BOOL)installReopenMenuItem;

@end

@implementation ANOpenLastTabPlugin

#pragma mark -
#pragma mark SIMBL methods

/*
 * This method is called by SIMBL when the bundle is loaded
 * to initialize the plug-in.
 */
+(void)load
{
	if(![ANOpenLastTabPlugin reassignShowTabBar])
	{
		NSLog(@"Anamnesis: Couldn't reassign Hide/Show Tab Bar key binding. Cancelling loading.");
		return;
	}
	if(![ANOpenLastTabPlugin installReopenMenuItem])
	{
		NSLog(@"Anamnesis: Couldn't install Reopen Last Closed Tab menu item. Cancelling loading.");
		return;
	}
	
	//Swizzle
	[NSWindowController ANSwizzleANCustomWindowController];
	[NSObject ANSwizzleANCustomTabView];
	
	NSLog(@"Anamnesis: Safari Open Last Closed Tab plugin loaded.");
}

#pragma mark -
#pragma mark Private Class methods

+(BOOL)reassignShowTabBar
{
	NSMenu* viewMenu;
	NSInteger showTabBarIndex;
	
	//First try "Show Tab Bar"
	viewMenu = [ANOpenLastTabPlugin getMenuAndItemIndex:&showTabBarIndex forMenuName:@"View" forItemName:@"Show Tab Bar"];
	if(viewMenu == nil)
	{
		//Don't despair, the menu may currently be displaying the "Hide Tab Bar" text
		viewMenu = [ANOpenLastTabPlugin getMenuAndItemIndex:&showTabBarIndex forMenuName:@"View" forItemName:@"Hide Tab Bar"];
	}
	if(viewMenu == nil)
	{
		//At this point, abandon all hope ye who enter here
		return NO;
	}
	
	//Reassign to make the Option key (NSAlternateKeyMask) necessary
	[[viewMenu itemAtIndex:showTabBarIndex] setKeyEquivalentModifierMask:(NSAlternateKeyMask|NSCommandKeyMask)];
	
	return YES;
}

+(BOOL)installReopenMenuItem
{
	NSMenu* historyMenu;
	NSInteger insertIndex;
	historyMenu = [ANOpenLastTabPlugin getMenuAndItemIndex:&insertIndex forMenuName:@"History" forItemName:@"Reopen Last Closed Window"];
	
	if(historyMenu == nil)
	{
		return NO;
	}
	
	insertIndex += 1;
	
	//Add our new menu item (we'll insert it at the index of Reopen Last Closed Window so it'll appear just above it
	//TODO: For some reason this removes the Reopen All Windows from Last Session item and replaces it.  I don't know
	//why but I suspect Safari is hacking the menu somehow to add the history items.
	[historyMenu insertItemWithTitle:@"Reopen Last Closed Tab" action:@selector(reopenLastTab:) keyEquivalent:@"T" atIndex:insertIndex];
	[[historyMenu itemAtIndex:insertIndex] setTarget:[ANOpenLastTabPlugin sharedInstance]];

	return YES;
}

+(NSMenu*)getMenuAndItemIndex:(NSInteger*)index forMenuName:(NSString*)menuName forItemName:(NSString*)itemName
{
	NSMenu* mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenu* targetMenu = nil;
	NSInteger itemIndex = NSNotFound, i = 0;
	
	//Location the target menu.
	for(NSMenuItem* menuItem in [mainMenu itemArray])
	{
		if([[menuItem title] isEqualToString:menuName])
		{
			targetMenu = [menuItem submenu];
			break;
		}
	}
	
	if(targetMenu == nil)
	{
		NSLog(@"Anamnesis: Couldn't find %@ menu.", menuName);
		return nil;
	}
	
	//Locate the taget item.
	for(NSMenuItem* menuItem in [targetMenu itemArray])
	{
		if([[menuItem title] isEqualToString:itemName])
		{
			itemIndex = i;
			break;
		}
		i++;
	}
	
	if(itemIndex == NSNotFound)
	{
		NSLog(@"Anamnesis: Couldn't find %@ menu item.", itemName);
		return nil;
	}
	
	//Everything went well
	(*index) = itemIndex;
	return targetMenu;
}

#pragma mark -
#pragma mark Open Last Tab methods
-(void)reopenLastTab:(id)sender
{
	//NSLog(@"Anamnesis: Reopening last tab.");
	
	id window = [[[NSApplication sharedApplication] keyWindow] windowController];
	
	if([NSStringFromClass([window class]) isEqualToString:@"BrowserWindowController"])
	{
		[window ANReopenLastClosedTab];
	}
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	//This will return NO in the event that keyWindow is nil.  Gotta
	//love obj-c messaging.
	return [[[[NSApplication sharedApplication] keyWindow] windowController] canReopenLastTab];
}

#pragma mark -
#pragma mark Singleton methods

+(ANOpenLastTabPlugin*)sharedInstance
{
	@synchronized(self)
	{
		if (sharedInstance == nil)
		{
			sharedInstance = [[ANOpenLastTabPlugin alloc] init];
		}
	}
	return sharedInstance;
}

+(id)allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if (sharedInstance == nil)
		{
			sharedInstance = [super allocWithZone:zone];
			return sharedInstance;  //Assignment and return on first allocation.
		}
	}
	return nil; //On subsequent allocation attempts return nil.
}

-(id)copyWithZone:(NSZone *)zone
{
	return self;
}

-(id)retain
{
	return self;
}

-(NSUInteger)retainCount
{
	return UINT_MAX;  //Denotes an object that cannot be released.
}

-(void)release
{
	//Do nothing.
}

-(id)autorelease
{
	return self;
}

@end
