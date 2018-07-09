#!/usr/bin/perl -w
use Data::Dumper;

sub canon {
    my $foo = shift;
    $foo =~ s/-/ /go;
    return join '', map { ucfirst lc } split /(\s+)/, $foo;
}

sub listdir {
    my $d = shift;
    opendir(D, $d) || die "opendir: $d: $!\n";
    my @foo = sort(grep(!/^\./o, readdir(D)));
    closedir(D);
    return @foo;
}

sub first {
    my $f = shift;
    my $line;
    open(F, $f) || die "open: $f: $!\n";
    chomp($line = <F>);
    close(F);
    return $line;
}

sub lines {
    my $f = shift;
    my @results;
    open(F, $f) || die "open: $f: $!\n";
    chomp(@results = <F>);
    close(F);
    return \@results; # REF!
}

sub doonion {
    my ($path, $onion) = @_;
    my $odir = "$path/$onion";
    my %result = ();
    $result{'title'} = &first("$odir/title");
    $result{'urls'} = &lines("$odir/urls");
    $result{'proof'} = &lines("$odir/proof") if (-f "$odir/proof"); # OPTIONAL
    $result{'comment'} = &lines("$odir/comment") if (-f "$odir/comment"); # OPTIONAL
    $result{'sortkey'} = "$result{title}::$onion";
    return \%result;
}

sub docat {
    my ($path, $category) = @_;
    my $catdir = "$path/$category";
    my @onions = &listdir($catdir);
    my %result = ();
    foreach $onion (@onions) {
        my $foo = &doonion($catdir, $onion);
        my $key = $$foo{'sortkey'};
        $result{$key} = $foo;
    }
    return \%result;
}

# load

@categories = &listdir('directory');

foreach $catname (@categories) {
    $tree{$catname} = &docat('directory', $catname);
}

# print

foreach $catname (sort keys %tree) {
    print "----\n\n";
    my $catprint = &canon($catname);
    print "# $catprint\n\n";
    $catcontents = $tree{$catname};
    foreach $catsortkey (sort keys %{$catcontents}) {
        my $ocontents = $catcontents->{$catsortkey};
        my @foo = keys(%{$ocontents});
        print "## $ocontents->{title}\n\n";
        foreach my $line (@{$ocontents->{urls}}) {
            print "* $line";
            print " :lock:" if ($line =~ m!https://!);
            print "\n";
        }
        foreach my $line (@{$ocontents->{proof}}) {
            print " * $line\n";
        }
        print "\n";
    }
    print "\n";
}

#print Dumper(\%tree);
