#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <assert.h>
#include <assert.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define IPADDR  		("141.212.11.114")
#define MAX_PACKET_SIZE 	1024
#define MAX_CODE_SIZE 		128
#define BEGIN_MSG_SIZE 		10
#define END_MSG_SIZE 		4

const char begin_msg[BEGIN_MSG_SIZE] 	= {' ', ' ', '_', 'S', 'E', 'C', 'R', 'E', 'T', '_'};
const char end_msg[END_MSG_SIZE] 	= {'S', 'T', 'O', 'P'};

int parse_mem_file(char* buf, char* filename);
int get_raw_instrs(int* instrs, char* filename);
int get_hex_num(char* input);

int main(int argc, char** argv) {
    	if (argc != 2){
		perror("No input mem file!");
		exit(1);
    	}	

    	char buf[MAX_PACKET_SIZE];
    	size_t buf_size = parse_mem_file(buf, argv[1]);

    	int sd;
    	struct sockaddr_in sockaddr;

    	// setup connection to server
    	sd = socket(AF_INET, SOCK_DGRAM, 0);
    	if (sd < 0){
       		perror("Could not open socket");
       		exit(1);
    	}

    	// destination settings
    	memset(&sockaddr, 0, sizeof(sockaddr));
    	sockaddr.sin_family = AF_INET;
    	sockaddr.sin_port = htons(55056);
    	inet_aton(IPADDR, &sockaddr.sin_addr);

    	// transmit arbitrary bytes
    	if (sendto(sd, buf, buf_size, MSG_NOSIGNAL, (struct sockaddr*)&sockaddr, sizeof(sockaddr)) < 0){
		perror("Failure to send");
		exit(1);
    	}

    	return 0;
}

int parse_mem_file(char* buf, char* filename){
	int instrs[MAX_CODE_SIZE];
	int i, n;

	int instr_size = get_raw_instrs(instrs, filename);
	char* data_packet = (char*)malloc(BEGIN_MSG_SIZE + 4*instr_size + END_MSG_SIZE);

	for (i = 0; i < BEGIN_MSG_SIZE; i++)
		data_packet[i] = begin_msg[i];

	for (n = 0; n < instr_size; n++){
		data_packet[i++] = (char)((instrs[n] >> 0) & 0xFF);
		data_packet[i++] = (char)((instrs[n] >> 8) & 0xFF);
		data_packet[i++] = (char)((instrs[n] >> 16) & 0xFF);
		data_packet[i++] = (char)((instrs[n] >> 24) & 0xFF);
	}

	for (n = 0; n < END_MSG_SIZE; n++)
		data_packet[i++] = end_msg[n];

	assert(i == BEGIN_MSG_SIZE + 4*instr_size + END_MSG_SIZE);
	memcpy(buf, data_packet, i);
	free(data_packet);
	return i;
}

int get_raw_instrs(int* instrs, char* filename){
	FILE *fp;
	fp = fopen(filename, "r");
	int pos = 0;
	if (fp == NULL){
		perror("Input mem file not found!");
		exit(1);
	}

	char buf[128];
	while (fgets(buf, sizeof(buf), fp) != NULL){
		if (buf[0] != '@')
			continue;
		char instr[9];
		memcpy(instr, buf + 10, 8);
		instr[8] = '\0';
		instrs[pos++] = get_hex_num(instr);
	}

	return pos;
}

int get_hex_num(char* input){
	int num;
	sscanf(input, "%x", &num);
	return num;
}
