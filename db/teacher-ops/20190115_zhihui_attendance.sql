-- 至慧出勤汇总

SELECT DATE(FROM_UNIXTIME(sc.class_date)) as `日期`
	, COUNT(*) as `课程预定人数`
	, COUNT(IF(sc.status = 6, 1, null)) as `其中旷课数`
	, COUNT(IF(sc.status = 7, 1, null)) as `其中请假数`
FROM classbooking.student_class as sc
	inner join newuuabc.student_user as su
		on sc.student_id = su.id
	inner join classschedule.train as t
		on sc.train_id = t.train_id
	inner join newuuabc.admin as a
		ON a.masterid = su.assign_teacher
where sc.train_id >= 103 and sc.train_id <= 117
	and DATE(FROM_UNIXTIME(sc.start_time)) < CURRENT_DATE
	and sc.status in (3, 5, 6, 7, 9)
group by sc.class_date;


-- 至慧出勤学生明细

SELECT su.id as `学生ID`
	, su.name as `学生姓名`
  , su.phone as `学生手机`
	, t.train_id as `所在车次ID`
	, t.name as `所在车次名称`
	, a.truename as `所属班主任`
	, FROM_UNIXTIME(sc.start_time) as `课程开始时间`
	, case sc.status 
		when 6 then '学生旷课'
		WHEN 7 then '学生请假'
		else '已上课' end as `课程状态`
FROM classbooking.student_class as sc
	inner join newuuabc.student_user as su
		on sc.student_id = su.id
	inner join classschedule.train as t
		on sc.train_id = t.train_id
	inner join newuuabc.admin as a
		ON a.masterid = su.assign_teacher
where sc.train_id >= 103 and sc.train_id <= 117
	and DATE(FROM_UNIXTIME(sc.start_time)) < CURRENT_DATE
	and sc.status in (3, 5, 6, 7, 9)
ORDER BY sc.start_time;