#define AM_TYPE 6

struct ctp_msg_t {
	uint16_t nodeid;
	uint16_t msgid;
	uint16_t humidity;
	uint8_t ttl;
};

struct ctp_syn_t {
	uint16_t nodeid;
	am_addr_t address;
	uint32_t timestamp;
	uint16_t etx;
};

struct ctp_routing_t {
	uint16_t nodeid;
	am_addr_t address;
	uint16_t etx;
	unsigned int rssi;
	uint32_t timestamp;
};
