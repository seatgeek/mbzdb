use DBI;
use DBD::mysql;

# mbz_connect()
# Make database connection. It will set the global $dbh and it will return it.
# $g_db_name, $g_db_host, $g_db_port, $g_db_user and $g_db_pass are supplied by settings.pl.
# @return $dbh
sub backend_mysql_connect {
	$dbh = DBI->connect("dbi:mysql:dbname=$g_db_name;host=$g_db_host;port=$g_db_port;mysql_local_infile=1;",
						$g_db_user, $g_db_pass);

	$dbh || die 'Unable to connect to the database: ' . $DBI::errstr;

	return $dbh;
}


# backend_mysql_create_extra_tables()
# The mbzdb plugins use a basic key-value table to hold information such as settings.
# @see mbz_set_key(), mbz_get_key().
# @return Passthru from $dbh::do().
sub backend_mysql_create_extra_tables {
	# no need to if the table already exists
	return 1 if(mbz_table_exists("kv"));

	$sql = "CREATE TABLE kv (" .
	       "name varchar(255) not null primary key," .
	       "value text" .
	       ")";
	$sql .= " engine=$g_mysql_engine" if($g_mysql_engine ne '');
	$sql .= " tablespace $g_tablespace" if($g_tablespace ne "");
	return mbz_do_sql($sql);
}


# mbz_escape_entity($entity)
# Wnen dealing with table and column names that contain upper and lowercase letters some databases
# require the table name to be encapsulated. MySQL uses back-ticks.
# @return A new encapsulated entity.
sub backend_mysql_escape_entity {
	my $entity = $_[0];
	return "`$entity`";
}


# backend_mysql_get_column_type($table_name, $col_name)
# Get the MySQL column type.
# @param $table_name The name of the table.
# @param $col_name The name of the column to fetch the type.
# @return MySQL column type.
sub backend_mysql_get_column_type {
	my ($table_name, $col_name) = @_;
	my $sth = $dbh->prepare("describe `$table_name`");
	$sth->execute();
	while(@result = $sth->fetchrow_array()) {
		return $result[1] if($result[0] eq $col_name);
	}

	return "";
}


# mbz_index_exists($index_name)
# Check if an index already exists.
# @param $index_name The name of the index to look for.
# @return 1 if the index exists, otherwise 0.
sub backend_mysql_index_exists {
	my $index_name = $_[0];

	# yes I know this is a highly inefficent way to do it, but its simple and is only called on
	# schema changes.
	my $sth = $dbh->prepare("show tables");
	$sth->execute();
	while(@result = $sth->fetchrow_array()) {
		my $sth2 = $dbh->prepare("show indexes from `$result[0]`");
		$sth2->execute();
		while(@result2 = $sth2->fetchrow_array()) {
			return 1 if($result2[2] eq $index_name);
		}
	}

	# the index was not found
	return 0;
}

sub backend_mysql_primary_key_exists {
        my $table_name = $_[0];

        # yes I know this is a highly inefficent way to do it, but its simple and is only called on
        # schema changes.
        my $sth2 = $dbh->prepare("show indexes from `$table_name`");
        $sth2->execute();
        while(@result2 = $sth2->fetchrow_array()) {
	        return 1 if($result2[2] eq 'PRIMARY');
        }

        # the index was not found
        return 0;
}

# mbz_load_data()
# Load the data from the mbdump files into the tables.
sub backend_mysql_load_data {
	my $temp_time = time();

	# opendir(DIR, "mbdump") || die "Can't open ./mbdump: $!";
	# my @files = sort(grep { $_ ne '.' and $_ ne '..' } readdir(DIR));
	# my $count = @files;
	# my $i = 1;

	$base_path = "/tmp/musicbrainz/mbdump/mbdump";

	@tables_to_load = (

		# area
		'area',
		'area_alias',
		'area_alias_type',
		'area_annotation',
		'area_gid_redirect',
		'area_type',

		# artist
		'artist',
		'artist_alias',
		'artist_alias_type',
		'artist_credit',
		'artist_credit_name',
		'artist_gid_redirect',
		'artist_ipi',
		'artist_isni',
		'artist_name',

		# label
		'label',
		'label_alias',
		'label_alias_type',
		'label_gid_redirect',
		'label_ipi',
		'label_isni',
		'label_name',
		'label_type',

		# release
		'release',
		'release_country',
		'release_gid_redirect',
		'release_group',
		'release_group_gid_redirect',
		'release_group_primary_type',
		'release_group_secondary_type',
		'release_group_secondary_type_join',
		'release_label',
		'release_name',
		'release_packaging',
		'release_status',
		'release_unknown_country',

		# url
		'url',
		'url_gid_redirect',

		# work
		'work',
		'work_alias',
		'work_alias_type',
		'work_gid_redirect',
		'work_name',
		'work_type',

		# random
		'country_area',
		'gender',

		# iso
		'iso_3166_1',
		'iso_3166_2',
		'iso_3166_3',

		# links
		'l_area_area',
		'l_area_artist',
		'l_area_label',
		'l_area_recording',
		'l_area_release',
		'l_area_release_group',
		'l_area_url',
		'l_area_work',
		'l_artist_artist',
		'l_artist_label',
		'l_artist_recording',
		'l_artist_release',
		'l_artist_release_group',
		'l_artist_url',
		'l_artist_work',
		'l_label_label',
		'l_label_recording',
		'l_label_release',
		'l_label_release_group',
		'l_label_url',
		'l_label_work',
		'l_recording_recording',
		'l_recording_release',
		'l_recording_release_group',
		'l_recording_url',
		'l_recording_work',
		'l_release_group_release_group',
		'l_release_group_url',
		'l_release_group_work',
		'l_release_release',
		'l_release_release_group',
		'l_release_url',
		'l_release_work',
		'l_url_url',
		'l_url_work',
		'l_work_work',

		# cover_art_archive
		'../coverart/cover_art_archive.art_type',
		'../coverart/cover_art_archive.cover_art',
		'../coverart/cover_art_archive.cover_art_type',
		'../coverart/cover_art_archive.image_type',
		'../coverart/cover_art_archive.release_group_cover_art',
	);

	my $count = @tables_to_load;
	my $i = 1;
	foreach my $file_name (@tables_to_load) {
		my $t1 = time();
		$full_path = "${base_path}/$file_name";
		next if (-d $full_path);

		$table = $file_name;
		if(substr($table, 0, 30) eq "../coverart/cover_art_archive.")
		{
			$table = substr($table, 30, length($table) - 30);
		}

		if(backend_mysql_table_column_exists($table,"dummycolumn"))
		{
			mbz_do_sql("ALTER TABLE `$table` DROP COLUMN dummycolumn");
		}

		print "\n" . localtime() . ": Loading data into '$table' ($i of $count)...\n";
		mbz_do_sql("LOAD DATA LOCAL INFILE '$full_path' INTO TABLE `$table` ".
		           "FIELDS TERMINATED BY '\\t' ".
		           "ENCLOSED BY '' ".
		           "ESCAPED BY '\\\\' ".
		           "LINES TERMINATED BY '\\n' ".
		           "STARTING BY ''");
		my $t2 = time();
		print "Done (" . mbz_format_time($t2 - $t1) . ")\n";
		++$i;
	}

	my $t2 = time();
	print "\nComplete (" . mbz_format_time($t2 - $temp_time) . ")\n";

	# foreach my $file (@files) {
	# 	my $t1 = time();
	# 	$table = $file;
	# 	next if($table eq "blank.file" || substr($table, 0, 1) eq '.');
	# 	next if( -d "./mbdump/$table");

	# 	if(substr($table, 0, 11) eq "statistics.")
	# 	{
	# 		$table = substr($table, 11, length($table) - 11);
	# 	}

	# 	if(backend_mysql_table_column_exists($table,"dummycolumn"))
	# 	{
 #       			mbz_do_sql("ALTER TABLE `$table` DROP COLUMN dummycolumn");
	# 	}

	# 	print "\n" . localtime() . ": Loading data into '$table' ($i of $count)...\n";
	# 	mbz_do_sql("LOAD DATA LOCAL INFILE 'mbdump/$file' INTO TABLE `$table` ".
	# 	           "FIELDS TERMINATED BY '\\t' ".
	# 	           "ENCLOSED BY '' ".
	# 	           "ESCAPED BY '\\\\' ".
	# 	           "LINES TERMINATED BY '\\n' ".
	# 	           "STARTING BY ''");

	# 	my $t2 = time();
	# 	print "Done (" . mbz_format_time($t2 - $t1) . ")\n";
	# 	++$i;
	# }

	# # clean up
	# closedir(DIR);
	# my $t2 = time();
	# print "\nComplete (" . mbz_format_time($t2 - $temp_time) . ")\n";
}


# mbz_load_pending($id)
# Load Pending and PendingData from the downaloded replication into the respective tables. This
# function is different to mbz_load_data that loads the raw mbdump/ whole tables.
# @param $id The current replication number. See mbz_get_current_replication().
# @return Always 1.
sub backend_mysql_load_pending {
	$id = $_[0];

	# make sure there are no pending transactions before cleanup
	return -1 if(mbz_get_count($g_pending, "") ne '0');

	# perform cleanup (makes sure there no left over records in the PendingData table)
	$dbh->do("DELETE FROM `$g_pending`");

	# load Pending and PendingData
	print localtime() . ": Loading pending tables... ";
	mbz_do_sql(qq|
		LOAD DATA LOCAL INFILE 'replication/$id/mbdump/$g_pendingfile'
		INTO TABLE `$g_pending`
	|);
	mbz_do_sql(qq|
		LOAD DATA LOCAL INFILE 'replication/$id/mbdump/$g_pendingdatafile'
		INTO TABLE `$g_pendingdata`
	|);
	print "Done\n";

	# PLUGIN_beforereplication()
	foreach my $plugin (@g_active_plugins) {
		my $function_name = "${plugin}_beforereplication";
		(\&$function_name)->($id) || die($!);
	}

	return 1;
}


# mbz_table_column_exists($table_name, $col_name)
# Check if a table already has a column.
# @param $table_name The name of the table to look for.
# @param $col_name The column name in the table.
# @return 1 if the table column exists, otherwise 0.
sub backend_mysql_table_column_exists {
	my ($table_name, $col_name) = @_;
	return 0 if($table_name eq "");

	my $sth = $dbh->prepare("describe `$table_name`");
	$sth->execute();
	while(@result = $sth->fetchrow_array()) {
		if($col_name eq "PRIMARY") {
			return 1 if($result[3] eq 'PRI');
		} else {
			return 1 if($result[0] eq $col_name);
		}
	}

	# table column was not found
	return 0;
}


# backend_mysql_table_exists($table_name)
# Check if a table already exists.
# @note This must support searching for VIEWs as well. mbz_table_exists() is used for testing if
#       tables and views exist.
# @param $table_name The name of the table to look for.
# @return 1 if the table exists, otherwise 0.
sub backend_mysql_table_exists {
	my $table_name = $_[0];

	my $sth = $dbh->prepare('show tables');
	$sth->execute();
	while(@result = $sth->fetchrow_array()) {
		return 1 if($result[0] eq $table_name);
	}

	# table was not found
	return 0;
}

sub backend_mysql_update_pk_from_file {
	my $file_path = $_[0];
	open(SQL, $file_path);
	my $index_size = 200;

	chomp(my @lines = <SQL>);
	foreach my $line (@lines) {
		$line = mbz_trim($line);

		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\" ||
		        substr($line, 0, 5) eq "BEGIN" ||
		        substr($line, 0, 3) eq "SET");

		my $pos_table = index($line, 'TABLE ');
		my $pos_add = index($line, 'ADD ');
		my $pos_index = index($line, 'CONSTRAINT ');

		my $table_name = mbz_trim(substr($line, $pos_table + length('TABLE '), $pos_add - $pos_table - length('TABLE ')));
		my $index_name = mbz_trim(substr($line, $pos_index + 11, index($line, ' ', $pos_index + 12) -
				                  $pos_index - 11));
		my $cols = substr($line, index($line, '(') + 1, index($line, ')') - index($line, '(') - 1);

		# no need to create the index if it already exists
		next if(backend_mysql_primary_key_exists($table_name));

		# split and clean column names. this is also a good time to find out there type, if its
		# TEXT then MySQL requires and index length.
		my @columns = split(",", $cols);
		for(my $i = 0; $i < @columns; ++$i) {
			if((backend_mysql_get_column_type($table_name, mbz_trim($columns[$i])) eq 'text')  || (backend_mysql_get_column_type($table_name, mbz_trim($columns[$i])) eq 'varchar') ) {
				$columns[$i] = "`" . mbz_trim(mbz_remove_quotes($columns[$i])) . "`($index_size)";
			} else {
				$columns[$i] = "`" . mbz_trim(mbz_remove_quotes($columns[$i])) . "`";
			}
		}

		# now we construct the index back together in case there was changes along the way
		$new_line = "ALTER TABLE `$table_name` ADD CONSTRAINT `$index_name` PRIMARY KEY  (";
		$new_line .= join(",", @columns) . ")";

		print $new_line;
		mbz_do_sql($new_line, 'nodie');
	}
	close(SQL);
}

sub backend_mysql_update_index_from_file {
	my $file_path = $_[0];
	open(SQL, $file_path);
	chomp(my @lines = <SQL>);

	my $index_size = 200;
	foreach my $line (@lines) {
		$line = mbz_trim($line);
		my $pos_index = index($line, 'INDEX ');
		my $pos_on = index($line, 'ON ');

		# skip blank lines, comments, psql settings and lines that arn't any use to us.
		next if($line eq '' || substr($line, 0, 2) eq '--' || substr($line, 0, 1) eq "\\" ||
		        $pos_index < 0);

		# skip function-based indexes.
		next if($line =~ /.*\(.*\(.*\)\)/);

		# get the names
		my $index_name = mbz_trim(substr($line, $pos_index + 6, index($line, ' ', $pos_index + 7) -
		                       $pos_index - 6));
		my $table_name = mbz_trim(substr($line, $pos_on + 3, index($line, ' ', $pos_on + 4) -
		                       $pos_on - 3));
		my $cols = substr($line, index($line, '(') + 1, index($line, ')') - index($line, '(') - 1);

		# PostgreSQL will put double-quotes around some entity names, we have to remove these
		$index_name = mbz_remove_quotes($index_name);
		$table_name = mbz_remove_quotes($table_name);

		# see if the index aleady exists, if so skip
		next if(mbz_index_exists($index_name));

		# split and clean column names. this is also a good time to find out there type, if its
		# TEXT then MySQL requires and index length.
		my @columns = split(",", $cols);
		for(my $i = 0; $i < @columns; ++$i) {
			if((backend_mysql_get_column_type($table_name, mbz_trim($columns[$i])) eq 'text') || (backend_mysql_get_column_type($table_name, mbz_trim($columns[$i])) eq 'varchar')  ) {
				$columns[$i] = "`" . mbz_trim(mbz_remove_quotes($columns[$i])) . "`($index_size)";
			} else {
				$columns[$i] = "`" . mbz_trim(mbz_remove_quotes($columns[$i])) . "`";
			}
		}

		# now we construct the index back together in case there was changes along the way
		$new_line = substr($line, 0, $pos_index) . "INDEX `$index_name` ON `$table_name` (";
		$new_line .= join(",", @columns) . ")";

		# all looks good so far ... create the index
		print "$new_line\n";
		my $success = mbz_do_sql($new_line);

		# if the index fails we will run it again as non-unique
		# TODO: nodie here?
		if(!$success) {
			$new_line =~ s/UNIQUE//;
			mbz_do_sql($new_line);
		}
	}
	close(SQL);
}


# backend_mysql_update_index()
# Attemp to pull as much relevant information from CreateIndexes.sql as we can. MySQL does not
# support function indexes so we will skip those. Any indexes created already on the database will
# be left intact.
# @return Always 1.
sub backend_mysql_update_index {

	print "Main DB\n";
	backend_mysql_update_index_from_file("replication/CreateIndexes.sql");
	backend_mysql_update_pk_from_file("replication/CreatePrimaryKeys.sql");

	print "Cover Art DB\n";
	backend_mysql_update_index_from_file("replication/coverart/CreateIndexes.sql");
	backend_mysql_update_pk_from_file("replication/coverart/CreatePrimaryKeys.sql");

	print "Done\n";
	return 1;
}

# backend_mysql_update_foreignkey_from_file()
# Attemp to pull as much relevant information from CreateFKConstraints.sql as we can.
# @return Always 1.
sub backend_mysql_update_foreignkey_from_file {
	my $file_path = $_[0];
	open(SQL, $file_path);
	chomp(my @lines = <SQL>);
	my $index_name = "", $table_name = "", $columns = [], $foreign_table_name = "", $foreign_columns = [];

	foreach my $line (@lines) {
		# skip blank lines and single bracket lines
		next if($line eq "" || substr($line, 0, 2) eq "--" || substr($line, 0, 1) eq "\\" ||
		        substr($line, 0, 5) eq "BEGIN");

		if(index($line, 'CONSTRAINT ') > 0) {
			my $pos_index = index($line, 'CONSTRAINT ');
			$index_name = mbz_trim(substr($line, $pos_index + length('CONSTRAINT ')));
		}
		if(index($line, 'TABLE ') > 0) {
			my $pos_index = index($line, 'TABLE ');
			$table_name = mbz_trim(substr($line, $pos_index + length('TABLE ')));
		}
		if(index($line, 'REFERENCES ') > 0) {
			my $pos_index = index($line, 'REFERENCES ');
			$foreign_table_name = mbz_trim(substr($line, $pos_index + length("REFERENCES "), index($line, '(') - $pos_index - length("REFERENCES ")));
            my $cols = substr($line, index($line, '(') + 1, index($line, ')') - index($line, '(') - 1);
		    @foreign_columns = split(",", $cols);
		    for(my $i = 0; $i < @columns; ++$i) {
			    $foreign_columns[$i] = "`" . mbz_trim(mbz_remove_quotes($foreign_columns[$i])) . "`";
		    }
		}
		if(index($line, 'FOREIGN KEY ') > 0) {
            my $cols = substr($line, index($line, '(') + 1, index($line, ')') - index($line, '(') - 1);
		    @columns = split(",", $cols);
		    for(my $i = 0; $i < @columns; ++$i) {
			    $columns[$i] = "`" . mbz_trim(mbz_remove_quotes($columns[$i])) . "`";
		    }
		}

		if(index($line, ';') > 0) {
			next if(backend_mysql_index_exists($index_name));
            $sql = "ALTER TABLE `$table_name` ADD CONSTRAINT `$index_name`";
            $sql .= " FOREIGN KEY (" . join(",", @columns) . ")";
            $sql .= " REFERENCES `$foreign_table_name`(" . join(",", @foreign_columns) . ")";

			print "$sql\n";
			mbz_do_sql($sql, 'nodie');
		}
	}
	close(SQL);

	print "Done\n";
	return 1;
}

sub backend_mysql_update_foreignkey {
	backend_mysql_update_foreignkey_from_file("replication/CreateFKConstraints.sql");
	backend_mysql_update_foreignkey_from_file("replication/coverart/CreateFKConstraints.sql");
}


sub backend_mysql_update_schema_from_file {
	# TODO: this does not check for columns that have changed their type, as a column that already
	#       exists will be ignored. I'm not sure how important this is but its worth noting.

	# this is where it has to translate PostgreSQL to MySQL as well as making any modifications
	# needed
	open(SQL, $_[0]);
	chomp(my @lines = <SQL>);
	my $table = "";
	my $enums = ();
	my $ignore = 0;
	foreach my $line (@lines) {
		#print "$line\n";

		# skip blank lines and single bracket lines
		next if($line eq "" || $line eq "(" || substr($line, 0, 1) eq "\\" || substr(mbz_trim($line), 0, 2) eq '--');

		#If in ignore mode
		if($ignore eq 1) {
			if ( (index($line,",") > 0) || (index($line,";") > 0) ) {
				$ignore = 0;
			}
			next;
		}

		my $stmt = '';

		if(substr($line, 0, 6) eq "CREATE" && index($line, "INDEX") < 0 &&
			index($line, "AGGREGATE") < 0 && index($line, "TYPE") < 0) {
			$table = mbz_remove_quotes(substr($line, 13, length($line)));
			if(substr($table, length($table) - 1, 1) eq '(') {
				$table = substr($table, 0, length($table) - 1);
			}
			$table = mbz_trim($table);
			print $L{'table'} . " $table\n";

			# do not create the table if it already exists
			if(!mbz_table_exists($table)) {
				$stmt = "CREATE TABLE `$table` (dummycolumn int)";
				$stmt .= " engine=$g_mysql_engine" if($g_mysql_engine ne '');
				$stmt .= " tablespace $g_tablespace" if($g_tablespace ne '');
			}
		} elsif(substr($line, 0, 6) eq "CREATE" && index($line, "TYPE") > 0) {
			my @p = split(" ", $line);
                        $table = mbz_trim(@p[2]);
			$content = substr($line, index($line, "AS") + 2, length($line));
			$content = substr($content, 0, index($content,";"));
                        print "Type $table -> $content\n";

			$enums{$table} = $content;
		} elsif(substr(mbz_trim($line),0,5) eq "CHECK" || substr(mbz_trim($line),0,5) eq 'ALTER') {
			#Ignore the line rest of lines
			if ( (index($line,",") > 0) || (index($line,";") > 0) ) {
				$ignore = 0;
			} else {
				$ignore = 1;
			}
		} elsif(substr($line, 0, 1) eq " " || substr($line, 0, 1) eq "\t") {

			my @parts = split(" ", $line);
			for($i = 0; $i < @parts; ++$i) {

				if(substr($parts[$i], 0, 2) eq "--") {
					@parts = @parts[0 .. ($i - 1)];
					last;
				}
				if(substr($parts[$i], 0, 5) eq "CHECK") {
					@parts = @parts[0 .. ($i - 1)];
					last;
				}

				if(substr($parts[$i], length($parts[$i]) - 2, 2) eq "[]") {
					$parts[$i] = "VARCHAR(255)";
				}
				if(uc(substr($parts[$i], 0, 7)) eq "VARCHAR" && index($line, '(') < 0) {
					$parts[$i] = "TEXT";
				}
				$parts[$i] = $enums{$parts[$i]} if($i != 0 && exists($enums{$parts[$i]}));
				$parts[$i] = "VARCHAR(15)" if(uc(substr($parts[$i], 0, 13)) eq "CHARACTER(15)");
				$parts[$i] = "INT NOT NULL" if(uc(substr($parts[$i], 0, 6)) eq "SERIAL");
				$parts[$i] = "CHAR(36)" if(uc(substr($parts[$i], 0, 4)) eq "UUID");
				$parts[$i] = "TEXT" if(uc(substr($parts[$i], 0, 4)) eq "CUBE");
				$parts[$i] = "CHAR(1)" if(uc(substr($parts[$i], 0, 4)) eq "BOOL");
				$parts[$i] = "VARCHAR(256)" if(uc($parts[$i]) eq "INTERVAL");
				$parts[$i] = "0" if(uc(substr($parts[$i], 0, 3)) eq "NOW");
				$parts[$i] = "0" if(uc(substr($parts[$i], 1, 1)) eq "{");
				$parts[$i] = $parts[$i + 1] = $parts[$i + 2] = "" if(uc($parts[$i]) eq "WITH");
				if(uc($parts[$i]) eq "VARCHAR" && substr($parts[$i + 1], 0, 1) ne "(") {
					$parts[$i] = "TEXT";
				}
			}
			if(substr(reverse($parts[@parts - 1]), 0, 1) eq ",") {
				$parts[@parts - 1] = substr($parts[@parts - 1], 0, length($parts[@parts - 1]) - 1);
			}

			next if(uc($parts[0]) eq "CHECK" || uc($parts[0]) eq "CONSTRAINT" || $parts[0] eq "");
			$parts[0] = mbz_remove_quotes($parts[0]);

			if(uc($parts[0]) ne "PRIMARY" && uc($parts[0]) ne "FOREIGN") {
				$new_col = "`$parts[0]`";
			} else {
				$new_col = $parts[0];
			}
			$stmt = "ALTER TABLE `$table` ADD $new_col " .
				join(" ", @parts[1 .. @parts - 1]);

			# no need to create the column if it already exists in the table
			$stmt = "" if($table eq "" || mbz_table_column_exists($table, $parts[0]));
		} elsif(substr($line, 0, 2) eq ");") {
			if($table ne "" && mbz_table_column_exists($table, "dummycolumn")) {
				$stmt = "ALTER TABLE `$table` DROP dummycolumn";
			}
		}

		if(mbz_trim($stmt) ne "") {
			mbz_do_sql($stmt);
			#$dbh->do($stmt) or print "";
		}
	}

	close(SQL);
	return 1;
}


# backend_mysql_update_schema()
# Attempt to update the scheme from the current version to a new version by creating a table with a
# dummy field, altering the tables by adding one field at a time them removing the dummy field. The
# idea is that given any schema and SQL file the new table fields will be added, the same fields
# will result in an error and the table will be left unchanged and fields and tables that have been
# removed from the new schema will not be removed from the current schema.
# This is a crude way of doing it. The field order in each table after it's altered will not be
# retained from the new schema however the field order should not have a big bearing on the usage
# of the database because name based and column ID in scripts that use the database will remain the
# same.
# It would be nice if this subroutine had a makeover so that it would check items before attempting
# to create (and replace) them. This is just so all the error messages and so nasty.
# @return Always 1.
sub backend_mysql_update_schema {
	backend_mysql_update_schema_from_file("replication/CreateTables.sql");
	backend_mysql_update_schema_from_file("replication/coverart/CreateTables.sql");
}


# be nice
return 1;
