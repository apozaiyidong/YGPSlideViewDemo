//
//  YLSlideConfig.h
//  YLSlideViewDemo
//
//  Created by 国平 杨 on 15/12/15.
//  Copyright © 2015年 国平 杨. All rights reserved.
//

#ifndef YLSlideConfig_h
#define YLSlideConfig_h


#define SCREEN_WIDTH_YLSLIDE  [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT_YLSLIDE [UIScreen mainScreen].bounds.size.height
#define SET_COLOS_YLSLIDE(R,G,B) [UIColor colorWithRed:R / 255.0 green:G / 255.0 blue:B / 255.0 alpha:1.0]

#define __WEAK_SELF_YLSLIDE     __weak typeof(self) weakSelf = self;
#define __STRONG_SELF_YLSLIDE   __strong typeof(weakSelf) strongSelf = weakSelf;
#import <UIKit/UIKit.h>

#endif /* YLSlideConfig_h */
