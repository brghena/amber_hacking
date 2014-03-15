#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <assert.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define IPADDR  ("141.212.11.114")

void main(int argc, char** argv) {
    int sd;
    struct sockaddr_in sockaddr;

    // setup connection to server
    sd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sd < 0) {
       perror("Could not open socket");
       exit(1);
    }

    // destination settings
    memset(&sockaddr, 0, sizeof(sockaddr));
    sockaddr.sin_family = AF_INET;
    sockaddr.sin_port = htons(55056);
    inet_aton(IPADDR, &sockaddr.sin_addr);

    // create a message
    char* buf = "Testestest";
    size_t buf_size = strlen(buf);

    // transmit arbitrary bytes
    if (sendto(sd, buf, buf_size, MSG_NOSIGNAL, (struct sockaddr*)&sockaddr, sizeof(sockaddr)) < 0) {
        perror("Failure to send");
        exit(1);
    }
}