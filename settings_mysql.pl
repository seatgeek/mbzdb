#############################
# Basic options
#############################

# Database user name.
$g_db_user = 'delete_enabled';

# Database user password.
$g_db_pass = 'godlikepowers';

# The name of the database to use.
$g_db_name = 'musicbrainz';


#############################
# Advanced database options
#############################

# The engine to use when creating tables with MySQL. Set this to "" if you want to use the MySQL
# default storage engine.
$g_mysql_engine = 'MyISAM';

# Server host, use 'localhost' if the database is on the same server as this script.
$g_db_host = 'recon-ec2-03.seatgeek.com';

# Port number, default is 3306
$g_db_port = 3306;

# Tablespace to create all tables and indexes in. Leave blank to use the default tablespace.
$g_tablespace = '';


return 1;
