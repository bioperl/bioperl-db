CREATE TABLE marker (
	markerid	integer(11) not null AUTO_INCREMENT,
	locus		varchar(64) not null,
	probe		varchar(64) not null,
	type		char(5)     not null,
	chrom		char(2)	    not null,
	fwdprimer	varchar(128) null,
	revprimer	varchar(128) null,	
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
       units  char(5)	 not null,
       PRIMARY KEY (mapid),
       UNIQUE KEY (name )       
);

CREATE TABLE map_position (
	markerid	integer(11) not null REFERENCES marker ( markerid ),
	position	float(8,4)  not null,
	mapid		integer(10) not null REFERENCES map ( mapid ),
	PRIMARY KEY (markerid,mapid),
	KEY (position)
);

create table marker_alias (
       markerid		  integer(11) not null REFERENCES marker (markerid),
       alias		  varchar(32) not null,
       source		  varchar(32) null,
       UNIQUE KEY i_id_alias (markerid,alias),    
       KEY i_source (source)
);

INSERT INTO map (name, units) VALUES ( 'none', '');
INSERT INTO map (name, units) VALUES ( 'genethon', 'cM');
INSERT INTO map (name, units) VALUES ( 'genethon_male', 'cM');
INSERT INTO map (name, units) VALUES ( 'genethon_female', 'cM');
INSERT INTO map (name, units) VALUES ( 'marshfield', 'cM');
INSERT INTO map (name, units) VALUES ( 'marshfield_male', 'cM');
INSERT INTO map (name, units) VALUES ( 'marshfield_female', 'cM');
INSERT INTO map (name, units) VALUES ( 'gp07oct2000', 'Mb');
INSERT INTO map (name, units) VALUES ( 'gp05sep2000', 'Mb');
INSERT INTO map (name, units) VALUES ( 'gp12dec2000', 'Mb');
INSERT INTO map (name, units) VALUES ( 'whitehead', 'cR');
INSERT INTO map (name, units) VALUES ( 'genemap99gb4', 'cR');
INSERT INTO map (name, units) VALUES ( 'genemap99g3', 'cR');
