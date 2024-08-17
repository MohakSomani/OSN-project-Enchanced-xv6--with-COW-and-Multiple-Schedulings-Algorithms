#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int 
main(void) {
    int r=getreadcount();
    printf("Till now total %d Read calls have occured.\n",r);
    // printf("Hi\n");
    return 0;
    exit(1);
 }