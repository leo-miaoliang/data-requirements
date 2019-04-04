# 督导绩效


**需求来源**

提出人: 傅尹莉<yinli.fu@uuabc.com>

部门:

**拉取周期**
每月


**用途**


**详细**

```
```

**SQL**

```sql
-- 替换日期将之前的统计周期改为当前的统计周期

use bi;

drop table if exists tmp_teacher;

create temporary table tmp_teacher
(
    teacher_id int
    ,teacher_name varchar(20)
    ,teacher_type int
);


-- 这个数据每个月让傅老师提供一次
insert into tmp_teacher values
(329,'杨海霞',1)
,(380,'朱书颖',1)
,(388,'陈佳静',4)
,(398,'卜柳',1)
,(399,'林敏',4)
,(401,'李许多',4)
,(405,'姚晶晶',4)
,(425,'王利斌',4)
,(445,'张娇娇',4)
,(446,'吕研科',4)
,(447,'程显梅',4)
,(460,'施雪娇',4)
,(461,'张雯娜',4)
,(468,'和涛',4)
,(483,'杨东亚',4)
,(493,'葛志远',4)
,(504,'盛贝麒',1)
,(505,'顾艳梅',1)
,(581,'熊鸣',4)
,(599,'范蕊',4)
,(600,'刘峰',4)
,(611,'刘雅',4)
,(618,'陈颖',4)
,(619,'丁冉',4)
,(630,'杜昊聪',4)
,(631,'王启迪',1)
;


drop table if exists tmp_student_contract_min_date;
create temporary table tmp_student_contract_min_date as
select
    student_id
    ,min(date1) as date1
from
    (select
        student_id
        ,date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) as date1
    from newuuabc.contract
    where status = 4
    and contract_type = 1
    -- and contract_amount > 0
    )   t1
group by t1.student_id
;


-- 上一个周期开始时的课时数据
drop table if exists tmp_student_hours_record_previous;
create temporary table tmp_student_hours_record_previous
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,key k1(student_id, date1)
);
insert into tmp_student_hours_record_previous
select
    t1.student_id
    ,t1.subject_id
    ,'2018-12-31' as date1
    ,t2.after_hours
from
    (select
        student_user_id as student_id
        ,subject_id
        -- ,date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) as date1
        ,max(id) as max_id
    from newuuabc.student_hours_record
    where subject_id in (1, 7)
    and date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) <= '2018-12-31'
    group by student_user_id, subject_id
    )   t1
left join
    newuuabc.student_hours_record t2
on  t1.max_id = t2.id
-- inner join
--  tmp_student_contract_min_date t3
-- on   t1.student_id = t3.student_id
;

-- 当前周期的开始时的课时数据
drop table if exists tmp_student_hours_record_current;
create temporary table tmp_student_hours_record_current
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,key k1(student_id, date1)
);
insert into tmp_student_hours_record_current
select
    t1.student_id
    ,t1.subject_id
    ,'2019-01-28' as date1
    ,t2.after_hours
from
    (select
        student_user_id as student_id
        ,subject_id
        -- ,date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) as date1
        ,max(id) as max_id
    from newuuabc.student_hours_record
    where subject_id in (1, 7)
    and date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) <= '2019-01-28'
    group by student_user_id, subject_id
    )   t1
left join
    newuuabc.student_hours_record t2
on  t1.max_id = t2.id
-- inner join
--  tmp_student_contract_min_date t3
-- on   t1.student_id = t3.student_id
;


-- 两个周期开始时的课时区别
drop table if exists tmp_student_hours_record_diff;
create temporary table tmp_student_hours_record_diff
(
    student_id int
    ,cnt_1v1_previous int
    ,cnt_1v1_current int
    ,cnt_1v4_previous int
    ,cnt_1v4_current int
    ,key k1(student_id)
);
insert into tmp_student_hours_record_diff
select
    t1.student_id
    ,sum(t1.cnt_1v1_previous) as cnt_1v1_previous
    ,sum(t1.cnt_1v1_current) as cnt_1v1_current
    ,sum(t1.cnt_1v4_previous) as cnt_1v4_previous
    ,sum(t1.cnt_1v4_current) as cnt_1v4_current
from
    (select
        student_id
        ,sum(case when subject_id = 1 then after_hours else 0 end) as cnt_1v1_previous
        ,sum(case when subject_id = 7 then after_hours else 0 end) as cnt_1v4_previous
        ,0 as cnt_1v1_current
        ,0 as cnt_1v4_current
    from tmp_student_hours_record_previous
    group by student_id
    union all
    select
        student_id
        ,0 as cnt_1v1_before
        ,0 as cnt_1v4_before
        ,sum(case when subject_id = 1 then after_hours else 0 end) as cnt_1v1_current
        ,sum(case when subject_id = 7 then after_hours else 0 end) as cnt_1v4_current
    from tmp_student_hours_record_current
    group by student_id
    )   t1
group by t1.student_id
;


-- 每天课时的最后一条记录
drop table if exists tmp_student_hours_record;
create temporary table tmp_student_hours_record
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,key k1(student_id, date1)
);
insert into tmp_student_hours_record
select
    t1.student_id
    ,t1.subject_id
    ,t1.date1
    ,t2.after_hours
from
    (select
        student_user_id as student_id
        ,subject_id
        ,date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) as date1
        ,max(id) as max_id
    from newuuabc.student_hours_record
    where subject_id in (1, 7)
    group by student_user_id, subject_id, date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00'))
    )   t1
left join
    newuuabc.student_hours_record t2
on  t1.max_id = t2.id
-- inner join
--  tmp_student_contract_min_date t3
-- on   t1.student_id = t3.student_id
;


-- 将学生的课时记录处理成每天一条记录
drop table if exists tmp_student_hours_record_1;
create temporary table tmp_student_hours_record_1
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,key k1(student_id, date1)
);
insert into tmp_student_hours_record_1
select
    student_id
    ,subject_id
    ,date1
    ,after_hours
from tmp_student_hours_record
;


drop table if exists tmp_student_hours_record_2;
create temporary table tmp_student_hours_record_2
(
    student_id int
    ,subject_id int
    ,start_date date
    ,start_hours int
    ,end_date date
    ,key k1(student_id, end_date)
);
insert into tmp_student_hours_record_2
select
    t1.student_id
    ,t1.subject_id
    ,t1.date1 as start_date
    ,t1.after_hours as start_hours
    ,coalesce(min(t2.date1), '2999-12-31') as end_date
from tmp_student_hours_record t1
left join
    tmp_student_hours_record_1 t2
on  t1.student_id = t2.student_id
and t1.subject_id = t2.subject_id
and t1.date1 < t2.date1
group by t1.student_id, t1.subject_id, t1.date1, t1.after_hours
;


-- select
--     *
-- from tmp_student_hours_record_2
-- -- where student_id = 292
-- ;

drop table if exists tmp_student_hours_record_3;
create temporary table tmp_student_hours_record_3
(
    student_id int
    ,subject_id int
    ,start_date date
    ,start_hours int
    ,end_date date
    ,end_hours int
    ,key k1(student_id)
);
insert into tmp_student_hours_record_3
select
    t1.student_id
    ,t1.subject_id
    ,t1.start_date
    ,t1.start_hours
    ,t1.end_date
    ,coalesce(t2.after_hours, t1.start_hours) as end_hours
from tmp_student_hours_record_2 t1
left join
    tmp_student_hours_record_1 t2
on  t1.student_id = t2.student_id
and t1.subject_id = t2.subject_id
and t1.end_date = t2.date1
;


-- select
--     *
-- from tmp_student_hours_record_3
-- ;

-- select
--     *
-- from tmp_student_hours_record_1
-- where student_id = 289
-- and subject_id = 1
-- ;

drop table if exists tmp_student_hours_record_4;
create temporary table tmp_student_hours_record_4
(
    student_id int
    ,subject_id int
    ,date1 date
    ,key k1(student_id, date1)
);
insert into tmp_student_hours_record_4
select
    t1.student_id
    ,t2.subject_id
    ,t3.date1
from
    (select distinct
        student_id
    from tmp_student_hours_record
    )   t1
join
    (select
        1 as subject_id
    union all
    select
        7 as subject_id
    )   t2
join
    (select
        date1
    from bi.dim_date
    where date1 between '2019-01-28' and '2019-02-24'
    )   t3
;

drop table if exists tmp_student_hours_record_5;
create temporary table tmp_student_hours_record_5
(
    student_id int
    ,subject_id int
    ,date1 date
    ,hours int
    ,key k1(student_id, date1)
);
insert into tmp_student_hours_record_5
select
    t1.student_id
    ,t1.subject_id
    ,t1.date1
    ,coalesce(t2.start_hours, 0) as hours
from tmp_student_hours_record_4 t1
left join
    tmp_student_hours_record_3 t2
on  t1.student_id = t2.student_id
and t1.subject_id = t2.subject_id
and t1.date1 >= t2.start_date
and t1.date1 < t2.end_date
;

-- select
--     *
-- from tmp_student_hours_record_3
-- where student_id = 292
-- and subject_id = 7
-- ;


-- select
--     *
-- from tmp_student_hours_record_5
-- ;


drop table if exists tmp_student_intime_after_hours;
create table tmp_student_intime_after_hours as
select
    t3.student_id
    ,t3.date1
    ,sum(case when t3.subject_id = 1 then t3.after_hours else 0 end) as after_hours_1v1
    ,sum(case when t3.subject_id = 7 then t3.after_hours else 0 end) as after_hours_1v4
from
    (select
        t1.student_id
        ,t1.subject_id
        ,'2019-01-28' as date1
        ,t2.after_hours
    from
        (select
            student_user_id as student_id
            ,subject_id
            ,max(id) as max_id
        from newuuabc.student_hours_record
        where date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) <= '2019-01-28'
        and subject_id in (1, 7)
        group by student_user_id, subject_id
        )   t1
    inner join
        newuuabc.student_hours_record t2
    on  t1.max_id = t2.id
    union all
    select
        t1.student_id
        ,t1.subject_id
        ,'2019-02-24' as date1
        ,t2.after_hours
    from
        (select
            student_user_id as student_id
            ,subject_id
            ,max(id) as max_id
        from newuuabc.student_hours_record
        where date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) <= '2019-02-24'
        and subject_id in (1, 7)
        group by student_user_id, subject_id
        )   t1
    inner join
        newuuabc.student_hours_record t2
    on  t1.max_id = t2.id
    )   t3
group by t3.student_id, t3.date1
;


drop table if exists tmp_teacher_student_start;
create temporary table tmp_teacher_student_start as
select
    t3.teacher_id
    ,t3.teacher_name
    ,t3.student_id
    ,t3.student_name
    ,t3.date1
    ,case when t8.student_id is not null and t8.date1 <= '2019-01-28' then coalesce(t7.after_hours_1v1, 0) else 0 end as cnt_1v1
    ,case when t8.student_id is not null and t8.date1 <= '2019-01-28' then coalesce(t7.after_hours_1v4, 0) else 0 end as cnt_1v4
from
    (select
        t1.student_id
        ,t1.student_name
        ,t1.teacher_id
        ,coalesce(t2.teacher_name, '') as teacher_name
        ,t1.date1
    from
        (select
            id as student_id
            ,name as student_name
            ,assign_teacher as teacher_id
            ,'2019-01-28' as date1
        from bi.student_user_his
        where partition_key = date_format('2019-01-28', '%Y%m%d')
        and flag = 1
        and disable = 0
        )   t1
    inner join
        tmp_teacher t2
    on  t1.teacher_id = t2.teacher_id
    )   t3
left join
    (select
        *
    from tmp_student_intime_after_hours
    where date1 = '2019-01-28'
    )   t7
on  t3.student_id = t7.student_id
left join
    tmp_student_contract_min_date t8
on  t3.student_id = t8.student_id
;


-- select
--  *
-- from tmp_teacher_student_end
-- ;


drop table if exists tmp_teacher_student_end;
create temporary table tmp_teacher_student_end as
select
    t3.teacher_id
    ,t3.teacher_name
    ,t3.student_id
    ,t3.student_name
    ,t3.date1
    ,case when t8.student_id is not null and t8.date1 <= '2019-02-24' then coalesce(t7.after_hours_1v1, 0) else 0 end as cnt_1v1
    ,case when t8.student_id is not null and t8.date1 <= '2019-02-24' then coalesce(t7.after_hours_1v4, 0) else 0 end as cnt_1v4
from
    (select
        t1.student_id
        ,t1.student_name
        ,t1.teacher_id
        ,coalesce(t2.teacher_name, '') as teacher_name
        ,t1.date1
    from
        (select
            id as student_id
            ,name as student_name
            ,assign_teacher as teacher_id
            ,'2019-02-24' as date1
        from bi.student_user_his
        where partition_key = date_format('2019-02-24', '%Y%m%d')
        and flag = 1
        and disable = 0
        )   t1
    inner join
        tmp_teacher t2
    on  t1.teacher_id = t2.teacher_id
    )   t3
left join
    tmp_student_intime_after_hours  t7
on  t3.student_id = t7.student_id
and t3.date1 = t7.date1
left join
    tmp_student_contract_min_date t8
on  t3.student_id = t8.student_id
;


-- 当前周期开始时老师所带学员数
select
    t1.teacher_id
    ,t1.teacher_name
    ,coalesce(t2.cnt1v1, 0)
    ,coalesce(t2.cnt1v4, 0)
from tmp_teacher t1
left join
    (select
        teacher_id
        ,teacher_name
        ,sum(case when date1 = '2019-01-28' and cnt_1v1 > 0 then 1 else 0 end) as cnt1v1  -- 带1v1学员数
        ,sum(case when date1 = '2019-01-28' and cnt_1v4 > 0 then 1 else 0 end) as cnt1v4  -- 带1v1学员数
    from tmp_teacher_student_start
    group by teacher_id, teacher_name
    )   t2
on  t1.teacher_id = t2.teacher_id
order by t1.teacher_id
;

-- 当前周期结束时老师所带学员数
select
    t1.teacher_id
    ,t1.teacher_name
    ,coalesce(t2.cnt1v1, 0)
    ,coalesce(t2.cnt1v4, 0)
from tmp_teacher t1
left join
    (select
        teacher_id
        ,teacher_name
        ,sum(case when date1 = '2019-02-24' and cnt_1v1 > 0 then 1 else 0 end) as cnt1v1  -- 带1v4学员数
        ,sum(case when date1 = '2019-02-24' and cnt_1v4 > 0 then 1 else 0 end) as cnt1v4  -- 带1v4学员数
    from tmp_teacher_student_end
    group by teacher_id, teacher_name
    )   t2
on  t1.teacher_id = t2.teacher_id
order by t1.teacher_id
;



-- 老师每天所带学员课时数
drop table if exists tmp_teacher_student_everyday;
create temporary table tmp_teacher_student_everyday
(
    student_id int
    ,student_name varchar(40)
    ,teacher_id int
    ,teacher_name varchar(40)
    ,teacher_type varchar(20)
    ,channel int
    ,is_zhihui int
    ,date1 date
    ,cnt_1v1 int
    ,cnt_1v4 int
    ,key k1(student_id, date1)
)
;
insert into tmp_teacher_student_everyday
select
    t1.student_id
    ,t1.student_name
    ,t1.teacher_id
    ,coalesce(t4.teacher_name, 0) as teacher_name
    ,t4.teacher_type
    ,t1.channel
    ,case when t3.id is not null then 1 else 0 end as is_zhihui
    ,t1.date1
    ,coalesce(t2.cnt_1v1, 0) as cnt_1v1
    ,coalesce(t2.cnt_1v4, 0) as cnt_1v4
from
    (select
        id as student_id
        ,name as student_name
        ,channel
        ,assign_teacher as teacher_id
        ,partition_key as date1
    from bi.student_user_his
    where partition_key between date_format('2019-01-28', '%Y%m%d') and date_format('2019-02-24', '%Y%m%d')
    and flag = 1
    and disable = 0
    and assign_teacher > 0
    )   t1
left join
    (select
        student_id
        ,date1
        ,sum(case when subject_id = 1 then hours else 0 end) as cnt_1v1
        ,sum(case when subject_id = 7 then hours else 0 end) as cnt_1v4
    from tmp_student_hours_record_5
    group by student_id, date1
    )   t2
on  t1.student_id = t2.student_id
and t1.date1 = t2.date1
left join
    (select
        t1.id
    from newuuabc.channel_list  t1
    left join
        newuuabc.channel_list   t2
    on  t1.pid = t2.id
    left join
        newuuabc.channel_list   t3
    on  t2.pid = t3.id
    left join
        newuuabc.channel_list   t4
    on  t3.pid = t4.id
    where t1.id = 339
    or t2.id = 339
    or t3.id = 339
    or t4.id = 339
    )   t3
on  t1.channel = t3.id
inner join
    tmp_teacher t4
on  t1.teacher_id = t4.teacher_id
;


select
    t5.teacher_id
    ,t6.cnt_1v1
    ,t6.cnt_1v4
    ,t6.cnt_quality
    ,t6.contract_amt
    ,t6.zhihui_pay_cnt
from tmp_teacher t5
left join
    (select
        t4.teacher_id  -- 老师id
        ,sum(t4.cnt_1v1) as cnt_1v1  -- 所带1v1学员完成课时数
        ,sum(t4.cnt_1v4) as cnt_1v4  -- 所带1v4付费学员完成课时数
        ,sum(t4.cnt_quality) as cnt_quality  -- 所带学员完成素质课课时数
        ,round(sum(t4.contract_amount) / 100, 2) as contract_amt  -- 所带学员续费金额
        ,sum(case when t4.is_zhihui = 1 and t4.is_pay = 1 then 1 else 0 end) as zhihui_pay_cnt  -- 来自至慧渠道的视听学员付费人数
    from
        (select
            t1.student_id
            ,t1.teacher_id
            ,t1.date1
            ,t1.is_zhihui
            ,coalesce(t3.cnt_1v1, 0) as cnt_1v1
            ,coalesce(t3.cnt_1v4, 0) as cnt_1v4
--          ,case when t1.cnt_1v1 > 0 then coalesce(t3.cnt_1v1, 0) else 0 end as cnt_1v1
--          ,case when t1.cnt_1v4 > 0 then coalesce(t3.cnt_1v4, 0) else 0 end as cnt_1v4
            ,coalesce(t3.cnt_quality, 0) as cnt_quality
            ,case when t5.student_id is not null then 1 else 0 end as is_pay
            ,coalesce(t6.contract_amount, 0) as contract_amount
        from
            (select
                *
            from tmp_teacher_student_everyday
            where date1 between '2019-01-28' and '2019-02-24'
            )   t1
        left join
            (select
                t2.student_id
                ,t2.date1
                ,sum(case when t2.type1 = '1v1' then t2.cnt1 else 0 end) as cnt_1v1
                ,sum(case when t2.type1 in ('1v4_old', '1v4_new') then t2.cnt1 else 0 end) as cnt_1v4
                ,sum(case when t2.type1 = '1v4_quality' then t2.cnt1 else 0 end) as cnt_quality
            from
                (select
                    student_user_id as student_id
                    ,date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) as date1
                    ,count(*) as cnt1
                    ,'1v1' as type1
                from newuuabc.appoint_course
                where class_appoint_course_id = 0
                and disabled = 0
                and course_type = 3
                and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between '2019-01-28' and '2019-02-24'
                group by student_user_id, date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00'))
                union all
                select
                    student_user_id as student_id
                    ,date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) as date1
                    ,count(*) as cnt
                    ,'1v4_old' as type1
                from newuuabc.appoint_course
                where class_appoint_course_id > 0
                and disabled = 0
                and course_type = 3
                and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between '2019-01-28' and '2019-02-24'
                group by student_user_id, date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00'))
                union all
                select
                    student_id
                    ,date(from_unixtime(start_time)) as date1
                    ,count(*) as cnt
                    ,'1v4_new' as type1
                from classbooking.student_class
                where status = 3
                and class_type = 1
                and date(from_unixtime(start_time)) between '2019-01-28' and '2019-02-24'
                group by student_id, date(from_unixtime(start_time))
                union all
                select
                    student_id
                    ,date(from_unixtime(start_time)) as date1
                    ,count(*) as cnt
                    ,'1v4_quality' as type1
                from classbooking.student_class
                where status = 3
                and class_type = 5
                and date(from_unixtime(start_time)) between '2019-01-28' and '2019-02-24'
                group by student_id, date(from_unixtime(start_time))
                )   t2
            group by t2.student_id, t2.date1
            )   t3
        on  t1.student_id = t3.student_id
        and t1.date1 = t3.date1
        left join
            (select
                student_id
                ,min(date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00'))) as date1
            from newuuabc.contract
    --      where date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between '2019-01-28' and '2019-02-24'
            where contract_type = 1 -- 销售合同
            and status = 4  -- 已付费
            and is_del = 1  -- 正常
            group by student_id
            )   t5
        on  t1.student_id = t5.student_id
        and t1.date1 = t5.date1
        left join
            (select
                student_id
                ,date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) as date1
                ,sum(contract_amount) as contract_amount
            from newuuabc.contract
            where date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between '2019-01-28' and '2019-02-24'
            and contract_type = 1  -- 销售合同
            and status = 4 -- 已付费
            and is_del = 1 -- 正常
            and attribute = 2  -- 续签
            group by student_id, date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00'))
            )   t6
        on  t1.student_id = t6.student_id
        and t1.date1 = t6.date1
        )   t4
    group by t4.teacher_id
    )   t6
on  t5.teacher_id = t6.teacher_id
order by t5.teacher_id
;

drop table if exists tmp_product_consume;
create temporary table tmp_product_consume
(
    `key` int
    ,`stuId` int
    ,`contractId` int
    ,key k1(`stuId`, `key`)
);

insert into tmp_product_consume
select
    `key`
    ,stuid
    ,contractid
from newuuabc.product_consume
;

-- 开课后退费明细
select
    t5.student_id
    ,t5.contract_id
    ,t5.contract_name
    ,t5.date1
    ,t5.teacher_id
    ,t5.teacher_name
from
    (select
        t2.student_id
        ,t2.contract_id
        ,t2.contract_name
        ,t2.date1
        ,t3.teacher_id
        ,t3.teacher_name
        ,coalesce(t4.cnt1, 0) as cnt1
    from
        (select
            t1.student_id
            ,t1.contract_id
            ,t1.contract_name
            ,t1.date1
        from
            (select
                t1.student_id
                ,t1.contract_id
                ,coalesce(t2.name, '') as contract_name
                ,min(date(convert_tz(from_unixtime(t1.refund_time), '+00:00', '+08:00'))) as date1
            from newuuabc.contract_refund t1
            left join
                newuuabc.contract_template t2
            on  t1.template_id = t2.id
            where t1.status = 1
            group by t1.student_id, t1.contract_id, coalesce(t2.name, '')
            )   t1
        where t1.date1 between '2019-01-28' and '2019-02-24'
        )   t2
    inner join
        (select
            *
        from tmp_teacher_student_everyday
        where date1 between '2019-01-28' and '2019-02-24'
        )   t3
    on  t2.student_id = t3.student_id
    and t2.date1 = t3.date1
    left join
        (select
            t3.contract_id
            ,sum(t3.cnt) as cnt1
        from
            (select
                contract_id
                ,count(*) as cnt
            from newuuabc.appoint_course
            where course_type = 3
            and disabled = 0
            union all
            select
                t1.contractId as contract_id
                ,count(*) as cnt
            from tmp_product_consume t1
            inner join
                classbooking.student_class t2
            on  t1.stuid = t2.student_id
            and t1.`key` = t2.student_class_id
            and t2.class_type <> 3  -- 不是试听课
            and t2.status = 3
            group by t1.contractid
            )   t3
        group by t3.contract_id
        )   t4
    on  t2.contract_id = t4.contract_id
    )   t5
where t5.cnt1 > 0
;



-- 退费人数
select
    t7.teacher_id
    ,coalesce(t8.cnt1, 0) as cnt1
from tmp_teacher t7
left join
    (select
        t5.teacher_id
        ,count(distinct case when t5.cnt1 > 0 then t5.student_id else null end) as cnt1
    from
        (select
            t2.student_id
            ,t2.contract_id
            ,t2.contract_name
            ,t2.date1
            ,t3.teacher_id
            ,t3.teacher_name
            ,coalesce(t4.cnt1, 0) as cnt1
        from
            (select
                t1.student_id
                ,t1.contract_id
                ,t1.contract_name
                ,t1.date1
            from
                (select
                    t1.student_id
                    ,t1.contract_id
                    ,coalesce(t2.name, '') as contract_name
                    ,min(date(convert_tz(from_unixtime(t1.refund_time), '+00:00', '+08:00'))) as date1
                from newuuabc.contract_refund t1
                left join
                    newuuabc.contract_template t2
                on  t1.contract_payment_id = t2.id
                where t1.status = 1
                group by t1.student_id, t1.contract_id, coalesce(t2.name, '')
                )   t1
            where t1.date1 between '2019-01-28' and '2019-02-24'
            )   t2
        inner join
            (select
                *
            from tmp_teacher_student_everyday
            where date1 between '2019-01-28' and '2019-02-24'
            )   t3
        on  t2.student_id = t3.student_id
        and t2.date1 = t3.date1
        left join
            (select
                t3.contract_id
                ,sum(t3.cnt) as cnt1
            from
                (select
                    contract_id
                    ,count(*) as cnt
                from newuuabc.appoint_course
                where course_type = 3
                and disabled = 0
                union all
                select
                    t1.contractId as contract_id
                    ,count(*) as cnt
                from tmp_product_consume t1
                inner join
                    classbooking.student_class t2
                on  t1.stuid = t2.student_id
                and t1.`key` = t2.student_class_id
                and t2.class_type <> 3  -- 不是试听课
                and t2.status = 3
                group by t1.contractid
                )   t3
            group by t3.contract_id
            )   t4
        on  t2.contract_id = t4.contract_id
        )   t5
    group by t5.teacher_id
    )   t8
on  t7.teacher_id = t8.teacher_id
order by t7.teacher_id
;


-- 续费期学员人数
select
    t4.teacher_id
    ,coalesce(t5.cnt1, 0) as cnt1
from tmp_teacher t4
left join
    (select
        t3.teacher_id
        ,t3.teacher_name
        ,sum(case when (t3.teacher_type = 1 and t3.cnt_1v1_previous > 8 and t3.cnt_1v1_current < 8)
            or  (t3.teacher_type = 4 and t3.cnt_1v4_previous > 8 and t3.cnt_1v4_current < 8)
            then 1 else 0
        end) as cnt1
    from
        (select
            t1.student_id
            ,t1.cnt_1v1_previous
            ,t1.cnt_1v4_previous
            ,t1.cnt_1v1_current
            ,t1.cnt_1v4_current
            ,t2.teacher_id
            ,t2.teacher_name
            ,t2.teacher_type
        from
            (select
                student_id
                ,cnt_1v1_previous
                ,cnt_1v4_previous
                ,cnt_1v1_current
                ,cnt_1v4_current
            from tmp_student_hours_record_diff
            )   t1
        inner join
            (select
                *
            from tmp_teacher_student_everyday
            where date1 = '2019-01-28'
            )   t2
        on  t1.student_id = t2.student_id
        )   t3
    group by t3.teacher_id, t3.teacher_name
    )   t5
on  t4.teacher_id = t5.teacher_id
group by t4.teacher_id
;





-- 续费明细
select
    t1.id as contract_id
    ,coalesce(t3.name, '') as contract_name
--  ,t1.contract_type
    ,t1.student_id
    ,coalesce(t2.name, '') as student_name
    ,t2.assign_teacher as teacher_id
    ,coalesce(t4.truename,'') as teacher_name
--  ,t1.status
--  ,case when t1.`attribute` = 1 then '新签' when t1.`attribute` = 2 then '续签' else '' end as `attribute`
    ,round(t1.contract_amount / 100, 2) as contract_amount
--  ,t1.sucess_at
--  ,t1.update_at
--  ,date(convert_tz(from_unixtime(case when t1.sucess_at is null or t1.sucess_at = 0 then t1.update_at else t1.sucess_at end), '+00:00', '+08:00')) as kk_date
    ,date(convert_tz(from_unixtime(t1.sucess_at), '+00:00', '+08:00')) as succesc_date
--  ,date(convert_tz(from_unixtime(t1.update_at), '+00:00', '+08:00')) as update_date
from newuuabc.contract t1
inner join
    newuuabc.student_user t2
on  t1.student_id = t2.id
and t2.flag = 1 -- 真实用户
and t2.disable = 0 -- 不禁用
left join
    newuuabc.contract_template t3
on  t1.template_id = t3.id
left join
    newuuabc.admin t4
on  t2.assign_teacher = t4.masterid
where t1.is_del = 1  -- 正常
and t1.status = 4  -- 已付费
and t1.contract_type = 1 -- 销售合同
and t1.`attribute` = 2 -- 续约
and date(convert_tz(from_unixtime(t1.sucess_at), '+00:00', '+08:00')) between '2019-01-28' and '2019-02-24'
;


-- 所带学员推荐付费的明细
select
    t2.assign_teacher
    ,t3.truename
    ,t2.id
    ,t2.name
    ,t1.id
    ,t1.name
--  ,t1.recommended
    ,t4.id as contract_id
    ,t5.name as contract_name
    ,round(t4.contract_amount / 100, 2) as contract_amount
    ,date(convert_tz(from_unixtime(t4.sucess_at), '+00:00', '+08:00')) as success_date
from newuuabc.student_user t1
inner join
    newuuabc.student_user t2
on  t1.recommended = t2.id
inner join
    newuuabc.admin t3
on  t2.assign_teacher = t3.masterid
inner join
    newuuabc.contract t4
on  t1.id = t4.student_id
and t4.contract_type = 1
and t4.status = 4
left join
    newuuabc.contract_template t5
on  t4.template_id = t5.id
where t1.flag = 1
and t1.disable = 0
and date(convert_tz(from_unixtime(t4.sucess_at), '+00:00', '+08:00')) between '2019-01-28' and '2019-02-24'
and datediff(date(convert_tz(from_unixtime(t4.sucess_at), '+00:00', '+08:00')), date(convert_tz(from_unixtime(t1.create_time), '+00:00', '+08:00'))) < 90
;

```

**备注**

