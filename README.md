# Oracle Database Health Check & Monitoring Tool

A comprehensive monitoring solution that generates detailed HTML reports of Oracle database environments. The tool automatically detects Oracle instances, collects critical metrics, and identifies potential issues to help database administrators maintain optimal database performance and availability.

## Features

- **Multi-platform support**: Tested and verified on Exadata, AIX, Linux, and Power9 systems
- **Container-aware**: SELECT statements work inside containers to display all outputs related to pluggable databases, users, and tablespaces
- **Auto-discovery**: Automatically detects Oracle installations and running instances
- **Comprehensive monitoring**: Collects 20+ key metrics including:
  - Database information and status
  - Tablespace usage and sizing
  - PDB status and metrics
  - User account status and expiration
  - ASM disk group usage
  - Data Guard statistics and synchronization
  - RMAN backup job details
  - System wait events and performance metrics
  - Database block corruption checks
  - Invalid objects reporting
- **Visual reporting**: Generates a well-formatted HTML report with color-coded alerts
- **Error highlighting**: Automatically highlights critical issues, warnings, and alerts
- **Easy deployment**: Simple script execution with minimal dependencies

## Requirements

- Oracle database environment (11g, 12c, 18c, 19c)
- SYSDBA access for monitoring
- Basic shell access on the database server

## Setup

Before running the script, you need to make two modifications:

1. **Set the Oracle Home path**: Edit the `ORACLE_POSSIBLE_HOMES` array to match your environment
   - For AIX: Edit line 18 in `oracle_monitor_aix.sh`
   - For Linux: Edit line 18 in `oracle_monitor_linux.sh`

2. **Change the Data Guard broker password**: 
   - For AIX: Edit line 507 in `oracle_monitor_aix.sh` to replace `sys/Ora2022`
   - For Linux: Edit line 507 in `oracle_monitor_linux.sh` to replace `sys/Ora2022_2022`

## Usage

1. Download the appropriate script for your platform:
   - AIX/KornShell: `oracle_monitor_aix.sh`
   - Linux/Bash: `oracle_monitor_linux.sh`

2. Make the script executable:
```bash
chmod +x oracle_monitor_*.sh
