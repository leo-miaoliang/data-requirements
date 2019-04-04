# 每日 /周 / 月外教老师课时统计


**需求来源**

提出人: 黄海<hai.huang@uuabc.com>

部门:

**拉取周期**
每日（11点）

每周一发送上周数据（11点）

每月1日发送上月数据


**用途**


**详细**

```
-- 老师ID - 姓名 - 日期 - 课时总数 – 被安排课数 – 请假次数 – 请假课数 - 迟到次数 – 迟到时长 – 受影响课数 – 旷工次数
```

**SQL**

```sql


set @begin_time := '2018-09-18';
set @end_time := '2018-09-19';

-- teacher

DROP TABLE IF EXISTS tmp_teacher;

CREATE TEMPORARY TABLE tmp_teacher (
    SELECT id, english_name
    FROM newuuabc.teacher_user_new AS tun
    WHERE tun.`type` = 1 AND tun.status = 3 AND tun.disable = 1
);

-- leave and absent

DROP TABLE IF EXISTS tmp_tl;

CREATE TEMPORARY TABLE tmp_tl (
    SELECT teacher_user_id AS teacher_id, COUNT(*) AS leave_cnt
    FROM newuuabc.teacher_leave
    WHERE teacher_user_id IN (SELECT id FROM tmp_teacher)
        AND status <> 3
        AND start_time >= UNIX_TIMESTAMP(@begin_time)
        AND start_time < UNIX_TIMESTAMP(@end_time)
    GROUP BY teacher_user_id
);

DROP TABLE IF EXISTS tmp_ast;

CREATE TEMPORARY TABLE tmp_ast (
    SELECT teacher_id, COUNT(*) AS ast_cnt
    FROM newuuabc.teacher_absenteeism
    WHERE teacher_id IN (SELECT id FROM tmp_teacher)
        AND status <> 3
        AND start_time >= UNIX_TIMESTAMP(@begin_time)
        AND start_time < UNIX_TIMESTAMP(@end_time)
    GROUP BY teacher_id
);


-- class schedule

DROP TABLE IF EXISTS tmp_teacher_day;

CREATE TEMPORARY TABLE tmp_teacher_day (
    SELECT tt.id, dr.date1 as d
    FROM tmp_teacher AS tt
        CROSS JOIN (
            SELECT date1 FROM bi.dim_date
            WHERE date1 >= @begin_time
                AND date1 < @end_time
        ) AS dr
    ORDER BY tt.id, dr.date1
);

CREATE TABLE IF NOT EXISTS tmp_teacher_slot_1 (
  teacher_id INT NOT NULL,
  class_date DATE NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  duration INT,
  is_leave BOOLEAN,
  is_ast BOOLEAN,
  is_allocated BOOLEAN
) ENGINE=MEMORY;

TRUNCATE TABLE tmp_teacher_slot_1;

INSERT INTO tmp_teacher_slot_1
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


-- tag leave/absent class

UPDATE tmp_teacher_slot_1 AS tsa
    INNER JOIN newuuabc.teacher_leave AS tl
        ON tsa.teacher_id = tl.teacher_user_id
            AND UNIX_TIMESTAMP(CONVERT_TZ(tsa.start_time, '+08:00','+00:00')) >= tl.start_time
            AND UNIX_TIMESTAMP(CONVERT_TZ(tsa.end_time, '+08:00','+00:00')) <= tl.end_time
SET is_leave = 1
WHERE tl.status <> 3;


UPDATE tmp_teacher_slot_1 AS tsa
    INNER JOIN newuuabc.teacher_absenteeism AS tl
        ON tsa.teacher_id = tl.teacher_id
            AND UNIX_TIMESTAMP(tsa.start_time) >= tl.start_time
            AND (UNIX_TIMESTAMP(tsa.end_time) <= tl.end_time
                OR
                UNIX_TIMESTAMP(DATE_SUB(tsa.end_time, INTERVAL 10 MINUTE)) <= tl.end_time
            )
SET is_ast = 1
WHERE tl.status <> 3;


-- class

DROP TABLE IF EXISTS tmp_1v1;

CREATE TEMPORARY TABLE tmp_1v1 (
    SELECT ac.teacher_user_id AS teacher_id
        , COUNT(*) AS 1v1_cnt
        , COUNT(IF(cd.teacher_into_time > ac.start_time, 1, NULL)) AS 1v1_late_cnt
        , SUM(IF(cd.teacher_into_time > ac.start_time, cd.teacher_into_time - ac.start_time, 0)) AS 1v1_late_secs
    FROM newuuabc.appoint_course AS ac
        INNER JOIN tmp_teacher AS t
            ON ac.teacher_user_id = t.id
        LEFT JOIN newuuabc.course_details AS cd
            ON ac.id = cd.appoint_course_id
                AND cd.class_appoint_course_id = 0
    WHERE ac.class_appoint_course_id = 0
        AND disabled = 0
        AND start_time >= UNIX_TIMESTAMP(CONVERT_TZ(@begin_time, '+08:00','+00:00'))
        AND start_time < UNIX_TIMESTAMP(CONVERT_TZ(@end_time, '+08:00','+00:00'))
        AND course_type IN (1, 3)
    GROUP BY ac.teacher_user_id
);


DROP TABLE IF EXISTS tmp_o1v4;

CREATE TEMPORARY TABLE tmp_o1v4 (
    SELECT ac.teacher_user_id AS teacher_id
        , COUNT(*) AS o1v4_cnt
        , COUNT(IF(FROM_UNIXTIME(ac.teacher_into_time) > FROM_UNIXTIME(ac.start_time), 1, NULL)) AS o1v4_late_cnt
        , SUM(IF(ac.teacher_into_time > ac.start_time, ac.teacher_into_time - ac.start_time, 0)) AS o1v4_late_secs
    FROM newuuabc.class_appoint_course AS ac
        INNER JOIN tmp_teacher AS t
                ON ac.teacher_user_id = t.id
    WHERE ac.disabled = 0
        AND ac.course_type IN (1, 3)
        AND start_time >= UNIX_TIMESTAMP(CONVERT_TZ(@begin_time, '+08:00','+00:00'))
        AND start_time < UNIX_TIMESTAMP(CONVERT_TZ(@end_time, '+08:00','+00:00'))
    GROUP BY ac.teacher_user_id
);


DROP TABLE IF EXISTS tmp_1v4;

CREATE TEMPORARY TABLE tmp_1v4 (
    SELECT teacher_id, COUNT(*) AS 1v4_cnt
        , COUNT(IF(c.teacher_entry_time > c.start_time, 1, NULL)) AS 1v4_late_cnt
        , SUM(IF(c.teacher_entry_time > c.start_time, c.teacher_entry_time - c.start_time, 0)) AS 1v4_late_secs
    FROM classbooking.classroom AS c
        INNER JOIN tmp_teacher AS t
            ON c.teacher_id = t.id
    WHERE start_time >= UNIX_TIMESTAMP(@begin_time)
        AND start_time < UNIX_TIMESTAMP(@end_time)
    GROUP BY teacher_id
);



-- result

-- 老师ID - 姓名 - 日期 - 课时总数 – 被安排课数 – 请假次数 – 请假课数 - 迟到次数 – 迟到时长 – 受影响课数 – 旷工次数

SELECT tt.id
    , tt.english_name
    , IFNULL(c.total_class_cnt, 0) AS `总车位数`
    , IFNULL(t1.1v1_cnt, 0) + IFNULL(to4.o1v4_cnt, 0) + IFNULL(t4.1v4_cnt, 0) AS `总排课数`
    , IFNULL(ttl.leave_cnt, 0) AS `请假次数`
    , IFNULL(c.leave_class_cnt, 0) AS `请假课数`
    , IFNULL(t1.1v1_late_cnt, 0) + IFNULL(to4.o1v4_late_cnt, 0) + IFNULL(t4.1v4_late_cnt, 0) AS `迟到次数`
    , IFNULL(t1.1v1_late_secs, 0) + IFNULL(to4.o1v4_late_secs, 0) + IFNULL(t4.1v4_late_secs, 0) AS `迟到时长(秒)`
    , IFNULL(ta.ast_cnt, 0) AS `旷工次数`
    , IFNULL(c.ast_class_cnt, 0) AS `旷工课数`
FROM tmp_teacher AS tt
    LEFT JOIN tmp_tl AS ttl
        ON tt.id = ttl.teacher_id
    LEFT JOIN tmp_ast AS ta
        ON tt.id = ta.teacher_id
    LEFT JOIN tmp_1v1 AS t1
        ON tt.id = t1.teacher_id
    LEFT JOIN tmp_o1v4 AS to4
        ON tt.id = to4.teacher_id
    LEFT JOIN tmp_1v4 AS t4
        ON tt.id = t4.teacher_id
    LEFT JOIN (
        SELECT teacher_id
            , COUNT(*) AS total_class_cnt
            , COUNT(IF(is_leave = 1, 1 , NULL)) AS leave_class_cnt
            , COUNT(IF(is_ast = 1, 1 , NULL)) AS ast_class_cnt
        FROM tmp_teacher_slot_1
        GROUP BY teacher_id
    ) AS c
        ON tt.id = c.teacher_id;

DROP TABLE IF EXISTS tmp_teacher_slot_1;
```

**备注**

