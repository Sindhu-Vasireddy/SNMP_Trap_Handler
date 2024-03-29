#!/usr/bin/perl -w

use Net::SNMP qw(:ALL);
use DBI;
use SNMP::Trapinfo;
use warnings;
no warnings;

use feature 'say';

say "I START HERE THIS TIME.";
#FETCHING FQDN AND STATUS
$trap = SNMP::Trapinfo->new(*STDIN);
$var= $trap->data;
$fqdn = @{$var}{'.1.3.6.1.4.1.41717.10.1'};
$cstatus = @{$var}{'.1.3.6.1.4.1.41717.10.2'};

say "fqdn: $fqdn";
say "status: $cstatus";

#CONNECTING TO THE DATABASE

my $driver = "SQLite";
my $database = "snmptrap.db";
my $dsn = "DBI:$driver:$database";
my $userid = "";
my $password = "";
my $dbh = DBI->connect($dsn,$userid,$password, { RaiseError => 1}) or die $DBI::errstr;
say "Opened database succesfully";

#CREATING TABLES IN CASE THEY DO NOT ALREADY EXIST 

my $stmt = qq(CREATE TABLE IF NOT EXISTS trap
          (fqdn CHAR(100), 
           cstatus INTEGER,
           ctime UNSIGNED32,
           pstatus INTEGER,
           ptime UNSIGNED32););

my $rv = $dbh -> do($stmt);
if ($rv < 0) {

	print $DBI::errstr;
} else {
	say "Table created succesfully \n";																																																																																																																						
}

#COUNT THE NUMBER OF ENTRIES WITH THE DANGER STATUS BEFORE UPDATING THE DATABASE WITH A NEW ENTRY. 
my $num_rows1 = $dbh->selectrow_array("select COUNT(*) as count from trap where cstatus=2");
say "No of Danger entries:$num_rows1";
																																																																										
#ctime
my $time=time;



#CHECK FOR PREVIOUS TRAPS FROM THE SAME DEVICE
my $stmt1 = qq(select rowid from trap where fqdn=$fqdn);
my $sql1 = $dbh->prepare($stmt1);
my $out1 = $sql1->execute()  or die " hello world unable to execute sql: $sql->errstr";
while ( my @row = $sql1->fetchrow_array()){
  $getid = $row[0];
  say $getid;
}
print "getid=$getid";


#IN CASE OF A PREVIOUS ENTRY
if ($getid){
#UPDATE ptime AND pstatus
my $stmt2 = qq(select cstatus,ctime from trap where fqdn=$fqdn);
my $sql2 = $dbh->prepare($stmt2);
my $out2 = $sql2->execute() or die $DBI::errstr;
while (my @row2 = $sql2->fetchrow_array()){
my $pstatus= $row2[0];
my $ptime= $row2[1];
say "hey:$ptime";
say "hey:$pstatus";

my $stmt3 = qq(update trap set pstatus=$pstatus, ptime=$ptime where fqdn=$fqdn);	
my $sql3 = $dbh->prepare($stmt3);
my $out3 = $sql3->execute() or die $DBI::errstr;

#UPDATE ctime AND cstatus
my $stmt4 = qq(update trap set cstatus=$cstatus, ctime=$time where fqdn=$fqdn);
my $sql4 = $dbh->prepare($stmt4);
my $out4 = $sql4->execute() or die $DBI::errstr;
}}



#IN CASE OF A NEW ENTRY
else{
my $stmt9 = qq(insert into trap (fqdn, ctime, cstatus) values ($fqdn, $time, $cstatus));
my $sql9 = $dbh->prepare($stmt9);
my $out9 = $sql9->execute() or die $DBI::errstr;}



#IF A DEVICE HAS REPORTED FAIL
say "Now checking for FAIL";
if ($cstatus == 3){
my $sql5 = $dbh->prepare("select ip,port,community from trapdestination");
my $out5 = $sql5->execute() or die $DBI::errstr;
while (($ip,$port,$community) = $sql5->fetchrow_array()){
my $snmp_ip = "$ip";
my $snmp_port= "$port";

say $snmp_ip;
say $snmp_port;

my $enterprise = '.1.3.6.1.4.1.41717.20';

my ($sess, $err) = Net::SNMP->session(
    -hostname  => $snmp_ip,
    -port      => $snmp_port,
    -version => 1, 
);

if (!defined $sess){
    print "Error connecting to target ". $snmp_ip . ": ". $err;
    next;}

my @varbindlist1 = ();
say $fqdn;

my $stmt10 = qq(select ctime,pstatus,ptime from trap where fqdn=$fqdn);		
my $sql10 = $dbh->prepare($stmt10);
my $out10 = $sql10->execute() or die $DBI::errstr;
while (($ctime,$pstatus,$ptime) = $sql10->fetchrow_array()){
my $stmt11 = qq(select fqdn from trap where ctime=$ctime);		
my $sql11 = $dbh->prepare($stmt11);
my $out11 = $sql11->execute() or die $DBI::errstr;	
while(($fqdnstring)=$sql11->fetchrow_array()){
if($ptime){
push(@varbindlist1,"1.3.6.1.4.1.41717.20.1", OCTET_STRING, $fqdnstring, "1.3.6.1.4.1.41717.20.2", UNSIGNED32, $time, "1.3.6.1.4.1.41717.20.3", INTEGER, $pstatus, "1.3.6.1.4.1.41717.20.4", UNSIGNED32, $ptime);}
else{
push(@varbindlist1,"1.3.6.1.4.1.41717.20.1", OCTET_STRING, $fqdnstring, "1.3.6.1.4.1.41717.20.2", UNSIGNED32, $time);} 
}}
my $result = $sess->trap(
		-varbindlist => \@varbindlist1
		);
if (!defined($result)){print "Error while sending the trap: " . $sess->error();}
$sess-> close();
}}



#IF A DEVICE HAS REPORTED DANGER
say "Now checking for Danger";
$i = 0;
my $num_rows = $dbh->selectrow_array("select COUNT(*) as count from trap where cstatus=2");
say "No of Danger entries:$num_rows";




if (($cstatus == 2) && ($num_rows >= 2 ) && ($num_rows1 < $num_rows))
{
my $sql6 = $dbh->prepare("select ip,port,community from trapdestination");
my $out6 = $sql6->execute() or die $DBI::errstr;
while (($ip,$port,$community) = $sql6->fetchrow_array()){
my $snmp_ip = "$ip";
my $snmp_port= "$port";

my $enterprise = '.1.3.6.1.4.1.41717.30';

my ($sess, $err) = Net::SNMP->session(
    -hostname  => $snmp_ip,
    -port      => $snmp_port,
    -version => 1, 
);

my $i = 1;
my $sql7 = $dbh->prepare("select fqdn from trap where cstatus=2");
my $out7 = $sql7->execute() or die $DBI::errstr;
my @varbindlist2 = ();
while (($fqdn) = $sql7->fetchrow_array()){
my $stmt8 = qq(select ctime,pstatus,ptime from trap where fqdn='$fqdn');		
my $sql8 = $dbh->prepare($stmt8);
my $out8 = $sql8->execute() or die $DBI::errstr;
while (($ctime,$pstatus,$ptime) = $sql8->fetchrow_array()){
say "$ctime $pstatus $ptime";	
push (@varbindlist2,"1.3.6.1.4.1.41717.30.$i",OCTET_STRING,$fqdn); $i++;
push (@varbindlist2,"1.3.6.1.4.1.41717.30.$i",UNSIGNED32,$ctime);$i++;
if ($ptime){
push (@varbindlist2,"1.3.6.1.4.1.41717.30.$i",INTEGER,$pstatus);$i++;
push (@varbindlist2,"1.3.6.1.4.1.41717.30.$i",UNSIGNED32,$ptime);$i++;}
else {$i = $i + 2;}
say "This is the array: $varbindlist2[5]";
}}
say "This is the array outside the loop: $varbindlist2[17]";
my $result = $sess->trap(
			-varbindlist => \@varbindlist2,
			);

if (!defined($result)){print "Error while sending the trap: " . $sess->error();}
$sess-> close();}}

$dbh->disconnect();

# # my $host = <STDIN>;
# # chomp($host);
# # say($host);
# # my $ip = <STDIN>;
# # chomp($ip);
# # say($ip);

# my $snmp_target_IP='192.168.184.1';
# my $snmp_trap_port=161;
# # my $fqdn=123456;
# # my $time=2245;
# my @oid=();
# my $enterprise='.1.3.6.1.4.1.41717.30';

# my ($sess, $err) = Net::SNMP->session(
#      -hostname  => $snmp_target_IP,
#      -community=> 'public',
#      -port      => $snmp_trap_port,
#      -version => 1, 
# );

# # say $sess,$err;

# if (!defined $sess){
#     print "Error connecting to target ". $snmp_target_IP . ": ". $err;
# }

# push(@oid,'.1.3.6.1.4.1.41717.30.3', INTEGER, 3); 

# #say shift @oid;
# #say pop @oid;
# #print join(",",@oid);
# print scalar @oid;

# # my $Jsonfmt=encode_json(\@oid);
# # say $Jsonfmt;

# my $result = $sess->trap(
# #                -enterprise => $enterprise,
# # #                -agentaddr => '',
# #                -generictrap => 6,  
# # #                -specifictrap => 17,      
# #		        -varbindlist => ['.1.3.6.1.4.1.41717.30.3', INTEGER, 3],
#                 -varbindlist => \@oid,
              
#  		);
# if (! $result){print "An error occurred sending the trap: " . $sess->error();}
# #say $result;
# $sess-> close();