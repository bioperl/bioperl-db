/* this should be seqdb eventually */

use sage;

/* Sybase EnsemblLite Scheme */

/* this is the basic schema for storing sequences, related info, 
and their features
*/

/*
 * Table structure for table 'dna'
 */
print 'creating table dna';
CREATE TABLE dna (
  id        numeric(10,0)  IDENTITY NOT NULL,
  sequence  text NOT NULL,
  created   datetime DEFAULT getdate() NOT NULL ,
  version     numeric(7,0) DEFAULT 0 NOT NULL, 
  ensembl_version numeric(7,0) DEFAULT 0 NOT NULL,
  accession varchar(40) NULL,
  CONSTRAINT pk_id PRIMARY KEY (id),
  CONSTRAINT i_id_ver UNIQUE (id, version, ens_version),
  CONSTRAINT i_accesion UNIQUE (id,accession)
);

/* 
 *   table structure for table 'dna_description' 
*/
print 'creating table dna_description'
CREATE TABLE dna_description (
       seqid numeric(10,0) NOT NULL,
       clone varchar(40) NOT NULL,
       tech char(12) NOT NULL,
       machine smallint NOT NULL,       
       daterun datetime default getdate() NOT NULL,
       CONSTRAINT fk_seqid FOREIGN KEY (seqid) REFERENCES dna (id )       
);

/*
* Table structure for table 'feature'
*/
print 'creating table feature';
CREATE TABLE feature (
  id            numeric(10,0)  IDENTITY NOT NULL ,
  seq           numeric(10,0)  NOT NULL,
  seq_start     numeric(10,0) NOT NULL,
  seq_end       numeric(10,0) NOT NULL,
  score         numeric(16,4) NOT NULL,
  strand        tinyint DEFAULT 1 NOT NULL,
  analysis      numeric(10,0)  NOT NULL,
  name          varchar(40) NULL,
  hstart        numeric(11,0) NOT NULL,
  hend          numeric(11,0) NOT NULL,
  hid           varchar(40) NOT NULL,
  evalue        numeric(16,4) NULL,
  perc_id       numeric(10,0) NULL,
  
  CONSTRAINT i_id PRIMARY KEY (id),
  CONSTRAINT fk_seq FOREIGN KEY (seq) REFERENCES dna ( id )
);
create index i_overlap on feature (id, seq,,seq_start,seq_end,analysis);
create index i_hid on feature (hid);

create table listval ( 
       listname char(16) not null,
       val      smallint not null,
       scode    char(8)  not null,
       lcode    varchar(32) not null,
       sortval  smallint not null,
       dsc      varchar(80) not null,
       constraint i_name_val UNIQUE (listname,val),
       constraint i_name_scode UNIQUE (listname,scode)
);

insert into listval values ( 'LAB_MACHINES', 1, 'LYCOR', 'Lycor Sequencer',
       1, 'Lycor Sequencer Machine');
insert into listval values ( 'LAB_MACHINES', 2, 'CEQ2000', 'Beckman CEQ2000',
       2, 'Beckman CEQ2000');
insert into listval values ( 'LAB_MACHINES', 3, 'WAVE', 'Beckman WAVE dHPLC',
       3, 'Beckman WAVE dHPLC');
