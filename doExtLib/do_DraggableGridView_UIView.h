//
//  do_DraggableGridView_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_DraggableGridView_IView.h"
#import "do_DraggableGridView_UIModel.h"
#import "doIUIModuleView.h"

@interface do_DraggableGridView_UIView_ItemView:UICollectionViewCell
{
    doModule* model;
    int data;
}
@property (nonatomic,strong) UIColor *selectedColor;
@property (nonatomic,strong) NSString* TemplateName;
-(void)setModel:(doModule*) _model;
-(doModule*)getModel;
-(void)setData:(int) _data;
@end

@interface do_DraggableGridView_UIView : UICollectionView<do_DraggableGridView_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_DraggableGridView_UIModel *_model;
}

@end
