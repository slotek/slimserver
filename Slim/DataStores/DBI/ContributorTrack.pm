package Slim::DataStores::DBI::ContributorTrack;

# $Id$
#
# Contributor to track mapping class

use strict;
use base 'Slim::DataStores::DBI::DataModel';

use constant ROLE_ARTIST => 1;
use constant ROLE_COMPOSER => 2;
use constant ROLE_CONDUCTOR => 3;
use constant ROLE_BAND => 4;

{
	my $class = __PACKAGE__;

	$class->table('contributor_track');
	$class->columns(Essential => qw/id role contributor track namesort/);

	$class->has_a(contributor => 'Slim::DataStores::DBI::Contributor');
	$class->has_a(track => 'Slim::DataStores::DBI::Track');

	# xxx - removed album => $track->album(), creates database coherency problem
	#$class->has_a(album => 'Slim::DataStores::DBI::Album');

	$class->add_constructor('contributorsFor' => 'track=?');
	$class->add_constructor('artistsFor' => "track=? AND role=".ROLE_ARTIST);
	$class->add_constructor('composersFor' => "track=? AND role=".ROLE_COMPOSER);
	$class->add_constructor('conductorsFor' => "track=? AND role=".ROLE_CONDUCTOR);
	$class->add_constructor('bandsFor' => "track=? AND role=".ROLE_BAND);
}

tie my %_cache, 'Tie::Cache::LRU', 5000;

sub add {
	my $class      = shift;
	my $artist     = shift;
	my $role       = shift;
	my $track      = shift;
	my $artistSort = shift;

	my @contributors = ();
	
	for my $artistSub (Slim::Music::Info::splitTag($artist)) {

		my $sortable_name = $artistSort || Slim::Utils::Text::ignoreCaseArticles($artist);
			
		my $artistObj;

		if (defined $_cache{$artistSub}) {

			$artistObj = $_cache{$artistSub};

		} else {

			$artistObj = Slim::DataStores::DBI::Contributor->find_or_create({ 
				name => $artistSub,
			});

			$artistObj->namesort($sortable_name);
			$artistObj->update();

			$_cache{$artistSub} = $artistObj;
		}

		push @contributors, $artistObj;

		# XXX - hog
		# xxx - removed album => $track->album(), creates database coherency problem
		Slim::DataStores::DBI::ContributorTrack->find_or_create({
			track => $track,
			contributor => $artistObj,
			role => $role,
			namesort => $sortable_name,
		});
	}

	return wantarray ? @contributors : $contributors[0];
}

1;

__END__


# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:
