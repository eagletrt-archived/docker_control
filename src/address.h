#ifndef FFT_ADDRESS_H
#define FFT_ADDRESS_H


#ifdef __MIPSEL
  #define INTERFACE_NAME "br-wlan"
#elif __APPLE__
  #define INTERFACE_NAME "en0"
  // #warning Building for testing platform
#elif __ARM7__
  //#define INTERFACE_NAME "en0"
  #define INTERFACE_NAME "eth1"
#elif linux
  #define INTERFACE_NAME "enp1s0"
  // #warning Building for testing platform
#else
  #error UNSUPPORTED PLATFORM
#endif

void get_mac_addr(char MAC_str[13], char *name);

#endif
