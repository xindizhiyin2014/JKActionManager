//
//  JKActionManagerMacro.h
//  JKActionManager
//
//  Created by JackLee on 2019/12/13.
//

#ifndef JKActionManagerMacro_h
#define JKActionManagerMacro_h
typedef NS_ENUM(NSInteger,JKActionStatus){
    ///ready to execute
    JKActionStatusReady = 0,
    ///executing
    JKActionStatusExecuting,
    ///canceled
    JKActionStatusCancel,
    ///finished
    JKActionStatusFinish
};


#endif /* JKActionManagerMacro_h */
