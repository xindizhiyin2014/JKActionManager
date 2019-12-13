//
//  JKPerson.h
//
//  Created by JackLee on 2019/12/12.
//  Copyright © 2019 xindizhiyin2014. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JKPerson : NSObject

@property (nonatomic, copy) NSString *name;

- (NSInteger)inputAge:(NSInteger)age;

@end

NS_ASSUME_NONNULL_END
