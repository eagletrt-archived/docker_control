#include <stdio.h>
#include "../defines.h"
#include "../address.h"

int main(int argc, char* argv[]) {
  char mac[13];
  if (argc < 2) {
    fprintf(stderr, "I need the interface name as single argument!\n");
    return -1;
  }
  get_mac_addr(mac, argv[1]);
  printf("Version: %s\nMAC address: %s\n", GIT_COMMIT_HASH, mac);
  return 0;
}
