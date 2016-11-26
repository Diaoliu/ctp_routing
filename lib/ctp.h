#ifndef _CTP_H
#define _CTP_H
#define AM_TYPE 6
#include <AM.h>

typedef nx_struct ctp_msg_t {
	nx_uint16_t nodeid;
	nx_uint16_t msgid;
	nx_uint16_t humidity;
	nx_uint8_t ttl;
} ctp_msg_t;

typedef nx_struct ctp_syn_t {
	nx_uint16_t nodeid;
	nx_am_addr_t address;
	nx_uint32_t timestamp;
	nx_uint16_t etx;
} ctp_syn_t;

typedef nx_struct ctp_routing_t {
	nx_uint16_t nodeid;
	nx_am_addr_t address;
	nx_uint16_t etx;
	nx_uint16_t rssi;
	nx_uint32_t timestamp;
} ctp_routing_t;

#endif
