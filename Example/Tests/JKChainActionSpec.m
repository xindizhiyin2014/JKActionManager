//
//  JKChainActionSpec.m
//
//  Created by JackLee on 2019/12/12.
//  Copyright 2019 xindizhiyin2014. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "JKGroupAction.h"
#import "JKSingleAction.h"

SPEC_BEGIN(JKChainActionSpec)

describe(@"JKChainAction", ^{
              context(@"initWithArray:", ^{
                 it(@"array nil", ^{
                     [[[JKChainAction initWithArray:nil].actions should] haveCountOf:0];
                 });
         
                 it(@"array contain NSString", ^{
                     NSArray *array = @[@"aaa"];
                     [[theBlock(^{
                         [JKChainAction initWithArray:array];
                     }) should] raiseWithName:nil reason:@"action in array must be kindof JKBaseAction"];
                 });
         
                 it(@"array contain JKChainAction", ^{
                     NSArray *array = @[[JKChainAction mock]];
                     [[theBlock(^{
                         [JKChainAction initWithArray:array];
                     }) should] raiseWithName:nil reason:@"JKChainAction instance cannot in JKChainAction array"];
                 });
             });
              
             context(@"addAction:", ^{
                 it(@"normal", ^{
                     JKSingleAction *JKAction = [JKSingleAction mock];
                     JKChainAction *chainAction = [JKChainAction initWithArray:@[JKAction]];
                     [[chainAction.actions should] haveCountOf:1];
                     JKSingleAction *JKAction1 = [JKSingleAction mock];
                     [chainAction addAction:JKAction1];
                     [[chainAction.actions should] haveCountOf:2];
                 });
                 it(@"status is not ready", ^{
                    JKSingleAction *JKAction = [JKSingleAction mock];
                     JKChainAction *chainAction = [JKChainAction initWithArray:nil];
                     chainAction.status = JKActionStatusCancel;
                     NSLog(@"chainAction %@",@([chainAction status]));
                     [[theBlock(^{
                         [chainAction addAction:JKAction];
                     }) should] raiseWithName:nil reason:@"make sure status is JKActionStatusReady before addAction"];
                 });
                 it(@"action is not JKBaseAction instance", ^{
                    JKChainAction *chainAction = [JKChainAction initWithArray:nil];
                     [[theBlock(^{
                         [chainAction addAction:@"aaa"];
                     }) should] raiseWithName:nil reason:@"action must be kindof JKBaseAction"];
                 });
                 it(@"action is kindof JKBatchAction", ^{
                     JKChainAction *action = [JKChainAction mock];
                   JKChainAction *batchAction = [JKChainAction initWithArray:nil];
                     [[theBlock(^{
                         [batchAction addAction:action];
                     }) should] raiseWithName:nil reason:@"action can not be an instance of JKChainAction"];
                 });
             });
});

SPEC_END
