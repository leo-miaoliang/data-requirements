# 老师车位绑定时间与约课时间匹配度


**需求来源**

提出人: 胡新星 <xinxing.hu@uuabc.com>

部门:

**拉取周期**

9月5日、9月16日、9月30日

**用途**


**详细**

```
拉取数据范围：所有一对一付费学员绑定的老师和车位&绑定学生最近一个月的约课情况
数据维度：学生姓名、班主任、顾问、绑定老师、绑定车位时间段、每个绑定车位时间段正式课上课节数
```

**SQL**

```sql
select
    t1.student_user_id
    ,t2.name as student_name
    ,t3.truename as class_teacher_name
    ,t4.truename as consultant_name
    ,t1.teacher_user_id
    ,t5.english_name
    ,t1.week
    ,sec_to_time(t1.start_time4 * 60) as start_time
    ,sec_to_time(t1.end_time4 * 60) as end_time
    ,count(*)
from
    (select   -- 老师id为0
        t1.teacher_user_id
        ,t1.student_user_id
        ,from_unixtime(t1.bind_start_time) as bind_start_time
        ,from_unixtime(t1.plan_end_time) as plan_end_time
        ,t2.week
        ,t2.start_time
        ,concat(t3.date1, ' ', sec_to_time(t2.start_time * 60)) as start_time1
        ,t4.start_time as start_time4
        ,t4.end_time  as end_time4
    from newuuabc.open_course_time  t1
    left join
        newuuabc.open_course_time_details    t2
    on  t1.id = t2.open_course_time_id
    left join
        (select
            date1
            ,bi.get_weekday(date1) as week1
        from bi.tmp_dim_date
        where date1 between 20180805 and 20180904
        )   t3
    on  t2.week = t3.week1
    left join
        newuuabc.carport_slot   t4
    on  t2.start_time = t4.start_time
    where t1.course_type = 3
    and t1.is_end in (1, 3)
    and t3.date1 between date(from_unixtime(t1.bind_start_time)) and date(from_unixtime(t1.plan_end_time))
    )   t1
inner join
    newuuabc.student_user   t2
on  t1.student_user_id = t2.id
and t2.flag = 1 -- 真实用户
left join
    newuuabc.admin  t3
on  t2.assign_teacher = t3.masterid
left join
    newuuabc.admin  t4
on  t2.assign_consultant = t4.masterid
left join
    newuuabc.teacher_user_new   t5
on  t1.teacher_user_id = t5.id
inner join
    (select
        student_user_id
        ,start_time
        ,convert_tz(from_unixtime(start_time), '+00:00', '+08:00') as start_time1
    from newuuabc.appoint_course
    where course_type = 3
    and disabled = 0
    and date(convert_tz(from_unixtime(start_time), '+08:00', '+00:00')) between 20180601 and 20180905
    )   t7
on  t1.student_user_id = t7.student_user_id
and t1.start_time1 = t7.start_time1
group by
    t1.student_user_id
    ,t2.name
    ,t3.truename
    ,t4.truename
    ,t1.teacher_user_id
    ,t5.english_name
    ,t1.week
    ,sec_to_time(t1.start_time4 * 60)
    ,sec_to_time(t1.end_time4 * 60)
;
```

**备注**

