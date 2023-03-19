/**********************************************
        CS415  Compilers  Project3
              Spring  2016
**********************************************/

#ifndef SYMTAB_H
#define SYMTAB_H

#include <string.h>
#include "attr.h"

typedef struct { /* need to augment this */
    char *name;
    int offset;
} varMapEntry;

extern void InitSymbolTable();

extern varMapEntry* lookup(char *name);

extern void insert(char *name, int offset);

extern void PrintSymbolTable();

#endif
