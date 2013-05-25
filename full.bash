CWD="$(dirname "$0")"
DATA_PATH="${CWD}/data"
echo $DATA_PATH

# download
echo "Run Download Script"
python download.py --path $DATA_PATH

echo "Create Replication Directories"
mkdir -p replication
mkdir -p replication/coverart

echo "Run Init Script"
init.pl 2

echo "Load Indexes"
init.pl 5

echo "Load FKs"
init.pl 6

echo "Load Data"
init.pl 4

echo "Load Views"
mysql -udelete_enabled -pgodlikepowers -D musicbrainz < sql/CreateSimpleViews.sql
# msyql -udelete_enabled -pgodlikepowers -D musicbrainz2 < sql/CreateSimpleViews.sql



