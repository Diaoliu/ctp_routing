#include "../lib/ctp.h"

/* minimum base frequency */
#define SAMPLING_FREQUENCY 500
/* sending sync msg periodically */
#define SYNC_FREQUENCY 1000
/* maximum transition hops */
#define TTL 25
/* we only can maintain a network with 10 motes */
#define TABLE_SIZE 10

module Sense {
	uses {
		interface Boot;
		interface Leds;
		/* sampling humidity periodically */
		interface TimerSense<TMilli>;
		/* sending Sync to maintain routing table periodically */
		interface TimerSync<TMilli>;
		/* read humidity from chip */
		interface Read<uint16_t>;
		/* get rssi value */
		interface CC2420Packet;
		interface ActiveMessageAddress;
		
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface AMReceive;
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
  
	event void Boot.booted() {
		initRoutingTable();
		/* get address of this node */
		self_address = call amAddress();
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
			sendMsg(playload);
		}
	}

	event void AMSend.sendDone(message_t* msg, error_t err) {
		if (&message == msg) {
			busy = FALSE;
		}	
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
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
	
/*******************************
* area for private functions
* need to be implemented
******************************/
	
	/* @autor Diao Liu
	 * @brief send or forward sampled data to next hop accoding rounting table
	 */
	void sendMsg(ctp_msg_t payload) {
		#warning add your code here
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
		/* every sync has a timestamp to record mote status, live or offline */
		uint32_t timestamp = TimerSync.getNow():

		#warning add your code here
	}

	/* @autor Tingze Hong
	 * @brief calculate etx based on routing table
	 * my etx = min(etx of neighborhood + its distance to me)	
	 */
	void updateEtx() {
		/* before seding sync, need to remove deactivated motes from routing table */
		updateTable(NULL, 0);

		#warning add your code here
	}

	/* @autor Hongduo Chen
	 * @brief when system is booted, its routing table shouble be empty 
	 */
	void initRoutingTable() {
		#warning add your code here
	}
	
	/* @autor Hongduo Chen
	 * @brief when syn message come in, add a neighborhood or update it
	 * @ syn, sync message from neighborhood
	 * @ rssi, rssi from neighborhood 
	 */
	void updateTable(ctp_syn_t syn, uint8_t rssi) {
		#warning add your code here
	}
}
