//
//  main-fix.c
//  scrcpy-core
//  > this file is created for fix main.c of scrcpy
//
//  Created by Ethan on 2021/12/8.
//

// Re-define main of scrcpy to scrcpy_main
#define main(...)            scrcpy_main(__VA_ARGS__)
#define scrcpy(...)          scrcpy_fix(__VA_ARGS__)

#include "main.c"
