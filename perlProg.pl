#!/usr/bin/perl -w

use Net::SNMP;
use feature 'say';
use strict;

my $snmp_target_IP='127.0.0.1';
my $snmp_port='162';
my $fqdn="sindhu:VBox";
my $time=2245;
my @oid=();
my $enterprise='1.3.6.1.4.1.41717.20';

my ($sess, $err) = Net::SNMP->session(
    -hostname  => $snmp_target_IP,
    -port      => $snmp_port,
    -version => 1, 
);

say $sess,$err;

if (!defined $sess){
    print "Error connecting to target ". $snmp_target_IP . ": ". $err;
}

push(@oid,"1.3.6.1.4.1.41717.20.1", OCTET_STRING, $fqdn); 

say shift @oid;
say pop @oid;

my $result = $sess->trap(
		-varbindlist => \@oid,
                -enterprise => $enterprise,
		);
if (! $result){print "An error occurred sending the trap: " . $sess->error();}
say $result;
$sess-> close();
