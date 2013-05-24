CREATE OR REPLACE VIEW s_artist AS
    SELECT
        a.id, a.gid as 'mbid', n.name, sn.name AS sort_name,
        a.begin_date_year, a.begin_date_month, a.begin_date_day,
        a.end_date_year, a.end_date_month, a.end_date_day,
        at.name as `type`, aa.name as 'country', gender, comment,
        a.edits_pending, a.last_updated, a.ended
    FROM artist a
    JOIN artist_name n ON a.name=n.id
    JOIN artist_name sn ON a.sort_name=sn.id
    JOIN area aa ON a.area = aa.id
    JOIN artist_type at ON at.id = a.type;

CREATE OR REPLACE VIEW s_artist_credit AS
    SELECT
        a.id, n.name, artist_count, ref_count, created
    FROM artist_credit a
    JOIN artist_name n ON a.name=n.id;

CREATE OR REPLACE VIEW s_artist_credit_name AS
    SELECT
        a.artist_credit, a.position, a.artist, n.name,
        a.join_phrase
    FROM artist_credit_name a
    JOIN artist_name n ON a.name = n.id;

CREATE OR REPLACE VIEW s_label AS
    SELECT
        a.id, a.gid, n.name, sn.name AS sort_name,
        a.begin_date_year, a.begin_date_month, a.begin_date_day,
        a.end_date_year, a.end_date_month, a.end_date_day,
        a.label_code, lt.name as 'type', aa.name as 'country', a.comment,
        a.edits_pending, a.last_updated, a.ended
    FROM label a
    JOIN label_name n ON a.name = n.id
    JOIN label_name sn ON a.sort_name = sn.id
    JOIN area aa ON a.area = aa.id
    JOIN label_type lt ON lt.id = a.type;

CREATE OR REPLACE VIEW s_recording AS
    SELECT
        r.id, gid, n.name, artist_credit,
        length, comment, edits_pending, last_updated
    FROM recording r
    JOIN track_name n ON r.name=n.id;

CREATE OR REPLACE VIEW s_release AS
    SELECT
        r.id, r.gid, n.name, artist_credit, release_group, status, packaging,
        language, script, a.name as 'country', date_year, date_month, date_day,
        barcode, comment, r.edits_pending, quality, r.last_updated
    FROM `release` r
    JOIN release_name n ON r.name=n.id
    JOIN release_country c ON r.id = c.`release`
    JOIN area a ON a.id = c.country;

CREATE OR REPLACE VIEW s_release_group AS
    SELECT
        rg.id, gid, n.name, artist_credit,
        type, comment, edits_pending, last_updated
    FROM release_group rg
    JOIN release_name n ON rg.name=n.id;

CREATE OR REPLACE VIEW s_track AS
    SELECT
        t.id, recording, medium, position, n.name, artist_credit,
        length, edits_pending, last_updated, t.number
    FROM track t
    JOIN track_name n ON t.name=n.id;

-- CUSTOM VIEWS
CREATE OR REPLACE VIEW s_official_url AS
SELECT  a.id,
        a.gid as 'mbid',
        an.name as 'artist_name',
        u.url as 'url'
FROM artist a
    JOIN artist_name an ON a.name = an.id
    JOIN l_artist_url au ON a.id = au.entity0
    JOIN url u ON u.id = au.entity1
    JOIN link l ON au.link = l.id
WHERE link_type in (287, 183, 219);

CREATE OR REPLACE VIEW v_official_url AS
SELECT  a.id,
        a.gid as 'mbid',
        an.name as 'artist_name',
        u.url as 'url'
FROM artist a
    JOIN artist_name an ON a.name = an.id
    JOIN l_artist_url au ON a.id = au.entity0
    JOIN url u ON u.id = au.entity1
    JOIN link l ON au.link = l.id
WHERE link_type in (287, 183, 219);

CREATE OR REPLACE VIEW s_all_links AS
SELECT  a.id as 'artist_id',
        a.gid as 'mbid',
        an.name as 'artist_name',
        u.url as 'url',
        lt.id as 'link_id',
        lt.name as 'link_name',
        lt.link_phrase
FROM artist a
    JOIN artist_name an ON a.name = an.id
    JOIN l_artist_url au ON a.id = au.entity0
    JOIN url u ON u.id = au.entity1
    JOIN link l ON au.link = l.id
    JOIN link_type lt ON lt.id = l.link_type;

CREATE OR REPLACE VIEW s_album_releases AS
SELECT  a.id,
        a.gid as 'mbid',
        acn.artist AS acn_artist,
        ac.id as ac_id,
        an.name as artist_name,
        r.id as release_id,
        aa.name as country,
        rc.date_year as 'year',
        r.release_group as release_group,
        r.name as release_name_id,
        r.status as release_status,
        rn.name as release_name
FROM artist a
    JOIN artist_name an ON a.name = an.id
    JOIN artist_credit_name acn ON acn.artist = a.id
    JOIN artist_credit ac ON ac.id = acn.artist_credit
    JOIN `release` r ON r.artist_credit = ac.id
    JOIN release_name rn ON rn.id = r.name
    JOIN release_country rc ON rc.release = r.id
    JOIN area aa ON aa.id = rc.country = aa.id
WHERE ac.id is not null
    AND r.id is not null
    AND rc.date_year is not NULL;

CREATE OR REPLACE VIEW v_album_releases AS
SELECT  a.id,
        a.gid as 'mbid',
        acn.artist AS acn_artist,
        ac.id as ac_id,
        an.name as artist_name,
        r.id as release_id,
        aa.name as country,
        rc.date_year as 'release_year',
        r.release_group as release_group,
        r.name as release_name_id,
        r.status as release_status,
        rn.name as release_name
FROM artist a
    JOIN artist_name an ON a.name = an.id
    JOIN artist_credit_name acn ON acn.artist = a.id
    JOIN artist_credit ac ON ac.id = acn.artist_credit
    JOIN `release` r ON r.artist_credit = ac.id
    JOIN release_name rn ON rn.id = r.name
    JOIN release_country rc ON rc.release = r.id
    JOIN area aa ON aa.id = rc.country = aa.id
WHERE ac.id is not null
    AND r.id is not null
    AND rc.date_year is not NULL;


CREATE OR REPLACE VIEW s_release_group_cover_art AS
select
rg.gid as 'release_group_mbid',
r.gid as 'release_mbid',
r.name as 'release_name',
rg.name as 'release_group_name',
ca.id as cover_art_id,
ca.mime_type, at.name as 'type'
from s_release r
    join cover_art ca ON ca.release = r.id
    join cover_art_type cat ON cat.id = ca.id
    join art_type at ON at.id = cat.type_id
    join s_release_group rg ON r.release_group = rg.id;

CREATE OR REPLACE VIEW s_release_groups_by_artist AS
select
    a.id as 'artist_id',
    a.gid as 'artist_mbid',
    acn.name as 'artist_name',
    rg.id as 'release_group_id',
    rg.gid as 'release_group_mbid',
    rn.name as 'release_group_name',
    pt.name as 'type',
st.name as 'secondary_type'
FROM artist a
    JOIN artist_credit_name acn ON acn.artist = a.id
    JOIN artist_credit ac ON acn.artist_credit = ac.id
    JOIN release_group rg ON rg.artist_credit = ac.id
    JOIN release_name rn ON rn.id = rg.name
    LEFT JOIN release_group_primary_type pt ON pt.id = rg.type
    LEFT JOIN release_group_secondary_type_join tj ON tj.release_group = rg.id
    LEFT JOIN release_group_secondary_type st ON st.id = tj.secondary_type;

CREATE OR REPLACE VIEW s_cover_art_by_artist AS
select
    a.id as 'artist_id',
    a.gid as 'artist_mbid',
    acn.name as 'artist_name',
    rg.id as 'release_group_id',
    rg.gid as 'release_group_mbid',
    rn.name as 'release_group_name',
    r.id as 'release_id',
    rn2.name as 'release_name',
    r.comment as 'release_comment',
    pt.name as 'primary_type',
    st.name as 'secondary_type',
    ca.id as cover_art_id,
    ca.mime_type, at.name as 'art_type',
    concat('http://coverartarchive.org/release/', r.gid, '/', cast(ca.id as char), '.jpg') as 'fullpx',
    concat('http://coverartarchive.org/release/', r.gid, '/', cast(ca.id as char), '-250.jpg') as '250px',
    concat('http://coverartarchive.org/release/', r.gid, '/', cast(ca.id as char), '-500.jpg') as '500px'
FROM artist a
    JOIN artist_credit_name acn ON acn.artist = a.id
    JOIN artist_credit ac ON acn.artist_credit = ac.id
    JOIN release_group rg ON rg.artist_credit = ac.id
    JOIN release_name rn ON rn.id = rg.name
    JOIN `release` r ON r.release_group = rg.id
    JOIN release_name rn2 ON rn2.id = r.name
    JOIN cover_art ca ON ca.release = r.id
    JOIN cover_art_type cat ON cat.id = ca.id
    JOIN art_type at ON at.id = cat.type_id
    LEFT JOIN release_group_primary_type pt ON pt.id = rg.type
    LEFT JOIN release_group_secondary_type_join tj ON tj.release_group = rg.id
    LEFT JOIN release_group_secondary_type st ON st.id = tj.secondary_type;


-- vi: set ts=4 sw=4 et :
