<?php


class MyDB extends SQLite3
{
      function __construct()
      {
         $this->open('snmptrap.db',$flags=SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE);

      }
}
$db = new MyDB();
if(!$db){
   echo $db->lastErrorMsg();
} 

$db->exec('CREATE TABLE IF NOT EXISTS trap(fqdn CHAR(100), cstatus INTEGER, ctime UNSIGNED32, pstatus INTEGER, ptime UNSIGNED32)');
$db->exec('CREATE TABLE IF NOT EXISTS trapdestination(community varchar(20), port varchar(20), ip varchar(20))');

$result1=$db->query('SELECT * from trap');
$num_rows1 = $db->querySingle("SELECT COUNT(*) as count from trap");

$result2=$db->query('SELECT * from trapdestination');
$num_rows2 = $db->querySingle("SELECT COUNT(*) as count from trapdestination");


?>
