DROP TABLE rb_vol;
DROP TABLE rb_source;
DROP TABLE rb_backup;

CREATE TABLE rb_vol
(
    VOL_ID INTEGER NOT NULL,
    FS_LABEL VARCHAR,	/* backup filesystem label */
    FS_UUID VARCHAR NOT NULL,
    BACKUP_DT TIMESTAMP, /* time last backup completed */
    PRIMARY KEY (VOL_ID)
);

CREATE UNIQUE INDEX FS_UUID ON rb_vol (FS_UUID);
CREATE INDEX FS_LABEL ON rb_vol (FS_LABEL);

CREATE TABLE rb_source	/* backup source */
(
    FS_ID INTEGER NOT NULL,
    LV_NAME VARCHAR,
    VG_NAME VARCHAR,
    FS_UUID VARCHAR,	 /* filesystem backed up */
    PRIMARY KEY (FS_ID)
);

CREATE TABLE rb_backup
(
    VOL_ID INTEGER NOT NULL,
    FS_ID INTEGER NOT NULL,
    BACKUP_DT TIMESTAMP, /* time backup completed */
    RB_NAME VARCHAR,	 /* backup name, usually looks like a date: YYMmmDD */
    PRIMARY KEY (VOL_ID,FS_ID,RB_NAME)
);
