#!/usr/bin/perl
#### SNMP trap handler

use Net::SNMP;
use DBI;
my $dsn = "dbi:mysql:snmp";
my $username = "root";
my $password = "sreekv333";
my %attr = (PrintError=>0,
            RaiseError=>1);
my $dbh = DBI->connect($dsn,$username,$password, \%attr);
my $TRAP_FILE = "/home/srikasyap/Desktop/traps.all.log";	
my $my_file = "/home/srikasyap/myfile.txt";
my $host = <STDIN>;	# Read the Hostname - First line of input from STDIN
chomp($host);
my $ip = <STDIN>;	# Read the IP - Second line of input
chomp($ip);
while(<STDIN>) {
chomp($_);
push(@vars,$_);}
open(TRAPFILE, ">> $TRAP_FILE");
$date = `date`;
chomp($date);
print(TRAPFILE "New trap received: $date for $OID\n\nHOST: $host\nIP: $ip\n");
foreach(@vars) {
print(TRAPFILE "TRAP: $_\n");}
print(TRAPFILE "\n----------\n");
close(TRAPFILE);


## to store the status,fqdn and timestamp in mysqldb ##
###### retrieving the values from the received trap ######
open(fh,"> $my_file");foreach (@vars) {print (fh "$_\n");}close(fh);

### to get the status of the trap ###
$out0 = `cat $my_file | grep 10.2`;@out0 = split /[ ]/,$out0;
$cstatus = $out0[-1];


### to get the FQDN from the trap ###
$out1 = `cat $my_file | grep 10.1`;@out1 = split /[ ]/,$out1;
$fqdn = $out1[-1];

### to store the present time in a variable ###
$time = time;
$del = `rm $my_file`;

###### to check the database for previous traps from same agent (fqdn) ##########
$sql = $dbh->prepare("select id from snmptrap where fqdn=$fqdn");
$out = $sql->execute() or die " hello world unable to execute sql: $sql->errstr";
while (($id) = $sql->fetchrow_array()){
$gett = $id;}
### if previous trap is present from the same agent (fqdn) ###########
if ($gett){
###### updating the previous timestamp and previous status columns in the existing row ######
$sql9 = $dbh->prepare("select cstatus,ctime from snmptrap where fqdn=$fqdn");
$out9 = $sql9->execute() or die "unable to execute sql: $sql9->errstr";
while ((my $pstatus,my $ptime) = $sql9->fetchrow_array()){
$sql18 = $dbh->prepare("update snmptrap set pstatus=$pstatus, ptime=$ptime where fqdn=$fqdn");
$out18 = $sql18->execute() or die "unable to execute sql: $sql18->errstr";

###### updating the current timestamp and current status of the of the new trap in the existing row ######

$sql19 = $dbh->prepare("update snmptrap set cstatus='$cstatus', ctime='$time' where fqdn=$fqdn");
$out19 = $sql19->execute() or die "unable to execute sql: $sql19->errstr";


### if current status is fail then

if ($cstatus == "3"){
$sql2 = $dbh->prepare("select ip,port,community from snmptrapmanager");
$out2 = $sql2->execute() or die "unable to execute sql: $sql2->errstr";
while (($ip,$port,$community) = $sql2->fetchrow_array()){
my $snmp_target = "$ip";
my $snmp_port= "$port";

my $enterprise = '.1.3.6.1.4.1.41717.20';

my ($sess, $err) = Net::SNMP->session(
    -hostname  => $snmp_target,
    -port      => $snmp_port,
    -version => 1, 
);

if (!defined $sess) {
    print "Error connecting to target ". $snmp_target . ": ". $err;
    next;}

my @oid = ();

if($ptime != "--"){
push(@oid,"1.3.6.1.4.1.41717.20.1", OCTET_STRING, $fqdn, "1.3.6.1.4.1.41717.20.2", UNSIGNED32, $time, "1.3.6.1.4.1.41717.20.3", INTEGER, $pstatus, "1.3.6.1.4.1.41717.20.4", UNSIGNED32, $ptime);}
else{
push(@oid,"1.3.6.1.4.1.41717.20.1", OCTET_STRING, $fqdn, "1.3.6.1.4.1.41717.20.2", UNSIGNED32, $time);} 
my $result = $sess->trap(
		-varbindlist => \@oid
		);
	$sess-> close();
}}


### checking if there are more than 2 danger traps
$i = 0;
$danger_count = $dbh->prepare("select $cstatus from snmptrap where cstatus=2");
$count = $danger_count->execute() or die "cannot query\n";
while (($cstatus) = $danger_count->fetchrow_array())
{$i++;}
if ($i >= 2 )
{
$sql2 = $dbh->prepare("select ip,port,community from snmptrapmanager");
$out2 = $sql2->execute() or die "unable to execute sql: $sql2->errstr";
while (($ip,$port,$community) = $sql2->fetchrow_array()){
my $snmp_target = "$ip";
my $snmp_port= "$port";

my $enterprise = '.1.3.6.1.4.1.41717.30';

my ($sess, $err) = Net::SNMP->session(
    -hostname  => $snmp_target,
    -port      => $snmp_port,
    -version => 1, 
);

$i = 1;
$sql99 = $dbh->prepare("select fqdn from snmptrap where cstatus=2");
$out99 = $sql99->execute() or die "connection failed";
while (($fqdn) = $sql99->fetchrow_array()){
$sql099 = $dbh->prepare("select ctime,pstatus,ptime from snmptrap where fqdn='$fqdn'");
$out099 = $sql099->execute() or die "connection failed";
@vars1 = ();
while (($ctime,$pstatus,$ptime) = $sql099->fetchrow_array()){
push (@vars1,"1.3.6.1.4.1.41717.30."."$i",OCTET_STRING,"$fqdn"); $i++;
push (@vars1,"1.3.6.1.4.1.41717.30."."$i",UNSIGNED32,$ctime);$i++;
if ($pstatus !="--"){
push (@vars1,"1.3.6.1.4.1.41717.30."."$i",OCTET_STRING,"$pstatus");$i++;
push (@vars1,"1.3.6.1.4.1.41717.30."."$i",UNSIGNED32,$ptime);$i++;}
else {$i = $i + 2;}
my $result = $sess->trap(
			-varbindlist => \@vars1
			);
}}
if (! $result){print "An error occurred sending the trap: " . $sess->error();}
$sess-> close();}}
}}


###### if there is no previous trap from the agent ######
######(fqdn) previously then we are going to create a new row for the agent (fqdn) ###### 
else{
$sql9 = $dbh->prepare("insert into snmptrap (fqdn, ctime, cstatus, pstatus, ptime) values ($fqdn, '$time', '$cstatus', '--', '--')");
$out9 = $sql9->execute() or die "unable to execute sql: $sql9->errstr";}


$dbh->disconnect();