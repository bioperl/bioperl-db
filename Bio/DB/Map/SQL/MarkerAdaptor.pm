
#
# BioPerl module for Bio::DB::Map::SQL::MarkerAdaptor
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::Map::SQL::MarkerAdaptor - Adaptor Object for Markers

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org             - General discussion
  http://bioperl.org/MailList.shtml - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bioperl.org
  http://bioperl.org/bioperl-bugs/

=head1 AUTHOR - Jason Stajich

Email jason@chg.mc.duke.edu

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::Map::SQL::MarkerAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::SQL::BaseAdaptor;
use Bio::DB::Map::Marker;

@ISA = qw(Bio::DB::SQL::BaseAdaptor);

sub new {
    my($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    return $self;
}


=head2 get

 Title   : get
 Usage   : my @markers = $markeradaptor->get(-ids => \@ids );
 Function: gets a list of Bio::DB::Map::Marker objects based on
           the list of queries
 Returns : list of Bio::DB::Map::Marker objects
 Args    : -id   => markerid
           -ids  => array ref of marker ids
           -name => marker name
           -names=> array ref of marker names
           -pcrprimers => array ref of pcrprimers to use to search for marker  
=cut

sub get {
    my ($self, @args) = @_;
    my ($id, $ids, $name, $names,
	$pcrprimers ) = $self->_rearrange( [qw(ID IDS NAME NAMES 
					       PCRPRIMERS )], 
						     @args );

    my (@n, @i);

    
    # for now we will ignore bad users who specify > 1 argument
    # by just handling input in a precedence order.    
    
    if( defined $pcrprimers ) {
	# pcr primers trump all for now
	if( ref($pcrprimers) !~ /array/i || 
	    scalar @$pcrprimers != 2 ) {
	    $self->warn("Did not supply a 2-entry array ref or paramer -pcrprimers");
	    return undef;
	}
	return $self->_get_marker_by_primers(@$pcrprimers);
    }
    
    
    if( defined $names ) {
	if( ref($names) !~ /array/i ) {
	    $self->warn("Must specify an array ref for the parameter -names");
	    return undef;
	}
	@n = @$names;       
    } elsif( defined $name ) {
	@n = ($name);	
    } 

    if( defined $ids ) {
	if( ref($ids ) !~ /array/i ) {
	    $self->warn("Must specify an array ref for the parameter - ids");
	    return undef;
	}	
	@i = @$ids;
    } elsif( defined $id ) {
	@i = ($id);
    } 
    if( ! @i && ! @n ) {
	$self->warn("did not pass in appropriate arguments to get!");
	return ();
    }
    # should we try and be sure that the lists produce a unique list?    
    return ( $self->_get_markers_by_ids(@i),
	     $self->_get_markers_by_names(@n) );
}

=head2 write

 Title   : write
 Usage   : $marker_adaptor->write($marker);
 Function: Store a new Marker or update an existing one 
 Returns : Bio::DB::Map::MarkerI object (id updated if necessary)
           or undef if not properly updated 
 Args    : Bio::DB::Map::MarkerI object

=cut

# this is not atomic and we don't have transactions so it is hard to
# rollback this stuff.  Right now if a marker has a map which is not in
# the db we don't find out until we get to that part of the data a
# better check should probably be done here to handle this properly

sub write {
    my ($self,$marker) = @_;

    if( !ref($marker) || ! $marker->isa('Bio::DB::Map::MarkerI') ) {
	$self->throw("Must specify a Bio::DB::Map::MarkerI object not '".ref($marker)."' for MarkerAdaptor::write");
    }

    my $mapadaptor = $self->db->get_MapAdaptor();
    my %maphash = $mapadaptor->get_mapids_hash();
    my $sth;
    if( $marker->id ) {
	# this is an update since marker already has an id
	my $rc = 0;
	my $UPDATESQL = 'UPDATE marker SET %s WHERE markerid = ? ';  
	# let's get the original and compare for
	# the sake of comparing aliases and map positions
	my ($markercopy) = $self->get('-id' => $marker->id );
	if( ! $markercopy ) {
	    $self->warn("Marker ". join(' ', ($marker->id, $marker->locus,
					      $marker->probe)). "DNE \n");
	    return;
	}
	my ( @updatefields, @updatevalues );

	foreach my $field ( qw(locus probe chrom type length) ) {
	    next if( !defined $marker->{$field} );
	    if( !defined $markercopy->{$field} ||
		($markercopy->{$field} ne $marker->{$field}) ) {
		push (@updatefields,"$field=?");
		push (@updatevalues, $marker->{$field});
	    }
	}

	if( $markercopy->pcrfwd ne $marker->pcrfwd ){
	    push (@updatefields,"fwdprimer=?");
	    push (@updatevalues, $marker->pcrfwd);
	}
	if( $markercopy->pcrrev ne $marker->pcrrev ){
	    push (@updatefields,"revprimer=?");
	    push (@updatevalues, $marker->pcrrev);
	}
	eval { 
	    if( @updatefields ) {
		my $sql = sprintf($UPDATESQL,
				  join(', ', @updatefields));
		$sth = $self->prepare($sql);
		$sth->execute(@updatevalues,$marker->id);
		$sth->finish();
	    }
	};
	if( $@ ) {
	    $self->warn($@);
	    $marker = undef;
	    return $marker;
	}
	# update aliases, in the current implementation we'll never 
	# remove aliases unless a marker is completely removed       
	$sth = $self->prepare(q(INSERT INTO marker_alias 
				( alias, markerid, source ) 
				VALUES ( ?, ?, ?) 
				));
	my $sthupdate = $self->prepare(q(UPDATE marker_alias 
					 SET source = ? 
					 WHERE markerid = ? 
					 AND alias = ?));
	foreach my $alias ( $marker->each_alias ) {
	    my $src = $marker->get_source_for_alias($alias);
	    eval { 
		if( ! $markercopy->is_alias($alias) ) {
		    $sth->execute($alias,$marker->id, $src);
		} elsif( $markercopy->get_source_for_alias($alias) ne 
			 $src ) {
		    $sthupdate->execute($src, $marker->id, $alias);
		}
	    };
	    if( $@) {		
		if ( $@ =~ /Duplicate entry/ ) {
		    $self->warn($@) if( $self->verbose >= 1);
		} else {
		    $rc = -1;
		    $self->warn($@);
		}
	    }
	}
	$sth->finish();
	$sthupdate->finish();

	# update positions    
	$sth = undef;

	my $updatesth = $self->prepare(q(UPDATE map_position 
					 SET position = ? 
					 WHERE markerid = ? 
					 AND mapid = ?));

	my $insertsth = $self->prepare(q(INSERT INTO map_position 
					 (position, markerid, mapid) 
					 VALUES ( ?, ?, ?) ));

	foreach my $position ( $marker->each_position ) {
	    my $mapid = $maphash{$position->{'map'}};
	    if( ! $mapid ) {
		$self->warn(sprintf("Trying to add positions for map '%s', which does not exist in this database yet, please add it first",
				    $position->{'map'}));
	    }	     
	    if( !defined $markercopy->get_position($position->{'map'})) {
		$sth = $insertsth; 
	    } elsif( $markercopy->get_position($position->{'map'}) !=
		     $position->{'position'} ) {
		$sth = $updatesth;
	    } else {  next; }	    
	    eval { 
		$sth->execute($position->{'position'}, $marker->id,$mapid);
	    };
	    if( $@) {
		$self->warn($@);
		$rc = -1;
	    }
	}
	$sth->finish() if( $sth);
	$updatesth->finish();
	$insertsth->finish();
	$marker = undef unless( $rc == 0);
    } else { 
	# this is a new insert       
	eval {
	    $sth = $self->prepare(q(INSERT INTO marker
					(locus,probe,type,chrom,
					 fwdprimer,revprimer,length)
					VALUES ( ?, ?, ?, ?, ?, ?, ?)));
	    my ($chr,$chrom) = ( $marker->chrom =~ /(chr)?(X|Y|UL|\d+)/ );

	    $sth->execute($marker->locus,$marker->probe,$marker->type,
			  $chrom, $marker->pcrfwd,$marker->pcrrev, 
			  $marker->length);	   
	    # for db cross-platform, even though I could just call
	    # $sth->{'mysql_insertid'};
	    # $self->get_last_id();
	    $marker->id($sth->{'mysql_insertid'});
	    $sth->finish();
	};
	if( $@ ) {    
	    if( $@ =~ /Duplicate entry/ ) {
		$self->warn($@) if( $self->verbose >= 1);
		return undef;
	    }
	    $self->warn($@);	
	    $self->warn("Working on marker \n" . $marker->to_string());
	    $marker = undef;
	    return $marker;
	}
	# let's insert aliases
	$sth = $self->prepare(q(INSERT INTO marker_alias 
					( markerid, alias, source) 
					VALUES ( ?, ?, ?)));	   
	    foreach my $alias ( $marker->each_alias ) {
		eval { 
		    $sth->execute($marker->id, $alias, 
				  $marker->get_source_for_alias($alias));
		};
		if ($@) {
		    $self->{'_dblasterr'} = $@;	    
		    $self->warn($@) unless ( $@ =~ /Duplicate entry/ &&
					     $self->verbose < 1 );
		}
	    }
	    $sth->finish();
	eval {
	    # let's insert map positions
	    $sth = $self->prepare(q(INSERT INTO map_position 
					(markerid, position, mapid) 
					VALUES ( ?, ?, ? )));
	    foreach my $position ( $marker->each_position ) {	       
		my $mapid = $maphash{$position->{'map'}};
		if( ! $mapid ) {
		    $self->warn("Map " . $position->{'map'}. " does not exist, please add it before adding this marker");			    
		    next;
		}
		    $sth->execute($marker->id,$position->{'position'},
				  $mapid);
	    }
	};
	if($@ ) {
	    if( $@ =~ /Duplicate entry/ ) {
		return undef;
	    }
	    $self->warn($@);	
	    $self->warn("Working on marker \n" . $marker->to_string());
	    $marker = undef;
	}
    }
    $marker->adaptor($self) if( $marker);
    return $marker;
}

=head2 delete

 Title   : delete
 Usage   : $markeradaptor->delete($marker);
 Function: Removes a marker from the database
 Returns : none
 Args    : Bio::DB::Map::MarkerI object

=cut

sub delete{
   my ($self,$markerid) = @_;

   if( ! $markerid ) {
       $self->warn("did not specify a valid marker id to remove"); 
   }
   eval  {
       # delete from map_positions
       my $sth = $self->prepare(q(DELETE FROM map_position 
				  WHERE markerid = ?));
       $sth->execute($markerid);
       # delete from aliases
       $sth = $self->prepare(q(DELETE FROM marker_alias WHERE markerid = ?));
       $sth->execute($markerid);
       # delete from marker
       $sth = $self->prepare(q(DELETE FROM marker WHERE markerid = ?));
       $sth->execute($markerid);  
   };
   if($@) {
       $self->warn($@);
       return 0;
   }
   return 1;
}

=head2 add_duplicate_marker

 Title   : add_marker_duplicate_marker
 Usage   : boolean $adaptor->add_duplicate_marker($marker ); 
 Function: Tries to find a duplicate marker for a marker and 
           updates it to contain merge of the two information srcs
 Returns : boolean if marker was added
 Args    : Bio::DB::Map::MarkerI object


=cut

sub add_duplicate_marker {
   my ($self,$marker) = @_;
   return 0 unless( defined $marker && ref($marker) 
		     && $marker->isa('Bio::DB::Map::MarkerI') );
   
   my @potential = $self->get('-pcrprimers' => [ $marker->pcrfwd,
						 $marker->pcrrev ] );
   
   if( ! @potential ) {
       @potential = $self->get('-name' => $marker->probe );       
       if( ! @potential ) {
	   @potential = $self->get('-name' => $marker->locus );
	   if( ! @potential ) {
	       @potential = $self->get('-names' => [ $marker->each_alias ] );
	   }
       }
   }

   if( @potential > 1) { $self->warn("got back " . scalar @potential . 
				     " markers for query!"); 
		     }
   my $dup = shift @potential; # take the first one
   return 0 if ( ! $dup );      
   
   foreach my $map ( $marker->each_position ) {
       if( $dup->get_position($map->{'map'} ) ) {
	   $dup->add_position($map->{'position'}, $map->{'map'} );
       }	       
   }	     
    
   foreach my $alias ( $marker->each_alias ) {
       if( ! $dup->is_alias($alias) ) {
	   $dup->add_alias($alias);
       }       
   }
      
   if( $dup->locus ne $marker->locus ) {
       $dup->add_alias($marker->locus);
   }
   if( $dup->probe  ne $marker->probe ) {
       $dup->add_alias($marker->probe);
   }
   return $self->write($dup);   
}


sub _get_markers_by_ids {
    my ($self, @ids) = @_;
    return () unless ( @ids);

    my $TEMPTABLESQL = q(CREATE TEMPORARY TABLE __markers 
			 ( markerid integer(11) not null PRIMARY KEY));
    my $TEMPLOAD = q(INSERT INTO __markers (markerid) values ( ? ));
    my $MARKERSQL = q(SELECT 
		      m.markerid  as '-id',
		      m.locus     as '-locus',
		      m.probe     as '-probe',
		      m.type      as '-type',
		      m.chrom     as '-chrom',
		      m.fwdprimer as '-pcrfwd',
		      m.revprimer as '-pcrrev',
		      m.length    as '-length'
		      FROM  marker m, __markers t
		      WHERE m.markerid = t.markerid);

    my $ALIASSQL =q(SELECT 
		    m.alias as alias, 
		    m.markerid as markerid, 
		    m.source as source 
		    FROM marker_alias m, __markers t 
		    WHERE m.markerid = t.markerid );

    my $POSITIONSQL = q(SELECT 
			p.markerid as markerid, 
			map.name as mapname, p.position as position 
			FROM   map, map_position p, __markers t 
			WHERE  p.mapid = map.mapid AND 
			p.markerid = t.markerid);
    my %markers;

    # create table no matter what, but don't die if table already exists
    # should actually write if( ! exists ) SQL code, but 
    # can't find the syntax

    eval { $self->prepare($TEMPTABLESQL)->execute() };
    if( $@ ) {
	# this is going to warn whenever we write > 1 marker at a
	# time, but there is no reason to pay the create/drop overhead
    }

    eval {	
	my $sth = $self->prepare($TEMPLOAD);
	foreach my $id ( @ids ) {
	    $sth->execute($id);
	}
	$sth->finish();
	
	$sth = $self->prepare($MARKERSQL);	
	$sth->execute();
	my $row;
	while( defined($row = $sth->fetchrow_hashref)  ) {
	    $markers{$row->{'-id'}} = new Bio::DB::Map::Marker( '-adaptor' => $self,
				    %{$row} );
	}
	$sth->finish();
	
	$sth = $self->prepare($ALIASSQL);
	$sth->execute();	
	while( defined($row = $sth->fetchrow_hashref) ) {
	    $markers{$row->{'markerid'}}->add_alias($row->{'alias'},
						    $row->{'source'});
	}
	$sth->finish();

	$sth = $self->prepare($POSITIONSQL);
	$sth->execute();
	while( defined($row = $sth->fetchrow_hashref) ) {
	    $markers{$row->{'markerid'}}->add_position($row->{'position'},
						       $row->{'mapname'});
	}
	$sth->finish();			
    };
    if( $@ ) { $self->warn($@);	}
    eval { $self->prepare('DELETE FROM __markers')->execute() };
    return values %markers;
}

sub _get_markers_by_names {
    my ($self, @names) = @_;
    return () unless ( @names);
        
    my $LOCUSFIND = 'SELECT markerid FROM marker WHERE locus = ?';
    my $PROBEFIND = 'SELECT markerid FROM marker WHERE probe = ?';
    my $ALIASFIND = 'SELECT markerid from marker_alias  WHERE alias = ?';
    
    my @ids;
    eval {
	my $sth;	
	# same basic code as the id search except we have 
	# to build up the list of ids by searching 
	# 3 different fields, probe, locus, and alias
	# to see if the name matches any of these
	#
	# if the name matches > 1 locus or alias (probe is unique)
	# then we spit a warning and do not process that marker
	
	my $probe = $self->prepare($PROBEFIND);
	my $locus = $self->prepare($LOCUSFIND);
	my $alias = $self->prepare($ALIASFIND);

	NAME: foreach my $name ( @names ) {	   
	    my @tids;
	    $probe->execute($name);
	    while( my ($tid) = $probe->fetchrow_array ) {
		push @tids, $tid;
	    }
	    if( ! @tids ) {
		
		$locus->execute($name);
		while( my ($tid) = $locus->fetchrow_array ) {
		    push @tids, $tid;
		}
		if( ! @ids ) {
		    $alias->execute($name);
		    while( my ($tid) = $alias->fetchrow_array ) {
			push @tids, $tid;
		    }
		    if( @tids > 1 ) {
			$self->warn("Requestion marker ($name) which matches > 1 Alias, please be more specific or request by markerid");
			next NAME;
		    }
		} elsif( @tids > 1 ) {
		    $self->warn("Requesting arker ($name) which matches > 1 Locus, please be more specific or request by markerid");
		    next NAME;
		}
	    }
	    push @ids, @tids;
	}	
    };
    if( $@ ) {
	$self->warn($@);
    }    
    return $self->_get_markers_by_ids(@ids);
}

sub _get_marker_by_primers {
    my ($self, $primer1,$primer2) = @_;
    my $SQL = q(SELECT markerid FROM marker 
		WHERE fwdprimer = ? AND revprimer = ?);
    my $marker;
    eval { 
	my $sth = $self->prepare($SQL);
	$sth->execute($primer1,$primer2);
	my ($row) = $sth->fetchrow_array;
	if( $row ) {	    
	    ( $marker)  = $self->get('-id' => $row);
	} else { 
	    $sth->execute($primer2,$primer1);
	    ($row) = $sth->fetchrow_array;
	    if( $row ) {
		( $marker) = $self->get('-id' => $row);
	    }
	}	
    };
    if( $@ ){
	$self->warn($@);	
    }
    return $marker;
}

sub prepare {
    my ($self, @args) = @_;
    $self->SUPER::prepare(@args);
}
1;
