CREATE TABLE marker (
	markerid	integer(11) not null AUTO_INCREMENT,
	locus		varchar(64) not null,
	probe		varchar(64) not null,
	type		char(5)     not null,
	chrom		char(2)	    not null,
	fwdprimer	varchar(128) not null,
	revprimer	varchar(128) not null,	
	length		smallint null,
	PRIMARY KEY (markerid),
	UNIQUE KEY (probe),	
	UNIQUE KEY (fwdprimer, revprimer),
	KEY (locus),
	KEY (type)
);

CREATE TABLE map (
       mapid integer(10) not null AUTO_INCREMENT,
       name   varchar(32) not null,
       unit  char(5)	 not null,
       PRIMARY KEY (mapid)
);

CREATE TABLE map_position (
	markerid	integer(11) not null,
	position	float(8,4)  not null,
	mapid		integer(10) not null,
	PRIMARY KEY (markerid,mapid),
	KEY (position)
);

create table marker_alias (
       markerid		  integer(11) not null,
       alias		  varchar(64) not null,
       mapid		  integer(10) null,
       UNIQUE KEY(markerid,alias)       
);

INSERT INTO map (name, unit) VALUES ( 'none', '');
INSERT INTO map (name, unit) VALUES ( 'genethon', 'cM');
INSERT INTO map (name, unit) VALUES ( 'genethon_male', 'cM');
INSERT INTO map (name, unit) VALUES ( 'genethon_female', 'cM');
INSERT INTO map (name, unit) VALUES ( 'marshfield', 'cM');
INSERT INTO map (name, unit) VALUES ( 'marshfield_male', 'cM');
INSERT INTO map (name, unit) VALUES ( 'marshfield_female', 'cM');
INSERT INTO map (name, unit) VALUES ( 'gp07oct2000', 'Mb');
INSERT INTO map (name, unit) VALUES ( 'gp05sep2000', 'Mb');
INSERT INTO map (name, unit) VALUES ( 'gp12dec2000', 'Mb');
INSERT INTO map (name, unit) VALUES ( 'whitehead', 'cR');
INSERT INTO map (name, unit) VALUES ( 'genemap99gb4', 'cR');
INSERT INTO map (name, unit) VALUES ( 'genemap99g3', 'cR');
