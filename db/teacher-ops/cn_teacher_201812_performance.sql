# 督导老师2018年12月奖金基础数据


**需求来源**

提出人: 傅尹莉<yinli.fu@uuabc.com>

部门:

**拉取周期**
每月20号左右


**用途**
版主任奖金计算


**详细**
每次要求都有可能有区别，这次总共改了两次计算规则
目前的规则是：
学生当天有剩余课时就算是班主任的学生

```
```

**SQL**

```sql

use bi;
drop table if exists tmp_teacher;
create temporary table tmp_teacher as
select
    masterid as teacher_id
    ,truename as teacher_name
    ,case when truename like '%杨海霞%'
        or truename like '%帖嫚丽%'
        or truename like '%朱书颖%'
        or truename like '%卜柳%'
        or truename like '%盛贝麒%'
        or  truename like '%王启迪%'
        or truename like '%顾艳梅%'
        then '1v1' else '1v4'
    end as teacher_type
from newuuabc.admin
where truename like '%杨海霞%'
or  truename like '%帖嫚丽%'
or  truename like '%朱书颖%'
or  truename like '%卜柳%'
or  truename like '%盛贝麒%'
or  truename like '%王启迪%'
or  truename like '%顾艳梅%'
or  truename like '%陈佳静%'
or  truename like '%李许多%'
or  truename like '%吕研科%'
or  truename like '%张娇娇%'
or  truename like '%程显梅%'
or  truename like '%施雪娇%'
or  truename like '%张雯娜%'
or  truename like '%和涛%'
or  truename like '%林敏%'
or  truename like '%葛志远%'
or  truename like '%熊鸣%'
or  truename like '%刘雅%'
or  truename like '%刘峰%'
or  truename like '%丁冉%'
or  truename like '%陈颖%'
or  truename like '%杜昊聪%'
or  truename like '%储贻敏%'
;


-- drop table if exists tmp_student_contract_min_date;
-- create temporary table tmp_student_contract_min_date as
-- select
--  student_id
--  ,min(date1) as date1
-- from
--  (select
--      student_id
--      ,date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) as date1
--  from newuuabc.contract
--  where status = 4
--  and contract_amount > 990
--  )   t1
-- group by t1.student_id
-- ;


-- select
--  status
--  ,cancel_type
--  ,disabled
--  ,count(*) as cnt1
-- from newuuabc.appoint_course
-- where cancel_type in (2, 4)
-- group by status, cancel_type, disabled
-- ;
--
--
-- select
--  *
-- from tmp_student_conctract_start_date;
-- ;


-- drop table if exists tmp_student_product_consume;
-- create temporary table tmp_student_product_consume
-- (
--  student_class_id int
--  ,student_id int
--  ,contract_id int
--  ,key k1(student_class_id)
--  ,key k2(student_class_id, student_id)
-- );

-- insert into tmp_student_product_consume
-- select
--  `key`
--  ,stuId
--  ,contractId
-- from newuuabc.product_consume
-- ;


-- drop table if exists tmp_student_conctract_start_date;
-- create temporary table tmp_student_conctract_start_date as
-- select
--  student_id
--  ,contract_id
--  ,min(t1.date1) as date1
-- from
--  (select
--      student_user_id as student_id
--      ,contract_id
--      ,min(date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00'))) as date1
--  from newuuabc.appoint_course
--  where contract_id is not null
--  and status = 3
--  and (disabled = 0 -- 0正常
--      or  (disabled = 1  -- 1取消
--          and (status in (1, 2, 5))  -- 1学生失约 2老师失约 5系统障碍
--          )
--      )
--  and contract_id > 0
--  and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) <= '2018-12-30'
--  group by student_user_id, contract_id
--  union all
--  select
--      t1.student_id
--      ,t1.student_id
--      ,min(date(from_unixtime(t2.class_date))) as date1
--  from tmp_student_product_consume t1
--  inner join
--      classbooking.student_class t2
--  on  t1.student_class_id = t2.student_class_id
--  and date(from_unixtime(t2.class_date)) <= '2018-12-30'
--  and t2.status in (3, 6, 9)
--  where t1.contract_id is not null
--  and t1.contract_id > 0
--  group by t1.student_id, t1.student_id
--  )   t1
-- group by t1.student_id, t1.contract_id
-- ;



-- select
--  class_type
--  ,count(*) as cnt1
-- from classbooking.student_class
-- group by class_type
-- ;
--
-- 1    130904
-- 5    2371
-- 6    172
-- 7    62
-- 8    2
--
-- select
--  *
-- from newuuabc.class_type
-- ;
--
-- 1    小班课
-- 2    1对1
-- 3    试听课
-- 4    直播课
-- 5    素质课
-- 6    中教课
-- 7    体验课
-- 8    智慧试听
--


-- select distinct
--  student_id
-- from
--  (select distinct
--      student_user_id as student_id
--  from newuuabc.appoint_course
--  where contract_id is not null
--  and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) < '2018-11-26'
--  union all
--  select distinct
--      stuId as student_id
--  from newuuabc.product_consume
--  where contractId is not null
--  and date(convert_tz(from_unixtime(create_date), '+00:00', '+08:00')) < '2018-11-26'
--  )   t1
-- ;


-- 可以用1, 7 来预估学生课时
-- select
--  subject_id
--  ,count(*) as cnt1
-- from newuuabc.student_hours_record
-- group by subject_id
-- ;

-- 1    67818
-- 3    807
-- 4    99889
-- 5    857
-- 6    796
-- 7    218511
-- 8    133

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


select
    *
from tmp_student_hours_record_2
-- where student_id = 292
;

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


select
    *
from tmp_student_hours_record_3
;

select
    *
from tmp_student_hours_record_1
where student_id = 289
and subject_id = 1
;

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
    where date1 between '2018-11-26' and '2018-12-30'
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

select
    *
from tmp_student_hours_record_3
where student_id = 292
and subject_id = 7
;


select
    *
from tmp_student_hours_record_5
;


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
        ,'2018-11-26' as date1
        ,t2.after_hours
    from
        (select
            student_user_id as student_id
            ,subject_id
            ,max(id) as max_id
        from newuuabc.student_hours_record
        where date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) <= '2018-11-26'
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
        ,'2018-12-30' as date1
        ,t2.after_hours
    from
        (select
            student_user_id as student_id
            ,subject_id
            ,max(id) as max_id
        from newuuabc.student_hours_record
        where date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) <= '2018-12-30'
        and subject_id in (1, 7)
        group by student_user_id, subject_id
        )   t1
    inner join
        newuuabc.student_hours_record t2
    on  t1.max_id = t2.id
    )   t3
group by t3.student_id, t3.date1
;


drop table if exists tmp_teacher_student_1126;
create temporary table tmp_teacher_student_1126 as
select
    t3.teacher_id
    ,t3.teacher_name
    ,t3.student_id
    ,t3.student_name
    ,t3.date1
    ,coalesce(t7.after_hours_1v1, 0) as cnt_1v1
    ,coalesce(t7.after_hours_1v4, 0) as cnt_1v4
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
            ,'2018-11-26' as date1
        from bi.student_user_his
        where partition_key = 20181126
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
    where date1 = '2018-11-26'
    )   t7
on  t3.student_id = t7.student_id
;


-- select
--  *
-- from tmp_teacher_student_1230
-- ;


drop table if exists tmp_teacher_student_1230;
create temporary table tmp_teacher_student_1230 as
select
    t3.teacher_id
    ,t3.teacher_name
    ,t3.student_id
    ,t3.student_name
    ,t3.date1
    ,coalesce(t7.after_hours_1v1, 0) as cnt_1v1
    ,coalesce(t7.after_hours_1v4, 0) as cnt_1v4
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
            ,'2018-12-30' as date1
        from bi.student_user_his
        where partition_key = 20181230
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
;


-- 1126号有课时
-- 1230号有课时


select
    t1.teacher_id
    ,t1.teacher_name
    ,coalesce(t2.cnt1v1_1126, 0)
    ,coalesce(t2.cnt1v4_1126, 0)
from tmp_teacher t1
left join
    (select
        teacher_id
        ,teacher_name
        ,sum(case when date1 = '2018-11-26' and cnt_1v1 > 0 then 1 else 0 end) as cnt1v1_1126  -- 20181126带1v1学员数
        ,sum(case when date1 = '2018-11-26' and cnt_1v4 > 0 then 1 else 0 end) as cnt1v4_1126  -- 20181230带1v1学员数
    from tmp_teacher_student_1126
    group by teacher_id, teacher_name
    )   t2
on  t1.teacher_id = t2.teacher_id
order by t1.teacher_id
;


select
    t1.teacher_id
    ,t1.teacher_name
    ,coalesce(t2.cnt1v1_1230, 0)
    ,coalesce(t2.cnt1v4_1230, 0)
from tmp_teacher t1
left join
    (select
        teacher_id
        ,teacher_name
        ,sum(case when date1 = '2018-12-30' and cnt_1v1 > 0 then 1 else 0 end) as cnt1v1_1230  -- 20181126带1v4学员数
        ,sum(case when date1 = '2018-12-30' and cnt_1v4 > 0 then 1 else 0 end) as cnt1v4_1230  -- 20181230带1v4学员数
    from tmp_teacher_student_1230
    group by teacher_id, teacher_name
    )   t2
on  t1.teacher_id = t2.teacher_id
order by t1.teacher_id
;




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
    where partition_key between 20181125 and 20181230
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
            where date1 between '2018-11-26' and '2018-12-30'
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
                and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between '2018-11-26' and '2018-12-30'
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
                and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between '2018-11-26' and '2018-12-30'
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
                and date(from_unixtime(start_time)) between '2018-11-26' and '2018-12-30'
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
                and date(from_unixtime(start_time)) between '2018-11-26' and '2018-12-30'
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
    --      where date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between '2018-11-26' and '2018-12-30'
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
            where date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between '2018-11-26' and '2018-12-30'
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


select
    t5.*
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
        where t1.date1 between '2018-11-26' and '2018-12-30'
        )   t2
    inner join
        (select
            *
        from tmp_teacher_student_everyday
        where date1 between '2018-11-26' and '2018-12-30'
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
    ,t8.cnt1
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
            where t1.date1 between '2018-11-26' and '2018-12-30'
            )   t2
        inner join
            (select
                *
            from tmp_teacher_student_everyday
            where date1 between '2018-11-26' and '2018-12-30'
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


-- 每天每种类型一条记录
drop table if exists tmp_student_hours;
create temporary table tmp_student_hours
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,key k1(student_id, date1)
);
insert into tmp_student_hours
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
;



select
    student_id
    ,subject_id
    ,date1
    ,count(*)
from tmp_student_hours
group by student_id, subject_id, date1
having count(*) > 1
;


drop table if exists tmp_student_hours_1;
create temporary table tmp_student_hours_1
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,key k1(student_id, date1)
);

insert into tmp_student_hours_1
select
    *
from tmp_student_hours
;



drop table if exists tmp_student_hours_2;
create temporary table tmp_student_hours_2
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,key k1(student_id, date1)
);

insert into tmp_student_hours_2
select
    *
from tmp_student_hours_1
;

drop table if exists tmp_student_hours_3;
create temporary table tmp_student_hours_3
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours int
    ,date2 date
    ,key k1(student_id, date2)
);
insert into tmp_student_hours_3
select
    t1.student_id
    ,t1.subject_id
    ,t1.date1
    ,t1.after_hours
    ,min(t2.date1) as date2
from tmp_student_hours_1 t1
left join
    tmp_student_hours_2 t2
on  t1.student_id = t2.student_id
and t1.subject_id = t2.subject_id
and t1.date1 < t2.date1
group by t1.student_id, t1.subject_id, t1.date1, t1.after_hours
;


select
    *
from tmp_student_hours_3
;


drop table if exists tmp_student_hours_4;
create temporary table tmp_student_hours_4
(
    student_id int
    ,subject_id int
    ,date1 date
    ,after_hours_1 int
    ,date2 date
    ,after_hours_2 int
    ,key k1(student_id, date1)
);


insert into tmp_student_hours_4
select
    t1.student_id
    ,t1.subject_id
    ,t1.date1
    ,t1.after_hours as after_hours_1
    ,t1.date2
    ,coalesce(t2.after_hours, 0) as after_hours_2
from tmp_student_hours_3 t1
left join
    tmp_student_hours_2 t2
on  t1.student_id = t2.student_id
and t1.subject_id = t2.subject_id
and t1.date2 = t2.date1
;


select
    *
from tmp_student_hours_4
;

select
    t4.teacher_id
    ,coalesce(t5.cnt1, 0) as cnt1
from tmp_teacher t4
left join
    (select
        t3.teacher_id
        ,t3.teacher_name
        ,sum(case when (t3.t3.teacher_type = '1v1' and t3.subject_id = 1)
            or  (t3.teacher_type = '1v4' and t3.subject_id = 7)
            then 1 else 0
        end) as cnt1
    from
        (select
            t1.student_id
            ,t1.subject_id
            ,t1.date1
            ,t2.teacher_id
            ,t2.teacher_name
            ,t2.teacher_type
--      select
--          count(*)
--          ,sum(case when teacher_type = '1v1' and subject_id = 1 then 1 else 0 end) as cnt1
--          ,sum(case when teacher_type = '1v4' and subject_id = 7 then 1 else 0 end) as cnt2
        from
            (select
                student_id
                ,subject_id
                ,date1
            from tmp_student_hours_4
            where date2 between '2018-11-26' and '2018-12-30'
            and after_hours_2 <= 8
--          and after_hours_2 > 0
            and after_hours_1 > 8
            )   t1
        inner join
            tmp_teacher_student_everyday    t2
        on  t1.student_id = t2.student_id
        and t1.date1 = t2.date1
        )   t3
    group by t3.teacher_id, t3.teacher_name
    )   t5
on  t4.teacher_id = t5.teacher_id
group by t4.teacher_id
;






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
and date(convert_tz(from_unixtime(t1.sucess_at), '+00:00', '+08:00')) between '2018-11-26' and '2018-12-30'
;



select
    t2.assign_teacher
    ,t3.truename
    ,t2.id
    ,t2.name
    ,t1.id
    ,t1.name
    ,t1.recommended
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
and date(convert_tz(from_unixtime(t4.sucess_at), '+00:00', '+08:00')) between '2018-11-26' and '2018-12-30'
and datediff(date(convert_tz(from_unixtime(t4.sucess_at), '+00:00', '+08:00')), date(convert_tz(from_unixtime(t1.create_time), '+00:00', '+08:00'))) < 90
;

```

**备注**

