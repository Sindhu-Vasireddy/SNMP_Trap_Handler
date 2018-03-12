# SNMP Trap Handler Project

## Overview
This project implements a Perl-based SNMP trap handler that receives SNMP traps, processes them, and updates an SQLite database with relevant trap information, including Fully Qualified Domain Name (FQDN) and status. Additionally, it responds to specific trap conditions by sending out additional SNMP traps.

## Features
- Receives SNMP traps from various network devices.
- Extracts FQDN and status information from the traps.
- Stores trap information in an SQLite database for historical tracking.
- Updates the database with new trap entries or modifies existing entries as needed.
- Sends SNMP traps to specified destinations in response to specific trap conditions (e.g., DANGER status or FAIL status).

## Prerequisites
To run the SNMP trap handler script, ensure that you have the following software installed:
- Perl
- Net::SNMP module for Perl
- DBI module for Perl
- SNMP::Trapinfo module for Perl

## Usage
1. Clone the repository to your local machine.
2. Install the required Perl modules using CPAN or any package manager you prefer.
3. Set up an SQLite database named "snmptrap.db" using the provided SQL schema.
4. Update the "trapdestination" table in the database with the destination details for SNMP traps (IP, port, community).
5. Run the SNMP trap handler script using the following command:
   ```perl snmp_trap_handler.pl```
6. The script will start listening for incoming SNMP traps. When traps are received, it will process them and update the database accordingly. It will also send additional traps when specific conditions are met.

## Contributing
Contributions to the project are welcome! If you find any issues or have suggestions for improvements, feel free to create an issue or submit a pull request.

