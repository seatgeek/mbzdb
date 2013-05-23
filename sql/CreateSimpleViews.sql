CREATE OR REPLACE VIEW s_artist AS
    SELECT
        a.id, a.gid, n.name, sn.name AS sort_name,
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

-- vi: set ts=4 sw=4 et :
