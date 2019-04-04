SELECT date as `日期`
	, ct as `课程类型`
	, class_id as `班级约课ID`
	, start_time as `课程开始时间`
	, into_time as `老师进入时间`
	, booked_cnt as `预定人数`
	, attended_cnt as `出席人数`
FROM (
	select DATE(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00')) as date
		, '1v1' as ct
		, ac.id as class_id
		, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') as start_time
		, CONVERT_TZ(FROM_UNIXTIME(cd.teacher_into_time), '+00:00', '+08:00') as into_time
		, 1 as booked_cnt
		, IF (cd.student_into_time > 0, 1, 0) as attended_cnt
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		LEFT JOIN newuuabc.course_details AS cd
			ON cd.appoint_course_id = ac.id AND cd.`type` = 1
	WHERE ac.disabled = 0
		AND ac.class_appoint_course_id = 0
		AND ac.course_type = 3
		AND ac.start_time >= UNIX_TIMESTAMP(CONVERT_TZ('2019-01-01', '+08:00','+00:00'))
		AND ac.start_time < UNIX_TIMESTAMP(CONVERT_TZ('2019-01-12', '+08:00','+00:00'))
		AND su.flag = 1
		and ac.status = 3
	UNION ALL
	select DATE(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00')) as date
		, '老小班课' as ct
		, ac.id as class_id
		, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') as start_time
		, CONVERT_TZ(FROM_UNIXTIME(cac.teacher_into_time), '+00:00', '+08:00') as into_time
		, COUNT(DISTINCT su.id) AS booked_cnt
		, COUNT(DISTINCT cd.student_id) AS attended_cnt
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.class_appoint_course as cac
			ON ac.class_appoint_course_id = cac.id
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		LEFT JOIN newuuabc.course_details AS cd
			ON cd.appoint_course_id = ac.id AND cd.`type` = 1
	WHERE ac.disabled = 0
		AND ac.class_appoint_course_id > 0
		AND ac.course_type = 3
		AND ac.start_time >= UNIX_TIMESTAMP(CONVERT_TZ('2019-01-01', '+08:00','+00:00'))
		AND ac.start_time < UNIX_TIMESTAMP(CONVERT_TZ('2019-01-12', '+08:00','+00:00'))
		AND su.flag = 1
		and ac.status = 3
	GROUP by ac.class_appoint_course_id
	UNION ALL
	SELECT DATE(FROM_UNIXTIME(sc.start_time)) as date
		, '新小班课' as ct
		, sc.room_id as class_id
		, FROM_UNIXTIME(sc.start_time) as start_time
		, FROM_UNIXTIME(r.teacher_entry_time) as into_time
		, COUNT(DISTINCT su.id) AS booked_cnt
		, COUNT(DISTINCT cd.student_id) AS attended_cnt
	from classbooking.student_class as sc
		INNER JOIN newuuabc.student_user as su
			ON sc.student_id = su.id
		inner join classbooking.classroom as r
			on sc.room_id = r.room_id
		LEFT JOIN newuuabc.course_details as cd
			ON cd.appoint_course_id = sc.student_class_id and cd.`type` = 2
	where sc.status = 3
		AND su.flag = 1
		AND sc.start_time >= UNIX_TIMESTAMP('2019-01-01')
		AND sc.start_time < UNIX_TIMESTAMP('2019-01-12')
	group by sc.room_id
	UNION ALL
	SELECT
		DATE(CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00')) as date
		, '试听' as ct
		, ac.class_appoint_course_id as class_id
		, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') as start_time
		, CONVERT_TZ(FROM_UNIXTIME(cac.teacher_into_time), '+00:00', '+08:00') as into_time
		, COUNT(DISTINCT su.id) AS booked_cnt
		, COUNT(DISTINCT cd.student_id) AS attended_cnt
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.class_appoint_course as cac
			ON ac.class_appoint_course_id = cac.id
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		LEFT JOIN newuuabc.course_details AS cd
			ON cd.appoint_course_id = ac.id AND cd.`type` = 1
	WHERE ac.disabled = 0
		AND ac.class_appoint_course_id > 0
		AND ac.course_type = 1
		AND ac.start_time >= UNIX_TIMESTAMP(CONVERT_TZ('2019-01-01', '+08:00','+00:00'))
		AND ac.start_time < UNIX_TIMESTAMP(CONVERT_TZ('2019-01-12', '+08:00','+00:00'))
		AND su.flag = 1
		and ac.status = 3
	group by ac.class_appoint_course_id
) as a
order by ct, start_time
	
	
	
	
	