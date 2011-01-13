#!/usr/bin/perl

use strict;
use warnings;
use open IN => ':utf8';
use Attribute::Constant;
use Getopt::Long;
use Text::CSV_XS;
use FindBin qw($Bin);
use DBIx::Simple;
use lib "$Bin/../lib";
use Lllo::Utils;
use Lllo::Database;

# -- Constant
my $PJ_CODE : Constant('jps');

# -- Get options
my $file;
GetOptions(
    'file=s' => \$file,
) or die "Failed to get options.";

unless (defined $file and -e $file) {
    die "Please specify the existing file.";
}

# -- Create objects
my $csv = Text::CSV_XS->new() or die Text::CSV_XS->error_diag();
my $db  = Lllo::Database->new($PJ_CODE)->connect({'RaiseError' => 1}) or die Lllo::Database->error();

# -- Processing data
open(my $fh, '<', $file) or die "Failed to open. $file";

$db->begin_work;
while (<$fh>) {
    chomp $_;
    next unless $csv->parse($_);
    my @fields = $csv->fields;
    next unless @fields > 3;

    my $site_name = $fields[1];
    my $url = $fields[2];
    my $lang_code = join(',', Lllo::Utils::langConvStr2Code($fields[3]));
    my $ctgr = '/Non_Categorized';  # TODO 
    my $desc = undef;               # TODO
    my ($query, @bind_values);

    my $exists = $db->query('SELECT SiteId FROM SITE WHERE Url = ?', $url)->hash;
    if ($exists) {
        # -- Update
        @bind_values = ($site_name, $url, $lang_code, $desc, $ctgr, time(), $exists->{'siteid'});
        $query = 'UPDATE SITE SET SiteName = ?, Url = ?, Language = ?, Description = ? ,Category = ?, UpdatedAt = ? WHERE SiteId = ?';
    } else {
        # -- Insert
        @bind_values = (undef, $site_name, $url, $lang_code, $desc, $ctgr, time()); 
        $query = 'INSERT INTO SITE VALUES (?,?,?,?,?,?,?)';
    }
    $db->query($query, @bind_values) or die $db->error;

    # -- If defined referer, replace into EXTRA table.
    if (defined $fields[4]) {
        my $referer = $fields[4];
        my $id = $db->query('SELECT LAST_INSERT_ID() as last_insert')->hash;

        @bind_values = (($exists) ? $exists->{'siteid'} : $id->{'last_insert'}, $referer);
        $db->query('REPLACE INTO EXTRA VALUES (?,?)', @bind_values) or die $db->error;
    }
}
$db->commit;
close($fh);

print "Sync OK\n";
exit 0;
