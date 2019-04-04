# 外教老师教学表现统计表


**需求来源**

提出人: 黄海<hai.huang@uuabc.com>

部门:

**拉取周期**
每月1号、16号


**用途**


**详细**

```
【外教ID】【外教姓名】【账号状态】【服务签约开始日】【服务签约截止日】【请假次数】【旷工次数】【总课数】【已上课数】【迟到课数】
【请假课数】【旷工课数】【学生评价总数】【学生评价均分】【学生评价标准差】【请假课时占比】【迟到课时占比】【旷工课时占比】

注明： 统计外教老师的签约周期，请假、迟到，已上课数，学生评价等相关信息
```

**SQL**

```sql
@set begin_date = '2018-06-15'
@set end_date = '2018-09-16'


DROP TABLE IF EXISTS tmp_teacher;

CREATE TEMPORARY TABLE tmp_teacher (
	SELECT id, english_name, disable FROM newuuabc.teacher_user_new
	WHERE status = 3 AND `type` = 1 AND (disable = 1 
		OR (disable = 2 AND update_at >= UNIX_TIMESTAMP(:begin_date))
	)
);

-- ----------------------------------------------------

DROP TABLE IF EXISTS tmp_tl;

CREATE TEMPORARY TABLE tmp_tl (
	SELECT teacher_user_id AS teacher_id, COUNT(*) AS leave_cnt 
	FROM newuuabc.teacher_leave 
	WHERE teacher_user_id IN (SELECT id FROM tmp_teacher)
		AND status <> 3
		AND start_time >= UNIX_TIMESTAMP(CONVERT_TZ(:begin_date, '+08:00','+00:00'))
		AND start_time < UNIX_TIMESTAMP(CONVERT_TZ(:end_date, '+08:00','+00:00'))
	GROUP BY teacher_user_id
);

DROP TABLE IF EXISTS tmp_ast;

CREATE TEMPORARY TABLE tmp_ast (
	SELECT teacher_id, COUNT(*) AS ast_cnt 
	FROM newuuabc.teacher_absenteeism 
	WHERE teacher_id IN (SELECT id FROM tmp_teacher)
		AND status <> 3
		AND start_time >= UNIX_TIMESTAMP(:begin_date)
		AND start_time < UNIX_TIMESTAMP(:end_date)
	GROUP BY teacher_id
);

-- ---------------------------------------------------------

DROP TABLE IF EXISTS tmp_1v1_class;

CREATE TEMPORARY TABLE tmp_1v1_class (
	SELECT ac.teacher_user_id AS teacher_id
		, COUNT(*) AS 1v1_cnt
		, COUNT(IF(FROM_UNIXTIME(cd.teacher_into_time) > DATE_ADD(FROM_UNIXTIME(ac.start_time), INTERVAL 1 MINUTE), 1, NULL)) AS 1v1_late_cnt
	FROM newuuabc.appoint_course AS ac
		INNER JOIN tmp_teacher AS t
			ON ac.teacher_user_id = t.id
		INNER JOIN newuuabc.course_details AS cd
			ON ac.id = cd.appoint_course_id
	WHERE ac.class_appoint_course_id = 0
		AND disabled = 0
		AND start_time >= UNIX_TIMESTAMP(CONVERT_TZ(:begin_date, '+08:00','+00:00'))
		AND start_time < UNIX_TIMESTAMP(CONVERT_TZ(:end_date, '+08:00','+00:00'))
		AND course_type IN (1, 3)
		AND cd.class_appoint_course_id = 0
	GROUP BY ac.teacher_user_id
);


DROP TABLE IF EXISTS tmp_o1v4_class;

CREATE TEMPORARY TABLE tmp_o1v4_class (
	SELECT ac.teacher_user_id AS teacher_id
		, COUNT(*) AS o1v4_cnt
		, COUNT(IF(FROM_UNIXTIME(ac.teacher_into_time) > DATE_ADD(FROM_UNIXTIME(ac.start_time), INTERVAL 1 MINUTE), 1, NULL)) AS o1v4_late_cnt
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
		, COUNT(IF(FROM_UNIXTIME(c.teacher_entry_time) > DATE_ADD(FROM_UNIXTIME(c.start_time), INTERVAL 1 MINUTE), 1, NULL)) AS 1v4_late_cnt
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


-- DROP TABLE IF EXISTS teacher_slot_all;
-- 
-- CREATE TABLE teacher_slot_all (
--   teacher_id INT NOT NULL,
--   class_date DATE NOT NULL, 
--   start_time DATETIME NOT NULL,
--   end_time DATETIME NOT NULL,
--   duration INT,
--   is_leave BOOLEAN,
--   is_ast BOOLEAN,
--   is_allocated BOOLEAN
-- ) ENGINE=MEMORY;


TRUNCATE TABLE bi.teacher_slot_all;

INSERT INTO bi.teacher_slot_all
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
UPDATE bi.teacher_slot_all AS tsa
	INNER JOIN newuuabc.teacher_leave AS tl
		ON tsa.teacher_id = tl.teacher_user_id
			AND UNIX_TIMESTAMP(CONVERT_TZ(tsa.start_time, '+08:00','+00:00')) >= tl.start_time
			AND UNIX_TIMESTAMP(CONVERT_TZ(tsa.end_time, '+08:00','+00:00')) <= tl.end_time
SET is_leave = 1
WHERE tl.status <> 3;


UPDATE bi.teacher_slot_all AS tsa
	INNER JOIN newuuabc.teacher_absenteeism AS tl
		ON tsa.teacher_id = tl.teacher_id
			AND UNIX_TIMESTAMP(tsa.start_time) >= tl.start_time
			AND UNIX_TIMESTAMP(tsa.end_time) <= tl.end_time
SET is_ast = 1
WHERE tl.status <> 3;


DROP TABLE IF EXISTS tmp_teacher_fb;

CREATE TEMPORARY TABLE tmp_teacher_fb (
	SELECT teacher_id, COUNT(*) AS fb_cnt, AVG(teacher_evaluate) AS fb_score, STD(teacher_evaluate) AS fb_std
	FROM (
		SELECT sc.teacher_id, se.teacher_evaluate FROM newuuabc.student_evaluate AS se
			INNER JOIN classbooking.student_class AS sc
				ON sc.student_class_id = se.appoint_course_id AND se.`type` = 4
		UNION ALL
		SELECT ac.teacher_user_id AS teacher_id, se.teacher_evaluate FROM newuuabc.student_evaluate AS se
			INNER JOIN newuuabc.appoint_course AS ac
				ON ac.id = se.appoint_course_id AND se.`type` = 1
		WHERE ac.status = 3 AND disabled = 0
		UNION ALL
		SELECT ac.teacher_user_id AS teacher_id, se.teacher_evaluate FROM newuuabc.student_evaluate AS se
			INNER JOIN newuuabc.appoint_course AS ac
				ON ac.id = se.appoint_course_id AND se.`type` = 3
		WHERE ac.status = 3 AND ac.disabled = 0 AND ac.class_appoint_course_id > 0 
		UNION ALL
		SELECT lc.teacher_user_id AS teacher_id, se.teacher_evaluate FROM newuuabc.student_evaluate AS se
			INNER JOIN newuuabc.live_course_details AS lcd
				ON lcd.appoint_course_id = se.appoint_course_id AND se.`type` = 2 and lcd.student_user_id=se.student_user_id
			INNER JOIN newuuabc.live_course AS lc
				ON lcd.appoint_course_id = lc.id
		WHERE lc.disabled = 1 AND lc.state = 1 AND lc.status = 3
	) AS a
	GROUP BY teacher_id
);


SELECT tun.id AS `外教ID`
 	, tun.english_name AS `外教姓名`
 	, IF(tun.disable = 1, '有效', '禁用') AS `账号状态`
 	, a.effective_start_time AS `服务签约开始日`
	, a.effective_end_time AS `服务签约截止日`
	, IFNULL(tl.leave_cnt, 0) AS `请假次数`
	, IFNULL(ta.ast_cnt, 0) AS `旷工次数`
	, IFNULL(c.total_class_cnt, 0) AS `总课数`
	, IFNULL(t1c.1v1_cnt, 0) + IFNULL(to4c.o1v4_cnt, 0) + IFNULL(t4c.1v4_cnt, 0) AS `已上课数`
	, IFNULL(t1c.1v1_late_cnt, 0) + IFNULL(to4c.o1v4_late_cnt, 0) + IFNULL(t4c.1v4_late_cnt, 0) AS `迟到课数`
	, IFNULL(c.leave_class_cnt, 0) AS `请假课数`	
	, IFNULL(c.ast_class_cnt, 0) AS `旷工课数`
	, IFNULL(ttf.fb_cnt, 0) AS `学生评价总数`
	, IFNULL(ttf.fb_score, 0) AS `学生评价均分`
	, ROUND(IFNULL(ttf.fb_std, 0), 4) AS `学生评价标准差`
	, IFNULL(c.leave_class_cnt, 0) / IFNULL(c.total_class_cnt, 0) AS `请假课时占比`
	, (IFNULL(t1c.1v1_late_cnt, 0) + IFNULL(to4c.o1v4_late_cnt, 0) + IFNULL(t4c.1v4_late_cnt, 0)) / IFNULL(c.total_class_cnt, 0) AS `迟到课时占比`
	, IFNULL(c.ast_class_cnt, 0) / IFNULL(c.total_class_cnt, 0) AS `旷工课时占比`
FROM tmp_teacher AS tun
	INNER JOIN (
		SELECT ts.teacher_id
			, FROM_UNIXTIME(min(ts.effective_start_time)) AS effective_start_time
			, FROM_UNIXTIME(max(ts.effective_end_time)) AS effective_end_time 
		FROM newuuabc.teacher_signed AS ts
		WHERE enable = 1 AND status = 1
		GROUP BY ts.teacher_id
	) AS a
		ON tun.id = a.teacher_id
	LEFT JOIN (
		SELECT teacher_id
			, COUNT(*) AS total_class_cnt
			, COUNT(IF(is_leave = 1, 1 , NULL)) AS leave_class_cnt
			, COUNT(IF(is_ast = 1, 1 , NULL)) AS ast_class_cnt
		FROM bi.teacher_slot_all
		GROUP BY teacher_id
	) AS c
		ON tun.id = c.teacher_id
	LEFT JOIN tmp_tl AS tl
		ON tun.id = tl.teacher_id
	LEFT JOIN tmp_1v1_class AS t1c
		ON tun.id = t1c.teacher_id
	LEFT JOIN tmp_o1v4_class AS to4c
		ON tun.id = to4c.teacher_id
	LEFT JOIN tmp_1v4_class AS t4c
		ON tun.id = t4c.teacher_id
	LEFT JOIN tmp_ast AS ta
		ON tun.id = ta.teacher_id
	LEFT JOIN tmp_teacher_fb AS ttf
		ON tun.id = ttf.teacher_id;
```

**备注**

