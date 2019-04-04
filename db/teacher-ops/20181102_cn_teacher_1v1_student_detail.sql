
set @stat_date = '2018-11-01';

-- 取制定老师的1v1学生
drop table if exists tmp_student_user;
create temporary table tmp_student_user as
select distinct
    su.id as student_id
    ,su.name as student_name
    ,a1.teacher_id
    ,a1.teacher_name
from newuuabc.student_user as su
inner join
    (select
        masterid as teacher_id
        ,truename as teacher_name
    from newuuabc.admin
    where masterid in (329, 343, 380, 398, 504, 505)  -- 指定老师
    )   a1
on  su.assign_teacher = a1.teacher_id
inner join newuuabc.contract as c
on su.id = c.student_id
inner join newuuabc.contract_details as cd
on c.id = cd.contract_id
where su.flag = 1  -- 1为真实用户
and su.disable = 0  -- 0 不禁用
and c.is_del = 1   -- 1 正常
and c.status in (4, 7)   -- 4 已付费
and c.contract_type = 1  -- 1销售合同
and cd.subject_id = 1  -- 1:1
and cd.total > 0
;

-- 计算学生最近上课日期及最早的正式课开课时间
drop table if exists tmp_student_class;
create temporary table tmp_student_class as
select
    t.student_id
    ,min(case when t.course_type = 3 then t.class_date end) as first_class_date
    ,max(t.class_date) as last_class_date
from
    (select
        student_user_id as student_id
        ,course_type
        ,date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) as class_date
    from newuuabc.appoint_course as ac
    -- where start_time >= unix_timestamp(convert_tz(date_sub(@stat_date, interval 1 month), '+08:00', '+00:00'))
    )   as t
group by t.student_id
;

-- 计算学生当前课时数
drop table if exists tmp_remain_class;
create temporary table tmp_remain_class as
select
    sh.student_id
    ,sum(sh.school_hour) as sh
from newuuabc.school_hour as sh
where sh.subject_id = 1  -- 1:1
group by sh.student_id
;


select
    ts.teacher_id
    ,ts.teacher_name
    ,ts.student_id
    ,ts.student_name
    ,tsc.first_class_date
    ,case when (tsc.student_id is not null and coalesce(tsc.last_class_date, '2000-01-01') >= date_sub(@stat_date, interval 21 day) and coalesce(tc.sh, 0) > 0)
            or (coalesce(tsc.last_class_date, '2000-01-01') >= @stat_date)
        then '在读' else '' end as active_student_cnt
    -- 开课学员 最近三周没课 且 剩余课时大于0
    ,case when tsc.student_id is not null and coalesce(tsc.last_class_date, '2000-01-01') < date_sub(@stat_date, interval 21 day)
            and coalesce(tc.sh, 0) > 0
        then '停课' else '' end as inactive_student_cnt
    -- 未开课学员 课时大于0
    ,case when coalesce(tc.sh, 0) > 0 and tsc.student_id is null then '未开课' else '' end as unstart_cnt
    -- 开课学员 剩余课时为0 且 最近三周没课
    ,case when coalesce(tc.sh, 0) = 0
                and tsc.student_id is not null and coalesce(tsc.last_class_date, '2000-01-01') < @stat_date
        then '结课' else '' end as class_over_student_cnt
from tmp_student_user as ts
left join tmp_student_class as tsc
on  ts.student_id = tsc.student_id
left join tmp_remain_class as tc
on  ts.student_id = tc.student_id
;

