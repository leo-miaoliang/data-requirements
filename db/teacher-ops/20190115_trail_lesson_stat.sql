	SELECT t.d as `日期`
		, TIME(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00','+08:00')) as `时间段`
		, COUNT(DISTINCT ac.class_appoint_course_id) as `课时数`
		, COUNT(DISTINCT su.id) AS `试听人数`
		, COUNT(DISTINCT cd.student_id) AS `出席人数`
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		INNER JOIN (
			SELECT DATE_SUB(CURRENT_DATE, INTERVAL 1 DAY) as d
			UNION
			SELECT DATE_SUB(CURRENT_DATE, INTERVAL 2 DAY)
			UNION
			SELECT DATE_SUB(CURRENT_DATE, INTERVAL 3 DAY)
			UNION
			SELECT DATE_SUB(CURRENT_DATE, INTERVAL 4 DAY)
			UNION
			SELECT DATE_SUB(CURRENT_DATE, INTERVAL 5 DAY)
			UNION
			SELECT DATE_SUB(CURRENT_DATE, INTERVAL 6 DAY)
			UNION
			SELECT DATE_SUB(CURRENT_DATE, INTERVAL 7 DAY)
		) as t
			ON t.d = DATE(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00'))
		LEFT JOIN newuuabc.course_details AS cd
			ON cd.appoint_course_id = ac.id AND cd.student_id = su.id
	WHERE ac.disabled = 0
		AND ac.course_type = 1
		AND su.flag = 1
		AND ac.status = 3
		AND ac.class_appoint_course_id > 0
	GROUP BY t.d, TIME(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00','+08:00'))
UNION
	SELECT t.d as `日期`
		, TIME(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00','+08:00')) as `时间段`
		, COUNT(DISTINCT ac.class_appoint_course_id) as `课时数`
		, COUNT(DISTINCT su.id) AS `试听人数`
		, '-' as `出席人数`
	FROM (
		SELECT CURRENT_DATE as d
		UNION
		SELECT DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY)
		UNION
		SELECT DATE_ADD(CURRENT_DATE, INTERVAL 2 DAY)
		UNION
		SELECT DATE_ADD(CURRENT_DATE, INTERVAL 3 DAY)
		UNION
		SELECT DATE_ADD(CURRENT_DATE, INTERVAL 4 DAY)
		UNION
		SELECT DATE_ADD(CURRENT_DATE, INTERVAL 5 DAY)
		UNION
		SELECT DATE_ADD(CURRENT_DATE, INTERVAL 6 DAY)
		UNION
		SELECT DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY)
	) AS t
		LEFT JOIN newuuabc.appoint_course AS ac
			ON t.d = DATE(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00'))
				AND ac.disabled = 0
				AND ac.course_type = 1 
		LEFT JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id AND su.flag = 1
	GROUP BY t.d, TIME(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00','+08:00'))
ORDER BY `日期`, `时间段` 

		