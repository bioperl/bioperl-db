#
# BioPerl module for Bio::EnsemblLite::UpdateableDB
#
# Cared for by Jason Stajich <jason@chg.mc.duke.edu>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
#
# _history
# July 1, 2000 - module begun
#
# POD Doc - main docs before code

=head1 NAME

Bio::EnsemblLite::UpdateableDB - Manages writing to an ensemble-lite database.

=head1 SYNOPSIS 

    # get a Bio::EnsemblLite::UpdateableDB somehow
    use Bio::EnsemblLite::UpdateableDB;

    my $ensembl = Bio::EnsemblLite::UpdateableDB->new(-host=>$host, 
					    -user=>$user,
					    -pass=>$pass);
    my $seq = $ensembl->get_Seq_by_id('some-id');
    $seq->desc('new desc');
    eval { 	
	$ensembl->write_seq( [ $seq ], undef, undef);
    };
    if( $@ ) {
	print STDERR "an error when trying to write seq : $@\n";
    }

=head1 DESCRIPTION

This module seeks to provide a simple method for pushing sequence changes 
back to a Sequence Database - which can be an SQL compliant database, a file 
based database, AceDB, etc.

=head1 AUTHOR

Jason Stajich <jason@chg.mc.duke.edu>.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track 
the bugs and their resolution. Bug reports can be submitted via email 
or the web:

    bioperl-bugs@bio.perl.org                   
    http://bio.perl.org/bioperl-bugs/           

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut
#Lets start some code

package Bio::EnsemblLite::UpdateableDB;

use strict;

use vars qw( @ISA @EXPORT @EXPORT_OK $REVISION $CENTERCODE $TECH $IDSEP 
	     $SEPARATOR %DBQUERY );
use DBI;
use Bio::DB::UpdateableSeqI;
use Bio::Root::Object;

$IDSEP = ':';
$SEPARATOR = '::;';
$CENTERCODE = 'LOCAL'; #default to LOCAL for center code
$TECH = $ENV{USER};

@EXPORT_OK = qw( $CENTERCODE $TECH );

$REVISION = '$Id$ ';

%DBQUERY = ( 
	     identity => { mysql  => 'LAST_INSERT_ID()',
			   sybase => '@@IDENITY',
			   },
	     );
# EnsEMBL requirements
use Bio::EnsEMBL::DBSQL::DummyStatement;

@ISA = qw(Bio::Root::Object Bio::DB::UpdateableSeqI );

sub _initialize {
  my($self,@args) = @_;
  my $make = $self->SUPER::_initialize;
  my ( $db, $host, $driver, $user, $password, $srv, $debug) = 
	   $self->_rearrange( [qw(DBNAME HOST DRIVER USER PASS
				  SERVER DEBUG )], 
			      @args);
  $db || $self->throw('Database object must have a database name');
  $user || $self->throw('Database object must have a user');
  if( $debug ) {
      $self->_debug($debug); 
  } else {
      $self->_debug(0);
  }
  if( ! $driver ) {
      $driver = 'mysql';
  }
  $self->_driver($driver);
  if( ! $host ) {
      $host = 'localhost';
  }

  my $dsn = "DBI:$driver:database=$db;host=$host";
  my $attribhash = { RaiseError=>1};

  if( $self->_driver eq 'sybase' ) {
      $dsn .= ";server=$srv;scriptName=ensembl-lite";
      $attribhash->{AutoCommit} = 1;
  }

  if( $debug && $debug > 10 ) {
      $self->_db_handle("dummy dbh handle in debug mode $debug");
  } else {
      
      my $dbh = DBI->connect("$dsn","$user",$password, $attribhash);
      $dbh || $self->throw("Could not connect to database $db user $user using [$dsn] as a locator;dsn = $dsn");
      
      if( $self->_debug > 3 ) {
	  $self->warn("Using connection $dbh");
      }     
      $self->_db_handle($dbh);
  }
  
  return $make;
}

sub DESTROY {
    my ( $self ) = @_;
    if( defined $self->{'_db_handle'} ) {
	$self->{'_db_handle'}->disconnect();
	$self->{'_db_handle'} = undef;
    }
}

=head2 write_seqs

 Title   : write_seqs
 Usage   : write_seqs(\@updatedseqs, \@addedseqs, \@deadseqs)
 Function: Writes changes 
 Example : 
 Returns : 
 Args    : 

=cut

sub write_seqs {
    my ($self, $updates, $additions, $deletes) = @_;
    if( defined $additions ) {
	for( my $i=0;$i<scalar @$additions; $i++ ) {
	    $self->_add_seq(@$additions[$i]);
	}
    } 
    if( defined $updates ) {
    }
    if( defined ($deletes)  ) {
	for( my $i=0;$i<scalar @$deletes;$i++) {
	    $self->_remove_seq(@$deletes[$i]);
	}
    }
}

=head2 _add_seq

 Title   : _add_seq
 Usage   : _add_seq($seq)
 Function: Adds a new sequence
 Example : 
 Returns : 
 Args    : 

=cut

sub _add_seq {
    my ($self, $seq) = @_;

    my ($rv, $sth, $rows, $SQL, $dnainsertid);
    $SQL = 'SELECT ' . $DBQUERY{identity}->{$self->_driver};
    my $idensth = $self->prepare($SQL);
    eval { 
	if( defined $seq->accession_number &&	    
	    $seq->accession_number ne 'unknown'  ) {
	    $SQL = qq(SELECT count(*) FROM dna_description 
		      WHERE accession = ?);
	    
	    $sth = $self->prepare($SQL);
	    $sth->execute($seq->accession_number);
	    ($rows) = $sth->fetchrow_array;
	    
	    if( $rows > 0 ) {
		print "rows = $rows\n";
		$self->throw("Accession number " . $seq->accession_number . 
			     " already defined in the db, must do an update or delete and re-add to change this seq"); 
	    } 
	    
	} else {
	    # we are inserting into a table with just one field
	    # that is an identity field, so can insert a null
	    # and get out next sequential number
	    $SQL = qq(INSERT INTO local_accession_num values (?));
	    $sth = $self->prepare($SQL);
	    $sth->execute();
	    $idensth->execute();
	    ($dnainsertid) = $idensth->fetchrow_array;
	    $seq->accession_number($CENTERCODE . $dnainsertid);
	    $seq->display_id($seq->accession_number) if( !defined $seq->display_id);
	}
	# insert the sequence
	$SQL = qq( INSERT INTO dna ( sequence,created ) VALUES ( ?,NOW()));
	$sth = $self->prepare( $SQL);
	
	$rv = $sth->execute($seq->seq());

	$idensth->execute();
	($dnainsertid) =  $idensth->fetchrow_array;
	$seq->primary_id(join($IDSEP, ($dnainsertid . '0')));
	# insert information about the sequence
	$SQL = sprintf('INSERT INTO dna_description ( seqid, name, accession, 
                                                      tech ) 
		        VALUES ( %s, ?, ?, %s )', 
		       $dnainsertid, $self->quote($TECH));
		       
	$sth = $self->prepare($SQL);
	$sth->execute($seq->display_id, $seq->accession_number);
	
        # now lets add the features
	my @features = $seq->all_SeqFeatures();
	$SQL = qq(INSERT INTO generic_feature ( seqid, name, strand,source,
					seq_start, seq_end)
		  VALUES ( $dnainsertid, ?, ?, ?, ?, ?));
	my $fsth = $self->prepare($SQL);
	$SQL = qq(INSERT INTO feature_detail ( tag, value ) 
		  VALUES ( ?, ? ));
	my $fset_sth = $self->prepare($SQL);
	$SQL = qq(INSERT INTO feature_detail_association ( featureid, detailid, rank ) 
		  VALUES ( ?, ?, ? ));
	my $fset_join_sth = $self->prepare($SQL);
	
	foreach my $f ( @features ) {
	    $fsth->execute($f->primary_tag, $f->strand, $f->source_tag, 
			  $f->start, $f->end);
	    
	    $idensth->execute();
	    my ($featureid) =  $idensth->fetchrow_array;

	    my @tags = $f->all_tags;		      
	    my $count = 0;
	    foreach my $t ( @tags ) {
		$fset_sth->execute($t, join($SEPARATOR, $f->each_tag_value($t)));
		$idensth->execute();
		my ($fsetid) = $idensth->fetchrow_array;
		$fset_join_sth->execute($featureid,$fsetid, $count++);
	    }
	}
	$self->commit;
    };
    if( $@ || ! $rv ) {
	$self->rollback;
	$self->throw("failed to insert dna $seq\n$@\n$SQL");
    }				  
}

=head2 _remove_seq

 Title   : _remove_seq
 Usage   : _remove_seq($seq)
 Function: Removes an existing sequence
 Example : 
 Returns : 
 Args    : exceptions "seq out of sync", "id does not exist", 
    "more than one seq exists for id"

=cut

sub _remove_seq {
    my ($self, $seq) = @_;
    my ( $id, $ver) = split(/:/,$seq->primary_id);
    my $SQL;
    eval { 
	$SQL = qq( SELECT seqid, version FROM dna_description 
		   WHERE seqid = ?);
	my $sth = $self->prepare( $SQL );
	$sth->execute($id);
	my ( $id_r, $ver_r, $data);
	$data = $sth->fetchall_arrayref;
 	if( $sth->rows == 0 ) {
	    $self->throw("id does not exist");
	} elsif ( $sth->rows > 1 ) {
	    $self->throw("more than one seq exists for id: corrupted db");
	}
	
	( $id_r, $ver_r) = @$data->[0]->[0];
	if( $ver_r > $ver ) {
	    $self->throw("seq out of sync");
	}
	$SQL = qq(DELETE FROM dna_description WHERE seqid = ?);
	$sth = $self->prepare($SQL);
	$sth->execute($id);
	
	$SQL = qq(SELECT distinct f.detailid FROM feature_detail_association f, generic_feature g
		  WHERE g.featureid = f.featureid AND g.seqid = ?);

	$sth = $self->prepare($SQL);
	$sth->execute($id);
	my $rows = $sth->fetchall_arrayref;

	$SQL = qq(DELETE FROM feature_detail_association WHERE detailid = ?);
	$sth = $self->prepare($SQL);

	$SQL = qq(DELETE FROM feature_detail WHERE detailid = ?);
	my $dsth = $self->prepare($SQL);
	
	foreach my $row ( @$rows ) { 
	    $sth->execute(@$row[0]);	    
	    $dsth->execute(@$row[0]);
	}
	$SQL = qq(DELETE from generic_feature WHERE seqid = ?);
	$sth = $self->prepare($SQL);
	$sth->execute($id);
	
	$SQL = qq(DELETE FROM dna WHERE id = ?);
	$sth = $self->prepare($SQL);
	$sth->execute($id);	
	$self->commit;
    };
    if( $@ ) {
	$self->rollback;
	$self->throw("trying to remove ". $seq->display_id . "$@\n$SQL");
    }
}

=head2 _update_seq
    
 Title   : _update_seq
 Usage   : _update_seq($seq)
 Function: Updates a sequence
 Example : 
 Returns : will throw an exception if
           sequence is out of sync from expected val.
 Args    : a seq object that was retrieved from Bio::DB::UpdateableSeqI

=cut

sub _update_seq {
    my ($self, $seq) = @_;
    
    
}


=head1 Methods inherieted from Bio::DB::RandomAccessI
    
=head2 get_Seq_by_id

 Title   : get_Seq_by_id
 Usage   : $seq = $db->get_Seq_by_id('ROA1_HUMAN')
 Function: Gets a Bio::Seq object by its name
 Returns : a Bio::Seq object
 Args    : the id (as a string) of a sequence
 Throws  : "id does not exist" exception

=cut
    
sub  get_Seq_by_id {
    my ( $self, $id ) = @_;

    if( !defined $id || length($id) eq 0 ) {
	$self->throw("Must specify a valid id");
    }
    my $seqid;
    eval { 	
	my $SQL = qq(SELECT seqid FROM dna_description 
		  WHERE name = ? );
	my $sth = $self->prepare($SQL);	
	$sth->execute($id);
	my $data = $sth->fetchall_arrayref;
	$seqid = @$data[0]->[0];
	if( $sth->rows > 1 ) {
	    $self->throw("more than one seq exists for id");
	    return undef;
	} elsif( $sth->rows == 0 && !defined $seqid) {
	    $self->throw("id, $id, does not exist");
	    return undef;
	} 	
    };
    return ( defined $seqid && $seqid ne '' ) ? 
	$self->_build_seq_by_seqid($seqid) : undef;
}

=head2 get_Seq_by_acc

 Title   : get_Seq_by_acc
 Usage   : $seq = $db->get_Seq_by_acc('X77802');
 Function: Gets a Bio::Seq object by accession number
 Returns : A Bio::Seq object
 Args    : accession number (as a string)
 Throws  : "acc does not exist" exception


=cut

sub  get_Seq_by_acc {
    my ( $self, $acc ) = @_;
    my $SQL = qq(SELECT seqid from dna_description where accession = ? 
		 ORDER BY version DESC);
    my $id;
    eval { 
	my $sth = $self->prepare($SQL);
	$sth->execute($acc);
	my $data = $sth->fetchall_arrayref;
	$id = @$data[0]->[0];
	if( !defined $id ) {
	    $self->throw("id, $acc does not exist");
	}
    };
    if( $@ ) {
	$self->throw("Could not query for $acc, $@\n");
    }

    return ( defined $id && $id ne '' ) ? $self->_build_seq_by_seqid($id) : undef;
}

=head1 Methods inheirited from Bio::DB::SeqI

=head2 get_PrimarySeq_stream

 Title   : get_PrimarySeq_stream
 Usage   : $stream = get_PrimarySeq_stream
 Function: Makes a Bio::DB::SeqStreamI compliant object
           which provides a single method, next_primary_seq
 Returns : Bio::DB::SeqStreamI
 Args    : none


=cut

sub get_PrimarySeq_stream 
{
}

=head2 get_all_primary_ids

 Title   : get_all_ids
 Usage   : @ids = $seqdb->get_all_primary_ids()
 Function: gives an array of all the primary_ids of the 
           sequence objects in the database. These
           maybe ids (display style) or accession numbers
           or something else completely different - they
           *are not* meaningful outside of this database
           implementation.
 Example :
 Returns : an array of strings
 Args    : none


=cut

sub get_all_primary_ids {
    my $self = shift;

    my @ids;
    my $SQL = qq(SELECT distinct seqid,version 
		 FROM dna_description 
		 ORDER BY accession);
    
    eval { 
	my $sth = $self->prepare($SQL);
	$sth->execute;
	while( my $row = $sth->fetchrow_arrayref ) {
	    push @ids, join($IDSEP, @$row);
	}
    };
    if( $@ ) {
	$self->throw("Could not query for ids, $@");
    }
    return @ids;
}

=head2 get_Seq_by_primary_id

 Title   : get_Seq_by_primary_id
 Usage   : $seq = $db->get_Seq_by_primary_id($primary_id_string);
 Function: Gets a Bio::Seq object by the primary id. The primary
           id in these cases has to come from $db->get_all_primary_ids.
           There is no other way to get (or guess) the primary_ids
           in a database.

           The other possibility is to get Bio::PrimarySeqI objects
           via the get_PrimarySeq_stream and the primary_id field
           on these objects are specified as the ids to use here.
 Returns : A Bio::Seq object
 Args    : accession number (as a string)
 Throws  : "acc does not exist" exception


=cut

sub get_Seq_by_primary_id {
    my ( $self, $id ) = @_;
    my ($seqid,$version) = split($IDSEP, $id);
    return undef if( !defined $seqid || $seqid eq '' );
    return $self->_build_seq_by_seqid($seqid);    
}

=head2 UpdateableDB specific helper functions

# newly defined helper functions
=head2 commit

 Title   : commit
 Usage   : $dbobj->commit;
 Function: commits changes
 Example : 
 Returns : 
 Args    : 

=cut

sub commit { 
    my ( $self ) = @_;
    $self->_db_handle->commit if( $self->_driver eq 'sybase' ||
				  $self->_driver eq 'oracle' );
}

=head2 rollback

 Title   : rollback
 Usage   : $dbobj->rollback;
 Function: rollbacks changes
 Example : 
 Returns : 
 Args    : 

=cut

sub rollback {
    my ( $self) = @_;
    $self->_db_handle->rollback if( $self->_driver eq 'sybase' ||
				    $self->_driver eq 'oracle');
}

=head2 quote

 Title   : quote
 Usage   : $dbobj->quote;
 Function: quote strings escaping chars if necessary 
 Example : 
 Returns : 
 Args    : 

=cut

sub quote {
    my ( $self, $str) = @_;
    return $self->_db_handle->quote($str);
}

=head2 _driver

 Title   : _driver
 Usage   : $obj->_driver($newval)
 Function: 
 Example : 
 Returns : value of _driver
 Args    : newvalue (optional)


=cut

sub _driver {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_driver'} = $value;
    }
    return lc $self->{'_driver'};
    
}

# Object specific functions
# copy and pasted from Bio::EnsEMBL::DBSQL::Obj

=head2 _debug

 Title   : _debug
 Usage   : $obj->_debug($newval)
 Function: 
 Example : 
 Returns : value of _debug
 Args    : newvalue (optional)


=cut

sub _debug{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_debug'} = $value;
    }
    return $self->{'_debug'};
    
}


=head2 _db_handle

 Title   : _db_handle
 Usage   : $obj->_db_handle($newval)
 Function: 
 Example : 
 Returns : value of _db_handle
 Args    : newvalue (optional)


=cut

sub _db_handle{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'_db_handle'} = $value;
    }
    return $self->{'_db_handle'};

}

=head2 prepare

 Title   : prepare
 Usage   : $sth = $dbobj->prepare("select seq_start,seq_end from feature where analysis = \" \" ");
 Function: prepares a SQL statement on the DBI handle

           If the debug level is greater than 10, provides information into the
           DummyStatement object
 Example :
 Returns : A DBI statement handle object
 Args    : a SQL string


=cut

sub prepare {
   my ($self,$string) = @_;

   if( ! $string ) {
       $self->throw("Attempting to prepare an empty SQL query!");
   }
   if( !defined $self->_db_handle ) {
      $self->throw("Database object has lost its database handle! getting otta here!");
   }
      

   if( $self->_debug > 10 ) {
       print STDERR "Prepared statement $string\n";
       my $st = Bio::EnsEMBL::DBSQL::DummyStatement->new();
       $st->_fileh(\*STDERR);
       $st->_statement($string);
       return $st;
   }

   # should we try to verify the string?

   return $self->_db_handle->prepare($string);
}

=head2 _build_seq_by_seqid

 Title   : _build_seq_by_seqid
 Usage   : my $seq = $dbhobj->_build_seq_by_seqid('10021')
 Function: Builds a sequence object based on the seqid
 Example :
 Returns : Bio::Seq
 Args    : a valid seqid in the db


=cut 
sub _build_seq_by_seqid {
    my ($self,$seqid) = @_;
    my $seq = new Bio::Seq;
    my ( $sth, $data );
    eval { 
	my $SQL = qq(SELECT f.version,f.name,f.accession,
		  d.sequence 
		  FROM dna_description f, dna d
		  WHERE f.seqid = d.id AND f.seqid = ? );
	$sth = $self->prepare($SQL);	
	$sth->execute($seqid);
	$data = $sth->fetchall_arrayref;
	if( $sth->rows > 1 ) {
	    $self->throw("primary key violation, more than one seq exists for seqid $seqid");
	    return undef;
	} elsif( $sth->rows == 0 ) {
	    $self->throw("id, $seqid, does not exist");
	    return undef;
	}	

	my $row = shift @$data;
	my ( $version,$name,$accession,$sequence) = @$row;
	$seq->primary_id("$seqid:$version");	
	$seq->accession_number($accession);
	$name = $accession if( !defined $name );
	$seq->display_id($name);
	$seq->seq($sequence);
	undef $row;
	$SQL = qq(SELECT f.featureid, f.name as name, f.strand as strand, 
		  f.source as source, f.seq_start as seq_start, 
		  f.seq_end as seq_end
		  FROM generic_feature f 
		  WHERE f.seqid = ? );		  
	$sth = $self->prepare($SQL);

	$SQL = qq(SELECT d.tag as tag, d.value as value 
		  FROM feature_detail_association a, feature_detail d 
		  WHERE a.featureid = ? AND a.detailid = d.detailid );
	my $feat_sth = $self->prepare($SQL);

	$sth->execute($seqid);
	my $feature;
	while( defined( $feature = $sth->fetchrow_hashref ) ) { 
	    my $sf = new Bio::SeqFeature::Generic;
	    $sf->strand($feature->{strand});
	    $sf->source_tag($feature->{source});
	    $sf->primary_tag($feature->{name});		
	    $sf->start($feature->{seq_start});
	    $sf->end($feature->{seq_end});
	    
	    $feat_sth->execute($feature->{featureid});
	    while( defined ($row = $feat_sth->fetchrow_hashref) ) {		
		my @values = split(/$SEPARATOR/, $row->{value} );
		foreach my $val ( @values ) {
		    if( ! $sf->add_tag_value($row->{tag}, $val) ) {
			print STDERR "adding ", $row->{tag}, " $val failed $@\n";
		    }
		}
	    }
	    $seq->add_SeqFeature($sf);
	}	
    };
    if( $@ ) {
	$self->throw("$@\n");
	return undef;
    }
    return $seq;           
}
1;
