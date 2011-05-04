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
my $LINK_TARGET : Constant('_blank');
my $USER_NAME : Constant('8qzbwi');

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

    unless ($csv->parse($_)) {
        print "CSVの行パースに失敗しました\n";
        print "$_\n";
        next;
    }

    my @fields = $csv->fields;

    unless (@fields > 3) {
        print "フィールド数が少ない\n";
        print "$_\n";
        next;
    }

    my $link_name        = $fields[1];
    my $link_url         = $fields[2];
    my $link_description = '';  # TODO
    my $lang_code        = join(',', Lllo::Utils::langConvStr2Code($fields[3]));
    my $term_taxonomy_id = 16;  # TODO

    my ($query, @bind_values);

    @bind_values = ($link_url, $link_name, $LINK_TARGET, $link_description);
    $query = "INSERT INTO jps_links (link_url,link_name,link_target,link_description,link_updated,link_notes) VALUES (?,?,?,?,NOW(),'')";
    $db->query($query, @bind_values) or die $db->error;

    @bind_values = ($lang_code, $USER_NAME);
    $query = "INSERT INTO jps_links_extrainfo (link_id,link_telephone,link_submitter,link_textfield,link_no_follow) VALUES (last_insert_id(),?,?,'','')";
    $db->query($query, @bind_values) or die $db->error;

    @bind_values = ($term_taxonomy_id);
    $query = "INSERT INTO jps_term_relationships (object_id,term_taxonomy_id) VALUES (last_insert_id(),?)";
    $db->query($query, @bind_values) or die $db->error;

}
$db->commit;
close($fh);

print "Sync OK\n";
exit 0;
