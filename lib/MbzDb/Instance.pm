#!/usr/bin/perl -w

package MbzDb::Instance;

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use MbzDb;
use MbzDb::Backend;
use MbzDb::Ini::Config;
use MbzDb::Logger;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(startFromCommandLine PrintCommandLineUsage);

use constant DEFAULT_INSTANCE => 'default';

sub new {
    my $class = shift;
    my $self = {
        'commandLineOptions' => {},
        'ini' => new MbzDb::Ini::Config($ENV{"HOME"} . '/mbzdb.ini')
    };
    return bless $self, $class;
}

sub getConfigOption {
    my ($self, $name) = @_;
    return $self->{'ini'}->get($name);
}

sub getInstanceName {
    my $self = shift;
    return $self->{'commandLineOptions'}{'instance'};
}

sub getInstanceOption {
    my ($self, @names) = @_;
    my @r;
    foreach my $name (@names) {
        push(@r, $self->getConfigOption($self->getInstanceName() . "." . $name));
    }
    return @r;
}

sub startFromCommandLine {
    my $self = shift;
    $self->{'commandLineOptions'} = $self->_getCommandLineOptions();
    
    # choose action
    if($self->{'commandLineOptions'}{'action'} eq 'help') {
        $self->help();
    }
    elsif($self->{'commandLineOptions'}{'action'} eq 'info') {
        $self->info();
    }
    elsif($self->{'commandLineOptions'}{'action'} eq 'install') {
        $self->install();
    }
    elsif($self->{'commandLineOptions'}{'action'} eq 'uninstall') {
        $self->uninstall();
    }
}

# uninstall()
# Remove a MbzDb instance.
sub uninstall {
    my $self = shift;
    my $logger = MbzDb::Logger::Get();
    
    # make sure the instance exists
    my $name = $self->{'commandLineOptions'}{'instance'};
    if(!$self->{'ini'}->instanceExists($name)) {
        $logger->logUserError("No such instance '$name'.");
        exit(1);
    }
    
    # get the instance
    my $class = MbzDb::Backend::GetClassByName($self->{'ini'}->get("$name._db"));
    
    # load backend
    MbzDb::LoadModule($class);
    my $obj = $class->new($self);
    
    # uninstall
    $obj->uninstall();
    
    # remove from the configuration file
    $self->{'ini'}->removeInstance($name);
}

# install()
# Setup a new MbzDb instance.
sub install {
    my $self = shift;
    my $logger = MbzDb::Logger::Get();
    
    # create the empty folders needed
    MbzDb::CreateFolders();
    
    # make sure the backend is valid
    my $db = $self->{'commandLineOptions'}{'db'};
    my $class = MbzDb::Backend::GetClassByName($db);
    if(!$class) {
        $logger->logUserError("Bad --db option or not specified.");
        exit(1);
    }
    
    # make sure the instance doesn't already exist
    my $name = $self->{'commandLineOptions'}{'instance'};
    if($self->{'ini'}->instanceExists($name)) {
        $logger->logUserError("An instance with that name '$name' already exists.");
        exit(1);
    }
    
    $self->{'ini'}->set("$name._db", $self->{'commandLineOptions'}{'db'});
    while(my ($key, $value) = each %{$self->{'commandLineOptions'}{'options'}}) {
        $self->{'ini'}->set("$name.$key", $value);
    }
    
    # load backend
    MbzDb::LoadModule($class);
    my $obj = $class->new($self);
    
    # initialise
    $obj->install();
    
    # download and install schema
    $obj->downloadSchema();
    $obj->updateSchema();
    
    # download and load data
    $obj->downloadData();
    $obj->unzipData();
    $obj->loadData();
}

# help()
# Print the command line usage and exit will a failure status.
sub help {
    my $self = shift;
    print "\n";
    print "Usage: ./mbzdb [options]\n";
    print "\n";
    print "    --help       Show this help message.\n";
    print "    --info       Show information about the instances.\n";
    print "    --install    Create a new instance.\n";
    print "      --db         The database (mysql, postgresql, etc).\n";
    print "      --options    Database options, like 'user=bob'.\n";
    print "        db           Database name (it will be created if it does not already exist).\n";
    print "        driver       DBI driver (default 'mysql').\n";
    print "        engine       Database engine (MySQL only).\n";
    print "        pass         Password.\n";
    print "        tablespace   Tablespace (MySQL only).\n";
    print "        user         User name.\n";
    print "    --uninstall  Remove an instance.\n";
    print "\n";
    exit(1);
}

# info()
# Print basic information then exit.
sub info {
    my $self = shift;
    print "MbzDb v" . MbzDb::Version() . "\n";
    exit(0);
}

sub _getCommandLineOptions {
    # the default values
    my %options = (
        'action' => '',
        'instance' => DEFAULT_INSTANCE,
        'language' => 'English',
        'db' => '',
        'options' => ''
    );
    my %actions = (
        'help' => '',
        'info' => '',
        'install' => '',
        'uninstall' => ''
    );

    # read the command line options
    GetOptions(
        "help" => \$actions{'help'},
        "instance=s" => \$options{'instance'},
        "language=s" => \$options{'language'},
        "info" => \$actions{'info'},
        "install" => \$actions{'install'},
        "uninstall" => \$actions{'uninstall'},
        "db=s" => \$options{'db'},
        "options=s" => \$options{'options'},
    );
    
    # post process
    foreach my $action (keys %actions) {
        if($actions{$action}) {
            $options{'action'} = $action;
        }
    }
    
    $options{'options'} = MbzDb::MakeHashFromKeyValues($options{'options'});
    
    return (\%options);
}

1;