#!/usr/bin/ksh

TIMEOUT=1000

# Start time in seconds since epoch
START_TIME=`perl -e 'print time'`

# Load Oracle environment
if [ -f $HOME/.profile ]; then
    . $HOME/.profile
fi

# Try multiple locations for sqlplus if not already in PATH
if ! which sqlplus >/dev/null 2>&1; then
    echo "Warning: sqlplus not found in PATH, trying common locations..."
    
    # Common Oracle binary locations on AIX
    ORACLE_POSSIBLE_HOMES="/oracle/app/19.0.0.0/grid /oracle/app/oracle/product/19.3.0.0/dbhome_1 /oracle/app/oracle/product/18.0.0/dbhome_1 /oracle/app/oracle/product/12.2.0/dbhome_1 /oracle/app/oracle/product/12.1.0/dbhome_1 /oracle/app/oracle/product/19.0.0/dbhome_1 /oracle/app/oracle/product/19.3.0/db_1"
    
    for OH in $ORACLE_POSSIBLE_HOMES; do
        if [ -d "$OH" ] && [ -f "$OH/bin/sqlplus" ]; then
            export ORACLE_HOME=$OH
            export PATH=$ORACLE_HOME/bin:$PATH
            echo "Found Oracle Home: $ORACLE_HOME"
            break
        fi
    done
    
    # Try to find Oracle home directories dynamically
    if ! which sqlplus >/dev/null 2>&1; then
        echo "Searching for Oracle installations..."
        FOUND_HOMES=`find /oracle /opt /ora* -name sqlplus 2>/dev/null | grep -v "instant" | grep -v "client" | head -1`
        
        if [ -n "$FOUND_HOMES" ]; then
            ORACLE_HOME=`dirname $(dirname $FOUND_HOMES)`
            export ORACLE_HOME
            export PATH=$ORACLE_HOME/bin:$PATH
            echo "Found Oracle Home: $ORACLE_HOME"
        fi
    fi
fi

# Final check for sqlplus
if ! which sqlplus >/dev/null 2>&1; then
    echo "Error: sqlplus not found in PATH"
    echo "Please enter the ORACLE_HOME path manually: "
    read REPLY?"ORACLE_HOME="
    user_oracle_home=$REPLY
    
    if [ -d "$user_oracle_home" ] && [ -f "$user_oracle_home/bin/sqlplus" ]; then
        export ORACLE_HOME=$user_oracle_home
        export PATH=$ORACLE_HOME/bin:$PATH
        echo "Using Oracle Home: $ORACLE_HOME"
    else
        echo "Invalid ORACLE_HOME or sqlplus not found in $user_oracle_home/bin"
        exit 1
    fi
fi

check_timeout() {
    CURRENT_TIME=`perl -e 'print time'`
    ELAPSED_TIME=`expr $CURRENT_TIME - $START_TIME`
    if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
        echo "Script timed out after $TIMEOUT seconds"
        exit 124
    fi
}

OUTPUT_DIR="/home/oracle/oracle_reports"

# Create output directory with fallback to current directory
if ! mkdir -p $OUTPUT_DIR 2>/dev/null; then
    OUTPUT_DIR="`pwd`/oracle_reports"
    mkdir -p $OUTPUT_DIR
    echo "Warning: Could not create directory at /home/oracle/oracle_reports"
    echo "Using current directory instead: $OUTPUT_DIR"
fi

OUTPUT_FILE="$OUTPUT_DIR/oracle_report_`date +%d_%m_%Y_%H_%M_%S`.html"

cat << EOF > $OUTPUT_FILE
<!DOCTYPE html>
<html>
<head>
    <title>Oracle Database Monitoring Report - `date`</title>
     <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #00205B; text-align: center; }
        h2 { color: #333; border-bottom: 2px solid #333; }
        h3 { color: #00418D; margin-left: 10px; }
        pre { background-color: #f5f5f5; padding: 10px; border-radius: 5px; }
        .section { margin-bottom: 30px; }
        .error { color: #FF0000; font-weight: bold; }
        .warning { color: #FFA500; font-weight: bold; }
        .critical { color: #FF0000; background-color: #FFE0E0; font-weight: bold; }
        .alert { color: #FF4500; font-weight: bold; }
        .expired { color: #FF6347; font-weight: bold; }
        .locked { color: #FF8C00; font-weight: bold; }
        .high-usage { color: #FF4500; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        #toc { background-color: #f8f8f8; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        #toc h2 { border-bottom: 1px solid #ddd; }
        #toc ul { list-style-type: none; padding-left: 10px; }
        #toc li { margin-bottom: 5px; }
        #toc a { text-decoration: none; color: #0066cc; }
        #toc a:hover { text-decoration: underline; }
        .sid-section { border: 1px solid #ddd; border-radius: 5px; margin-bottom: 30px; padding: 15px; }
        .sid-section h2 { background-color: #e6f2ff; padding: 10px; margin-top: 0; }
        .summary { background-color: #f2f2f2; padding: 15px; border-radius: 5px; margin-top: 20px; }
    </style>
</head>
<body>
    <h1>Oracle Database Monitoring Report V1 (AIX)</h1>
    <p style="text-align: center;">Generated on: `date`</p>
    
    <div id="toc">
        <h2>Table of Databases</h2>
        <ul>
            <li><a href="#system-info">System Information</a></li>
EOF

# Add system-level sections first
add_system_section() {
    echo "<div class='section' id='system-info'>" >> $OUTPUT_FILE
    echo "<h2>System Information</h2>" >> $OUTPUT_FILE
    
    # Add subsections for system information
    echo "<div class='section'>" >> $OUTPUT_FILE
    echo "<h3>Oracle Environment</h3>" >> $OUTPUT_FILE
    echo "<pre>" >> $OUTPUT_FILE
    echo "ORACLE_HOME=$ORACLE_HOME" >> $OUTPUT_FILE
    echo "PATH=$PATH" >> $OUTPUT_FILE
    env | grep -E "ORACLE|TNS|LD_LIBRARY" | while read line; do
        line=`echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`
        echo "$line"
    done >> $OUTPUT_FILE
    echo "</pre>" >> $OUTPUT_FILE
    echo "</div>" >> $OUTPUT_FILE
    
    echo "<div class='section'>" >> $OUTPUT_FILE
    echo "<h3>Disk Space Usage</h3>" >> $OUTPUT_FILE
    echo "<pre>" >> $OUTPUT_FILE
    df -g 2>/dev/null | while read line; do
        line=`echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`
        
        if echo "$line" | grep -E "100%|9[0-9]%" > /dev/null; then
            echo "<span class='high-usage'>$line</span>"
        else
            echo "$line"
        fi
    done >> $OUTPUT_FILE
    echo "</pre>" >> $OUTPUT_FILE
    echo "</div>" >> $OUTPUT_FILE
    
    echo "<div class='section'>" >> $OUTPUT_FILE
    echo "<h3>Memory Check</h3>" >> $OUTPUT_FILE
    echo "<pre>" >> $OUTPUT_FILE
    # AIX uses different memory commands
    svmon -G 2>/dev/null || vmstat 2>/dev/null | while read line; do
        line=`echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`
        echo "$line"
    done >> $OUTPUT_FILE
    echo "</pre>" >> $OUTPUT_FILE
    echo "</div>" >> $OUTPUT_FILE
    
    echo "<div class='section'>" >> $OUTPUT_FILE
    echo "<h3>Oracle Process Monitor Status</h3>" >> $OUTPUT_FILE
    echo "<pre>" >> $OUTPUT_FILE
    ps -ef 2>/dev/null | grep "ora_" | grep "smon" | grep -v grep | while read line; do
        line=`echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`
        echo "$line"
    done >> $OUTPUT_FILE
    echo "</pre>" >> $OUTPUT_FILE
    echo "</div>" >> $OUTPUT_FILE
    
    # Try to check listener status if lsnrctl is available
    if which lsnrctl >/dev/null 2>&1; then
        echo "<div class='section'>" >> $OUTPUT_FILE
        echo "<h3>Listener Status</h3>" >> $OUTPUT_FILE
        echo "<pre>" >> $OUTPUT_FILE
        lsnrctl status 2>/dev/null | while read line; do
            line=`echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`
            
            if echo "$line" | grep -iE "ERROR|not running" > /dev/null; then
                echo "<span class='critical'>$line</span>"
            else
                echo "$line"
            fi
        done >> $OUTPUT_FILE
        echo "</pre>" >> $OUTPUT_FILE
        echo "</div>" >> $OUTPUT_FILE
    fi
    
    echo "</div>" >> $OUTPUT_FILE
}

# Detect all Oracle SIDs
get_oracle_sids() {
    # Method 1: Check from running processes (looking for smon instead of pmon)
    ps_output=`ps -ef 2>/dev/null | grep "ora_smon_" | grep -v grep | awk '{print $NF}' | sort`
    
    if [ -n "$ps_output" ]; then
        echo "$ps_output" | sed 's/ora_smon_//g'
        return
    fi
    
    # Method 2: Check oratab if ps doesn't work
    if [ -f /etc/oratab ]; then
        grep -v "^#" /etc/oratab | cut -d: -f1 | grep -v '*' | sort
        return
    fi
    
    # Method 2.5: Direct check for Oracle processes
    ps_output=`ps -ef | grep "ora_smon_" | grep -v grep`
    if [ -n "$ps_output" ]; then
        echo "$ps_output" | awk '{print $NF}' | sed 's/ora_smon_//g'
        return
    fi
    
    # Method 3: Try getting SID from Oracle environment if set
    if [ -n "$ORACLE_SID" ]; then
        echo "$ORACLE_SID"
        return
    fi
    
    # Method 4: Ask user if no SIDs found
    echo "No Oracle SIDs detected."
    read REPLY?"Please enter an Oracle SID manually: "
    echo "$REPLY"
}

# For each SID, add a section in the TOC
ORACLE_SIDS=`get_oracle_sids`
sid_count=0

if [ -z "$ORACLE_SIDS" ]; then
    echo "Error: No Oracle SIDs found. Please make sure Oracle instances are running."
    exit 1
fi

for SID in $ORACLE_SIDS; do
    sid_count=`expr $sid_count + 1`
    echo "            <li><a href=\"#$SID\">Database: $SID</a></li>" >> $OUTPUT_FILE
done

# Finish TOC
echo "        </ul>" >> $OUTPUT_FILE
echo "    </div>" >> $OUTPUT_FILE

# Add system-level info first
add_system_section

# Process each SID
for SID in $ORACLE_SIDS; do
    echo "Processing database: $SID"
    
    # Create a section for this SID
    echo "<div class='sid-section' id='$SID'>" >> $OUTPUT_FILE
    echo "<h2>Database: $SID</h2>" >> $OUTPUT_FILE
    
    # Set the ORACLE_SID for this iteration
    export ORACLE_SID=$SID
    
    SQLPLUS=$ORACLE_HOME/bin/sqlplus
    
    if [ ! -f "$SQLPLUS" ]; then
        echo "<div class='section'>" >> $OUTPUT_FILE
        echo "<h3>Error</h3>" >> $OUTPUT_FILE
        echo "<pre class='critical'>Error: SQLPlus not found at $SQLPLUS. Please check ORACLE_HOME setting.</pre>" >> $OUTPUT_FILE
        echo "</div>" >> $OUTPUT_FILE
        continue
    fi
    
    # Test connection to database
    connection_test=`$SQLPLUS -S "/ as sysdba" << EOF
set heading off feedback off verify off
set pages 0 lines 200 trimout on trimspool on
SELECT 'Connection successful' FROM dual;
exit;
EOF
    `
    
    if ! echo "$connection_test" | grep -q "Connection successful"; then
        echo "<div class='section'>" >> $OUTPUT_FILE
        echo "<h3>Connection Error</h3>" >> $OUTPUT_FILE
        echo "<pre class='critical'>Failed to connect to database $SID. Check if the database is running and accessible.</pre>" >> $OUTPUT_FILE
        echo "</div>" >> $OUTPUT_FILE
        continue
    fi
    
    # AIX compatible timeout command - using perl
    perl -e 'alarm(300); exec @ARGV' $SQLPLUS -S "/ as sysdba" << 'EOT' >> $OUTPUT_FILE
set pagesize 1000
set linesize 200
set feedback off
set heading on
set echo off
set verify off
set timing off
set termout on

-- Databases Info
prompt "<div class='section'>"
prompt "<h2>Databases Info</h2>"
prompt "<pre>"
SELECT database_role role, name,db_unique_name, open_mode, log_mode, flashback_on, protection_mode, protection_level FROM v$database;
prompt "</pre>"
prompt "</div>"

-- Active Sessions
prompt "<div class='section'>"
prompt "<h2>Active Sessions</h2>"
prompt "<pre>"
SELECT count (*) , inst_id, status from gv$session group by inst_id , status order by inst_id;
prompt "</pre>"
prompt "</div>"

-- Add section for PDBs
prompt "<div class='section'>"
prompt "<h2>Pluggable Databases</h2>"
prompt "<pre>"
show pdbs
prompt "</pre>"
prompt "</div>"

-- Add section for User Status
prompt "<div class='section'>"
prompt "<h2>Database User Status</h2>"
prompt "<pre>"
SET PAGESIZE 80;
SET LINESIZE 200;
COLUMN PDB_NAME FORMAT A30;
COLUMN USERNAME FORMAT A20;
COLUMN ACCOUNT_STATUS FORMAT A15;
COLUMN EXPIRY_DATE FORMAT A20;
SELECT 
    u.CON_ID,
    (SELECT NAME FROM v$pdbs WHERE con_id = u.con_id) AS PDB_NAME,
    u.USERNAME, 
    u.ACCOUNT_STATUS, 
    u.EXPIRY_DATE 
FROM 
    CDB_USERS u
WHERE 
    ORACLE_MAINTAINED ='N'
    AND (
        u.ACCOUNT_STATUS IN ('LOCKED', 'EXPIRED') 
        OR (u.EXPIRY_DATE IS NOT NULL AND u.EXPIRY_DATE < SYSDATE + 28)
    )
    AND (u.EXPIRY_DATE IS NULL OR u.EXPIRY_DATE > ADD_MONTHS(SYSDATE, -2))
ORDER BY 
    u.CON_ID, u.EXPIRY_DATE DESC;

prompt "</pre>"
prompt "</div>"

-- Add section for Recovery File Destination
prompt "<div class='section'>"
prompt "<h2>Recovery File Destination Space Usage</h2>"
prompt "<pre>"
SELECT ROUND(SPACE_LIMIT / 1024 / 1024 / 1024, 2)              AS "Total Size (GB)", 
       ROUND(SPACE_USED / 1024 / 1024 / 1024, 2)               AS "Used Size (GB)",
       ROUND((SPACE_LIMIT-SPACE_USED) / 1024 / 1024 / 1024, 2) AS "Free Size (GB)",
       ROUND((SPACE_USED / SPACE_LIMIT) * 100, 2)              AS "Used %",
       ROUND(((SPACE_LIMIT-SPACE_USED)/ SPACE_LIMIT) * 100, 2) AS "Free % ",
       ROUND(SPACE_RECLAIMABLE / 1024 / 1024 / 1024, 2)        AS "++ RECLAIMABLE Size (GB)"
FROM V$RECOVERY_FILE_DEST;

prompt "</pre>"
prompt "</div>"

-- Table space size for PDBs
prompt "<div class='section'>"
prompt "<h2>Table space size (All PDBs)</h2>"
prompt "<pre>"

SET PAGES 999
SET LINES 400

COLUMN con_name FORMAT A20
COLUMN tablespace_name FORMAT A20
COLUMN TS_SIZE FORMAT A15
COLUMN TS_FREE FORMAT A15
COLUMN USED_TS FORMAT A15
COLUMN MAX_SIZE FORMAT A15

SELECT 
    cdb.tablespace_name,
    c.name AS con_name,
    ROUND((cdb.bytes - SUM(fs.bytes)) * 100 / cdb.bytes, 2) AS Usage,
    CASE 
        WHEN cdb.bytes >= 1024 * 1024 * 1000 THEN ROUND(cdb.bytes / (1024 * 1024 * 1024), 2) || ' GB'
        ELSE ROUND(cdb.bytes / (1024 * 1024), 2) || ' MB'
    END AS TS_SIZE,
    CASE 
        WHEN SUM(fs.bytes) >= 1024 * 1024 * 1000 THEN ROUND(SUM(fs.bytes) / (1024 * 1024 * 1024), 2) || ' GB'
        ELSE ROUND(SUM(fs.bytes) / (1024 * 1024), 2) || ' MB'
    END AS TS_FREE,
    CASE 
        WHEN (cdb.bytes - SUM(fs.bytes)) >= 1024 * 1024 * 1000 THEN ROUND((cdb.bytes - SUM(fs.bytes)) / (1024 * 1024 * 1024), 2) || ' GB'
        ELSE ROUND((cdb.bytes - SUM(fs.bytes)) / (1024 * 1024), 2) || ' MB'
    END AS USED_TS,
    NVL(ROUND(SUM(fs.bytes) * 100 / cdb.bytes), 2) AS FREE_PCT,
    CASE 
        WHEN cdb.maxbytes >= 1024 * 1024 * 1000 THEN ROUND(cdb.maxbytes / (1024 * 1024 * 1024), 2) || ' GB'
        ELSE ROUND(cdb.maxbytes / (1024 * 1024), 2) || ' MB'
    END AS MAX_SIZE,
    ROUND((cdb.bytes - SUM(fs.bytes)) / (cdb.maxbytes) * 100, 2) AS used_pct_of_max,
    MAX(cdb.autoextensible) AS auto_ext
FROM CDB_FREE_SPACE fs
JOIN 
    (SELECT con_id, tablespace_name, SUM(bytes) bytes, 
            SUM(DECODE(maxbytes, 0, bytes, maxbytes)) maxbytes, 
            MAX(autoextensible) autoextensible 
     FROM CDB_DATA_FILES 
     GROUP BY con_id, tablespace_name) cdb
ON fs.con_id = cdb.con_id AND fs.tablespace_name = cdb.tablespace_name
JOIN V$CONTAINERS c ON c.con_id = cdb.con_id
GROUP BY cdb.tablespace_name, cdb.bytes, cdb.maxbytes, c.name
ORDER BY 2 DESC;

prompt "</pre>"
prompt "</div>"

#Change This #delete this line if the script take two long to run

-- sync between HQ & DR
prompt "<div class='section'>"
prompt "<h2>sync between HQ and DR</h2>"
prompt "<pre>"
SELECT ARCH.THREAD# "Thread", ARCH.SEQUENCE# "Last Sequence Received", APPL.SEQUENCE# "Last Sequence Applied", (ARCH.SEQUENCE# - APPL.SEQUENCE#) "Difference" 
FROM (SELECT THREAD# ,SEQUENCE# FROM V$ARCHIVED_LOG WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$ARCHIVED_LOG GROUP BY THREAD#)) ARCH,(SELECT THREAD# ,SEQUENCE# FROM V$LOG_HISTORY WHERE (THREAD#,FIRST_TIME ) IN (SELECT THREAD#,MAX(FIRST_TIME) 
FROM V$LOG_HISTORY GROUP BY THREAD#)) APPL WHERE ARCH.THREAD# = APPL.THREAD# ORDER BY 1;

prompt "</pre>"
prompt "</div>"

-- used & size of (DATA & FRA)
prompt "<div class='section'>"
prompt "<h2>used and size of (DATA and FRA)</h2>"
prompt "<pre>"
SELECT NAME, STATE, TYPE,
ROUND(TOTAL_MB / 1024, 2) "SIZE_GB",
ROUND(FREE_MB / 1024, 2) "AVAILABLE_GB",
ROUND ((total_mb - free_mb) / total_mb *100, 2) AS "Used%"
FROM v$asm_diskgroup; 

prompt "</pre>"
prompt "</div>"

-- RMAN Backup Job Details
prompt "<div class='section'>"
prompt "<h2>RMAN Backup Job Details</h2>"
prompt "<pre>"
select
SESSION_KEY, INPUT_TYPE, STATUS,
to_char(START_TIME,'mm/dd/yy hh24:mi') start_time,
to_char(END_TIME,'mm/dd/yy hh24:mi')   end_time,
elapsed_seconds/3600                   hrs
from V$RMAN_BACKUP_JOB_DETAILS
order by session_key;
prompt "</pre>"
prompt "</div>"



-- Database Uptime
prompt "<div class='section'>"
prompt "<h2>Database Uptime</h2>"
prompt "<pre>"
SELECT
  FLOOR(SYSDATE - STARTUP_TIME) AS days,
  FLOOR(MOD((SYSDATE - STARTUP_TIME) * 24, 24)) AS hours,
  FLOOR(MOD((SYSDATE - STARTUP_TIME) * 24 * 60, 60)) AS minutes
FROM
  V\$INSTANCE;
prompt "</pre>"
prompt "</div>"

-- Temporary Tablespace Usage
prompt "<div class='section'>"
prompt "<h2>Temporary Tablespace Usage</h2>"
prompt "<pre>"
SELECT * FROM v$temp_space_header;
prompt "</pre>"
prompt "</div>"

-- Undo Tablespaces Status
prompt "<div class='section'>"
prompt "<h2>Undo Tablespaces Status</h2>"
prompt "<pre>"
SELECT tablespace_name, status FROM dba_tablespaces WHERE contents = 'UNDO';
prompt "</pre>"
prompt "</div>"

-- System Wait Events (Non-Idle)
prompt "<div class='section'>"
prompt "<h2>System Wait Events (Non-Idle)</h2>"
prompt "<pre>"
SELECT event, total_waits, time_waited, average_wait 
FROM v$system_event 
WHERE wait_class != 'Idle'
ORDER BY time_waited DESC;
prompt "</pre>"
prompt "</div>"

-- Blocking Locks
prompt "<div class='section'>"
prompt "<h2>Blocking Locks</h2>"
prompt "<pre>"
SELECT * FROM v\$lock WHERE block != 0;
prompt "</pre>"
prompt "</div>"

-- Database Block Corruption
prompt "<div class='section'>"
prompt "<h2>Database Block Corruption</h2>"
prompt "<pre>"
SELECT * FROM v$database_block_corruption;
prompt "</pre>"
prompt "</div>"

-- Invalid Objects
prompt "<div class='section'>"
prompt "<h2>Invalid Objects</h2>"
prompt "<pre>"
SELECT owner, object_type, COUNT(*) as COUNT
FROM dba_objects 
WHERE status = 'INVALID' 
GROUP BY owner, object_type
ORDER BY owner, COUNT DESC;
prompt "</pre>"
prompt "</div>"


-- Data Guard Statistics
prompt "<div class='section'>"
prompt "<h2>Data Guard Statistics</h2>"
prompt "<pre>"
SELECT 
    RPAD(name, 15) || ' ' ||
    RPAD(TO_CHAR(value), 15) || ' ' ||
    RPAD(unit, 10) || ' computed at ' ||
    time_computed
    AS formatted_output
FROM v$dataguard_stats;  
prompt "</pre>"
prompt "</div>"

EXIT;
EOT

    check_timeout
    
    # Add alert log section for this SID
    ALERT_LOG_DIR=`$SQLPLUS -S "/ as sysdba" << EOF
set heading off feedback off verify off
set pages 0 lines 200 trimout on trimspool on
select value from v\\$diag_info where name = 'Diag Trace';
exit;
EOF
    `
    
    ALERT_LOG_FILE=`find "$ALERT_LOG_DIR" -name "alert_${SID}.log" 2>/dev/null`
    
    echo "<div class='section'>" >> $OUTPUT_FILE
    echo "<h3>Alert Log</h3>" >> $OUTPUT_FILE
    echo "<pre>" >> $OUTPUT_FILE
    
    if [ -f "$ALERT_LOG_FILE" ]; then
        tail -600 "$ALERT_LOG_FILE" | while read line; do
            line=`echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`
            
            if echo "$line" | grep -iE "ORA-|ERROR|FATAL|SEVERE|CRITICAL" > /dev/null; then
                echo "<span class='critical'>$line</span>"
            elif echo "$line" | grep -iE "WARNING|WARN|CAUTION" > /dev/null; then
                echo "<span class='warning'>$line</span>"
            elif echo "$line" | grep -iE "ALERT|ATTENTION" > /dev/null; then
                echo "<span class='alert'>$line</span>"
            else
                echo "$line"
            fi
        done >> $OUTPUT_FILE
    else
        echo "<span class='warning'>Alert log file not found for $SID at expected path: $ALERT_LOG_DIR</span>" >> $OUTPUT_FILE
    fi
    
    echo "</pre>" >> $OUTPUT_FILE
    echo "</div>" >> $OUTPUT_FILE
    
  if which dgmgrl >/dev/null 2>&1; then
    echo "<div class='section'>" >> $OUTPUT_FILE
    echo "<h3>Data Guard Status</h3>" >> $OUTPUT_FILE
    echo "<pre>" >> $OUTPUT_FILE
    
    dgmgrl sys/Ora2022 << EOF | while read line; do
show configuration;
show database "$SID";
validate network configuration for all;
EOF
        line=`echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'`
        
        if echo "$line" | grep -iE "ERROR|FATAL|WARNING" > /dev/null; then
            echo "<span class='critical'>$line</span>"
        elif echo "$line" | grep -iE "SUCCESS" > /dev/null; then
            echo "<span class='success'>$line</span>"
        else
            echo "$line"
        fi
    done >> $OUTPUT_FILE
    
    echo "</pre>" >> $OUTPUT_FILE
    echo "</div>" >> $OUTPUT_FILE
fi
   
    
    echo "</div><!-- End of SID section -->" >> $OUTPUT_FILE
done


echo "</body></html>" >> $OUTPUT_FILE

chmod 644 $OUTPUT_FILE

echo "Report generated: $OUTPUT_FILE"
