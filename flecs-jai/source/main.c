//
// A simple C file to be able to compile flecs into a dynamic (.dll) and static (.lib).
//
// The flecs.h and flecs.c files are from commit 6fb148466afeac1b2f3269c72776ac0b38d462af
//
#define FLECS_NO_CPP
#define flecs_EXPORTS 1
#include "flecs.h";
