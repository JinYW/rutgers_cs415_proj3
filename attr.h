/**********************************************
        CS415  Compilers  Project3
              Spring 2016
**********************************************/

#ifndef ATTR_H
#define ATTR_H

typedef union {int num; char *str;} tokentype;

typedef struct {  
        int targetRegister;
        char *str;
        int type;
        int size;
        } regInfo;

typedef struct {  
        int targetRegister;
        int thenLabel;
        int elseLabel;
        int exitLabel;
        } labelInfo;

#endif


