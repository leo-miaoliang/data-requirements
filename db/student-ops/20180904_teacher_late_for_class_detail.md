# 每日老师上课迟到数据报表


**需求来源**

提出人: 胡新星 <xinxing.hu@uuabc.com>

部门:

**拉取周期**

9月5日——9月30日每天上午11点

**用途**


**详细**

```
报表提交时间：9月5日——9月30日每天上午11点
拉取数据日期范围：每日拉取前一天的数据
课程范围：一对一  已上课  正式课
数据维度：课程ID、学生姓名、班主任、外教ID、外教姓名、外教迟到时长
维度解释：外教迟到时长=外教进入教室时间-标准上课起始时间
```

**SQL**

```sql


set @date1 := '2018-09-19';
set @date2 := '2018-09-19';
-- 新1对4
select
    date(from_unixtime(t1.start_time)) as '日期'
    ,t1.student_class_id as '课程id'
    -- ,t1.room_id
    -- ,t1.student_id
    ,t3.name as '学生姓名'
    ,t4.truename as '班主任'
    ,t1.teacher_id as '外教id'
    ,t5.english_name as '外教姓名'
    -- ,t1.start_time
    -- ,t1.end_time
    ,t1.start_time1 as '车位开始时间'
    ,from_unixtime(t2.teacher_entry_time) as '外教进入教室时间'
    ,t1.end_time1 as '车位结束时间'
    ,from_unixtime(t2.teacher_leave_time) as '外教离开教室时间'
    ,case when coalesce(t2.teacher_entry_time, 0) < t1.start_time then 0 else coalesce(t2.teacher_entry_time, 0) - t1.start_time end as '外教迟到时长'
-- select
--     t1.student_class_id
--     ,t1.room_id
--     ,t1.student_id
--     ,t1.teacher_id
--     ,count(*)
from
    (select
        student_class_id
        ,room_id
        ,student_id
        ,teacher_id
        ,start_time
        ,end_time
        ,from_unixtime(start_time) as start_time1
        ,from_unixtime(end_time) as end_time1
    from classbooking.student_class
    where status = 3
    and date(from_unixtime(start_time)) between @date1 and @date2
    )   t1
left join
    classbooking.classroom  t2
on  t1.room_id = t2.room_id
inner join
    newuuabc.student_user   t3
on  t1.student_id = t3.id
and t3.flag = 1
left join
    newuuabc.admin  t4
on  t3.assign_teacher = t4.masterid
left join
    newuuabc.teacher_user_new   t5
on  t1.teacher_id = t5.id

union all

-- 老1对4
select
    t1.date1 as '日期'
    ,t1.id as '课程id'
    -- ,t1.student_user_id
    ,t3.name as '学生姓名'
    -- ,t3.assign_teacher
    ,t5.truename as '班主任'
    ,t1.teacher_user_id as '外教id'
    ,t6.english_name as '外教姓名'
    ,convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00') as '车位开始时间'
    ,convert_tz(from_unixtime(t1.teacher_into_time), '+00:00', '+08:00') as '外教进入教室时间'
    ,convert_tz(from_unixtime(t1.end_time), '+00:00', '+08:00') as '车位结束时间'
    ,convert_tz(from_unixtime(t1.teacher_out_time), '+00:00', '+08:00') as '外教离开教室时间'
    -- ,t1.start_time as ''
    -- ,t1.teacher_into_time
    ,case when t1.teacher_into_time <= t1.start_time then 0
        else t1.teacher_into_time - t1.start_time
    end as '外教迟到时长'
from
    (select
        t1.id
        ,t1.student_user_id
        ,t1.teacher_user_id
        ,t1.start_time
        ,t1.end_time
        ,t2.teacher_into_time
        ,t2.teacher_out_time
        ,t1.attributes
        ,t1.disabled
        ,date(convert_tz(FROM_UNIXTIME(t1.start_time), '+00:00', '+08:00')) as date1
    from newuuabc.appoint_course    t1
    left join
        newuuabc.class_appoint_course t2
    on  t1.class_appoint_course_id = t2.id
    -- and t2.class_appoint_course_id = 0   --
    where t1.course_type = 3  -- 正式课
    and t1.status = 3  -- 已上课
    and t1.class_appoint_course_id <> 0
    and t1.disabled = 0  -- 0正常
    -- AND t1.start_time >= UNIX_TIMESTAMP(CONVERT_TZ(@date1, '+08:00', '+00:00'))
    -- AND t1.start_time < UNIX_TIMESTAMP(CONVERT_TZ(@date2, '+08:00', '+00:00'))
    and date(convert_tz(from_unixtime(t1.start_time), '+00:00', +'08:00')) between @date1 and @date2
    )   t1
-- inner join
--     (select distinct
--         student_id
--     from newuuabc.contract
--     where is_del = 1
--     and status = 4
--     )   t2
-- on  t1.student_user_id = t2.student_id
inner join
    newuuabc.student_user   t3
on  t1.student_user_id = t3.id
and t3.flag = 1   -- 去除测试数据
left join
    newuuabc.admin  t5
on  t3.assign_teacher = t5.masterid
left join
    newuuabc.teacher_user_new   t6
on  t1.teacher_user_id = t6.id

union all

select
    date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) as '日期'
    ,t1.id as '课程id'
    -- ,t1.student_user_id
    ,t3.name as '学生姓名'
    -- ,t3.assign_teacher
    ,t5.truename as '班主任'
    ,t1.teacher_user_id as '外教id'
    ,t6.english_name as '外教姓名'
    ,convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00') as '车位开始时间'
    ,convert_tz(from_unixtime(t1.teacher_into_time), '+00:00', '+08:00') as '外教进入教室时间'
    ,convert_tz(from_unixtime(t1.end_time), '+00:00', '+08:00') as '车位结束时间'
    ,convert_tz(from_unixtime(t1.teacher_out_time), '+00:00', '+08:00') as '外教离开教室时间'
    -- ,t1.start_time as ''
    -- ,t1.teacher_into_time
    ,case when t1.teacher_into_time <= t1.start_time then 0
        else t1.teacher_into_time - t1.start_time
    end as '外教迟到时长'
from
    (select
        t1.id
        ,t1.student_user_id
        ,t1.teacher_user_id
        ,t1.start_time
        ,t1.end_time
        ,t2.teacher_into_time
        ,t2.teacher_out_time
        ,t1.attributes
        ,t1.disabled
    from newuuabc.appoint_course    t1
    left join
        newuuabc.course_details t2
    on  t1.id = t2.appoint_course_id
    and t2.class_appoint_course_id = 0   --
    where t1.course_type = 3  -- 正式课
    and t1.status = 3  -- 已上课
    and t1.class_appoint_course_id = 0
    and t1.disabled = 0  -- 0正常
    -- AND t1.start_time >= UNIX_TIMESTAMP(CONVERT_TZ(@date1, '+08:00', '+00:00'))
    -- AND t1.start_time < UNIX_TIMESTAMP(CONVERT_TZ(@date2, '+08:00', '+00:00'))
    and date(convert_tz(from_unixtime(t1.start_time), '+00:00', +'08:00')) between @date1 and @date2
    -- and date(from_unixtime(t1.start_time)) = 20180904
    )   t1
-- inner join
--     (select distinct
--         student_id
--     from newuuabc.contract
--     where is_del = 1
--     and status = 4
--     )   t2
-- on  t1.student_user_id = t2.student_id
inner join
    newuuabc.student_user   t3
on  t1.student_user_id = t3.id
and t3.flag = 1   -- 去除测试数据
left join
    newuuabc.admin  t5
on  t3.assign_teacher = t5.masterid
left join
    newuuabc.teacher_user_new   t6
on  t1.teacher_user_id = t6.id
;
```

**备注**

