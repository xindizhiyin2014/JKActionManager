//
//  JKActionManagerSpec.m
//  
//
//  Created by JackLee on 2019/12/12.
//  Copyright 2019 xindizhiyin2014. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "JKActionManager.h"
#import "JKSingleAction.h"
#import "JKGroupAction.h"
#import "JKPerson.h"


SPEC_BEGIN(JKActionManagerSpec)

describe(@"JKActionManager", ^{
     context(@"addAction:data:", ^{
    beforeEach(^{
        [JKActionManager removeAllActions];
    });
        it(@"action is nil", ^{
            [[theBlock(^{
                [JKActionManager addAction:nil data:nil];
            }) should] raiseWithName:nil reason:@"action can not be nil"];
        });
        it(@"action is JKSingleAction", ^{
            JKSingleAction *action = [JKSingleAction new];
            JKPerson *person = [JKPerson new];
            __block NSInteger age = 0;
            action.actionBlock = ^(id  _Nullable data) {
               age = [person inputAge:18];
            };
            [action start];
            action.completeBlock(action);
            [[expectFutureValue(theValue(age)) shouldEventually] equal:theValue(18)];
            [[[JKActionManager sharedManager].actions should] haveCountOf:1];
            [JKActionManager removeAction:action];
            [[[JKActionManager sharedManager].actions should] haveCountOf:0];
        });
        it(@"action is JKBatchAction", ^{
            __block NSInteger age1 = 0;
            __block NSInteger age2 = 0;
            __block NSInteger age3 = 0;
            __block NSInteger age4 = 0;
            JKPerson *person = [JKPerson new];

            JKSingleAction *action1 = [JKSingleAction new];
            action1.actionBlock = ^(id  _Nullable data) {
               age1 = [person inputAge:1];
            };
            JKSingleAction *action2 = [JKSingleAction new];
            action2.actionBlock = ^(id  _Nullable data) {
               age2 = [person inputAge:2];
            };
            JKSingleAction *action3 = [JKSingleAction new];
            action3.actionBlock = ^(id  _Nullable data) {
               age3 = [person inputAge:3];
            };
            JKBatchAction *batchAction = [JKBatchAction initWithArray:@[action1,action2,action3]];
            [batchAction start];
            batchAction.completeBlock = ^(__kindof JKBatchAction * _Nonnull batchAction, __kindof JKBaseAction * _Nullable failedAction) {
                if(!failedAction){
                    age4 = age1 + age2 + age3;
                }
            };
            action1.completeBlock(action1);
            action2.completeBlock(action2);
            action3.completeBlock(action3);
            [[expectFutureValue(theValue(age1)) shouldEventually] equal:theValue(1)];
            [[expectFutureValue(theValue(age2)) shouldEventually] equal:theValue(2)];
            [[expectFutureValue(theValue(age3)) shouldEventually] equal:theValue(3)];
            [[expectFutureValue(theValue(age4)) shouldEventually] equal:theValue(6)];
            [[[JKActionManager sharedManager].actions should] haveCountOf:3];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:1];
            [JKActionManager removeAction:batchAction];
            [[[JKActionManager sharedManager].actions should] haveCountOf:0];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:0];
        });
        it(@"action is JKChainAction ", ^{
            __block NSInteger age1 = 0;
            __block NSInteger age2 = 0;
            __block NSInteger age3 = 0;
            __block NSInteger age4 = 0;
            JKPerson *person = [JKPerson new];

            JKSingleAction *action1 = [JKSingleAction new];
            action1.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age1 = [person inputAge:1];
                action1.result = @(age1);
                action1.completeBlock(action1);
            };
            JKSingleAction *action2 = [JKSingleAction new];
            action2.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age2 = [person inputAge:2];
                action2.result = @(age2 + [data integerValue]);
                action2.completeBlock(action2);
            };
            JKSingleAction *action3 = [JKSingleAction new];
            action3.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age3 = [person inputAge:3];
                action3.result = @(age3 + [data integerValue]);
                action3.completeBlock(action3);
            };
            JKChainAction *chainAction = [JKChainAction initWithArray:@[action1,action2,action3]];
            [chainAction start];
            chainAction.completeBlock = ^(__kindof JKChainAction * _Nonnull chainAction, __kindof JKBaseAction * _Nullable failedAction) {
                if(!failedAction){
                    for(__kindof JKSingleAction *singleAction in chainAction.actions){
                        NSLog(@"__age %@\n",singleAction.result);
                        age4 += [singleAction.result integerValue];
                    }
                }
            };
            
            [[expectFutureValue(theValue(age1)) shouldEventually] equal:theValue(1)];
            [[expectFutureValue(theValue(age2)) shouldEventually] equal:theValue(2)];
            [[expectFutureValue(theValue(age3)) shouldEventually] equal:theValue(3)];
            [[expectFutureValue(theValue(age4)) shouldEventually] equal:theValue(10)];
            [[[JKActionManager sharedManager].actions should] haveCountOf:3];
            [[[JKActionManager sharedManager].chainActions should] haveCountOf:1];
            [JKActionManager removeAction:chainAction];
            [[[JKActionManager sharedManager].actions should] haveCountOf:0];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:0];
        });
        it(@"action is JKChainAction and it contain JKBatchAction", ^{
            
            __block NSInteger age1 = 0;
            __block NSInteger age2 = 0;
            __block NSInteger age3 = 0;
            __block NSInteger age4 = 0;
            JKPerson *person = [JKPerson new];

            JKSingleAction *action1 = [JKSingleAction new];
            action1.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age1 = [person inputAge:1];
                action1.result = @(age1);
                action1.completeBlock(action1);
            };
            JKSingleAction *action2 = [JKSingleAction new];
            action2.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age2 = [person inputAge:2];
                action2.result = @(age2 + [data integerValue]);
                action2.completeBlock(action2);
            };
            JKSingleAction *action3 = [JKSingleAction new];
            action3.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age3 = [person inputAge:3];
                action3.result = @(age3 + [data integerValue]);
                action3.completeBlock(action3);
            };
            
            
            JKSingleAction *action4 = [JKSingleAction new];
            action4.actionBlock = ^(id  _Nullable data) {
               action4.completeBlock(action4);

            };
            JKSingleAction *action5 = [JKSingleAction new];
            action5.actionBlock = ^(id  _Nullable data) {
               action5.completeBlock(action5);

            };
            JKSingleAction *action6 = [JKSingleAction new];
            action6.actionBlock = ^(id  _Nullable data) {
               action6.completeBlock(action6);

            };
            JKBatchAction *batchAction = [JKBatchAction initWithArray:@[action4,action5,action6]];
            batchAction.completeBlock = ^(__kindof JKBatchAction * _Nonnull batchAction, __kindof JKBaseAction * _Nullable failedAction) {
                if(!failedAction){
                    batchAction.result = @(10);
                }
            };
            
            JKChainAction *chainAction = [JKChainAction initWithArray:@[action1,action2,action3,batchAction]];
            [chainAction start];
            chainAction.completeBlock = ^(__kindof JKChainAction * _Nonnull chainAction, __kindof JKBaseAction * _Nullable failedAction) {
                if(!failedAction){
                    for(__kindof JKBaseAction *singleAction in chainAction.actions){
                        NSLog(@"__age %@\n",singleAction.result);
                        age4 += [singleAction.result integerValue];
                    }
                }
            };
            
            [[expectFutureValue(theValue(age1)) shouldEventually] equal:theValue(1)];
            [[expectFutureValue(theValue(age2)) shouldEventually] equal:theValue(2)];
            [[expectFutureValue(theValue(age3)) shouldEventually] equal:theValue(3)];
            [[expectFutureValue(theValue(age4)) shouldEventually] equal:theValue(20)];
            [[[JKActionManager sharedManager].actions should] haveCountOf:6];
            [[[JKActionManager sharedManager].chainActions should] haveCountOf:1];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:1];
            [JKActionManager removeAction:chainAction];
            [[[JKActionManager sharedManager].actions should] haveCountOf:0];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:0];
        });
        it(@"action is JKBatchAction and it contain JKChainAction", ^{
            
            __block NSInteger age1 = 0;
            __block NSInteger age2 = 0;
            __block NSInteger age3 = 0;
            __block NSInteger age4 = 0;
            __block NSInteger age5 = 0;
            JKPerson *person = [JKPerson new];

            JKSingleAction *action1 = [JKSingleAction new];
            action1.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age1 = [person inputAge:1];
                action1.result = @(age1);
                action1.completeBlock(action1);
            };
            JKSingleAction *action2 = [JKSingleAction new];
            action2.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age2 = [person inputAge:2];
                action2.result = @(age2 + [data integerValue]);
                action2.completeBlock(action2);
            };
            JKSingleAction *action3 = [JKSingleAction new];
            action3.actionBlock = ^(id  _Nullable data) {
                NSLog(@"__data %@\n",data);
               age3 = [person inputAge:3];
                action3.result = @(age3 + [data integerValue]);
                action3.completeBlock(action3);
            };
            
            
            JKSingleAction *action4 = [JKSingleAction new];
            action4.actionBlock = ^(id  _Nullable data) {
               action4.completeBlock(action4);

            };
            JKSingleAction *action5 = [JKSingleAction new];
            action5.actionBlock = ^(id  _Nullable data) {
               action5.completeBlock(action5);

            };
            JKSingleAction *action6 = [JKSingleAction new];
            action6.actionBlock = ^(id  _Nullable data) {
               action6.completeBlock(action6);

            };
            JKChainAction *chainAction = [JKChainAction initWithArray:@[action1,action2,action3]];
            chainAction.completeBlock = ^(__kindof JKChainAction * _Nonnull chainAction, __kindof JKBaseAction * _Nullable failedAction) {
                if(!failedAction){
                    for(__kindof JKBaseAction *singleAction in chainAction.actions){
                        NSLog(@"__age %@\n",singleAction.result);
                        age4 += [singleAction.result integerValue];
                        chainAction.result = @(age4);
                    }
                }
            };
            
            JKBatchAction *batchAction = [JKBatchAction initWithArray:@[action4,action5,action6,chainAction]];
            [batchAction start];
            batchAction.completeBlock = ^(__kindof JKBatchAction * _Nonnull batchAction, __kindof JKBaseAction * _Nullable failedAction) {
                if(!failedAction){
                    
                    batchAction.result = @(10);
                    age5 = [batchAction.result integerValue] + [chainAction.result integerValue];
                }
            };
            
            
            
            [[expectFutureValue(theValue(age1)) shouldEventually] equal:theValue(1)];
            [[expectFutureValue(theValue(age2)) shouldEventually] equal:theValue(2)];
            [[expectFutureValue(theValue(age3)) shouldEventually] equal:theValue(3)];
            [[expectFutureValue(theValue(age4)) shouldEventually] equal:theValue(10)];
            [[expectFutureValue(theValue(age5)) shouldEventually] equal:theValue(20)];
            [[[JKActionManager sharedManager].actions should] haveCountOf:6];
            [[[JKActionManager sharedManager].chainActions should] haveCountOf:1];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:1];
            [JKActionManager removeAction:batchAction];
            [[[JKActionManager sharedManager].actions should] haveCountOf:0];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:0];
        });
        it(@"removeAllActions", ^{
            [[[JKActionManager sharedManager].actions should] haveCountOf:0];
            [[[JKActionManager sharedManager].batchActions should] haveCountOf:0];
            [[[JKActionManager sharedManager].chainActions should] haveCountOf:0];
        });
        it(@"updateOperationPriority", ^{
            NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                
            }];
            operation.queuePriority = NSOperationQueuePriorityHigh;
            NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
                
            }];
            operation1.queuePriority = NSOperationQueuePriorityLow;
            NSString *selectorName = @"updateOperationPriorityWithQueueOperations:";
            [JKActionManager performSelector:NSSelectorFromString(selectorName) withObject:@[operation,operation1]];
            [[theValue(operation.queuePriority) should] equal:@(NSOperationQueuePriorityHigh)];
            [[theValue(operation1.queuePriority) should] equal:@(NSOperationQueuePriorityNormal)];
        });
    
    
     });
});

SPEC_END
