# -*- Perl -*-
#    TigerLily:  A client for the lily CMC, written in Perl.
#    Copyright (C) 1999  The TigerLily Team, <tigerlily@einstein.org>
#                                http://www.hitchhiker.org/tigerlily/
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License version 2, as published
#  by the Free Software Foundation; see the included file COPYING.
#
# $Header: /home/mjr/tmp/tlilycvs/lily/tigerlily2/TLily/Daemon/Attic/Connection.pm,v 1.2 1999/03/23 08:05:25 albert Exp $

package TLily::Daemon::Connection;

use strict;
use vars qw($errno);
use Carp;

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};

    croak "Required parameter 'sock' missing!" unless defined($args{sock});
    croak "Required parameter 'proto' missing!" unless defined($args{proto});

    #	my $ui = TLily::UI::name();
    #	$ui->print($args{sock});

    $self->{sock} = $args{sock};
    $self->{proto} = $args{proto};
    $self->{io_id} = TLily::Event::io_r (handle => $self->{sock},
					 mode   => 'r',
					 obj    => $self,
					 call   => \&receive);
    
    bless $self, $class;
}

sub receive {
    my ($self, $mode, $handler) = @_;
    my $buf;
    
    my $rc = sysread($self->{sock}, $buf, 4096);
    if ($rc < 0) {
	return if $errno == EAGAIN();
    }
    
    if ($rc <= 0) {
	$self->close();
	return;
    }
    
    TLily::Event::send(type   => "$self->{proto}_data",
		       daemon => $self,
		       text   => $buf);
}

sub close {
    my $self = shift;
    
    close $self->{sock};
    
    TLily::Event::send(type   => "$self->{proto}_close",
		       daemon => $self);
    
    TLily::Event::io_u($self->{io_id});
    $self->{daemon}->cxn_u($self);
}

1;