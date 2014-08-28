//
//  LEANTabManager.m
//  GoNativeIOS
//
//  Created by Weiyin He on 8/14/14.
//  Copyright (c) 2014 GoNative.io LLC. All rights reserved.
//

#import "LEANTabManager.h"
#import "LEANWebViewController.h"
#import "LEANAppConfig.h"

@interface LEANTabManager() <UITabBarDelegate>
@property UITabBar *tabBar;
@property NSArray *menu;
@property (weak, nonatomic) LEANWebViewController* wvc;
@property NSString *currentMenuID;
@end

@implementation LEANTabManager

- (instancetype)initWithTabBar:(UITabBar*)tabBar webviewController:(LEANWebViewController*)wvc;
{
    self = [super init];
    if (self) {
        self.tabBar = tabBar;
        self.tabBar.delegate = self;
        self.wvc = wvc;
    }
    return self;
}

- (void)didLoadUrl:(NSURL *)url
{
    NSArray *tabMenuRegexes = [LEANAppConfig sharedAppConfig].tabMenuRegexes;
    if (!tabMenuRegexes || !url) return;
    
    NSString *urlString = [url absoluteString];
    
    BOOL showTabBar = NO;
    for (NSUInteger i = 0; i < [tabMenuRegexes count]; i++) {
        NSPredicate *predicate = tabMenuRegexes[i];
        if ([predicate evaluateWithObject:urlString]) {
            [self loadTabBarMenu:[LEANAppConfig sharedAppConfig].tabMenuIDs[i]];
            showTabBar = YES;
            break;
        }
    }
    
    if (showTabBar) {
        [self.wvc showTabBar];
    } else {
        [self.wvc hideTabBar];
    }
}

- (void)loadTabBarMenu:(NSString*)menuID
{
    if ([menuID isEqualToString:self.currentMenuID]) {
        return;
    }
    
    self.currentMenuID = menuID;
    
    NSArray *menu = [LEANAppConfig sharedAppConfig].tabMenus[menuID];
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:[menu count]];
    
    for (NSUInteger i = 0; i < [menu count]; i++) {
        NSString *label = menu[i][@"label"];
        NSString *iconName = menu[i][@"icon"];
        UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"tabbar-%@", iconName]];
        [items addObject:[[UITabBarItem alloc] initWithTitle:label image:iconImage tag:i]];
    }
    
    self.menu = menu;
    [self.tabBar setItems:items animated:NO];
    
    // select first item
    if ([items count] > 0) {
        self.tabBar.selectedItem = items[0];
    }
}


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSInteger idx = item.tag;
    if (idx < [self.menu count]) {
        NSString *url = self.menu[idx][@"url"];
        NSString *javascript = self.menu[idx][@"javascript"];
        
        if ([url length] > 0) {
            if ([url hasPrefix:@"javascript:"]) {
                NSString *js = [url substringFromIndex: [@"javascript:" length]];
                [self.wvc runJavascript:js];
            }
            else if ([javascript length] > 0) {
                [self.wvc loadUrl:[NSURL URLWithString:url] andJavascript:javascript];
            } else {
                [self.wvc loadUrl:[NSURL URLWithString:url]];
            }
        }
    }
}

@end
