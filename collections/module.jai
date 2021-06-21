//
// Copyright (C) 2020 Alejandro Coto Gutiérrez (https://github.com/acoto87)
//
// This software is provided 'as-is', without any express or implied
// warranty.  In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.
//
// collections-jai is a library written in Jai.
//
// It includes commonly used data structures like lists, stacks, queues and hash maps.
//
#module_parameters (
    loadTests := false
);

#load "list.jai";
#load "small_list.jai";
#load "map.jai";
#load "small_map.jai";
#load "set.jai";
#load "small_set.jai";
#load "stack.jai";
#load "small_stack.jai";
#load "queue.jai";
#load "small_queue.jai";
#load "binary_heap.jai";
#load "stable_list.jai";

#if loadTests {
    #load "tests/list_test.jai";
    #load "tests/small_list_test.jai";
    #load "tests/map_test.jai";
    #load "tests/small_map_test.jai";
    #load "tests/set_test.jai";
    #load "tests/small_set_test.jai";
    #load "tests/stack_test.jai";
    #load "tests/small_stack_test.jai";
    #load "tests/queue_test.jai";
    #load "tests/small_queue_test.jai";
    #load "tests/binary_heap_test.jai";
}
