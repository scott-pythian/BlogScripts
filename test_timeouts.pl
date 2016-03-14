#!/usr/bin/perl
# Timeout test script
# for blog, March 11, 2016
# --------------------------
# John D. Scott <scott@pythian.com>
#
# prerequisites: libdbi-perl, libdbd-mysql-perl
#
# recommended: a .my.cnf in your home directory
#              example .my.cnf below:
#
# [client]
# user=pythian
# password=loveyourdata
#
# user must have CREATE, DROP, SELECT, INSERT, DELETE on *.*
# 
# If you do not have a .my.cnf, then you must edit the DbConnect
# subroutine below to add the desired username,password to the
# database connection, manually.
# 
# The purpose of this script is to create a small test schema,
# to set and test three distinct types of timeouts on MySQL
#
# objective is to trigger the timeouts and receive appropriate
# error messages.
#
# * wait_timeout
# * net_read_timeout (unsuccessful)
# * net_write_timeout (unsuccessful)
#
# script usage:
# --------------
# to run the killable wait_timeout test
#
#  <path_to>/test_timeouts.pl -K
# -
# to run the wait_timeout test
#
#  <path_to>/test_timeouts.pl -W
# -
# to run the net_write_timeout test
#
#  <path_to>/test_timeouts.pl -w
# -
# to run the net_read_timeout test
#
# <path_to>/test_timeoutst.pl -r
# 
#
# multiple arguments given results in multiple tests run
#
# note on style: I don't often use strict, but mostly act like it.
#                Hopefully that's not too annoying for the 
#		 perl-savvy reader.
####################################################################

use Getopt::Std;

our ($opt_K,$opt_W,$opt_w,$opt_r) = ('','','');
getopts('KWwr');

# if we don't receive any of our arguments, we're going to print the 
# usage and exit.

if (!$opt_K && !$opt_W && !$opt_w && !$opt_r) {
	print qq|\nUSAGE:
script usage:
--------------
to run the killable wait_timeout test

<path_to>/test_timeouts.pl -K
-
to run the wait_timeout test

<path_to>/test_timeouts.pl -W
-
to run the net_write_timeout test

<path_to>/test_timeouts.pl -w
-
to run the net_read_timeout test

<path_to>/test_timeoutst.pl -r
-
multiple arguments given results in multiple tests run

|;
	exit 1;
}

# connecting to database server (See sub DbConnect below)
# using information schema b/c at this point we are not sure
# if our test database exists yet.

my $dbh = DbConnect('information_schema');

# creating the test database and elements if it does not exist
CreateTestDB($dbh);

# If we received the -W argument, doing our wait timeout test
if($opt_W) {
	print "Doing Wait Timeout Test\n";
	WaitTimeoutTest($dbh);
}
if($opt_K) {
	print "Doing Killable Wait Timeout Test\n";
	print "ATTN: You have 20 seconds to kill the MySQL thread!!\n";
	KillableWaitTimeoutTest($dbh);
}
# If we received the -w argument, doing our net write timeout test
if($opt_w) {
	print "Doing Net Write Timeout Test\n";
	NetWriteTimeoutTest($dbh);
}
# If we received the -r argument, doing our net read timeout test
if($opt_r) {
	print "Doing Net Read Timeout Test\n";
	NetReadTimeoutTest($dbh);
}
$dbh->disconnect;


sub NetReadTimeoutTest {
}

sub NetWriteTimeoutTest {
}
sub KillableWaitTimeoutTest {
	my $dbh = $_[0];
	my $iter = '';

	$dbh->do("set session wait_timeout = 100");
	sleep 20;
	my $sth = $dbh->prepare("select testId from tdata;");
	$sth->{mysql_use_result}=1;
	$sth->execute() or die "-------------\nErr: $DBI::err\nErrStr: $DBI::errstr\nState: $DBI::state\n";
	print "$DBI::state\n";
	while ($iter = $sth->fetchrow()) {
		print "$iter\n";
		sleep 12;
	}
	$sth->finish;
}

sub WaitTimeoutTest {
	my $dbh = $_[0];
	my $iter = '';

	$dbh->do("set session wait_timeout = 1");
	my $sth = $dbh->prepare("select testId from tdata;");
	$sth->{mysql_use_result}=1;
	sleep 2;
	$sth->execute() or die "-------------\nErr: $DBI::err\nErrStr: $DBI::errstr\nState: $DBI::state\n";
	print "$DBI::state\n";
	while ($iter = $sth->fetchrow()) {
		print "$iter\n";
	}
	$sth->finish;
}

sub DbConnect {
use DBI;

    my $database = $_[0];
    my $dsn = "DBI:mysql:$database;host=127.0.0.1;mysql_read_default_file=~/.my.cnf";
    my $dbh = DBI->connect($dsn) or die "$DBI::errstr";
    return $dbh;

}

sub CreateTestDB {
	my $dbh = $_[0];

	$dbh->do(qq|create database if not exists timeout_test;|);
	$dbh->do(qq|use timeout_test|);
	$dbh->do(qq|create table if not exists tdata
			(testId int not null primary key auto_increment,
			 testStrng varchar(10) not null default 'zzzzTest'
			) engine=innodb;|);
	$dbh->do(qq|create table if not exists tdata2
			(testId int not null primary key auto_increment,
			 testStrng varchar(10) not null default 'zzzzTest'
			) engine=innodb;|);
	$dbh->do(qq|truncate tdata;|);
	$dbh->do(qq|truncate tdata2;|);
	$dbh->do(qq|insert into tdata (testStrng) values ('This'),('That'),('TheOther');|);	

}
