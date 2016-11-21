#define AM_TYPE 6

struct ctp_msg_t {
	uint16_t next_hop;
	uint16_t nodeid;
	uint16_t msgid;
	uint16_t humidity;
	unsigned int ttl;
};

struct ctp_syn_t {
	uint16_t nodeid;
	uint32_t timestamp;
	uint16_t etx;
};

struct ctp_routing_t {
	uint16_t nodeid;
	uint16_t etx;
	unsigned int rssi;
	uint32_t timestamp;
};
