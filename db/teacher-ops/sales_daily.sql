begin 

set @target_date := current_date;

-- 今日试听

-- DROP TABLE IF EXISTS tmp_try_today;

CREATE TEMPORARY TABLE tmp_try_today (
	SELECT a.truename
		, a.masterid
		, COUNT(DISTINCT su.id) AS `今日预约试听人数`
	--  SELECT ac.student_user_id AS `学生 ID`
	--  	, su.phone
	-- 	, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') AS `试听课上课时间`
	-- 	, CONVERT_TZ(FROM_UNIXTIME(cd.student_into_time), '+00:00', '+08:00') AS `试听课学生进入时间`
	-- 	, a.truename
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		INNER JOIN newuuabc.admin AS a
			ON su.assign_consultant = a.masterid
		LEFT JOIN newuuabc.course_details AS cd
			ON cd.appoint_course_id = ac.id AND cd.student_id = su.id
	WHERE ac.disabled = 0
		AND ac.course_type = 1
		AND ac.start_time BETWEEN UNIX_TIMESTAMP(CONVERT_TZ(@target_date, '+08:00','+00:00'))
			AND UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(@target_date, INTERVAL 1 DAY), '+08:00','+00:00'))
		AND su.flag = 1
	GROUP BY a.masterid, a.truename
);


-- 明日试听

-- DROP TABLE IF EXISTS tmp_try_tom;

CREATE TEMPORARY TABLE tmp_try_tom (
	SELECT a.truename
		, a.masterid
		, COUNT(DISTINCT su.id) AS `明日预约试听人数`
	--  SELECT ac.student_user_id AS `学生 ID`
	--  	, su.phone
	-- 	, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') AS `试听课上课时间`
	-- 	, CONVERT_TZ(FROM_UNIXTIME(cd.student_into_time), '+00:00', '+08:00') AS `试听课学生进入时间`
	-- 	, a.truename
	-- 	, d.depart_name
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		INNER JOIN newuuabc.admin AS a
			ON su.assign_consultant = a.masterid
		LEFT JOIN newuuabc.course_details AS cd
			ON cd.appoint_course_id = ac.id AND cd.student_id = su.id
	WHERE ac.disabled = 0
		AND ac.course_type = 1
		AND ac.start_time BETWEEN UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(@target_date, INTERVAL 1 DAY), '+08:00','+00:00'))
			AND UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(@target_date, INTERVAL 2 DAY), '+08:00','+00:00'))
		AND su.flag = 1
	GROUP BY a.masterid, a.truename
);


-- 昨日试听

-- DROP TABLE IF EXISTS tmp_try_yestoday;

CREATE TEMPORARY TABLE tmp_try_yestoday(
	SELECT a.truename
		, a.masterid
		, COUNT(DISTINCT su.id) AS `昨日预约试听人数`
		, COUNT(DISTINCT cd.student_id) AS `昨日试听出席人数`
	--  SELECT ac.student_user_id AS `学生 ID`
	--  	, su.phone
	-- 	, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') AS `试听课上课时间`
	-- 	, CONVERT_TZ(FROM_UNIXTIME(cd.student_into_time), '+00:00', '+08:00') AS `试听课学生进入时间`
	-- 	, cd.student_id
	-- 	, a.truename
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		INNER JOIN newuuabc.admin AS a
			ON su.assign_consultant = a.masterid
		LEFT JOIN newuuabc.course_details AS cd
			ON cd.appoint_course_id = ac.id AND cd.student_id = su.id
	WHERE ac.disabled = 0
		AND ac.course_type = 1
		AND ac.start_time BETWEEN UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(@target_date, INTERVAL -1 DAY), '+08:00','+00:00'))
			AND UNIX_TIMESTAMP(CONVERT_TZ(@target_date, '+08:00','+00:00'))
		AND su.flag = 1
		AND ac.status = 3
	GROUP BY a.masterid, a.truename
);

-- 昨日付费

-- DROP TABLE IF EXISTS tmp_paid;

CREATE TEMPORARY TABLE tmp_paid (
	SELECT a.truename
		, a.masterid
		, COUNT(DISTINCT su.id) AS `昨日付费人数`
	-- SELECT CONVERT_TZ(FROM_UNIXTIME(c.sucess_at), '+00:00', '+08:00') 
	-- 	, su.assign_consultant
	-- 	, c.contract_amount
	-- 	, a.truename
	FROM newuuabc.contract AS c 
		INNER JOIN newuuabc.student_user AS su
			ON c.student_id = su.id
		INNER JOIN newuuabc.admin AS a
			ON su.assign_consultant = a.masterid
	WHERE c.contract_type = 1
		AND c.status = 4
		AND c.is_del = 1
		AND c.contract_amount > 0
		AND c.sucess_at BETWEEN UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(@target_date, INTERVAL -1 DAY), '+08:00','+00:00'))
			AND UNIX_TIMESTAMP(CONVERT_TZ(@target_date, '+08:00','+00:00'))
		AND su.flag = 1	
	GROUP BY a.masterid, a.truename
);


-- 昨日邀约

-- DROP TABLE IF EXISTS tmp_created_yestoday;

CREATE TEMPORARY TABLE tmp_created_yestoday (
	SELECT a.truename
		, a.masterid
		, COUNT(DISTINCT su.id) AS `昨日试听邀约人数`	
	--  SELECT ac.student_user_id AS `学生 ID`
	--  	, su.phone
	-- 	, CONVERT_TZ(FROM_UNIXTIME(ac.create_time), '+00:00', '+08:00') AS `试听课上课时间`
	-- 	, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') AS `试听课上课时间`
	-- 	, a.truename
	-- 	, d.depart_name
	FROM newuuabc.appoint_course AS ac
		INNER JOIN newuuabc.student_user AS su
			ON ac.student_user_id = su.id
		INNER JOIN newuuabc.admin AS a
			ON su.assign_consultant = a.masterid
	WHERE ac.disabled = 0
		AND ac.course_type = 1
		AND ac.create_time BETWEEN UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(@target_date, INTERVAL -1 DAY), '+08:00','+00:00'))
			AND UNIX_TIMESTAMP(CONVERT_TZ(@target_date, '+08:00','+00:00'))
		AND su.flag = 1
	GROUP BY a.masterid, a.truename
);


-- DROP TABLE IF EXISTS tmp_cc;

CREATE TEMPORARY TABLE tmp_cc (
	SELECT masterid, truename FROM (
	SELECT masterid, truename FROM tmp_try_today
	UNION
	SELECT masterid, truename FROM tmp_try_tom
	UNION 
	SELECT masterid, truename FROM tmp_try_yestoday
	UNION 
	SELECT masterid, truename FROM tmp_paid 
	UNION
	SELECT masterid, truename FROM tmp_created_yestoday
	) AS c
);

drop table if exists bi.today_sales_daily;
create table bi.today_sales_daily
as
SELECT tc.truename AS `姓名`
	, d.depart_name AS `组`
	, COALESCE(tty.`昨日预约试听人数`, 0) AS `昨日预约试听人数`
	, COALESCE(tty.`昨日试听出席人数`, 0) AS `昨日试听出席人数`
	, COALESCE(tp.`昨日付费人数`, 0) AS `昨日付费人数`
	, COALESCE(tcy.`昨日试听邀约人数`, 0) AS `昨日试听邀约人数`
	, COALESCE(ttt.`今日预约试听人数`, 0) AS `今日预约试听人数`
	, COALESCE(tttm.`明日预约试听人数`, 0) AS `明日预约试听人数`
FROM tmp_cc AS tc
	INNER JOIN newuuabc.admin AS a
		ON tc.masterid = a.masterid
	INNER JOIN newuuabc.department AS d
		ON a.dept = d.id
	LEFT JOIN tmp_try_today AS ttt
		ON tc.masterid = ttt.masterid
	LEFT JOIN tmp_try_yestoday AS tty
		ON tc.masterid = tty.masterid
	LEFT JOIN tmp_paid AS tp
		ON tc.masterid = tp.masterid
	LEFT JOIN tmp_created_yestoday AS tcy
		ON tc.masterid = tcy.masterid
	LEFT JOIN tmp_try_tom AS tttm
		ON tc.masterid = tttm.masterid;

end
