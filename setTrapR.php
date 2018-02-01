<?php

include 'config.php';

$ip =$_GET['ip'];
$port = $_GET['port'];
$community = $_GET['community'];
if (empty($port) || empty($community) || empty($ip)){
$message = "FALSE";
echo $message."<br\>";
}
else{
$message = "OK";

if ($num_rows2 > 0){
while($row =$result2->fetchArray()){
$db->exec("update trapdestination set ip='$ip', port='$port', community='$community'");
}}
else{
$db->exec("INSERT INTO trapdestination(community, port, ip) VALUES ('$community','$port','$ip')");
}
echo $message."<br\>";
}


?>

