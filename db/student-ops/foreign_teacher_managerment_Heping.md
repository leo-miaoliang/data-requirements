# 外教运营


**需求来源**

提出人: 何平<ping.he@uuabc.com>

部门:

**拉取周期**

每天

**用途**


**详细**

```
每天发给何平的报表分为3个模块:
【最近七天约课率】新系统的外教老师最近7天的总车位数以及排上课的总数；当天的剩余车位数；每个老师的最近七天约课率
【需求已停止截止到20180919】【外教各个时间段排课情况】新系统外教在各个时间段10:15~21:15的排课情况，1 代表这个外教这个时间段可用，2 代表已经约上课了
【需求已停止截止到20180919】【车次在各个时间段已排课情况】车次在每个上课时间段的已经约上课的数量；以及后面新增的需求 计算各个时间段的今天待分配学生数、今天待上课学生数


```

**SQL**

```sql
【调用存储过程的脚本】
call bi.P_today_recent7days_New();
call bi.P_today_train_totalclass();
call bi.P_today_teacher_schedule();

【最近七天约课率sql】
DROP TABLE IF EXISTS tmp_new_1v4;

CREATE TEMPORARY TABLE tmp_new_1v4 (
	SELECT ts.teacher_id
		, DATE_ADD(FROM_UNIXTIME(ts.slot_date), INTERVAL cs.start_time MINUTE) AS start_time
		, ts.status
		, '1v4' AS source
	FROM classschedule.teacher_slot AS ts 
		INNER JOIN newuuabc.carport_slot AS cs
			ON ts.carport_time_id = cs.id
	WHERE ts.teacher_id IN (
		SELECT id
		FROM newuuabc.teacher_user_new
		WHERE is_old = 2 AND status = 3 AND `type` = 1 AND disable = 1
	) AND ts.slot_date >= UNIX_TIMESTAMP(current_date - INTERVAL 7 DAY)
		AND ts.slot_date <= UNIX_TIMESTAMP(current_date)
		AND ts.status <> 4
);

DROP TABLE IF EXISTS tmp_1v1;

CREATE TEMPORARY TABLE tmp_1v1 (
	SELECT ac.teacher_user_id AS teacher_id
		, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') AS start_time
		, 2 AS status
		, '1v1' AS source
	FROM newuuabc.appoint_course AS ac
	WHERE ac.teacher_user_id IN (
			SELECT id
			FROM newuuabc.teacher_user_new
			WHERE is_old = 2 AND status = 3 AND `type` = 1 AND disable = 1
		) AND class_appoint_course_id = 0
		AND ac.disabled = 0
		AND ac.start_time >= UNIX_TIMESTAMP(CONVERT_TZ(current_date, '+08:00','+00:00') - INTERVAL 7 DAY) 
		AND ac.start_time < UNIX_TIMESTAMP(CONVERT_TZ(current_date + interval 1 day, '+08:00', '+00:00'))
);	


DROP TABLE IF EXISTS tmp_old_1v4;

CREATE TEMPORARY TABLE tmp_old_1v4 (
	SELECT ac.teacher_user_id AS teacher_id
		, CONVERT_TZ(FROM_UNIXTIME(ac.start_time), '+00:00', '+08:00') AS start_time
		, 2 AS status
		, 'o1v4' AS source
	FROM newuuabc.class_appoint_course AS ac
	WHERE ac.teacher_user_id IN (
			SELECT id
			FROM newuuabc.teacher_user_new
			WHERE is_old = 2 AND status = 3 AND `type` = 1 AND disable = 1
		)
		AND ac.disabled = 0
		AND ac.start_time >= UNIX_TIMESTAMP(CONVERT_TZ(current_date, '+08:00','+00:00') - INTERVAL 7 DAY) 
		AND ac.start_time < UNIX_TIMESTAMP(CONVERT_TZ(current_date + interval 1 day, '+08:00', '+00:00'))
);


DROP TABLE IF EXISTS tmp_result;

CREATE TEMPORARY TABLE tmp_result(
	SELECT * FROM (
		SELECT IF(tn2.source IS NULL, tn1.teacher_id, tn2.teacher_id) AS teacher_id
			, IF(tn2.source IS NULL, tn1.start_time, tn2.start_time) AS start_time
			, IF(tn2.source IS NULL, tn1.status, tn2.status) AS status
			, IF(tn2.source IS NULL, tn1.source, tn2.source) AS source
		FROM tmp_new_1v4 AS tn1
			LEFT JOIN (
				SELECT * FROM tmp_1v1
				UNION ALL
				SELECT * FROM tmp_old_1v4
			) AS tn2
				ON tn1.teacher_id = tn2.teacher_id
					AND tn1.start_time = tn2.start_time
	) AS a
	WHERE a.status <> 3
);


DROP TABLE IF EXISTS tmp_final;

CREATE  TEMPORARY TABLE tmp_final(
	  SELECT tr.* 
    from tmp_result AS tr
		LEFT JOIN newuuabc.teacher_leave AS tl
			ON tl.status <> 3
				AND tr.teacher_id = tl.teacher_user_id
				AND tr.start_time >= CONVERT_TZ(FROM_UNIXTIME(tl.start_time), '+00:00', '+08:00')
				AND tr.start_time < CONVERT_TZ(FROM_UNIXTIME(tl.end_time), '+00:00', '+08:00')
	WHERE tl.id IS NULL
);


-- 最终加载到目标表的数据
truncate table bi.today_recent7days_position;

insert into bi.today_recent7days_position
( teacher_id,teacher_english_name,t7_total_cnt,t7_occupy_cnt,t6_total_cnt,t6_occupy_cnt,t5_total_cnt,t5_occupy_cnt,t4_total_cnt,t4_occupy_cnt,t3_total_cnt,t3_occupy_cnt,t2_total_cnt,t2_occupy_cnt,t1_total_cnt,t1_occupy_cnt,t_total_cnt,t_remain_cnt)

SELECT  a.teacher_id
	, tun.english_name
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 7 DAY) THEN total ELSE 0 END) AS `7-total`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 7 DAY) THEN used ELSE 0 END) AS `7-used`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 6 DAY) THEN total ELSE 0 END) AS `6-total`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 6 DAY) THEN used ELSE 0 END) AS `6-used`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 5 DAY) THEN total ELSE 0 END) AS `5-total`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 5 DAY) THEN used ELSE 0 END) AS `5-used`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 4 DAY) THEN total ELSE 0 END) AS `4-total`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 4 DAY) THEN used ELSE 0 END) AS `4-used`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 3 DAY) THEN total ELSE 0 END) AS `3-total`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 3 DAY) THEN used ELSE 0 END) AS `3-used`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 2 DAY) THEN total ELSE 0 END) AS `2-total`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 2 DAY) THEN used ELSE 0 END) AS `2-used`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 1 DAY) THEN total ELSE 0 END) AS `1-total`
	, MAX(CASE WHEN d = DATE_SUB(current_date, INTERVAL 1 DAY) THEN used ELSE 0 END) AS `1-used`
	, MAX(CASE WHEN d = current_date THEN total ELSE 0 END) AS `today-total`
	, MAX(CASE WHEN d = current_date THEN empty ELSE 0 END) AS `today-empty` 
FROM (
	SELECT teacher_id
		, date(start_time) AS d
		, COUNT(*) AS total 
		, COUNT(IF(status=2, 1, NULL)) AS used
		, COUNT(IF(status=1, 1, NULL)) AS empty
	from tmp_final
	GROUP BY teacher_id, date(start_time)
) AS a
	INNER JOIN newuuabc.teacher_user_new AS tun
		ON a.teacher_id = tun.id
  where a.teacher_id in (select teacher_user_id
                         from newuuabc.signed_time
                         group by teacher_user_id
                         having max(left(FROM_UNIXTIME(effective_end_time),10)) >=current_date 
                         )
GROUP BY a.teacher_id;





【外教各个时间段排课情况】
 SELECT
	ss.teacher_id ,
	CURRENT_DATE,
	max(IF(id = 3, STATUS, '')) AS '10:15-10:45',
	max(IF(id = 4, STATUS, '')) AS '10:50-11:20',
	max(IF(id = 5, STATUS, '')) AS '11:25-11:55',
	max(IF(id = 6, STATUS, '')) AS '12:00-12:30',
	max(IF(id = 7, STATUS, '')) AS '12:35-13:05',
	max(IF(id = 8, STATUS, '')) AS '13:10-13:40',
	max(IF(id = 9, STATUS, '')) AS '13:45-14:15',
	max(IF(id = 10, STATUS, '')) AS '14:20-14:50',
	max(IF(id = 11, STATUS, '')) AS '14:55-15:25',
	max(IF(id = 12, STATUS, '')) AS '15:30-16:00',
	max(IF(id = 13, STATUS, '')) AS '16:05-16:35',
	max(IF(id = 14, STATUS, '')) AS '16:40-17:10',
	max(IF(id = 15, STATUS, '')) AS '17:15-17:45',
	max(IF(id = 16, STATUS, '')) AS '17:50-18:20',
	max(IF(id = 17, STATUS, '')) AS '18:25-18:55',
	max(IF(id = 18, STATUS, '')) AS '19:00-19:30',
	max(IF(id = 19, STATUS, '')) AS '19:35-20:05',
	max(IF(id = 20, STATUS, '')) AS '20:10-20:40',
	max(IF(id = 21, STATUS, '')) AS '20:45-21:15'
FROM
	(
		SELECT
			main_tb.teacher_id,
			main_tb.timeperiod,
			main_tb.id,
			s. STATUS
		FROM
			(
				SELECT
					tmp.teacher_id,
					s.id,
					s.timeperiod
				FROM
					(
						SELECT
							id AS teacher_id
						FROM
							newuuabc.teacher_user_new
						WHERE
							is_old = 2 AND STATUS = 3
						    AND `type` = 1 AND DISABLE = 1
					) tmp -- 取当天的老师数据
				JOIN (
					SELECT
						cs.id,
						concat(LEFT (cs.startime, 5),'-',LEFT (cs.endtime, 5)) AS timeperiod
					FROM
						(
							SELECT
								id,
								SEC_TO_TIME(start_time * 60) AS startime,
								SEC_TO_TIME(end_time * 60) endtime
							FROM
								newuuabc.carport_slot
						) cs
					WHERE
						id > 2
				) s -- 获取所有时间段的数据
			) main_tb -- 构建为主表
		LEFT JOIN -- 以下为时间段有状态的老师
		(
			SELECT
				t.teacher_id,
				t. STATUS,
				t.carport_time_id
			FROM
				classschedule.teacher_slot t
			LEFT JOIN (
				SELECT
					id
				FROM
					newuuabc.carport_slot
			) cs ON t.carport_time_id = cs.id
			WHERE
				t. STATUS IN (1, 2)
			AND t.slot_date = UNIX_TIMESTAMP(CURRENT_DATE)
		) s ON main_tb.teacher_id = s.teacher_id
		AND main_tb.id = s.carport_time_id
	) ss
GROUP BY
	teacher_id;

【车次Sheet在各个时间段已排课情况1】
 SELECT
	train_id,
	CURRENT_DATE AS DateID,
	max(IF(id = 3, STATUS, '')) AS '10:15-10:45',
	max(IF(id = 4, STATUS, '')) AS '10:50-11:20',
	max(IF(id = 5, STATUS, '')) AS '11:25-11:55',
	max(IF(id = 6, STATUS, '')) AS '12:00-12:30',
	max(IF(id = 7, STATUS, '')) AS '12:35-13:05',
	max(IF(id = 8, STATUS, '')) AS '13:10-13:40',
	max(IF(id = 9, STATUS, '')) AS '13:45-14:15',
	max(IF(id = 10, STATUS, '')) AS '14:20-14:50',
	max(IF(id = 11, STATUS, '')) AS '14:55-15:25',
	max(IF(id = 12, STATUS, '')) AS '15:30-16:00',
	max(IF(id = 13, STATUS, '')) AS '16:05-16:35',
	max(IF(id = 14, STATUS, '')) AS '16:40-17:10',
	max(IF(id = 15, STATUS, '')) AS '17:15-17:45',
	max(IF(id = 16, STATUS, '')) AS '17:50-18:20',
	max(IF(id = 17, STATUS, '')) AS '18:25-18:55',
	max(IF(id = 18, STATUS, '')) AS '19:00-19:30',
	max(IF(id = 19, STATUS, '')) AS '19:35-20:05',
	max(IF(id = 20, STATUS, '')) AS '20:10-20:40',
	max(IF(id = 21, STATUS, '')) AS '20:45-21:15'
FROM
	(
		SELECT
			main.train_id,
			main.timeperiod,
			main.id,
			sss.cnt AS STATUS
		FROM
			(
				SELECT
					train_id,
					s.id,
					s.timeperiod
				FROM
					(
						SELECT DISTINCT
							cts.train_id
						FROM
							classschedule.teacher_slot AS ts
						INNER JOIN newuuabc.carport_slot AS cs ON ts.carport_time_id = cs.id
						INNER JOIN classschedule.train_slot cts ON cts.slot_id = ts.slot_id
						WHERE
							slot_date = UNIX_TIMESTAMP(CURRENT_DATE)
						AND ts. STATUS = 2
					)  tr
				JOIN (
					  SELECT
						cs.id,
						concat(LEFT (cs.startime, 5),'-',LEFT (cs.endtime, 5)) AS timeperiod
					  FROM
						(
							SELECT
								id,
								SEC_TO_TIME(start_time * 60) AS startime,
								SEC_TO_TIME(end_time * 60) endtime
							FROM
								newuuabc.carport_slot
						 ) cs
					   WHERE id > 2
				     ) s
			) main -- 构建主表完成 车次与时间段做笛卡尔积
		LEFT JOIN 
     (
			  SELECT
				train_id,
				time_id,
				concat(LEFT (t.startime, 5),'-',LEFT (t.endtime, 5)) AS periodtime,
				count(1) AS cnt
			  FROM
				(
					SELECT
						cts.train_id,
						SEC_TO_TIME(cs.start_time * 60) AS startime,
						SEC_TO_TIME(cs.end_time * 60) AS endtime,
						ts.carport_time_id AS time_id
					FROM classschedule.teacher_slot AS ts
					INNER JOIN newuuabc.carport_slot AS cs ON ts.carport_time_id = cs.id
					INNER JOIN classschedule.train_slot cts ON cts.slot_id = ts.slot_id
          inner join newuuabc.teacher_user_new a on a.id=ts.teacher_id
							and a.is_old = 2
						AND a.STATUS = 3
						AND a.`type` = 1
						AND a.DISABLE = 1 -- 统计新系统老师
					WHERE
						 ts.slot_date = UNIX_TIMESTAMP(CURRENT_DATE)
					   AND ts. STATUS =2
				) t
			  GROUP BY
				  train_id,
				  concat(LEFT (t.startime, 5),'-',LEFT (t.endtime, 5))
		   ) sss -- 构建数据表完成
		   ON main.id = sss.time_id
		    AND main.train_id = sss.train_id
	) ttt -- 大表
GROUP BY
	train_id;

【车次Sheet计算各个时间段的今天待分配学生数、今天待上课学生数 2】
select category,
max(if(id=3,status,0)) as '10:15-10:45',
max(if(id=4,status,0)) as '10:50-11:20',
max(if(id=5,status,0)) as '11:25-11:55',
max(if(id=6,status,0)) as '12:00-12:30',
max(if(id=7,status,0)) as '12:35-13:05',
max(if(id=8,status,0)) as '13:10-13:40',
max(if(id=9,status,0)) as '13:45-14:15',
max(if(id=10,status,0)) as '14:20-14:50',
max(if(id=11,status,0)) as '14:55-15:25',
max(if(id=12,status,0)) as '15:30-16:00',
max(if(id=13,status,0)) as '16:05-16:35',
max(if(id=14,status,0)) as '16:40-17:10',
max(if(id=15,status,0)) as '17:15-17:45',
max(if(id=16,status,0)) as '17:50-18:20',
max(if(id=17,status,0)) as '18:25-18:55',
max(if(id=18,status,0)) as '19:00-19:30',
max(if(id=19,status,0)) as '19:35-20:05',
max(if(id=20,status,0)) as '20:10-20:40',
max(if(id=21,status,0)) as '20:45-21:15'
from 
(
     select t.id,ifnull(s.cnt,0) status,category
     from 
       (select cs.id,startime
        from 
          (
          select id,SEC_TO_TIME(start_time * 60) as startime,SEC_TO_TIME(end_time * 60) endtime
          from newuuabc.carport_slot 
	  ) cs
        where id>2
       ) t -- 主表时间段
     left join  -- 关联
     (
       SELECT status as category,TIME(FROM_UNIXTIME(start_time)) timeperiod, COUNT(*) cnt 
       FROM classbooking.student_class
       WHERE class_date = UNIX_TIMESTAMP(current_date)
	     AND status IN (1,2)
       GROUP BY TIME(FROM_UNIXTIME(start_time)) -- 从表具体的数据
      ) s 
      on t.startime=s.timeperiod
) tt  -- tt 为主表

group by category

```

**备注**
运行脚本步骤：
Step1：跑数存储过程
call bi.P_today_recent7days_New();
call bi.P_today_train_totalclass();
call bi.P_today_teacher_schedule();

Step2：最近七天约课率sheet数据查询
select * from bi.today_recent7days_position;

-- 利用率计算公式：
-- =(P3+N3+L3+J3+H3+F3+D3)/(C3+E3+G3+I3+K3+M3+O3)

Step3： 外教sheet数据查询

select *
from bi.today_teacher_schedule 
where dateid=current_date
and `外教ID` in(select distinct teacher_id 
                from bi.today_recent7days_position )

Step4：车次sheet
-- 4.1车次排课情况
select * from bi.today_train_totalclass where DateID=current_date;
-- 4.2 各个时间段的今天待分配学生数、今天待上课学生数 
select category,
max(if(id=3,status,0)) as '10:15-10:45',
max(if(id=4,status,0)) as '10:50-11:20',
max(if(id=5,status,0)) as '11:25-11:55',
max(if(id=6,status,0)) as '12:00-12:30',
max(if(id=7,status,0)) as '12:35-13:05',
max(if(id=8,status,0)) as '13:10-13:40',
max(if(id=9,status,0)) as '13:45-14:15',
max(if(id=10,status,0)) as '14:20-14:50',
max(if(id=11,status,0)) as '14:55-15:25',
max(if(id=12,status,0)) as '15:30-16:00',
max(if(id=13,status,0)) as '16:05-16:35',
max(if(id=14,status,0)) as '16:40-17:10',
max(if(id=15,status,0)) as '17:15-17:45',
max(if(id=16,status,0)) as '17:50-18:20',
max(if(id=17,status,0)) as '18:25-18:55',
max(if(id=18,status,0)) as '19:00-19:30',
max(if(id=19,status,0)) as '19:35-20:05',
max(if(id=20,status,0)) as '20:10-20:40',
max(if(id=21,status,0)) as '20:45-21:15'
from 
(
     select t.id,ifnull(s.cnt,0) status,category
     from 
       (select cs.id,startime
        from 
          (
          select id,SEC_TO_TIME(start_time * 60) as startime,SEC_TO_TIME(end_time * 60) endtime
          from newuuabc.carport_slot 
	  ) cs
        where id>2
       ) t -- 主表时间段
     left join  -- 关联
     (
       SELECT status as category,TIME(FROM_UNIXTIME(start_time)) timeperiod, COUNT(*) cnt 
       FROM classbooking.student_class
       WHERE class_date = UNIX_TIMESTAMP(current_date)
	     AND status IN (1,2)
       GROUP BY TIME(FROM_UNIXTIME(start_time)) -- 从表具体的数据
      ) s 
      on t.startime=s.timeperiod
) tt  -- tt 为主表

group by category

