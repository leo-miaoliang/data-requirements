
-- 老系统 1:1
select
    t1.teacher_user_id as '老师id'
    ,t2.english_name as '姓名'
    ,t3.start_time as '服务签约开始时间'
    ,t3.end_time as '服务签约结束时间'
    ,t1.id as '课程id'
    ,date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) as '日期'
    ,convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00') as '实际课时时间'
    ,convert_tz(from_unixtime(t4.teacher_into_time), '+00:00', '+08:00') as '实际进入时间'
    ,case when t5.id is not null or t4.teacher_into_time <= t1.start_time then 0 else t4.teacher_into_time - t1.start_time end as '迟到时长'
    ,case when t5.id is not null then '旷工' else '未旷工' end as '是否旷工'
from
    (select
        id
        ,teacher_user_id
        ,start_time
    from newuuabc.appoint_course
    where disabled = 0
    and course_type in (1, 3)
    )   t1
inner join
    newuuabc.teacher_user_new   t2
on  t1.teacher_user_id = t2.id
and t2.type = 1 -- 外教
and t2.status = 3 -- 全职签约老师
and t2.disable = 1 -- 有效
left join
    (select
        teacher_id
        ,convert_tz(from_unixtime(min(effective_start_time)), '+00:00', '+08:00') as start_time
        ,convert_tz(from_unixtime(max(effective_end_time)), '+00:00', '+08:00') as end_time
    from newuuabc.teacher_signed
    where status = 1
    and enable = 1
    group by teacher_id
    )   t3
on  t1.teacher_user_id = t3.teacher_id
left join
    newuuabc.course_details     t4
on  t1.id = t4.appoint_course_id
and t4.class_appoint_course_id = 0
left join
    newuuabc.teacher_absenteeism    t5
on  t1.teacher_user_id = t5.teacher_id
and t5.status <> 3
and unix_timestamp(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between t5.start_time and t5.end_time
where date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between 20180901 and 20180909

union all
-- 老系统 1:4 
select
    t1.teacher_user_id as '老师id'
    ,t2.english_name as '姓名'
    ,t3.start_time as '服务签约开始时间'
    ,t3.end_time as '服务签约结束时间'
    ,t1.id as '课程id'
    ,date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) as '日期'
    ,convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00') as '实际课时时间'
    ,convert_tz(from_unixtime(t1.teacher_into_time), '+00:00', '+08:00') as '实际进入时间'
    ,case when t4.id is not null or t1.teacher_into_time <= t1.start_time then 0 else t1.teacher_into_time - t1.start_time end as '迟到时长'
    ,case when t4.id is not null then '旷工' else '未旷工' end as '是否旷工'
from newuuabc.class_appoint_course  t1
inner join
    newuuabc.teacher_user_new   t2
on  t1.teacher_user_id = t2.id
and t2.type = 1 -- 外教
and t2.status = 3 -- 全职签约老师
and t2.disable = 1 -- 有效
left join
    (select
        teacher_id
        ,convert_tz(from_unixtime(min(effective_start_time)), '+00:00', '+08:00') as start_time
        ,convert_tz(from_unixtime(max(effective_end_time)), '+00:00', '+08:00') as end_time
    from newuuabc.teacher_signed
    where status = 1
    and enable = 1
    group by teacher_id
    )   t3
on  t1.teacher_user_id = t3.teacher_id
left join
    newuuabc.teacher_absenteeism    t4
on  t1.teacher_user_id = t4.teacher_id
and t4.status <> 3
and unix_timestamp(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between t4.start_time and t4.end_time
where t1.course_type in (1, 3)
and t1.disabled = 0
and date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between 20180901 and 20180909

-- 新系统
union all
select
    t1.teacher_id as '老师id'
    ,t3.english_name as '姓名'
    ,t2.start_time as '服务签约开始时间'
    ,t2.end_time as '服务签约结束时间'
    ,t1.room_id as '课程id'
    ,date(from_unixtime(t1.start_time)) as '日期'
    ,from_unixtime(t1.start_time) as '实际课时时间'
    ,from_unixtime(t1.teacher_entry_time) as '实际进入时间'
    ,case when t4.id is not null or t1.teacher_entry_time <= t1.start_time then 0 else t1.teacher_entry_time - t1.start_time end as '迟到时长'
    ,case when t4.id is not null then '旷工' else '未旷工' end as '是否旷工'
from classbooking.classroom  t1
left join
    (select
        teacher_id
        ,convert_tz(from_unixtime(min(effective_start_time)), '+00:00', '+08:00') as start_time
        ,convert_tz(from_unixtime(max(effective_end_time)), '+00:00', '+08:00') as end_time
    from newuuabc.teacher_signed
    where status = 1
    and enable = 1
    group by teacher_id
    )   t2
on  t1.teacher_id = t2.teacher_id
inner join
    newuuabc.teacher_user_new   t3
on  t1.teacher_id = t3.id
and t3.type = 1 -- 外教
and t3.status = 3 -- 全职签约老师
and t3.disable = 1 -- 有效
left join
    newuuabc.teacher_absenteeism    t4
on  t1.teacher_id = t4.teacher_id
and t4.status <> 3
and t1.start_time between t4.start_time and t4.end_time
where date(from_unixtime(t1.start_time)) between 20180901 and 20180909
;