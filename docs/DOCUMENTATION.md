```markdown
# Oracle Database Health Check & Monitoring Tool Documentation

## Overview

This tool provides comprehensive monitoring for Oracle database environments by collecting crucial metrics and generating a detailed HTML report. It's designed to help database administrators quickly identify potential issues and maintain optimal database performance.

## Platform Support

The script has been tested and verified on multiple platforms:
- **Exadata** environments
- **AIX** with KornShell (ksh)
- **Linux** with Bash
- **IBM Power9** systems

## Container Database Support

The tool is fully aware of Oracle's multitenant architecture:
- Detects and reports on Container Databases (CDBs) and Pluggable Databases (PDBs)
- SELECT statements work across container boundaries to display accurate information for:
  - Pluggable database status
  - User accounts across all PDBs
  - Tablespace usage for all PDBs
- Cross-container queries provide a complete view of the database environment

## Metrics Collected

### System Level Information
- Oracle environment variables
- Disk space usage with highlighting for nearly full filesystems
- Memory utilization
- Oracle process status
- Listener status

### Database Information
- Database role, name, and status
- Open mode and logging configuration
- Flashback status
- Data protection mode and level

### User Account Status
- Locked accounts
- Expired passwords
- Accounts nearing expiration

### Storage Information
- Tablespace usage and free space
- Recovery area usage
- ASM disk group utilization

### Performance Metrics
- Active sessions
- System wait events
- Blocking locks
- Database uptime

### Data Protection
- Data Guard statistics and synchronization
- RMAN backup job details
- Database corruption checks

### Alerts and Logs
- Recent entries from alert logs
- Highlighting of errors, warnings, and critical issues

## Required Modifications

Before using the script, you must make two key modifications:

### 1. Oracle Home Path

Edit the `ORACLE_POSSIBLE_HOMES` array to match your Oracle installation paths:

For AIX (oracle_monitor_aix.sh):
```bash
# Around line 18
ORACLE_POSSIBLE_HOMES="/oracle/app/19.0.0.0/grid /oracle/app/oracle/product/19.3.0.0/dbhome_1 /oracle/app/oracle/product/18.0.0/dbhome_1 /oracle/app/oracle/product/12.2.0/dbhome_1 /oracle/app/oracle/product/12.1.0/dbhome_1 /oracle/app/oracle/product/19.0.0/dbhome_1 /oracle/app/oracle/product/19.3.0/db_1"
