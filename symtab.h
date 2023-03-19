/**********************************************
        CS415  Compilers  Project3
              Spring  2016
**********************************************/

#ifndef SYMTAB_H
#define SYMTAB_H

#include <string.h>
#include "attr.h"


static int idlist_size = 0; 
static int id_count = 0; 


typedef struct { /* need to augment this */
    char *name;
    int address;
} varMapEntry;

static varMapEntry **HashTable;


extern void InitSymbolTable();

extern varMapEntry* lookup(char *name);

extern void insert(char *name, int address);

extern void PrintSymbolTable();

#endif
