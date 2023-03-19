/**********************************************
        CS415  Compilers  Project3
              Spring  2016
**********************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"
#define HASH_TABLE_SIZE 999


static varMapEntry **HashTable;
static idlist_size = 0; 

static int hash(char *name) {
    return *name - 'a';
}


void InitSymbolTable() {
    int i;
    HashTable = (varMapEntry **) malloc (sizeof(varMapEntry *) * HASH_TABLE_SIZE);
    for (i=0; i < HASH_TABLE_SIZE; i++)
        HashTable[i] = NULL;
}



varMapEntry * lookup(char *name) {
    int currentIndex;
    int checkedIndex = 0;

    currentIndex = hash(name);
    while (HashTable[currentIndex] != NULL && checkedIndex < HASH_TABLE_SIZE) {
        if (!strcmp(HashTable[currentIndex]->name, name) )
            return HashTable[currentIndex];
        currentIndex = (currentIndex + 1) % HASH_TABLE_SIZE; 
        checkedIndex++;
    }
    return NULL;
}


void insert(char *name, int offset) {
    int currentIndex;
    currentIndex = hash(name);

    printf("inserting variable %s with offset %d index is %d \n", name, offset, currentIndex); 

    HashTable[currentIndex] = (varMapEntry *) malloc (sizeof(varMapEntry));
    HashTable[currentIndex]->name = (char *) malloc (strlen(name)+1);
    strcpy(HashTable[currentIndex]->name, name);
    HashTable[currentIndex]->offset = offset; /* in bytes */

}


extern void PrintSymbolTable(){
  int i;

  printf("\n --- Symbol Table ---------------\n\n");
  for (i=0; i < HASH_TABLE_SIZE; i++) {
      if (HashTable[i] != NULL) {
        printf("variable %s with offset %d\n", HashTable[i]->name, HashTable[i]->offset); 
      }
  }
  printf("\n --------------------------------\n\n");

}

