


@set begin_time = '2018-10-29'
@set end_time = '2018-11-05'

-- teacher

DROP TABLE IF EXISTS tmp_teacher;

CREATE TEMPORARY TABLE tmp_teacher (
	SELECT id, english_name
	FROM newuuabc.teacher_user_new AS tun
	WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1
);


-- class schedule

DROP TABLE IF EXISTS tmp_teacher_day;

CREATE TEMPORARY TABLE tmp_teacher_day (
	SELECT tt.id, dr.date1 as d
	FROM tmp_teacher AS tt
		CROSS JOIN (
			SELECT date1 FROM bi.dim_date
			WHERE date1 >= :begin_time
				AND date1 < :end_time
		) AS dr
	ORDER BY tt.id, dr.date1
);


SELECT teacher_id AS `外教ID`
	, english_name AS `姓名` 
	, GROUP_CONCAT(DISTINCT effective_time, ' / ') AS `签约时间`
	, COUNT(*) AS `总课时数`
	, COUNT(IF(is_leave = 1, 1, NULL)) AS `请假课时数`
FROM (
	SELECT ttd.id AS teacher_id
	, tun.english_name
	, d AS class_date
	, CONCAT(FROM_UNIXTIME(ts.effective_start_time), ' - ', FROM_UNIXTIME(ts.effective_end_time)) AS effective_time
	, FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.start_time * 60) AS start_time
	, FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.end_time * 60) AS end_time
	, (cs.end_time - cs.start_time) AS duration
	, IF (tl.id IS NOT NULL, 1, 0) AS is_leave
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
		INNER JOIN newuuabc.teacher_user_new AS tun
			ON ttd.id = tun.id
		LEFT JOIN newuuabc.teacher_leave AS tl
			ON ttd.id = tl.teacher_user_id
				AND UNIX_TIMESTAMP(CONVERT_TZ(FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.start_time * 60), '+08:00','+00:00')) >= tl.start_time
				AND UNIX_TIMESTAMP(CONVERT_TZ(FROM_UNIXTIME(UNIX_TIMESTAMP(d) + cs.end_time * 60), '+08:00','+00:00')) <= tl.end_time
				AND tl.status <> 3
	WHERE ts.enable = 1 AND ts.status = 1
) AS a
GROUP BY teacher_id;





