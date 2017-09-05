#!/usr/bin/perl

use strict; use warnings;

##########################
# Edit the options below #
##########################

# This is the monitored interface name as reported by ifconfig.
my $monitored_iface = 'wlo1';

# Automatically start rtorrent when connected to this(these) gateway(s).
# This can be a single mac address or a comma seperated list of mac addresses
#my $mac_list = '2c:7e:81:af:4c:ff';
my $mac_list = 'c8:b7:e1:16:62:ef,3d:38:d3:6d:1a:a3,2c:7e:81:af:4c:ff';

# The name of the user that should run rtorrent.
# This is normally your username.
my $rtorrent_user = "jay";

########################################
# Do NOT edit anything below this line #
# Unless you know what you are doing   #
########################################
# Global Variables
my $allowed_mac; my $rtorrent_pid; my $rtorrent_screen_pid = 1; my $irssi_pid; my $irssi_screen_pid = 1;

# Validate Input
die "error: script requires 2 arguments\n" if @ARGV != 2;
if ( $ARGV[0] ne "$monitored_iface" ) { print "ignoring interface $ARGV[0]\n"; exit 0; }
if ( $ARGV[1] !~ /^up$|^down$/ ) { print "ignoring state $ARGV[1]\n"; exit 0; }
if ( !defined($monitored_iface) ) { print "no monitored interface specified\n"; exit 0; }
if ( !defined($rtorrent_user) ) { print "no rtorrent user specified\n"; exit 0; }
if ( !defined($mac_list) ) { print "no MAC address specified\n"; exit 0; } else { $mac_list =~ s/\ //g; }

sub check_gateway {
 # Function Variables
 my $gateway_ip; my $gateway_mac; my $mac_address; my @mac_array = split(',', $mac_list);
 my $arp_regex = '.*\sat\s((?:\w\w\:){5}\w\w)\s'; my $mac_regex = '([A-F0-9]{12})';
 my $route_regex = '.*via\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s';

 # Get the IP of the default route
 my $route_cmd = '/sbin/ip route show 0.0.0.0/0'; my $route_output = `$route_cmd`;
 if ( $route_output =~ /$route_regex/ ) { $gateway_ip = $1; } else { print "could not find a valid default route.\n"; exit 0 }

 # Get the MAC address of the default route
 my $arp_cmd = "/usr/sbin/arp -n -a $gateway_ip"; my $arp_output = `$arp_cmd`;
 if ( $arp_output =~ /$arp_regex/ ) { $gateway_mac = $1; } else { print "could not find a valid gateway MAC address.\n"; exit 0 }

 # Strip all characters from the gateway MAC that are not hexadecimal and convert to lowercase
 $gateway_mac =~ s/[^A-F0-9]+//ig; $gateway_mac = lc($gateway_mac);

 # Iterate through the user supplied MAC list
 foreach my $mac_address (@mac_array) {
  # Strip all characters from the provided MAC that are not hexadecimal and convert to lowercase
  $mac_address =~ s/[^A-F0-9]+//ig; $mac_address = lc($mac_address);

  # Check the provided MAC to make sure it is 12 hexadecimal characters
  if ( $mac_address !~ /$mac_regex/i ) { print "invalid mac address \"$mac_address\" specified.\n"; exit 0; }

  # If the gateway MAC and the user provided MAC are the same assign the MAC to allowed_mac
  if ( $gateway_mac eq $mac_address ) { $allowed_mac = $mac_address; }
 }
}

sub check_rtorrent {
 # Function Variables
 my $rtorrent_test = '/usr/bin/pgrep "rtorrent" || echo "1"';

 # If rtorrent is running return the PID otherwise return 1
 $rtorrent_pid = `$rtorrent_test`; chomp($rtorrent_pid);

 # If rtorrent is running the PID will be greater than 1
 if ( $rtorrent_pid gt 1 ) {
  # Get the process tree of rtorrent and check to see if it is being run in screen
  my $rtorrent_tree_cmd = '/usr/bin/pstree -ps ' . $rtorrent_pid;
  my $rtorrent_tree_out = `$rtorrent_tree_cmd`;
  if ( $rtorrent_tree_out =~ /screen\((\d{1,})\)/ ) { $rtorrent_screen_pid = $1; }
 }
}

sub check_irssi {
 # Function variables
 my $irssi_test = '/usr/bin/pgrep "irssi" || echo "1"';

 # If irssi is running return the PID otherwise return 1
 $irssi_pid = `$irssi_test`; chomp($irssi_pid);

 # If irssi is running the PID will be greater than 1
 if ( $irssi_pid gt 1 ) {
  # Get the process tree of irssi and check to see if it is being run in screen
  my $irssi_tree_cmd = '/usr/bin/pstree -ps ' . $irssi_pid;
  my $irssi_tree_out = `$irssi_tree_cmd`;
  if ( $irssi_tree_out =~ /screen\((\d{1,})\)/ ) { $irssi_screen_pid = $1; }
 }
}

&check_gateway;
# If allowed_mac is not defined then there is nothing to do
# IF allowed_mac is defined we have a match
# If rtorrent or irssi is running we kill it no matter what
# If the connection came up we start both
if ( !defined($allowed_mac) ) {print "gateway not matched.\n"; exit 0; } else {
 &check_rtorrent;
 if ( $rtorrent_pid gt 1 ) { `kill $rtorrent_pid`; sleep(1); }
 if ( $rtorrent_screen_pid gt 1 ) { `kill $rtorrent_screen_pid`; sleep(1); }
 &check_irssi;
 if ( $irssi_pid gt 1 ) { `kill $irssi_pid`; sleep(1); }
 if ( $irssi_screen_pid gt 1 ) { `kill $irssi_screen_pid`; sleep(1); }
 if ( $ARGV[1] eq 'up' ) {
  my $start_rtorrent_screen = '/usr/bin/sudo -u ' . "$rtorrent_user" . ' /usr/bin/screen -dmS rtorrent';
  my $start_irssi_screen = '/usr/bin/sudo -u ' . "$rtorrent_user" . ' /usr/bin/screen -dmS irssi';
  system($start_irssi_screen); sleep(1); system('/usr/bin/screen -S irssi -p 0 -X stuff "/usr/bin/irssi^M"'); sleep(1);
  system($start_rtorrent_screen); sleep(1); system('/usr/bin/screen -S rtorrent -p 0 -X stuff "/usr/bin/rtorrent^M"'); sleep(1);
 }
}
exit 0;
