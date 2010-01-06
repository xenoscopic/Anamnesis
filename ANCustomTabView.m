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

#import "ANCustomTabView.h"
#import "JRSwizzle.h"

@implementation NSObject (ANCustomTabView)

+(void)ANSwizzleANCustomTabView
{
	[NSClassFromString(@"TabBarView") jr_swizzleMethod:@selector(_AN_safari_tabViewDidChangeNumberOfTabViewItems:) withMethod:@selector(tabViewDidChangeNumberOfTabViewItems:) error:NULL];
	[NSClassFromString(@"TabBarView") jr_swizzleMethod:@selector(tabViewDidChangeNumberOfTabViewItems:) withMethod:@selector(_anamnesis_tabViewDidChangeNumberOfTabViewItems:) error:NULL];
}

-(void)_anamnesis_tabViewDidChangeNumberOfTabViewItems:(id)arg1
{
	[self _AN_safari_tabViewDidChangeNumberOfTabViewItems:arg1];

	//TODO:
	//This will trigger a redraw of the TabBarView items.  I don't
	//know why this is necessary, but it seems that tabs opening
	//in the background don't redraw properly.  This only happens
	//when the plugin is loaded.  Even if the plugin +(void)load
	//method does absolutely nothing, the problem is there, but if
	//I take it away (and leave SIMBL intact) the problem vanishes.
	//I can't find a redraw method in any of the Safari headers so
	//I'm forced to iterate through the tabs and select them all,
	//then return to the one that was originally selected.  This
	//doesn't seem to have a terrible performance on impact (or even
	//a noticable one), but if I could find a way around this, it
	//would be awesome.
	NSTabView* tabView = (NSTabView*)arg1;
	NSInteger count = [tabView numberOfTabViewItems];
	NSInteger i;
	NSTabViewItem* selected = [tabView selectedTabViewItem];
	for(i=0;i<count;i++)
	{
		[tabView selectTabViewItemAtIndex:i];
	}
	[tabView selectTabViewItem:selected];
}

-(void)_AN_safari_tabViewDidChangeNumberOfTabViewItems:(id)arg1 {}

@end
