# Oracle Database Health Check & Monitoring Tool

A comprehensive monitoring solution that generates detailed HTML reports of Oracle database environments. The tool automatically detects Oracle instances, collects critical metrics, and identifies potential issues to help database administrators maintain optimal database performance and availability.

## 💝 Support This Project

**This tool is completely FREE!** If this Oracle monitoring solution has been helpful for your database administration needs, please consider supporting its development:

[![Donate with PayPal](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://paypal.me/AhmedAlhedewy?country.x=EG&locale.x=en_US)

Your donations help me continue developing and maintaining free Oracle tools for the DBA community. With your support, I can create more useful scripts and utilities to help Oracle administrators worldwide. Every contribution, no matter how small, makes a difference! 🙏

**Why donate?**
- Keep this tool free and open source
- Fund development of additional Oracle monitoring scripts
- Support ongoing maintenance and updates
- Help create more database administration utilities

---

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
   - For AIX: Edit line 507 in `oracle_monitor_aix.sh` to replace `sys/PASSWORD`
   - For Linux: Edit line 507 in `oracle_monitor_linux.sh` to replace `sys/PASSWORD`

## Usage

1. Download the appropriate script for your platform:
   - AIX/KornShell: `oracle_monitor_aix.sh`
   - Linux/Bash: `oracle_monitor_linux.sh`

2. Make the script executable:
```bash
chmod +x oracle_monitor_*.sh
```

## Contributing

Contributions are welcome! If you find bugs or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is open source. Feel free to use, modify, and distribute according to your needs.

---

**Made with ❤️ for the Oracle DBA community**
