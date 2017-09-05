# torrent-gateway

A simple script to automatically start rtorrent when connected to specific networks and stop rtorrent when the monitored interface goes down.

For example:  
Stop rtorrent when the wireless interface goes down.  
Start rtorrent when connected to WiFi at home.  
Do not start rtorrent when tethered to cell phone or connected at work.  

How to use:

There are three variables that need to be edited in the script:

monitored_interface: The interface that we should watch (eth0, wlo1, etc)  
mac_list: When connected to one of these networks rtorrent will automatically start. This is a single address or a comma seperated list.  
rtorrent_user: the username of the user that should run rtorrent. Generally your username.  

Rename the script to xxtorrentgateway where xx is a 2 digit number (recommend greater than 40)

Copy the script to /etc/NetworkManager/dispatcher.d/ and make executable.
