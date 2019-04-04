# 1对1进入续费期学员


**需求来源**

提出人: 帖嫚丽 <manli.tie@uuabc.com>

部门:

**拉取周期**

临时

**用途**


**详细**

```
学生ID , 学生姓名，学生手机号，总课时，剩余课时，学生对应班主任姓名
```

**SQL**

```sql


set @stat_date := '2018-12-09';

-- 班主任对应的1对1学员
-- 学员已付费（未退费）的合同中若存在1对1主课课时数，那么该学员算是对应班主任的1对1学员
drop table if exists tmp_students;
create temporary table tmp_students (
    select 
        a1.masterid as teacher_id
        ,a1.truename as teacher_name
        ,su.id as student_id
        ,su.name as student_name
        ,su.phone as student_phone
    from newuuabc.admin as a1
    inner join newuuabc.student_user as su
    on  a1.masterid = su.assign_teacher
    and su.flag = 1  -- 1为真实用户
    and su.disable = 0  -- 0 不禁用
    inner join 
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (1, 2)
        and total > 0
        )   sc
    on  su.id = sc.student_id
    where a1.masterid in (329, 343, 380, 398, 505, 504)   -- 只需要这几个老师的数据
);


-- 学员最近一次1对1主课上课日期
drop table if exists tmp_last_class;
create temporary table tmp_last_class (
    select 
        t.student_id
        ,max(t.class_date) as last_class_date 
    from 
        (select 
            student_user_id as student_id
            ,date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) as class_date
        from newuuabc.appoint_course as ac
        where ac.course_type = 3  -- 正式课
        and ac.class_appoint_course_id = 0  -- 1:1课时
        and ac.subject_id = 1  -- 1:1主课
        and ac.disabled = 0 -- 正常
        and ac.status = 3  -- 已上课
        and date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) <= @stat_date
        )   as t
    group by t.student_id
);

-- 学员剩余正式课时数
drop table if exists tmp_remain_class;
create temporary table tmp_remain_class (
    select 
        sh.student_id
        ,sum(sh.total) as total
        ,sum(sh.school_hour) as sh
    from newuuabc.school_hour as sh
    where sh.subject_id = 1  -- 1:1
    group by sh.student_id
);

-- 学员剩余的1对1正式预订课时数
drop table if exists tmp_booked_class;
create temporary table tmp_booked_class (
    select 
        ac.student_user_id as student_id
        ,count(*) as booked_cnt
    from newuuabc.appoint_course as ac
    where date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) > @stat_date
    and ac.class_appoint_course_id = 0   -- 1:1
    and ac.disabled = 0  -- 0正常
    and ac.course_type = 3  -- 3 正式课
    and ac.subject_id = 1
    and ac.status < 3  -- 课程状态：0 待约课；1 约课中 2上课中 3已经上课
    group by ac.student_user_id
);

select 
    ts.student_id
    ,ts.student_name
    ,ts.teacher_id
    ,ts.teacher_name
    ,ts.student_phone
    ,tc.total
    ,tc.sh
    -- 进入续费期学员 上过正式课，正式课时小于等于12节
from tmp_students as ts
left join tmp_remain_class as tc
on  ts.student_id = tc.student_id
left join tmp_booked_class as tbc
on  ts.student_id = tbc.student_id
where tc.student_id is not null 
and (coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0)) > 0 
and (coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0)) <= 12 
;

```

**备注**

