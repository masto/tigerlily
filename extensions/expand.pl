# $Header: /home/mjr/tmp/tlilycvs/lily/tigerlily2/extensions/expand.pl,v 1.2 1999/02/24 21:51:56 neild Exp $ 

use strict;

use LC::UI;
use LC::Server::SLCP;
use LC::Global qw($event);


my %expansions = ('sendgroup' => '',
		  'sender'    => '',
		  'recips'    => '');

my @past_sends = ();


sub exp_expand {
	my($ui, $command, $key) = @_;
	my($pos, $line) = $ui->get_input;

	if ($pos == 0) {
		my $exp;
		if ($key eq '=') {
			$exp = $expansions{'sendgroup'};
			return unless ($exp);
			$key = ';';
		} elsif ($key eq ':') {
			$exp = $expansions{'sender'};
		} elsif ($key eq ';') {
			$exp = $expansions{'recips'};
		} else {
			return;
		}

		$exp =~ tr/ /_/;
		$ui->set_input(length($exp) + 1, $exp . $key . $line);
	} elsif (($key eq ':') || ($key eq ';') || ($key eq ',')) {
		my $fore = substr($line, 0, $pos);
		my $aft  = substr($line, $pos);
		
		return if ($fore =~ /[:;]/);
		return if ($fore =~ /^\s*[\/\$\?%]/);
		
		my @dests = split(/,/, $fore);
		foreach (@dests) {
			my $full = LC::Server::SLCP::expand_name($_);
			next unless ($full);
			$_ = $full;
			$_ =~ tr/ /_/;
		}
		
		$fore = join(',', @dests);
		$ui->set_input(length($fore) + 1, $fore . $key . $aft);
	}
	
	return;
}


sub exp_complete {
	my($ui, $command, $key) = @_;
	my($pos, $line) = $ui->get_input;

	my $partial = substr($line, 0, $pos);
	my $full;

	if ($pos == 0) {
		return unless @past_sends;
		$full = $past_sends[0] . ';';
	} elsif ($partial !~ /[\@\[\]\;\:\=\"\?\s]/) {
		my($fore, $aft) = ($partial =~ m/^(.*,)?(.*)/);
		$aft = LC::Server::SLCP::expand_name($aft);
		return unless $aft;
		$full = $fore if (defined($fore));
		$full .= $aft;
		$full =~ tr/ /_/;
	} elsif (substr($partial, 0, -1) !~ /[\@\[\]\;\:\=\"\?\s]/) {
		chop $partial;
		return unless (@past_sends);
		$full = $past_sends[0];
		for (my $i = 0; $i < @past_sends; $i++) {
			if ($past_sends[$i] eq $partial) {
				$full = $past_sends[($i+1)%@past_sends];
				last;
			}
		}
		$full .= ';';
	}
	
	if ($full) {
		substr($line, 0, $pos) = $full;
		$pos = length($full);
		$ui->set_input($pos, $line);
	}

	return;
}


LC::UI::command_r("expand"   => \&exp_expand);
LC::UI::command_r("complete" => \&exp_complete);
LC::UI::bind(','   => "expand");
LC::UI::bind(':'   => "expand");
LC::UI::bind(';'   => "expand");
LC::UI::bind('='   => "expand");
LC::UI::bind('C-I' => "complete");

sub private_handler {
	my($event,$handler) = @_;
	$expansions{sender} = $event->{SOURCE};

	my $me = $event->{server}->user_name();
	return unless (defined $me);

	my @group = split /, /, $event->{RECIPS};
	if (@group > 1) {
		push @group, $event->{SOURCE};
		@group = grep { $_ ne $me } @group;
		$expansions{sendgroup} = join(",", @group);
	}

	return;
}
$event->event_r(type => 'private',
		call => \&private_handler);

sub user_send_handler {
	my($event, $handler) = @_;
	my $dlist = join(",", @{$event->{RECIPS}});

	$expansions{recips} = $dlist;

	@past_sends = grep { $_ ne $dlist } @past_sends;
	unshift @past_sends, $dlist;
	pop @past_sends if (@past_sends > 5);

	return;
}
$event->event_r(type => 'user_send',
		call => \&user_send_handler);
