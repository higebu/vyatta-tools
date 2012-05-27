#!/usr/bin/perl -w
# show-dhcp-shared-network.pl
# Output dhcp-server's shared-network-name in JSON format
#

use strict;
use JSON;
use lib "/opt/vyatta/share/perl5/";
use Vyatta::Config;

my $config = new Vyatta::Config;

my $level = "service dhcp-server shared-network-name";
$config->setLevel($level);
my @pools = $config->listOrigNodes();

my @pool_list = ();
my %pool_hash = ();
my @shared_network_list = ();
my %shared_network_hash = ();

foreach my $pool (@pools) {
  $config->setLevel("$level $pool subnet");
  my @cidrs = $config->listOrigNodes();
  my %map_hash = ();
  my %cidr_hash = ();
  my @cidr_list = ();
  my %subnet_hash = ();
  foreach my $cidr (@cidrs) {
    $config->setLevel("$level $pool subnet $cidr static-mapping");
    my @maps = $config->listOrigNodes();
    my %server_hash = ();
    my @server_list = ();
    foreach my $map (@maps) {
      my $ip = $config->returnOrigValue("$map ip-address");
      my $mac = $config->returnOrigValue("$map mac-address");
      $server_hash{$map}{'ip-address'} = $ip;
      $server_hash{$map}{'mac-address'} = $mac;
    }
    push(@server_list, { %server_hash });
    $map_hash{'static-mapping'} = [ @server_list ];
    $cidr_hash{$cidr} = { %map_hash };
  }
  push(@cidr_list, { %cidr_hash });
  $subnet_hash{'subnet'} = [ @cidr_list ];
  $pool_hash{$pool} = { %subnet_hash };
}
push(@shared_network_list, { %pool_hash });
$shared_network_hash{'shared-network-name'} = [ @shared_network_list ];

my $ref = \%shared_network_hash;
my $json = JSON->new->encode($ref);
print "$json\n";
