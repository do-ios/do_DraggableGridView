//
//  do_DraggableGridView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_DraggableGridView_IView <NSObject>

@required
//属性方法
- (void)change_hSpacing:(NSString *)newValue;
- (void)change_numColumns:(NSString *)newValue;
- (void)change_templates:(NSString *)newValue;
- (void)change_vSpacing:(NSString *)newValue;

//同步或异步方法
- (void)bindItems:(NSArray *)parms;
- (void)cancel:(NSArray *)parms;
- (void)edit:(NSArray *)parms;
- (void)refreshItems:(NSArray *)parms;


@end