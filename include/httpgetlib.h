#ifndef HTTPGETLIB_H
#define HTTPGETLIB_H

#include <proto/bsdsocket.h>

extern BOOL isConnected(void);
extern int httpget(char* url, char* filePath);
extern int httpgetWithVerbose(char* url, char* filePath, BOOL Verbose);

#endif