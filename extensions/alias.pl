# -*- Perl -*-
# $Header: /home/mjr/tmp/tlilycvs/lily/tigerlily2/extensions/alias.pl,v 1.4 1999/03/23 08:33:38 josh Exp $

use strict;

my %alias;

sub load {
    event_r(type  => "user_input",
	    order => "before",
	    call  => \&aliaser);
    command_r(alias => \&alias_cmd);

    shelp_r(alias => "Define client aliases");
    help_r(alias => "%alias <command> <newcommand>
%alias clear <command>
%alias list

Supports the following special characters in \"newcommand]\":
\$1 .. \$9  arguments to command
\$*        all arguments to command
\\n        command separator

Examples:

%alias hi bob;hi there\\njim;I hate you!
%alias inbeener /who beener \$*
");
}

sub alias_cmd {
    my ($ui,$args) = @_;
    
    if (! length($args) || $args eq "list") {
	if (scalar keys %alias) {
	    $ui->print("The following aliases are defined:\n");
	    foreach (sort keys %alias) {
		$ui->print("$_: $alias{$_}\n");
	    }
	} else {
	    $ui->print("(no aliases are currently defined)\n");
	}
	return;
    }
    
    my ($key,$val) = ($args =~ /(\S+)\s+(.*)/);
    
    if ($key eq "clear") {
	if($val eq "") {
	    $ui->print("(Usage: %alias clear [alias])\n"); return;
	}
	undef $alias{$val};
        $ui->print("(\%$key is now unaliased.)\n");
    }

    if ($key =~ /\S/ and $val =~ /\S/) {
	$alias{$key}=$val;
        $ui->print("(\%$key is now aliased to '$val')\n");
    }
}

sub aliaser {
    my($e, $h) = @_;
    my $server = server_name();
    
    if ($e->{text} =~ /^%(\S+)\s*(.*)/) {	
	my $newstr = $alias{$1};
	my $args = $2;
	my @args = ($1, (split /\s+/,$2));
	if ($newstr) {
	    for (0..9) {
		$newstr =~ s/\$$_/$args[$_]/g;
	    }
	    $newstr =~ s/\$\*/$args/g;
	    if ($newstr =~ /\\n/) {
		my @rest;
		($newstr,@rest) = split /\\n/,$newstr;
		foreach (@rest) {
		    TLily::Event::send({type => 'user_input',
					ui   => $e->{ui},
					text => "$_\n"});		    
		}
	    }
	    $e->{text} = $newstr;
	}
    }

    return 0;
}

