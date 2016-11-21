## A very basic impletemntation of CTP protocal

[Reference Paper](http://sensys.acm.org/2011/sensys09-ctp.pdf)

#### Routing gradient

In oder to forward the packet efficiently, the mote will choose the shortest distance to root mote. Based on RSSI value, we could detect the relative distance between motes.

#### Routing principle

Below is the basic principle, how a message is forwarded to the root mote along the route.
![](https://dl.dropboxusercontent.com/u/55616012/note/ctp_routing.svg)

#### Routing table

| Node id   | ETX    | RSSI  | Timestamp |
| --------- |:------:| -----:| ---------:|
| 16        | 1      | 2     | 14:22     |
| 1         | 35     | 4     | 15:22     |
| 5         | 16     | 6     | 15:20     |
| 12        | 2      | 52    | 15:18     |

1. From the table we could see, **node 16** is most closed to root mote, but it is long time deactive, so we can not forward the message to it.
2. **node 12** is also very closed to root mote, but it is too far away from us, so it is not the best choise
3. **node 5** is the final choosen one, ETX + RSSI = 16 + 6 = 22, this is also the ETX value of current mote

