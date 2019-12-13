//
//  JKBatchActionSpec.m
//  
//
//  Created by JackLee on 2019/12/12.
//  Copyright 2019 xindizhiyin2014. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "JKGroupAction.h"
#import "JKSingleAction.h"

SPEC_BEGIN(JKBatchActionSpec)

describe(@"JKBatchAction", ^{
         context(@"initWithArray:", ^{
            it(@"array nil", ^{
                [[[JKBatchAction initWithArray:nil].actions should] haveCountOf:0];
            });
    
            it(@"array contain NSString", ^{
                NSArray *array = @[@"aaa"];
                [[theBlock(^{
                    [JKBatchAction initWithArray:array];
                }) should] raiseWithName:nil reason:@"action in array must be kindof JKBaseAction"];
            });
    
            it(@"array contain JKBatchAction", ^{
                NSArray *array = @[[JKBatchAction mock]];
                [[theBlock(^{
                    [JKBatchAction initWithArray:array];
                }) should] raiseWithName:nil reason:@"action in array can not be an instance of JKBatchAction"];
            });
        });
         
        context(@"addAction:", ^{
            it(@"normal", ^{
                JKSingleAction *JKAction = [JKSingleAction mock];
                JKBatchAction *batchAction = [JKBatchAction initWithArray:@[JKAction]];
                [[batchAction.actions should] haveCountOf:1];
                JKSingleAction *JKAction1 = [JKSingleAction mock];
                [batchAction addAction:JKAction1];
                [[batchAction.actions should] haveCountOf:2];
            });
            it(@"status is not ready", ^{
               JKSingleAction *JKAction = [JKSingleAction mock];
                JKBatchAction *batchAction = [JKBatchAction initWithArray:nil];
                batchAction.status = JKActionStatusCancel;
                [[theBlock(^{
                    [batchAction addAction:JKAction];
                }) should] raiseWithName:nil reason:@"make sure status is JKActionStatusReady before addAction"];
            });
            it(@"action is not JKBaseAction instance", ^{
               JKBatchAction *batchAction = [JKBatchAction initWithArray:nil];
                [[theBlock(^{
                    [batchAction addAction:@"aaa"];
                }) should] raiseWithName:nil reason:@"action must be kindof JKBaseAction"];
            });
            it(@"action is kindof JKBatchAction", ^{
                JKBatchAction *action = [JKBatchAction mock];
              JKBatchAction *batchAction = [JKBatchAction initWithArray:nil];
                [[theBlock(^{
                    [batchAction addAction:action];
                }) should] raiseWithName:nil reason:@"action can not be an instance of JKBatchAction"];
            });
        });
});

SPEC_END
