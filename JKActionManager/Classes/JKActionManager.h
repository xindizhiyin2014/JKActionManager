//
//  JKActionManager.h
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#import <Foundation/Foundation.h>
#import "JKSingleAction.h"
#import "JKGroupAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface JKActionManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray <__kindof JKSingleAction *>*actions;
@property (nonatomic, strong, readonly) NSMutableArray <__kindof JKBatchAction *>*batchActions;
@property (nonatomic, strong, readonly) NSMutableArray <__kindof JKChainAction *>*chainActions;


+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)sharedManager;

///action must be member of class JKSingleAction,JKBatchAction,JKChainAction
+ (void)addAction:(__kindof JKBaseAction *)action
             data:(nullable id)data;

+ (void)removeAction:(__kindof JKBaseAction *)action;

+ (void)removeAllActions;

@end

NS_ASSUME_NONNULL_END
