@set begin_date = '2018-09-17'
@set end_date = '2018-09-24'


DROP TABLE IF EXISTS tmp_teacher;

CREATE TEMPORARY TABLE tmp_teacher (
	SELECT id, english_name, is_old FROM newuuabc.teacher_user_new
	WHERE status = 3 AND `type` = 1 AND disable = 1
);

-- ---------------------------------------------------------

DROP TABLE IF EXISTS tmp_1v1_class;

CREATE TEMPORARY TABLE tmp_1v1_class (
	SELECT ac.teacher_user_id AS teacher_id
		, COUNT(*) AS 1v1_cnt
	FROM newuuabc.appoint_course AS ac
		INNER JOIN tmp_teacher AS t
			ON ac.teacher_user_id = t.id
	WHERE ac.class_appoint_course_id = 0
		AND ac.disabled = 0
		AND ac.start_time >= UNIX_TIMESTAMP(CONVERT_TZ(:begin_date, '+08:00','+00:00'))
		AND ac.start_time < UNIX_TIMESTAMP(CONVERT_TZ(:end_date, '+08:00','+00:00'))
		AND ac.course_type IN (1, 3)
	GROUP BY ac.teacher_user_id
);


DROP TABLE IF EXISTS tmp_o1v4_class;

CREATE TEMPORARY TABLE tmp_o1v4_class (
	SELECT ac.teacher_user_id AS teacher_id
		, COUNT(*) AS o1v4_cnt
	FROM newuuabc.class_appoint_course AS ac
		INNER JOIN tmp_teacher AS t
				ON ac.teacher_user_id = t.id
	WHERE ac.disabled = 0
		AND ac.course_type IN (1, 3)
		AND start_time >= UNIX_TIMESTAMP(CONVERT_TZ(:begin_date, '+08:00','+00:00'))
		AND start_time < UNIX_TIMESTAMP(CONVERT_TZ(:end_date, '+08:00','+00:00'))
	GROUP BY ac.teacher_user_id
);


DROP TABLE IF EXISTS tmp_1v4_class;

CREATE TEMPORARY TABLE tmp_1v4_class (
	SELECT teacher_id, COUNT(*) AS 1v4_cnt
	FROM classbooking.classroom AS c
		INNER JOIN tmp_teacher AS t
			ON c.teacher_id = t.id
	WHERE start_time >= UNIX_TIMESTAMP(:begin_date)
		AND start_time < UNIX_TIMESTAMP(:end_date)
	GROUP BY teacher_id
);


-- -----------------------------------------------------------



DROP TABLE IF EXISTS tmp_teacher_day;

CREATE TEMPORARY TABLE tmp_teacher_day (
	SELECT tt.id, dr.d
	FROM tmp_teacher AS tt
		CROSS JOIN (
			SELECT date1 AS d FROM bi.dim_date
			WHERE date1 >= :begin_date
				AND date1 < :end_date
		) AS dr
	ORDER BY tt.id, dr.d
);


-- DROP TABLE IF EXISTS tmp_teacher_slot_all_2;
-- 
-- CREATE TABLE tmp_teacher_slot_all_2 (
--   teacher_id INT NOT NULL,
--   class_date DATE NOT NULL, 
--   start_time DATETIME NOT NULL,
--   end_time DATETIME NOT NULL,
--   duration INT,
--   is_leave BOOLEAN,
--   is_ast BOOLEAN,
--   is_allocated BOOLEAN
-- ) ENGINE=MEMORY;


TRUNCATE TABLE tmp_teacher_slot_all_2;

INSERT INTO tmp_teacher_slot_all_2
SELECT ttd.id AS teacher_id
	, d AS class_date
	, FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.start_time * 60) AS start_time
	, FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.end_time * 60) AS end_time
	, (cs.end_time - cs.start_time) AS duration
	, NULL AS is_leave
	, NULL AS is_ast
	, NULL AS is_allocated
FROM tmp_teacher_day AS ttd
		INNER JOIN newuuabc.signed_time AS st
			ON ttd.id = st.teacher_user_id
				AND UNIX_TIMESTAMP(ttd.d) >= st.effective_start_time
				AND UNIX_TIMESTAMP(ttd.d) <= st.effective_end_time
				AND bi.GET_WEEKDAY(ttd.d) = st.weekday
		INNER JOIN newuuabc.teacher_signed AS ts
			ON st.signed_id = ts.id
		INNER JOIN newuuabc.carport_slot AS cs
			ON st.start_time <= cs.start_time
				AND st.end_time >= cs.end_time
	WHERE ts.enable = 1 AND ts.status = 1;
	
	
-- SELECT COUNT(*) FROM; 
UPDATE tmp_teacher_slot_all_2 AS tsa
	INNER JOIN newuuabc.teacher_leave AS tl
		ON tsa.teacher_id = tl.teacher_user_id
			AND UNIX_TIMESTAMP(CONVERT_TZ(tsa.start_time, '+08:00','+00:00')) >= tl.start_time
			AND UNIX_TIMESTAMP(CONVERT_TZ(tsa.end_time, '+08:00','+00:00')) <= tl.end_time
SET is_leave = 1
WHERE tl.status <> 3;


UPDATE tmp_teacher_slot_all_2 AS tsa
	INNER JOIN newuuabc.teacher_absenteeism AS tl
		ON tsa.teacher_id = tl.teacher_id
			AND UNIX_TIMESTAMP(tsa.start_time) >= tl.start_time
			AND UNIX_TIMESTAMP(tsa.end_time) <= tl.end_time
SET is_ast = 1
WHERE tl.status <> 3;

-- ---------------------------------------------------------------------------------------



SELECT COUNT(IF(is_old = 1, 1, NULL)) AS `老系统老师数`
	, SUM(IF(is_old = 1, finished_class_cnt, 0)) AS `老系统老师被约课时数`
	, SUM(IF(is_old = 1, all_class_cnt, 0)) AS `老系统老师总课时数`
	, SUM(IF(is_old = 1, finished_class_cnt, 0)) / SUM(IF(is_old = 1, all_class_cnt, 0)) AS `老系统老师平均约课率`
	, COUNT(IF(is_old = 2, 1, NULL)) AS `新系统老师数`
	, SUM(IF(is_old = 2, finished_class_cnt, 0)) AS `新系统老师被约课时数`
	, SUM(IF(is_old = 2, all_class_cnt, 0)) AS `新系统老师总课时数`
	, SUM(IF(is_old = 2, finished_class_cnt, 0)) / SUM(IF(is_old = 2, all_class_cnt, 0)) AS `新系统老师平均约课率`
	, SUM(finished_class_cnt) / SUM(all_class_cnt) AS `所有老师平均约课率`
FROM (
	SELECT tun.id
		, tun.english_name
		, tun.is_old
		, IFNULL(ta.all_class_cnt, 0) AS all_class_cnt
		, IFNULL(t1c.1v1_cnt, 0) + IFNULL(to4c.o1v4_cnt, 0) + IFNULL(t4c.1v4_cnt, 0) AS finished_class_cnt
	FROM tmp_teacher AS tun
		LEFT JOIN (
			SELECT tsa.teacher_id, COUNT(*) AS all_class_cnt
			FROM tmp_teacher_slot_all_2 AS tsa
			WHERE tsa.is_leave IS NULL AND tsa.is_ast IS NULL
			GROUP BY tsa.teacher_id
		) AS ta
			ON tun.id = ta.teacher_id
		LEFT JOIN tmp_1v1_class AS t1c
			ON tun.id = t1c.teacher_id
		LEFT JOIN tmp_o1v4_class AS to4c
			ON tun.id = to4c.teacher_id
		LEFT JOIN tmp_1v4_class AS t4c
			ON tun.id = t4c.teacher_id
) AS a

