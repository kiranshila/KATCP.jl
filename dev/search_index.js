var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = KATCP","category":"page"},{"location":"#KATCP","page":"Home","title":"KATCP","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for KATCP.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [KATCP]","category":"page"},{"location":"#KATCP.AbstractKatcpMessage","page":"Home","title":"KATCP.AbstractKatcpMessage","text":"Supertype of the three abstract messages; Replies, Informs, and Requests\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.DisconnectInform","page":"Home","title":"KATCP.DisconnectInform","text":"Sent to the client by the device shortly before the client is disconnected. In the case where a client is being disconnected because a new client has connected, the message should include the IP number and port of the new client for tracking purposes.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.HaltReply","page":"Home","title":"KATCP.HaltReply","text":"This reply is sent just before the halt occurs.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.HaltRequest","page":"Home","title":"KATCP.HaltRequest","text":"This request should trigger a software halt. It is expected to close the connection and put the software and hardware into a state where it is safe to power down.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.HelpInform","page":"Home","title":"KATCP.HelpInform","text":"Although the description is not intended to be machine readable, the preferred convention for describing the parameters and return values is to use a syntax like that seen on the right-hand side of a BNF produc- tion (as commonly seen in the usage strings of UNIX command-line utilities and the synopsis sections of man pages).\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.HelpRequest","page":"Home","title":"KATCP.HelpRequest","text":"Before sending a reply, the help request will send a number of #help inform messages. If no name parameter is sent the help request will return one inform message for each request available on the device. If a name parameter is specified, only an inform message for that request will be sent. On success the first reply parameter after the status code will contain the number of help inform messages generated by this request. If the name parameter does not correspond to a request on the device, a reply with a failure code and message should be sent.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.InterfaceChangedInform","page":"Home","title":"KATCP.InterfaceChangedInform","text":"Only required for dynamic devices, i.e. devices that may change their katcp interface during a connection. Sent to the client by the device to indicate that the katcp interface has changed. Passing no arguments with the inform implies that the whole katcp interface may have changed. The optional parameters allow more fine grained specification of what changed\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.KatcpAddress","page":"Home","title":"KATCP.KatcpAddress","text":"The IPv4/v6 address type from KATCP\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.RawMessage","page":"Home","title":"KATCP.RawMessage","text":"The core message type of KATCP.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.RawMessage-Tuple{AbstractArray{UInt8}}","page":"Home","title":"KATCP.RawMessage","text":"Parse an incoming vector of bytes (without trailing newline) into a RawMessage.\n\n\n\n\n\n","category":"method"},{"location":"#KATCP.RestartReply","page":"Home","title":"KATCP.RestartReply","text":"This reply is sent just before the restart occurs.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.RestartRequest","page":"Home","title":"KATCP.RestartRequest","text":"This message should trigger a software reset. It is expected to close the connection, reload the software and begin execution again, preferably without changing the hardware configuration (if possible). It would end with the device being ready to accept new connections again. The reply should be sent before the connection to the current client is closed.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.VersionConnectInform","page":"Home","title":"KATCP.VersionConnectInform","text":"Sent to the client when it connects. These inform messages use the same argument format as VersionListInform and all roles and components declared via VersionConnectInform should be included in the informs sent in response to VersionListRequest.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.VersionListRequest","page":"Home","title":"KATCP.VersionListRequest","text":"Before sending a reply the ?version-list command will send a series of #version-list informs. The list of informs should include all of the roles and components returned via #version-connect but may contain additional roles or components.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.WatchdogReply","page":"Home","title":"KATCP.WatchdogReply","text":"This reply is sent in response to a WatchdogRequest\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.WatchdogRequest","page":"Home","title":"KATCP.WatchdogRequest","text":"This  may be sent by the client occasionally to check that the connection to the device is still active. The device should respond with a success reply if it receives the watchdog request.\n\n\n\n\n\n","category":"type"},{"location":"#KATCP.serialize-Tuple{RawMessage}","page":"Home","title":"KATCP.serialize","text":"Serialize a RawMessage into a vector of bytes (without trailing newline)\n\n\n\n\n\n","category":"method"}]
}