//
//  config.h
//  Scrcpy
//
//  Created by Ethan on 2021/12/9.
//

#include "x/app/config.h"

#ifdef PREFIX
#undef PREFIX
#define PREFIX  "$TMPDIR"
#endif
