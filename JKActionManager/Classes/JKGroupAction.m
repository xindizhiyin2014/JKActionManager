//
//  JKGroupAction.m
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import "JKGroupAction.h"

#import "JKActionManager.h"

@interface JKBatchAction()

@property (nonatomic, strong, readwrite) NSMutableArray <__kindof JKBaseAction *>*actions;
@property (nonatomic, copy, nullable) void(^afterCompleteBlock)(__kindof JKBatchAction *batchAction, __kindof JKBaseAction * _Nullable failedAction);

@end

@implementation JKBatchAction

+ (instancetype)initWithArray:(NSArray <__kindof JKBaseAction *>*)array
{
    for (id action in array) {
        if (![action isKindOfClass:[JKBaseAction class]]) {
#if DEBUG
        NSAssert(NO, @"action in array must be kindof JKBaseAction");
#endif
            return nil;
        }
        if ([action isKindOfClass:[JKBatchAction class]]) {
#if DEBUG
        NSAssert(NO, @"action in array can not be an instance of JKBatchAction");
#endif
        return nil;
        }
    }
    JKBatchAction *batchAction = [[self alloc] init];
    if (batchAction) {
        if (array) {
           [batchAction.actions addObjectsFromArray:array];
        }
    }
    return batchAction;
}

- (void)addAction:(__kindof JKBaseAction *)action
{
    if (self.status != JKActionStatusReady) {
#if DEBUG
        NSAssert(NO, @"make sure status is JKActionStatusReady before addAction");
#endif
        return;
    }
    if (action) {
        if (![action isKindOfClass:[JKBaseAction class]]) {
#if DEBUG
            NSAssert(NO, @"action must be kindof JKBaseAction");
#endif
            return;
        }
        if ([action isKindOfClass:[JKBatchAction class]]) {
#if DEBUG
            NSAssert(NO, @"action can not be an instance of JKBatchAction");
#endif
            return;
        }
        [self.actions addObject:action];
    }
}

- (void)cleanBlock
{
    if (self.completeBlock) {
        self.completeBlock = nil;
    }
    if (self.afterCompleteBlock) {
        self.afterCompleteBlock = nil;
    }
}

#pragma mark - - getter - -
- (NSMutableArray *)actions
{
    if (!_actions) {
        _actions = [NSMutableArray new];
    }
    return _actions;
}

@end

@interface JKChainAction()

@property (nonatomic, strong, readwrite) NSMutableArray <__kindof JKBaseAction *>*actions;
@property (nonatomic, copy, nullable) void(^afterCompleteBlock)(__kindof JKChainAction *batchAction, __kindof JKBaseAction * _Nullable failedAction);

@end

@implementation JKChainAction

+ (instancetype)initWithArray:(NSArray <__kindof JKBaseAction *>*)array
{
    for (id action in array) {
        if (![action isKindOfClass:[JKBaseAction class]]) {
#if DEBUG
            NSAssert(NO, @"action in array must be kindof JKBaseAction");
#endif
            return nil;
        }
        if ([action isKindOfClass:[JKChainAction class]]) {
#if DEBUG
            NSAssert(NO, @"JKChainAction instance cannot in JKChainAction array");
#endif
            return nil;
        }
    }
    JKChainAction *chainAction = [[self alloc] init];
    if (chainAction) {
        if (array) {
           [chainAction.actions addObjectsFromArray:array];
        }
    }
    return chainAction;
}

- (void)addAction:(__kindof JKBaseAction *)action
{
    if (self.status != JKActionStatusReady) {
#if DEBUG
        NSAssert(NO, @"make sure status is JKActionStatusReady before addAction");
#endif
        return;
    }
    if (action) {
        if (![action isKindOfClass:[JKBaseAction class]]) {
#if DEBUG
            NSAssert(NO, @"action must be kindof JKBaseAction");
#endif
            return;
        }
        if ([action isKindOfClass:[JKChainAction class]]) {
#if DEBUG
         NSAssert(NO, @"action can not be an instance of JKChainAction");
#endif
            return;
        }
        
        [self.actions addObject:action];
    }
}

- (void)cleanBlock
{
    if (self.completeBlock) {
        self.completeBlock = nil;
    }
    if (self.afterCompleteBlock) {
        self.afterCompleteBlock = nil;
    }
}

#pragma mark - - getter - -
- (NSMutableArray *)actions
{
    if (!_actions) {
        _actions = [NSMutableArray new];
    }
    return _actions;
}

@end
