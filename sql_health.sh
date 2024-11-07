#!/bin/bash

# MySQL credentials for ArcSight
MYSQL_CMD="/opt/arcsight/logger/current/arcsight/bin/mysql"
MYSQL_USER="arcsight"
MYSQL_PASSWORD='PutPasswordHere'
LOGFILE="mysql_health_check.log"
MY_CNF_PATH="/opt/arcsight/logger/current/arcsight/logger/config/logger/my.cnf"

# Create or clear log file
echo "MySQL Health Check - $(date)" > "$LOGFILE"

# Function to run a MySQL query within the arcsight database and log output
run_mysql_query() {
    $MYSQL_CMD -u"$MYSQL_USER" --password="$MYSQL_PASSWORD" -e "USE arcsight; $1"
}

# 1. Configuration Analysis
echo "1. Configuration Analysis" | tee -a "$LOGFILE"
echo "--------------------------" | tee -a "$LOGFILE"
# Buffer Pool Size
run_mysql_query "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';" | tee -a "$LOGFILE"

# Query Cache Size
run_mysql_query "SHOW VARIABLES LIKE 'query_cache_size';" | tee -a "$LOGFILE"

# Max Connections
run_mysql_query "SHOW VARIABLES LIKE 'max_connections';" | tee -a "$LOGFILE"

# Temporary Table Size
run_mysql_query "SHOW VARIABLES LIKE 'tmp_table_size';" | tee -a "$LOGFILE"

# 2. Storage Engine and Tables Analysis
echo -e "\n2. Storage Engine and Tables Analysis" | tee -a "$LOGFILE"
run_mysql_query "SELECT table_name, engine FROM information_schema.tables WHERE table_schema = 'arcsight';" | tee -a "$LOGFILE"

# 3. Slow Query Analysis
echo -e "\n3. Slow Query Analysis" | tee -a "$LOGFILE"
run_mysql_query "SET GLOBAL slow_query_log = 'ON';"
run_mysql_query "SHOW VARIABLES LIKE 'long_query_time';" | tee -a "$LOGFILE"
run_mysql_query "SHOW GLOBAL STATUS LIKE 'Slow_queries';" | tee -a "$LOGFILE"

# 4. Disk and I/O Pressure
echo -e "\n4. Disk and I/O Pressure" | tee -a "$LOGFILE"
run_mysql_query "SHOW GLOBAL STATUS LIKE 'Innodb_data_reads';" | tee -a "$LOGFILE"
run_mysql_query "SHOW GLOBAL STATUS LIKE 'Innodb_data_writes';" | tee -a "$LOGFILE"

# Disk Latency (requires iostat)
if command -v iostat &> /dev/null; then
    echo "Disk Latency (I/O) Check" | tee -a "$LOGFILE"
    iostat -dx 1 3 | tee -a "$LOGFILE"
else
    echo "iostat command not found. Install sysstat package for disk I/O analysis." | tee -a "$LOGFILE"
fi

# 5. CPU and Memory Pressure
echo -e "\n5. CPU and Memory Pressure" | tee -a "$LOGFILE"
# Check CPU utilization
echo "CPU Utilization:" | tee -a "$LOGFILE"
top -bn1 | grep "Cpu(s)" | tee -a "$LOGFILE"

# Check memory usage
echo "Memory Usage:" | tee -a "$LOGFILE"
free -h | tee -a "$LOGFILE"

# InnoDB Buffer Pool Utilization
run_mysql_query "SHOW STATUS LIKE 'Innodb_buffer_pool_pages_data';" | tee -a "$LOGFILE"
run_mysql_query "SHOW STATUS LIKE 'Innodb_buffer_pool_pages_free';" | tee -a "$LOGFILE"

# 6. Locking and Concurrency
echo -e "\n6. Locking and Concurrency" | tee -a "$LOGFILE"
run_mysql_query "SHOW ENGINE INNODB STATUS\G" | tee -a "$LOGFILE"

# 7. Index and Schema Optimization
echo -e "\n7. Index and Schema Optimization" | tee -a "$LOGFILE"
run_mysql_query "SELECT table_name, index_name, non_unique FROM information_schema.statistics WHERE table_schema = 'arcsight';" | tee -a "$LOGFILE"
run_mysql_query "SELECT * FROM sys.schema_unused_indexes;" | tee -a "$LOGFILE"

# 8. Replication Health (if applicable)
echo -e "\n8. Replication Health" | tee -a "$LOGFILE"
run_mysql_query "SHOW SLAVE STATUS\G" | tee -a "$LOGFILE"

# 9. Custom SQL Queries for ArcSight Data
echo -e "\n9. ArcSight Custom Queries" | tee -a "$LOGFILE"

# Active list query sorted by over limit
echo -e "\n// Active List Query Sorted by Over Limit" | tee -a "$LOGFILE"
run_mysql_query "SELECT TABLE_NAME, TABLE_ROWS, arc.capacity, ar.name, CASE WHEN TABLE_ROWS > arc.capacity THEN 'OVER' ELSE 'OK' END AS OVER_CAPACITY FROM INFORMATION_SCHEMA.TABLES alltables INNER JOIN arc_active_list arc ON UPPER(alltables.table_name) = UPPER(CONCAT('arc_ald_', arc.data_table_id)) INNER JOIN arc_resource ar ON arc.id=ar.id ORDER BY OVER_CAPACITY DESC;" | tee -a "$LOGFILE"

# Sorted by size
echo -e "\n// Active List Query Sorted by Size" | tee -a "$LOGFILE"
run_mysql_query "SELECT TABLE_NAME, TABLE_ROWS, arc.capacity, ar.name, CASE WHEN TABLE_ROWS > arc.capacity THEN 'OVER' ELSE 'OK' END AS OVER_CAPACITY FROM INFORMATION_SCHEMA.TABLES alltables INNER JOIN arc_active_list arc ON UPPER(alltables.table_name) = UPPER(CONCAT('arc_ald_', arc.data_table_id)) INNER JOIN arc_resource ar ON arc.id=ar.id ORDER BY TABLE_ROWS DESC;" | tee -a "$LOGFILE"

# Session list query
echo -e "\n// Session List Query" | tee -a "$LOGFILE"
run_mysql_query "SELECT TABLE_NAME, TABLE_ROWS, arc.in_memory_capacity, ar.name, CASE WHEN TABLE_ROWS > arc.in_memory_capacity THEN 'OVER' ELSE 'OK' END AS OVER_CAPACITY FROM INFORMATION_SCHEMA.TABLES alltables INNER JOIN arc_session_list arc ON UPPER(alltables.table_name) = UPPER(CONCAT('arc_sld_', arc.data_table_id)) INNER JOIN arc_resource ar ON arc.id=ar.id ORDER BY OVER_CAPACITY DESC;" | tee -a "$LOGFILE"

# Trend query
echo -e "\n// Trend Query" | tee -a "$LOGFILE"
run_mysql_query "SELECT round(((data_length + index_length) / 1024 / 1024), 2) 'Size in MB', table_name, arc_trend.id as 'Resource ID', arc_resource.name as 'Resource Name', TABLE_ROWS as 'Row Count', REPLACE(REPLACE(ExtractValue(trend_xml, '/Trend/MaxRows'), ' ', ''),'\n','') as 'Max Rows', CASE WHEN TABLE_ROWS > CAST(REPLACE(REPLACE(ExtractValue(trend_xml, '/Trend/MaxRows'), ' ', ''),'\n','') AS UNSIGNED) THEN 'OVER' ELSE 'OK' END as Over_Capacity FROM information_schema.TABLES LEFT JOIN (arc_trend,arc_resource) ON (arc_trend.table_id=UPPER(mid(table_name,11,6)) AND arc_trend.id=arc_resource.id) WHERE table_name like 'arc_trend_%' order by OVER_Capacity desc, round(((data_length + index_length) / 1024 / 1024), 2) desc;" | tee -a "$LOGFILE"

# 10. my.cnf Configuration Analysis
echo -e "\n10. my.cnf Configuration Analysis" | tee -a "$LOGFILE"
if [ -f "$MY_CNF_PATH" ]; then
    echo "Checking $MY_CNF_PATH for key configurations:" | tee -a "$LOGFILE"
    
    # Check for InnoDB Buffer Pool Size
    grep -E "innodb_buffer_pool_size" "$MY_CNF_PATH" | tee -a "$LOGFILE"
    
    # Check Query Cache Size
    grep -E "query_cache_size" "$MY_CNF_PATH" | tee -a "$LOGFILE"
    
    # Check Max Connections
    grep -E "max_connections" "$MY_CNF_PATH" | tee -a "$LOGFILE"
    
    # Check Temp Table and Heap Table Size
    grep -E "tmp_table_size|max_heap_table_size" "$MY_CNF_PATH" | tee -a "$LOGFILE"
    
    # Check Binary Log Configurations
    grep -E "log_bin|max_binlog_size|expire_logs_days" "$MY_CNF_PATH" | tee -a "$LOGFILE"
    
    # Check other important configurations
    grep -E "innodb_log_file_size|innodb_flush_log_at_trx_commit|innodb_io_capacity" "$MY_CNF_PATH" | tee -a "$LOGFILE"
else
    echo "Configuration file $MY_CNF_PATH not found." | tee -a "$LOGFILE"
fi

# Commented Out: Maintenance Checks
: <<'EOF'
# echo -e "\nMaintenance Checks" | tee -a "$LOGFILE"
# run_mysql_query "ANALYZE TABLE your_table_name;" | tee -a "$LOGFILE"
# run_mysql_query "OPTIMIZE TABLE your_table_name;" | tee -a "$LOGFILE"
# run_mysql_query "SHOW BINARY LOGS;" | tee -a "$LOGFILE"
EOF

echo -e "\nMySQL Health Check Complete. Results saved in $LOGFILE."
