# Podcast Parser v0.0
# Copyright (c) 2005 Slim Devices, Inc. (www.slimdevices.com)

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License, 
# version 2.

# This package allows SlimServer to treat a podcast as a playlist

# XXX - Currently works only when podcast is retrieved via http.

package Plugins::Podcast::Parse;
use strict;

use Slim::Formats::Parse;
use Slim::Utils::Misc;
use XML::Simple;

init();

sub init {
	# text/xml is a terrible choice for content type, but most
	# podcasts seem to use it
	Slim::Formats::Parse::registerParser('xml',
										 \&readPodcast,
										 undef,
										 undef);
	# at least one uses application/rss+xml, which types.conf maps to 'pod'
	Slim::Formats::Parse::registerParser('pod',
										 \&readPodcast,
										 undef,
										 undef);

}

sub readPodcast {
	my $in = shift;

	$::d_plugins && msg("Podcast: parsing...\n");

	my @urls = ();

	# async http request succeeded.  Parse XML
	# forcearray to treat items as array,
	# keyattr => [] prevents id attrs from overriding
	my $xml = eval { XMLin($in,
						   forcearray => ["item"], keyattr => []) };

	if ($@) {
		$::d_plugins && msg("Podcast: failed to parse feed because:\n$@\n");
		# TODO: how can we get error message to client?
		return undef;
	}

	# some feeds (slashdot) have items at same level as channel
	my $items;
	if ($xml->{item}) {
		$items = $xml->{item};
	} else {
		$items = $xml->{channel}->{item};
	}

	for my $item (@$items) {
		my $enclosure = $item->{enclosure};
		if ($enclosure) {
			if ($enclosure->{type} =~ /audio/) {
				push @urls, $enclosure->{url};
				if ($item->{title}) {
					# associate a title with the url
					# XXX calling routine beginning with "_"
					Slim::Formats::Parse::_updateMetaData($enclosure->{url},
														  $item->{title});
				}
			}
		}
	}

	# it seems like the caller of this sub should be the one to close,
	# since they openned it.  But I'm copying other read routines
	# which call close at the end.
	close $in;

	$::d_plugins && msg("Podcast: parsed podcast.  Returning urls:\n" . join("\n", @urls) . "\n");

	return @urls;
}
