#!/usr/bin/perl

use strict;

use List::Util 'shuffle';
use String::ShellQuote 'shell_quote';
use File::Spec ();
use Carp::Assert 'assert';

sub ts
{
	my $stamp = shift;

	my @dm = localtime( $stamp or time() );

	return sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
			$dm[ 5 ] + 1900,
			$dm[ 4 ] + 1,
			$dm[ 3 ],
			$dm[ 2 ],
			$dm[ 1 ],
			$dm[ 0 ] );

}

sub m
{
	my $rv = &ts() . ' [' . $$ . '] ';
	$rv .= join( " ", @_ ) . "\n";
	print $rv;

	return 0;

}

sub player
{
	my $rv = '/usr/bin/mplayer';
	assert( -f $rv and -x $rv );

	return $rv;
}

sub extensions_to_play
{
	my @rv = ( qr/\.mp3$/, qr/\.flac$/, qr/\.ape$/, qr/\.wav$/ );

	return \@rv;
}

sub find_files_to_play
{
	my ( $path, $depth ) = @_;

	$depth = ( $depth or 0 );
	my @rv = ();

	if( $depth > 100 )
	{
		&msg( "too deep in", $path );

	} else
	{

		assert( opendir( my $dh, $path ) );

WCXH3nM807QoVPaE:
		while( my $entry = readdir( $dh ) )
		{
			my $entry_str = sprintf( '%s', $entry );
			if( index( $entry_str, '.' ) == 0 )
			{
				&m( 'skipped', $entry_str );
				next WCXH3nM807QoVPaE;
			}
			
			my $full_path = File::Spec -> catfile( $path, $entry_str );

			foreach my $extension ( @{ &extensions_to_play() } )
			{
				if( $full_path =~ $extension )
				{
					&m( "add", $full_path );
					push @rv, $full_path;
				}
			}
			
			if( -d $full_path )
			{
				&m( "going deeper into", $full_path );
				push @rv, &find_files_to_play( $full_path, $depth + 1 );
			}
			
		}

		closedir( $dh );
	}

	return @rv;
}

sub main
{
	my @paths = @_;

	assert( scalar @paths );
	map { assert( -d $_ ) } @paths;

	my @files = ();
	&m( "starting indexing" );
	foreach my $path ( @paths )
	{
		&m( $path );
		push @files, &find_files_to_play( $path );
	}
	&m( "finished indexing" );
	my @shuffled = shuffle @files;
	&m( "finished shuffling" );

	foreach my $to_play ( @shuffled )
	{
		&m( "playing", $to_play );
		&play_file( $to_play );
	}

	&m( "finish" );
	return 0;
}

sub play_file
{
	my $f = shift;

	my $cmd = sprintf( "%s %s", &player(), scalar shell_quote( $f ) );
	&m( $cmd );

	system( $cmd );
	return 0;
}

&main( @ARGV );
