<?php

include 'config.php';

if ($num_rows1 == 0){
$message = "FALSE";
echo $message;}

else{
while($row =$result1->fetchArray()){
echo $row["fqdn"]." | ".$row["cstatus"]." | ".$row["ctime"]." | ".$row["pstatus"]." | ".$row["ptime"];
echo nl2br("\n");

}}

?>
