// gcc -o isdisk -O3 -fPIC isdisk.c


#include <stdio.h>
#include <string.h>


int main(int nOptions, char **listOptions) {
	if (nOptions < 2) {printf("no"); return -1;}
	
	char *_given = listOptions[1];
	if (strlen(_given) < 8) {printf("no"); return -1;}
	if (strncmp(&_given[5], "sd", 2) == 0) {printf("sd"); return 0;}
	if (strncmp(&_given[5], "mm", 2) == 0) {printf("mm"); return 0;}
	if (strncmp(&_given[5], "nv", 2) == 0) {printf("nv"); return 0;}
	
	printf("?");
	return 0;
}
