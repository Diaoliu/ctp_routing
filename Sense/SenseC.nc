#include "../lib/ctp.h"
#include <AM.h>
#include "Timer.h"
/* minimum base frequency */
#define SAMPLING_FREQUENCY 500
/* sending sync msg periodically */
#define SYNC_FREQUENCY 1000
/* maximum transition hops */
#define TTL 25
/* we only can maintain a network with 10 motes */
#define TABLE_SIZE 10

module SenseC {
	uses {
		interface Boot;
		interface Leds;
		/* sampling humidity periodically */
		interface Timer<TMilli> as TimerSense;
		/* sending Sync to maintain routing table periodically */
		interface Timer<TMilli> as TimerSync;
		/* read humidity from chip */
		interface Read<uint16_t>;
		/* get rssi value */
		interface CC2420Packet;
		interface ActiveMessageAddress;
		
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface Receive;
		interface SplitControl as AMControl;
	}
}

implementation {

	/* active message address of this node */
	am_addr_t self_address;

	/* wrapper to carry message*/
	message_t message;
	/* message serial */
	uint16_t counter;
	/* ETX: expected distance between this and root mote */
	uint16_t etx = 0xFFFF;
	/* parent mote */
	am_addr_t parent;
	/* routing table */
	ctp_routing_t routing_table[TABLE_SIZE];
	
	bool busy = FALSE;

/***********************************
* area for private functions
* need to be implemented by everyone
************************************/
	
	/* @autor Diao Liu
	 * @brief send or forward sampled data to next hop accoding rounting table
	 */
	void sendMsg(ctp_msg_t payload) {
		if (!busy) {
			ctp_msg_t *out = (ctp_msg_t*)(call Packet.getPayload(&message, sizeof(ctp_msg_t)));
			if (out == NULL) {
				return;
			}
			*out = payload;
			if (call AMSend.send(parent, &message, sizeof(ctp_msg_t)) == SUCCESS) {
				busy = TRUE;
			}
		}		
	}

	/* @autor Tingze Hong
	 * @brief boardcast my etx 
	 */
	void sendSyn() {
		if (!busy) {
			ctp_syn_t* out = (ctp_syn_t*)(call Packet.getPayload(&message, sizeof(ctp_syn_t)));
			if (out == NULL)
				return;
			out->nodeid = TOS_NODE_ID;
			out->address = self_address;
			out->etx = etx;
			if (call AMSend.send(AM_BROADCAST_ADDR, &message, sizeof(ctp_syn_t)) == SUCCESS) {
			busy = TRUE;
			}
		}
	}

	/* @autor Hongduo Chen
	 * @brief when syn message come in, add a neighborhood or update it
	 *        the items will be ascending sorted
	 * @syn sync message from neighborhood
	 * @rssi rssi from neighborhood 
	 */
	void updateTable(ctp_syn_t syn, uint8_t rssi) {
		/* new item need to be insert */
		ctp_routing_t node;
		node.nodeid = syn.nodeid;
		node.address = syn.address;
		node.etx = syn.etx;
		node.rssi = rssi;
		node.timestamp = call TimerSync.getNow();

		for (int i = 0; i < TABLE_SIZE; ++i) {
			/* current item */
			ctp_routing_t current = routing_table[i];
			/* this item is not empty */
			if(current.nodeid != 0) {
				uint16_t route = node.etx + node.rssi;
				/* new item has better route to root */
				if(route < current.etx + current.rssi) {				
					if (i == TABLE_SIZE - 1) {
						/* relace the last item with new one */
						routing_table[i] = node;
					} else {
						/* shift items by one */
						ctp_routing_t *begin = routing_table + i;
						memcpy(begin + 1, begin, (TABLE_SIZE - 1 - i) * sizeof(ctp_routing_t));
						/* relace the current item with new one */
						routing_table[i] = node;
					}				
				}
			} else {
				/* adding item at a empty place */
				routing_table[i] = node;
			}
		}
	}

	/* @autor Tingze Hong
	 * @brief calculate etx based on routing table
	 * my etx = min(etx of neighborhood + its distance to me)	
	 */
	void updateEtx() {
		/* before seding sync, need to remove deactivated motes from routing table */
		if (routing_table[0] != 0) {
			etx = routing_table[0].ext + routing_table[0].rssi;
			parent = routing_table[0].address;
		}	
	}

	/* @autor Hongduo Chen
	 * @brief when system is booted, its routing table shouble be empty 
	 */
	void initRoutingTable() {
		memset(routing_table, 0, TABLE_SIZE * sizeof(ctp_routing_t));
	}

	event void Boot.booted() {
		initRoutingTable();
		/* get address of this node */
		self_address = call ActiveMessageAddress.amAddress();
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call TimerSense.startPeriodic(SAMPLING_FREQUENCY * TOS_NODE_ID);
			call TimerSync.startPeriodic(SYNC_FREQUENCY + TOS_NODE_ID * 10);
		} else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {}
	
	event void TimerSense.fired() {
		call Read.read();
	}

	event void TimerSync.fired() {
		updateEtx();
		sendSyn();
	}
	
	event void Read.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			ctp_msg_t payload;
			payload.nodeid = TOS_NODE_ID;
			payload.msgid = counter++;
			payload.humidity = data;
			payload.ttl = TTL;
			sendMsg(payload);
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&message == msg) {
			busy = FALSE;
		}	
	}

	async event void ActiveMessageAddress.changed(){}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(ctp_msg_t)) {
			ctp_msg_t *data = (ctp_msg_t*)payload;
			/* if the message has time to live, then forward it to next hop */
			if(data->ttl > 0) {
				ctp_msg_t forward;
				forward.nodeid = data->nodeid;
				forward.msgid = data->msgid;
				forward.humidity = data->humidity;
				forward.ttl = data->ttl - 1;
	
				sendMsg(forward);
			}
		}
			
		if (len == sizeof(ctp_syn_t)) {
			unsigned int old_etx; 
			ctp_syn_t *syn = (ctp_syn_t*)payload;
			uint16_t rssi = (uint16_t) call CC2420Packet.getRssi(msg);
			/* rssi is always negtive */
			updateTable(*syn, -rssi);
			updateEtx();
			if(old_etx != etx) {
				sendSyn();
			}
		}

		return msg;	
	}
}
