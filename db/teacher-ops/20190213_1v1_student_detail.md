# 班主任1on1停课及未开课明细


**需求来源**

提出人: 帖嫚丽 <manli.tie@uuabc.com>

部门:

**拉取周期**
临时

**用途**


**详细**

```
```

**SQL**

```sql
drop table if exists tmp_students;
create temporary table tmp_students (
    select 
        a1.masterid as teacher_id
        ,a1.truename as teacher_name
        ,su.id as student_id
        ,su.name as student_name
        ,su.type as type1
    from newuuabc.admin as a1
    inner join newuuabc.student_user as su
    on  a1.masterid = su.assign_teacher
    and su.flag = 1  -- 1为真实用户
    and su.disable = 0  -- 0 不禁用
    inner join 
--        (select distinct
--            c.student_id
--        from newuuabc.contract as c
--        inner join newuuabc.contract_details as cd
--        on  c.id = cd.contract_id
--        and cd.subject_id = 1  -- 1:1
--        and cd.total > 0
--        where c.is_del = 1   -- 1 正常
--        and c.status = 4   -- 4 已付费
--        and c.contract_type = 1  -- 1销售合同
--        )   sc
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (1, 2)
        and total > 0
        )   sc
    on  su.id = sc.student_id
    where a1.masterid in (329, 343, 380, 398, 504, 631)   -- 只需要这几个老师的数据  去掉505
    and ((a1.masterid = 329
            and su.type in (1, 2)
            )
        or  (a1.masterid <> 329
            and su.type = 2
            )
        )
);

-- drop table if exists tmp_students_total;

-- create temporary table tmp_students_total (
--  select a1.masterid as teacher_id
--      , a1.truename as teacher_name
--      , su.id as student_id
--      , su.name as student_name
--  from newuuabc.admin as a1
--      inner join newuuabc.student_user as su
--          on a1.masterid = su.assign_teacher
--  where a1.dept in (select id from newuuabc.department where topid = 111 and status = 1)
--      and a1.disable = 2  -- 2不禁用
--      and su.flag = 1  -- 1为真实用户
--      and su.disable = 0  -- 0 不禁用
--  group by a1.masterid, a1.truename, su.id, su.name
-- );

-- 学员当天绑定车位数
drop table if exists tmp_student_class_bind;
create temporary table tmp_student_class_bind(
    select
        t1.student_user_id as student_id
        ,count(*) as bind_cnt
    from newuuabc.open_course_time t1
    left join
        newuuabc.open_course_time_details t2
    on  t1.id = t2.open_course_time_id
    where t1.is_check = 5
    and t1.is_end = 1
    and t1.course_type = 3
    and t2.`week` = dayofweek('2019-02-12') - 1
    group by t1.student_user_id
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
        and date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) <= '2019-02-12'
        )   as t
    group by t.student_id
);

-- 学员剩余正式课时数
drop table if exists tmp_remain_class;
create temporary table tmp_remain_class (
    select 
        sh.student_id
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
    where date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) > '2019-02-12'
    and ac.class_appoint_course_id = 0   -- 1:1
    and ac.disabled = 0  -- 0正常
    and ac.course_type = 3  -- 3 正式课
    and ac.subject_id = 1
    and ac.status < 3  -- 课程状态：0 待约课；1 约课中 2上课中 3已经上课
    group by ac.student_user_id
);


drop table if exists tmp_booked_class_max_date;
create temporary table tmp_booked_class_max_date(
    select
        student_user_id as student_id
        ,max(date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00'))) as max_date
    from newuuabc.appoint_course
    where class_appoint_course_id = 0
    and disabled = 0
    and course_type = 3
    and subject_id = 1
    and status < 3
    group by student_user_id
);

-- 当天分配到班主任名下的学员
drop table if exists tmp_teacher_changed;
create temporary table tmp_teacher_changed (
    select 
        t1.student_id
        ,t1.assign_teacher1
        ,t1.assign_teacher2
    from
        (select 
            id as student_id
            ,sum(case when partition_key = date_format('2019-02-12', '%Y%m%d') then flag else 0 end) as flag
            ,sum(case when partition_key = date_format('2019-02-12', '%Y%m%d') then disable else 0 end) as disable
            ,sum(case when partition_key = date_format('2019-02-12', '%Y%m%d') then assign_teacher else 0 end) as assign_teacher1
            ,sum(case when partition_key = date_format(date_sub('2019-02-12', interval 1 day), '%Y%m%d') then assign_teacher else 0 end) as assign_teacher2
        from bi.student_user_his
        where partition_key between date_format(date_sub('2019-02-12', interval 1 day), '%Y%m%d') and date_format('2019-02-12', '%Y%m%d')
        group by id
        )   as t1
    where t1.assign_teacher1 <> t1.assign_teacher2
    and t1.flag = 1 
    and t1.disable = 0
);


-- select * from tmp_teacher_changed;

-- ----------------------------------------------------------------------------

drop table if exists tmp_stat_student;
create temporary table tmp_stat_student (
    select 
        ts.teacher_id
        ,ts.teacher_name
        ,ts.student_id
        ,ts.student_name
        -- 开课学员 最近三周有上过正式课 且 剩余课时大于0
        ,case when tlc.student_id is not null 
                and coalesce(tlc.last_class_date, '2000-01-01') >= date_sub('2019-02-12', interval 21 day) 
                and (coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0)) > 0
            then 1 else 0 end
        as active_student_cnt
        -- 停课学员 最近三周没上过正式课 且 剩余课时大于0
        ,case when tlc.student_id is not null 
                and coalesce(tlc.last_class_date, '2000-01-01') < date_sub('2019-02-12', interval 21 day)
                and coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0) > 0
            then 1 else 0 end
        as inactive_student_cnt
        -- 未开课学员 课时大于0，没上过正式课
        ,case when coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0) > 0 
                and tlc.student_id is null 
            then 1 else 0 end
        as unstart_cnt
        -- 结课学员 上过正式课，当前正式课时为0
        ,case when coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0) = 0
                and tlc.student_id is not null 
                and tbcmd.max_date = '2019-02-12'
            then 1 else 0 end
        as class_over_student_cnt
    from tmp_students as ts
    left join tmp_last_class as tlc
    on  ts.student_id = tlc.student_id
    left join tmp_remain_class as tc
    on  ts.student_id = tc.student_id
    left join tmp_booked_class as tbc
    on  ts.student_id = tbc.student_id
    left join tmp_booked_class_max_date tbcmd
    on  ts.student_id = tbcmd.student_id
);
```

**备注**

