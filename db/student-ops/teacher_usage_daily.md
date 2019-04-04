# 每天老师利用率


**需求来源**

提出人: 颜巍<wei.yan@uuabc.com>

部门:

**拉取周期**

每个工作日

**用途**


**详细**

```
抽取新系统1V4小班课工作日17:50:00~21:15:00、以及周末10:15:00~21:15:00高峰时期【昨天】的总车位数、已排课数,以及老师利用率：已排课数/总车位数
当天的试听课数，以及新系统当天 1 v 4 可用车位数：排课表中状态是可用的

```

**SQL**

```sql
-- 昨天的总车位数
-- 需设置begindate=current_date - interval 1 day 为昨天数值

SELECT COUNT(*) into total_cnts
FROM classschedule.teacher_slot AS ts
	INNER JOIN newuuabc.carport_slot AS cs 
		ON ts.carport_time_id = cs.id
	INNER JOIN bi.peak_time AS pt 
		ON SEC_TO_TIME(cs.start_time * 60) = pt.start_time
			AND SEC_TO_TIME(cs.end_time * 60) = pt.end_time
			AND ((WEEKDAY(FROM_UNIXTIME(ts.slot_date)) IN (5, 6) AND pt.is_weekend = 1)
				OR 
				(WEEKDAY(FROM_UNIXTIME(ts.slot_date)) IN (0, 1, 2, 3, 4) AND pt.is_weekend = 0)
			)
WHERE ts.status IN (1 , 2) 
	AND ts.slot_date = UNIX_TIMESTAMP(begindate)  ;

-- 昨天的已排课数
SELECT COUNT(*) into actual_cnts
FROM classschedule.teacher_slot AS ts
	INNER JOIN newuuabc.carport_slot AS cs 
		ON ts.carport_time_id = cs.id
	INNER JOIN bi.peak_time AS pt 
		ON SEC_TO_TIME(cs.start_time * 60) = pt.start_time
			AND SEC_TO_TIME(cs.end_time * 60) = pt.end_time
			AND ((WEEKDAY(FROM_UNIXTIME(ts.slot_date)) IN (5, 6) AND pt.is_weekend = 1)
				OR 
				(WEEKDAY(FROM_UNIXTIME(ts.slot_date)) IN (0, 1, 2, 3, 4) AND pt.is_weekend = 0)
			)
WHERE ts.status = 2
	AND ts.slot_date = UNIX_TIMESTAMP(begindate);

-- `当天试听课排课数量`
SELECT COUNT(*) into try_cnts
FROM newuuabc.appoint_course AS ac
WHERE class_id = 0 
	AND class_appoint_course_id = 0
	AND course_type = 1
	AND disabled = 0
	AND start_time BETWEEN UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(begindate, INTERVAL 1 DAY), '+08:00','+00:00'))  
	AND UNIX_TIMESTAMP(CONVERT_TZ(DATE_ADD(begindate, INTERVAL 2 DAY),'+08:00','+00:00'));



-- `当天总车位数`
SELECT COUNT(*)  into today_cnts
FROM classschedule.teacher_slot AS ts
WHERE ts.status IN (1, 2) 
	AND ts.slot_date = UNIX_TIMESTAMP(DATE_ADD(begindate, INTERVAL 1 DAY));

-- `需要减去的当天已排课车位数`
SELECT COUNT(*) into today_cnts_s
FROM classschedule.teacher_slot AS ts
WHERE ts.status IN (2) 
     AND ts.slot_date = UNIX_TIMESTAMP(DATE_ADD(begindate, INTERVAL 1 DAY));
```

**备注**

