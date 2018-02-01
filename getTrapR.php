<?php

include 'config.php';

if ($num_rows2 == 0){
$message = "FALSE";
echo $message."<br\>";}

else{
while($row =$result2->fetchArray()){
echo $row["community"]."@".$row["ip"].":".$row["port"];
}}


?>
