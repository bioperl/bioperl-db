#
# Table structure for table 'dna'
#

CREATE TABLE dna (
  id  int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  sequence  mediumtext NOT NULL,
  created   datetime DEFAULT '0000-00-00 00:00:00' NOT NULL
);


# basic dna description storage

CREATE TABLE dna_description (
       seqid int(10) unsigned NOT NULL PRIMARY KEY,
       version	int(7) default '0' NOT NULL,
       name  varchar(40) NOT NULL,
       accession char(12) NOT NULL,       
       tech char(12) NULL,
       machine smallint default '0' NOT NULL,       
       daterun datetime default '0000-00-00 00:00:00' NOT NULL,       
       UNIQUE KEY i_accession ( accession ),
       KEY i_name ( name ),
       KEY i_date ( daterun)       
);
#
# Table structure for table 'feature'
#

CREATE TABLE generic_feature (
  featureid    int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  seqid        int(10) unsigned NOT NULL,
  name		varchar(40) NOT NULL,
  strand	tinyint default '1' NOT NULL,
  source	varchar(40) NOT NULL,
  seq_start     int(10) NOT NULL,
  seq_end       int(10) NOT NULL,  
  KEY overlap (featureid,seqid,seq_start,seq_end),
  KEY dna (seqid)
);

#
# Table structure for table 'fset'
#

CREATE TABLE feature_detail (
  detailid   int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  tag	    varchar(20) NOT NULL,
  value     text	NOT NULL,
  KEY i_tag ( tag )  
);


#
# Table structure for table 'fset_feature'
#

CREATE TABLE feature_detail_association (
  featureid   int(10) unsigned NOT NULL,
  detailid      int(10) unsigned NOT NULL,
  rank	       int(11) NOT NULL,
  
  PRIMARY KEY (featureid,detailid,rank),
  KEY fset (detailid)
);

create table local_accession_num (
       used_num int(10) unsigned NOT NULL auto_increment PRIMARY KEY
);

create table listval ( 
       listname char(16) not null,
       val      smallint unsigned not null,
       scode    char(8)  not null,
       lcode    varchar(32) not null,
       sortval  smallint unsigned not null,
       dsc      varchar(80) not null,
       UNIQUE KEY i_name_val (listname,val),
       UNIQUE KEY  i_name_scode (listname,scode)
);

insert into listval values ( 'LAB_MACHINES', 0, 'GENSEQ', 'Generic Sequencer',
       0, 'Generic Sequencing machine');
insert into listval values ( 'LAB_MACHINES', 1, 'LYCOR', 'Lycor Sequencer',
       1, 'Lycor Sequencer Machine');
insert into listval values ( 'LAB_MACHINES', 2, 'CEQ2000', 'Beckman CEQ2000',
       2, 'Beckman CEQ2000');
insert into listval values ( 'LAB_MACHINES', 3, 'WAVE', 'Beckman WAVE dHPLC',
       3, 'Beckman WAVE dHPLC');
