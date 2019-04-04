# 每日课件未完成 数据报表


**需求来源**

提出人: 胡新星 <xinxing.hu@uuabc.com>

部门:

**拉取周期**

9月5日——9月30日每天上午11点

**用途**


**详细**

```
报表提交时间：9月5日——9月30日每天上午11点
拉取数据日期范围：每日拉取前一天数据
课程范围：一对一  已上课  正式课
数据维度：课程ID、学生姓名、班主任、外教ID、外教姓名、课件、课程等级、当前课件总页码、当堂课已完成页码
```

**SQL**

```sql
SELECT ac.id AS `课程ID`
    , su.english_name AS `学生姓名`
    , a.truename AS `班主任`
    , ac.teacher_user_id AS `外教ID`
    , tun.english_name AS `外教姓名`
    , c.courseware_name AS `课件`
    , ct.course_name AS `课程等级`
    , ac.opt_page AS `当堂课已完成页码`
    , c.courseware_page AS `当前课件总页码`
FROM newuuabc.appoint_course AS ac
INNER JOIN newuuabc.student_user AS su
    ON ac.student_user_id = su.id
LEFT JOIN newuuabc.admin AS a
    ON su.assign_teacher = a.masterid
LEFT JOIN newuuabc.teacher_user_new AS tun
    ON ac.teacher_user_id = tun.id
LEFT JOIN newuuabc.courseware AS c
    ON ac.courseware_id = c.id
LEFT JOIN newuuabc.course_type AS ct
    ON ac.course_level = ct.id
WHERE ac.class_appoint_course_id = 0
AND ac.course_type = 3
AND ac.status = 3
AND ac.disabled = 0
AND ac.start_time >= UNIX_TIMESTAMP(CONVERT_TZ('2018-09-04', '+08:00', '+00:00'))
AND ac.start_time < UNIX_TIMESTAMP(CONVERT_TZ('2018-09-05', '+08:00', '+00:00'))
;
```

**备注**

