#include <stdio.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#ifdef __APPLE__
#include <sys/sysctl.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif

#include "address.h"


void get_mac_addr(char MAC_str[13], char *name) {
  unsigned char       *ptr;
#ifdef __APPLE__
  int                  mib[6];
  size_t               len;
  char                *buf;
  struct if_msghdr    *ifm;
  struct sockaddr_dl  *sdl;

  mib[0] = CTL_NET;
  mib[1] = AF_ROUTE;
  mib[2] = 0;
  mib[3] = AF_LINK;
  mib[4] = NET_RT_IFLIST;
  if ((mib[5] = if_nametoindex(name)) == 0) {
      perror("if_nametoindex error");
      exit(2);
  }

  if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
      perror("sysctl 1 error");
      exit(3);
  }

  if ((buf = malloc(len)) == NULL) {
      perror("malloc error");
      exit(4);
  }

  if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
      perror("sysctl 2 error");
      exit(5);
  }

  ifm = (struct if_msghdr *)buf;
  sdl = (struct sockaddr_dl *)(ifm + 1);
  ptr = (unsigned char *)LLADDR(sdl);

#else
  #define HWADDR_len 6
  int s;
  struct ifreq ifr;
  if ((s = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
    perror("socket error");
    exit(1);
  }
  strcpy(ifr.ifr_name, name);

  if (ioctl(s, SIOCGIFHWADDR, &ifr) < 0) {
    perror("ioctl error");
    exit(2);
  }

  ptr = (unsigned char*)ifr.ifr_hwaddr.sa_data;

#endif

  sprintf(MAC_str, "%02x%02x%02x%02x%02x%02x", *ptr, *(ptr+1), *(ptr+2),
        *(ptr+3), *(ptr+4), *(ptr+5));
  MAC_str[12]='\0';
}


#ifdef MAKE_ADDRESS_MAIN
int main(int argc, char *argv[])
{
    char mac[13];

    get_mac_addr(mac, INTERFACE_NAME);
    puts(mac);

    return 0;
}
#endif
