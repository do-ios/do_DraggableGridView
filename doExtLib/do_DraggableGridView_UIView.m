//
//  do_DraggableGridView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_DraggableGridView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doIListData.h"
#import "doUIContainer.h"
#import "doServiceContainer.h"
#import "doIPage.h"
#import "doISourceFS.h"
#import "doILogEngine.h"
#import "doJsonHelper.h"
#import "doTextHelper.h"

@implementation do_DraggableGridView_UIView_ItemView
{
    UIColor *bkColor;
}

-(void)setModel:(doModule*) _model
{
    model = _model;
    bkColor = self.backgroundColor;
    [self setLongPress];
}
-(doModule*)getModel
{
    return model;
}
-(void) setData:(int) _data
{
    data=_data;
}
-(void) setLongPress
{
//    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
//    [self addGestureRecognizer:longPress];
}
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setBackgroundColor:self.selectedColor];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setBackgroundColor:bkColor];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setBackgroundColor:bkColor];
    [self fireEvent:@"touch"];
}
- (void)longPress:(UILongPressGestureRecognizer *)longPress
{
    if(longPress.state == UIGestureRecognizerStateBegan)
    {
        [self fireEvent:@"longTouch"];
    }
}
-(void) fireEvent:(NSString*) _event
{
    doInvokeResult* _result = [[doInvokeResult alloc]init:model.UniqueKey];
    [_result SetResultInteger:data];
    [model.EventCenter FireEvent:_event :_result ];
}
-(void) removeFromSuperview
{
    model = nil;
    [super removeFromSuperview];
}

@end

@interface do_DraggableGridView_UIView()<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic,strong) NSIndexPath *beginPath;
@property (nonatomic,strong) NSIndexPath *changePath;

@end

@implementation do_DraggableGridView_UIView
{
    NSMutableArray* _cellTemplatesArray;
    NSMutableArray* modulesArray;
    id<doIListData> _dataArrays;
    int _row;
    int _column;
    float _vSpace;
    float _hSpace;
    float _columnHeight;
    UICollectionViewFlowLayout *flowLayout;
    
    //保存模板
    NSMutableDictionary *_templates;
    
    UIColor *selectedColor;
    
    BOOL isDrag;
    NSInteger beginPoint;
}
-(instancetype) init
{
    flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    self = [super initWithFrame:CGRectMake(0, 0, 0, 0) collectionViewLayout:flowLayout];
    return self;
}

#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    self.bounces = NO;//禁止拖动
    modulesArray = [[NSMutableArray alloc]init];
    _cellTemplatesArray =[[NSMutableArray alloc]init];
    self.delegate = self;
    self.dataSource = self;
    
    
    [self setCollectionViewLayout:flowLayout];
    //对Cell注册(必须否则程序会挂掉)
    [self registerClass:[do_DraggableGridView_UIView_ItemView class] forCellWithReuseIdentifier:@"CellIdentifier"];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setUserInteractionEnabled:YES];
    //默认值
    self.showsVerticalScrollIndicator = YES;
    
    _templates = [NSMutableDictionary dictionary];
    
    selectedColor = [UIColor clearColor];
    
    isDrag = YES;
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlelongGesture:)];
    [self addGestureRecognizer:longGesture];
}
//销毁所有的全局对象
- (void) OnDispose
{
    self.delegate = nil;
    self.dataSource = nil;
    _model = nil;
    //自定义的全局属性
    [ (doModule*)_dataArrays Dispose];
    for(int i =0;i<modulesArray.count;i++){
        [(doModule*) modulesArray[i] Dispose];
    }
    [modulesArray removeAllObjects];
    modulesArray = nil;
    [_cellTemplatesArray removeAllObjects];
    _cellTemplatesArray = nil;
    
    [_templates removeAllObjects];
    _templates = nil;
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    if([self isAutoHeight]){
        float contentheight = self.collectionViewLayout.collectionViewContentSize.height;
        if(contentheight<=0)contentheight = 0.1;//girdview如果设置为0的时候，会导致数据不加载
        if(self.frame.size.height!=contentheight){
            [self setFrame:CGRectMake(_model.RealX, _model.RealY, _model.RealWidth, contentheight)];
            [doUIModuleHelper OnResize:_model];
        }
    }else{
        [doUIModuleHelper OnRedraw:_model];
    }}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_hSpacing:(NSString *)newValue
{
    //自己的代码实现
    _hSpace = [[doTextHelper Instance] StrToFloat:newValue :0];
}
- (void)change_numColumns:(NSString *)newValue
{
    //自己的代码实现
    _column = [[doTextHelper Instance] StrToInt:newValue :1];
    _row = (int)([_dataArrays GetCount]/_column);
}
- (void)change_templates:(NSString *)newValue
{
    //自己的代码实现
    [_cellTemplatesArray removeAllObjects];
    [_cellTemplatesArray addObjectsFromArray:[newValue componentsSeparatedByString:@","]];
    
    [_templates removeAllObjects];
}
- (void)change_vSpacing:(NSString *)newValue
{
    //自己的代码实现
    _vSpace = [[doTextHelper Instance] StrToFloat:newValue :0];

}

#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)bindItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine= [parms objectAtIndex:1];
    NSString* _address = [doJsonHelper GetOneText: _dictParas :@"data": nil];
    @try {
        if (_address == nil || _address.length <= 0) [NSException raise:@"doGridView" format:@"未指定相关的gridview data参数！",nil];
        id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
        if (bindingModule == nil) [NSException raise:@"doGridView" format:@"data参数无效！",nil];
        if([bindingModule conformsToProtocol:@protocol(doIListData)])
        {
            if(_dataArrays!= bindingModule)
                _dataArrays = bindingModule;
            if ([_dataArrays GetCount]>0) {
                [self refreshItems:parms];
            }
        }
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception : @"模板为空或者下标越界"];
        doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
        [_result SetException:exception];
    }
}
- (void)cancel:(NSArray *)parms
{
    isDrag = NO;
}
- (void)edit:(NSArray *)parms
{
    isDrag = YES;
}
- (void)refreshItems:(NSArray *)parms
{
    [self reloadData];
    
}
#pragma mark - private
-(BOOL) isAutoHeight
{
    return [[_model GetPropertyValue:@"height"] isEqualToString:@"-1"];
}
- (UIView *)getInsertView:(id)jsonValue :(NSString *)template :(BOOL)isConcrete
{
    doUIModule* module = [_templates objectForKey:template];
    BOOL isReCreate = NO;
    isReCreate = isConcrete;
    if (!isConcrete) {
        isReCreate = module?NO:YES;
    }else{
        isReCreate = YES;
    }
    if (isReCreate) {
        doSourceFile *source = [[[_model.CurrentPage CurrentApp] SourceFS] GetSourceByFileName:template];
        id<doIPage> pageModel = _model.CurrentPage;
        doUIContainer *container = [[doUIContainer alloc] init:pageModel];
        [container LoadFromFile:source:nil:nil];
        module = container.RootView;
        @try {
            if (!module) {
                [NSException raise:self.description format:@"该模板不存在",nil];
            }
        }
        @catch (NSException *exception) {
            [[doServiceContainer Instance].LogEngine WriteError:exception : @"该模板不存在"];
            doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
            [_result SetException:exception];
            return nil;
        }
        [modulesArray addObject:module];
        [container LoadDefalutScriptFile:template];
        [_templates setObject:module forKey:template];
    }
    [module SetModelData:jsonValue];
    [module.CurrentUIModuleView OnRedraw];
    return (UIView *)module.CurrentUIModuleView;
}
- (NSString *)getTemplate:(id)jsonValue
{
    NSDictionary *dataNode = [doJsonHelper GetNode:jsonValue];
    int cellIndex = [doJsonHelper GetOneInteger: dataNode :@"template" :0];
    NSString* template;
    @try {
        if(_cellTemplatesArray.count<=0)
            [NSException raise:@"Gridview" format:@"模板不能为空"];
        else if (cellIndex>=_cellTemplatesArray.count || cellIndex<0){
            [NSException raise:@"Gridview" format:@"下标为%i的模板下标越界",cellIndex];
            cellIndex = 0;
        }
        template = _cellTemplatesArray[cellIndex];
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception : @"模板为空或者下标越界"];
        doInvokeResult* _result = [[doInvokeResult alloc]init:nil];
        [_result SetException:exception];
    }
    @finally {
        
    }
    return template;
}
- (void)handlelongGesture:(UILongPressGestureRecognizer *)longGesture {
    CGPoint tmpPointTouch = [longGesture locationInView:self];
     NSIndexPath *tempIndex = [self indexPathForItemAtPoint:tmpPointTouch];
    doInvokeResult* _result = [[doInvokeResult alloc]init];
    [_result SetResultInteger:(int)tempIndex.row];
    [_model.EventCenter FireEvent:@"longTouch" :_result ];
    //判断手势状态
    if (isDrag) {
        switch (longGesture.state) {
            case UIGestureRecognizerStateBegan:{
                //判断手势落点位置是否在路径上
                _beginPath = [self indexPathForItemAtPoint:[longGesture locationInView:self]];
                beginPoint = _beginPath.row;
                if (_beginPath == nil) {
                    break;
                }
                beginPoint = _beginPath.row;
            }
                break;
            case UIGestureRecognizerStateChanged:{
                NSIndexPath *tempPath = [self indexPathForItemAtPoint:[longGesture locationInView:self]];
                if (tempPath.row == _changePath.row) {
                    break;
                }
                _changePath = tempPath;
                if (_changePath == nil) {
                    break;
                }
                if (_beginPath.row == _changePath.row) {
                    break;
                }
                [self moveItemAtIndexPath:_beginPath toIndexPath:_changePath];
                _beginPath = [self indexPathForItemAtPoint:[longGesture locationInView:self]];
            }
                break;
            case UIGestureRecognizerStateEnded:
            {
                NSMutableDictionary *node = [NSMutableDictionary dictionary];
                [node setObject:@(beginPoint) forKey:@"old"];
                [node setObject:@(_changePath.row) forKey:@"new"];
                _beginPath = [self indexPathForItemAtPoint:[longGesture locationInView:self]];
            }
                break;
            default:
                break;
        }
    }
}
#pragma mark - UICollectionViewDataSource sourcedelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_dataArrays GetCount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int index = ((int)indexPath.row);
    NSString * CellIdentifier = @"CellIdentifier";
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id jsonValue = [_dataArrays GetData:index];
    NSString *template = [self getTemplate:jsonValue];
    
    do_DraggableGridView_UIView_ItemView* itemview = (do_DraggableGridView_UIView_ItemView*)cell;
    itemview.selectedColor = selectedColor;
    itemview.backgroundColor = [UIColor clearColor];
    if([itemview getModel]==nil)
        [itemview setModel:_model];
    if([itemview.TemplateName isEqualToString:template]&&itemview.contentView.subviews.count>0)
    {
        doUIModule* module = [(id<doIUIModuleView>)[itemview.contentView.subviews objectAtIndex:0] GetModel];
        [module SetModelData:jsonValue];
    }else{
        if(itemview.contentView.subviews.count>0)
        {
            [itemview.contentView.subviews[0] removeFromSuperview];
        }
        UIView *insertView = [self getInsertView:jsonValue :template :YES];
        cell.contentView.frame = insertView.frame;
        [cell.contentView addSubview:insertView];
        [flowLayout setItemSize:cell.contentView.frame.size];
        itemview.TemplateName = template;
    }
    [itemview setData:index];
    [self OnRedraw];
    
    return cell;
}
#pragma mark - UICollectionViewDelegate delegate
//cell的最小行间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return _vSpace*_model.YZoom;
}

//cell的最小列间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return _hSpace*_model.XZoom;
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
