




drop table if exists tmp_assign_teacher_t1;
create temporary table tmp_assign_teacher_t1
(
    truename varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci
    ,order_id int
);
insert into tmp_assign_teacher_t1 values
('李许多',1)
,('储贻敏',2)
,('和涛',3)
,('陈佳静',4)
,('林敏',5)
,('吕研科',6)
,('张娇娇',7)
,('程显梅',8)
,('施雪娇',9)
,('葛志远',10)
,('张雯娜',11)
,('阙寿玲',12)
,('林浩',13)
,('杨东亚',14)
,('孙宁',15)
,('杨海霞',16)
,('帖嫚丽',17)
,('朱书颖',18)
,('卜柳',19)
,('盛贝麒',20)
,('顾艳梅',21)
,('简玉',22)
,('蔡彦',23)
;



drop table if exists bi.tmp_teacher_20181129;
create table bi.tmp_teacher_20181129
(
    job_number varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci
    ,order_id int
    ,teacher_id int
    ,teacher_name varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci
);
insert into bi.tmp_teacher_20181129
select
    t2.job_number
    ,t1.order_id
    ,t2.masterid as teacher_id
    ,t2.truename as teacher_name
from tmp_assign_teacher_t1 t1
left join
    newuuabc.admin  t2
on  t1.truename = t2.truename
;

-- 需要用那一天的学生来代表督导老师一整月的学生
drop table if exists bi.tmp_student_20181129;
create table bi.tmp_student_20181129
(
    student_id int
    ,student_name varchar(50) CHARACTER SET utf8mb4
    ,teacher_id int
    ,channel int
    ,data_date date
    ,recommended int
    ,flag int
    ,disable int
    ,type int
    ,key k1(student_id)
    ,key k2(teacher_id)
    ,key k3(channel)
);
insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,partition_key as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key between 20180927 and 20181025
;

insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20180926 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180927
;

insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20180930 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180929
;

insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20181001 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180929
;


insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20181002 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180929
;

insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20181003 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180929
;

insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20181004 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180929
;

insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20181005 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180929
;

insert into bi.tmp_student_20181129
select
    id as student_id
    ,name as student_name
    ,assign_teacher as teacher_id
    ,channel
    ,20181006 as data_date
    ,recommended
    ,flag
    ,disable
    ,type
from bi.student_user_his
where partition_key = 20180929
;


-- SELECT
--     data_date
--     ,count(*)
-- from bi.tmp_student_20181129
-- group by data_date
-- ;


-- 1v1跟1v4是指学生签订合同的类别吗？还是学生注册的时候注册的类型？
-- 如果是按签订合同来计算的话，假设学生没有签订合同就不算了吗？

-- 20180926带1v1学员数：
   -- 20180926这个学生是指派给这个督导的

   -- # 拉取数据当天1:1课时有剩余或者指定日期有上过课的学生，按这些学生取拉取数据时的督导老师


    drop table if exists teacher_1v1_student_cnt_0926;
    create temporary table teacher_1v1_student_cnt_0926
    (
        teacher_id int
        ,teacher_name varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into teacher_1v1_student_cnt_0926
    select
        t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        bi.tmp_teacher_20181129 t0
    left join
        (select
            student_id
            ,teacher_id
        from bi.tmp_student_20181129
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        and data_date = 20180926
        )   t1
    on  t0.teacher_id = t1.teacher_id
    left join
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (1, 2)  -- 1:1课时
        and school_hour > 0  -- 剩余课时数
        union
        select distinct
            student_user_id as student_id
        from newuuabc.appoint_course
        where course_type = 3  -- 正式课
        -- and status = 3  -- 已经上课
        -- and disabled = 0  -- 正常
        and class_appoint_course_id = 0  -- 约课id
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) = 20180926  -- 上课日期
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
    order by t0.order_id
    ;


-- 20181025带1v1学员数：
--    20181025这个学生是指派给这个督导的
    drop table if exists teacher_1v1_student_cnt_1025;
    create temporary table teacher_1v1_student_cnt_1025
    (
        teacher_id int
        ,teacher_name varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into teacher_1v1_student_cnt_1025
    select
        t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        bi.tmp_teacher_20181129 t0
    left join
        (select
            student_id
            ,teacher_id
        from bi.tmp_student_20181129
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        and data_date = 20181025
        )   t1
    on  t0.teacher_id = t1.teacher_id
    left join
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (1, 2)  -- 1:1课时
        and school_hour > 0  -- 剩余课时数
        union
        select distinct
            student_user_id as student_id
        from newuuabc.appoint_course
        where course_type = 3  -- 正式课
        -- and status = 3  -- 已经上课
        -- and disabled = 0  -- 正常
        and class_appoint_course_id = 0  -- 约课id
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) = 20181025  -- 上课日期
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
    order by t0.order_id
    ;

-- 20180926带1v4学员数：
--    20180926这个学生是指派给这个督导的

    drop table if exists teacher_1v4_student_cnt_0926;
    create temporary table teacher_1v4_student_cnt_0926
    (
        teacher_id int
        ,teacher_name varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into teacher_1v4_student_cnt_0926
    select
        t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        bi.tmp_teacher_20181129   t0
    left join
        (select
            student_id
            ,teacher_id
        from bi.tmp_student_20181129
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        and teacher_id <> 0  -- 课程顾问
        and data_date = 20180926
        )   t1
    on  t0.teacher_id = t1.teacher_id
    left join
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (7, 8)  -- 1:4课时
        and school_hour > 0
        union
        select distinct
            student_user_id as student_id
        from newuuabc.appoint_course
        where course_type = 3  -- 正式课
        -- and status = 3  -- 已经上课
        -- and disabled = 0  -- 正常
        and class_appoint_course_id <> 0  -- 1:4
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) = 20180926
        union
        select distinct
            student_id
        from classbooking.student_class
        -- where status = 3  -- 已完成
        -- and date(from_unixtime(start_time)) between 20180827 and 20180827
        where date(from_unixtime(start_time)) = 20180926
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
    order by t0.order_id
    ;

-- 20181025带1v4学员数：
--    20181025这个学生是指派给这个督导的

    drop table if exists teacher_1v4_student_cnt_1025;
    create temporary table teacher_1v4_student_cnt_1025
    (
        teacher_id int
        ,teacher_name varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into teacher_1v4_student_cnt_1025
    select
        t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        bi.tmp_teacher_20181129  t0
    left join
        (select
            student_id
            ,teacher_id
        from bi.tmp_student_20181129
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        and data_date = 20181025
        -- and teacher_id <> 0  -- 课程顾问
        )   t1
    on  t0.teacher_id = t1.teacher_id
    left join
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (7, 8)  -- 1:4课时
        and school_hour > 0
        union
        select distinct
            student_user_id as student_id
        from newuuabc.appoint_course
        where course_type = 3  -- 正式课
        -- and status = 3  -- 已经上课
        -- and disabled = 0  -- 正常
        and class_appoint_course_id <> 0  -- 1:4
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) = 20181025
        union
        select distinct
            student_id
        from classbooking.student_class
        -- where status = 3  -- 已完成
        -- and date(from_unixtime(start_time)) between 20180923 and 20180923
        where date(from_unixtime(start_time)) = 20181025
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.teacher_id
        ,t0.teacher_name
        ,t0.job_number
    order by t0.order_id
    ;



-- 所带1v1学员完成课时数：

--    每天指派给这个督导的学生完成的课程数之和（有上课就算完成）

    drop table if exists teacher_1v1_course_cnt;
    create temporary table teacher_1v1_course_cnt
    (
        teacher_id int
        ,cnt1 int
    );
    insert into teacher_1v1_course_cnt
    select
        t0.teacher_id
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from bi.tmp_teacher_20181129 t0
    left join
        bi.tmp_student_20181129  t1
    on  t0.teacher_id = t1.teacher_id
    and t1.flag = 1
    and t1.disable = 0
    left join
        (select
            student_user_id as student_id
            ,date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) as course_date
        from newuuabc.appoint_course
        where disabled = 0  -- 这个条件有问题
        and course_type = 3
        and class_appoint_course_id = 0
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180926 and 20181025
        )     t2
    on  t1.student_id = t2.student_id
    and t1.data_date = t2.course_date
    group by t0.teacher_id
    order by t0.order_id
    ;


    -- appoint_sourse.status = 3
    -- and appoint_sourse.disabled = 0
    -- and appoint_course.course_type = 3
    -- and appoint_course.class_appoint_course_id = 0
    -- and student_user.flag = 1


-- 所带1v4付费学员完成课时数

--   20180926 至 20181025，有合同付费金额大于0的学员，合计这些学员的1：4完成课时

    drop table if exists teacher_1v4_course_cnt;
    create temporary table teacher_1v4_course_cnt
    (
        teacher_id int
        ,cnt1 int
    );
    insert into teacher_1v4_course_cnt
    select
        t1.teacher_id
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from bi.tmp_teacher_20181129  t1
    left join
        bi.tmp_student_20181129   t3
    on  t1.teacher_id = t3.teacher_id
    and t3.flag = 1
    and t3.disable = 0
    and t3.type = 2
    left join
        (select
            student_user_id as student_id
            ,date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) as course_date
        from newuuabc.appoint_course
        where disabled = 0
        and course_type = 3
        and class_appoint_course_id <> 0
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180926 and 20181025
        union all
        select
            student_id
            ,date(from_unixtime(start_time)) as course_date
        from classbooking.student_class
        where status = 3
        and date(from_unixtime(start_time)) between 20180926 and 20181025
        )     t2
    on  t3.student_id = t2.student_id
    and t3.data_date = t2.course_date
    group by t1.teacher_id
    order by t1.order_id
    ;



    -- 老：
    --     appoint_course.status = 3
    --     and appoint_course.disabled = 0
    --     and appoint_course.course_type = 3
    --     and appoint_course.class_apoint_course_id > 0
    --     and student_user.flag = 1
    --     and student_user.type = 2
    -- 新：
    --     student_class.status = 3
    --     and student_user.flag = 1
    --     and student_user.type = 2 (包含素质课)

-- 所带1v4免费20课时学员完成课时数

-- 优氏英语 暑期20课时免费课程包  contract_template.id = 404


    drop table if exists teacher_free_course_cnt;
    create temporary table teacher_free_course_cnt
    (
        teacher_id int
        ,cnt1 int
    );
    insert into teacher_free_course_cnt
    select
        t0.teacher_id
        ,sum(coalesce(t5.cnt, 0))
    from bi.tmp_teacher_20181129 t0
    left join
        bi.tmp_student_20181129 t2
    on  t0.teacher_id = t2.teacher_id
    and t2.flag = 1
    and t2.disable = 0
    left join
        (select
            t1.student_id
            ,date(from_unixtime(t1.start_time)) as course_date
            ,count(*) as cnt
        from classbooking.student_class  t1
        inner join
            newuuabc.product_consume t2
        on  t1.student_class_id = t2.key
        and t1.student_id = t2.stuId
        inner join
            newuuabc.contract t3
        on  t2.contractId = t3.id
        and t3.template_id in (295, 404, 349)
        where t1.status = 3
        and date(from_unixtime(t1.start_time)) between 20180926 and 20181025
        group by t1.student_id, date(from_unixtime(t1.start_time))
        )   t5
    on  t2.student_id = t5.student_id
    and t2.data_date = t5.course_date
    group by t0.teacher_id
    ;

    insert into teacher_free_course_cnt
    select
        t0.teacher_id
        ,sum(coalesce(t5.cnt, 0))
    from bi.tmp_teacher_20181129 t0
    left join
        bi.tmp_student_20181129 t2
    on  t0.teacher_id = t2.teacher_id
    and t2.flag = 1
    and t2.disable = 0
    left join
        (select
            t1.student_user_id as student_id
            ,date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) as course_date
            ,count(*) as cnt
        from newuuabc.appoint_course  t1
        inner join
            newuuabc.contract t2
        on  t1.contract_id = t2.id
        and t2.template_id in (295, 404, 349)
        where date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between 20180926 and 20181025
        group by t1.student_user_id, date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00'))
        )   t5
    on  t2.student_id = t5.student_id
    and t2.data_date = t5.course_date
    group by t0.teacher_id
    ;

-- 所带学员完成素质课课时数

    drop table if exists teacher_quality_course_cnt;
    create temporary table teacher_quality_course_cnt
    (
        teacher_id int
        ,cnt1 int
    );
    insert into teacher_quality_course_cnt
    select
        t0.teacher_id
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt
    from bi.tmp_teacher_20181129 t0
    inner join
        bi.tmp_student_20181129   t1
    on  t0.teacher_id = t1.teacher_id
    and t1.flag = 1
    and t1.disable = 0
    left join
        (select
            student_id
            ,date(from_unixtime(start_time)) as course_date
        from classbooking.student_class
        where status = 3
        and class_type = 5
        and date(from_unixtime(start_time)) between 20180926 and 20181025
        )    t2
    on  t1.student_id = t2.student_id
    and t1.data_date = t2.course_date
    group by t0.teacher_id
    ;

    -- 新：
    --     student_class.status = 3
    --     and student_user.flag = 1
    --     and student_user.type = 2
    --     and student_class.class_type= 5(素质课)
    -- 新1：4才有素质课

-- 所带学员续费金额
--    统计周期内学员的续费金额之和？

--  20180926 至 20181025，有进行续费的学员，金额总和

    drop table if exists teacher_continue_pay_amt;
    create temporary table teacher_continue_pay_amt
    (
        teacher_id int
        ,amt1 double
    );
    insert into teacher_continue_pay_amt
    select
        t0.teacher_id
        ,sum(coalesce(t2.total_fee, 0) / 100) as amt1
    from
        (select
            t0.teacher_id
            ,t0.order_id
            ,t1.student_id
            ,t1.data_date
        from bi.tmp_teacher_20181129 t0
        inner join
            bi.tmp_student_20181129 t1
        on  t0.teacher_id = t1.teacher_id
        and t1.flag = 1
        and t1.disable = 0
        )   t0
    inner join
        (select
            t1.id as contract_id
            ,t1.student_id
            ,t2.total_fee
            ,date(convert_tz(from_unixtime(coalesce(t1.sucess_at, t1.update_at)), '+00:00', '+08:00')) as contract_date
        from newuuabc.contract  t1
        left join
            (select
                contract_id
                ,sum(total_fee) as total_fee
            from newuuabc.contract_payment
            where is_success = 2
            group by contract_id
            )   t2
        on  t1.id = t2.contract_id
        where t1.is_del = 1
        and t1.contract_type = 1
        and t1.attribute = 2
        and ((t1.status = 3
            and date(convert_tz(from_unixtime(t1.update_at), '+00:00', '+08:00')) between 20180926 and 20181025
            )
            or  (t1.status = 4
                and date(convert_tz(from_unixtime(t1.sucess_at), '+00:00', '+08:00')) between 20180926 and 20181025
                )
            )
        )   t2
    on  t0.student_id = t2.student_id
    where t0.data_date = t2.contract_date
    group by t0.teacher_id
    order by t0.order_id
    ;

    --  contract_payment：
    --    8月：
    --        sum(contract_payment.total_fee / 100)
    --        and contract.contract_type = 1
    --        and contract.attribute = 2
    --        and ((contract.status = 3 and contract.update_at between 开始 and 结束)
    --            or (contract.status = 4 and contract.sucess_at between 开始 and 结束)
    --            )
    --        and student_user.flag = 1
    --        and student_user.type = 2




    --    9月：
    --        sum(contract_payment.total_fee / 100)
    --        and contract.contract_type = 1
    --        and contract.attribute = 2
    --        and contract_pyament.success_at between 开始 and 结束
    --        and student_user.flag = 1
    --        and student_user.type = 2

-- 来自至慧渠道的视听学员付费人数：
--    付费日期在统计周期内？

--    20180926 至 20181025 付费的来自至慧渠道的学员，归属到当前督导

drop table if exists tmp_teacher_student;
create temporary table tmp_teacher_student as
select
    t1.student_id
    ,t1.student_name
    ,t1.recommended
    ,t1.teacher_id
    ,t1.data_date
    ,t0.order_id
    ,t1.channel
from bi.tmp_teacher_20181129  t0
inner join
    bi.tmp_student_20181129 t1
on  t0.teacher_id = t1.teacher_id
and t1.flag = 1
and t1.disable = 0
;

drop table if exists tmp_student_contract;
create temporary table tmp_student_contract as
select
    t1.student_id
    ,date(convert_tz(from_unixtime(coalesce(t1.sucess_at, t1.update_at)), '+00:00', '+08:00')) as contract_date
from newuuabc.contract  t1
inner join
    (select distinct
        contract_id
    from newuuabc.contract_payment
    where is_success = 2
    and total_fee > 0
    )   t2
on  t1.id = t2.contract_id
where t1.is_del = 1  -- 正常
and t1.contract_type = 1  -- 销售合同
and ((t1.status = 3
    and date(convert_tz(from_unixtime(t1.update_at), '+00:00', '+08:00')) between 20180926 and 20181025
    )
    or  (t1.status = 4
        and date(convert_tz(from_unixtime(t1.sucess_at), '+00:00', '+08:00')) between 20180926 and 20181025
        )
    )
;

    drop table if exists teacher_zhihui_pay_cnt;
    create temporary table teacher_zhihui_pay_cnt
    (
        teacher_id int
        ,cnt1 int
    );
    insert into teacher_zhihui_pay_cnt
    select
        t0.teacher_id
        ,count(distinct case when t3.student_id is not null then t0.student_id else null end) as cnt1
    from tmp_teacher_student t0
    inner join
        (
        -- 渠道 至慧学堂
        select
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
        )   t2
    on  t0.channel = t2.id
    left join
        tmp_student_contract   t3
    on  t0.student_id = t3.student_id
    where t0.data_date = t3.contract_date
    group by t0.teacher_id
    order by t0.order_id
    ;


-- 所带学员推荐1v1新生付费人数：
--    首次付费日期还是注册日期在统计周期内？


    drop table if exists teacher_recommend_1v1_pay_cnt;
    create temporary table teacher_recommend_1v1_pay_cnt
    (
        teacher_id int
        ,cnt1 int
    );
    insert into teacher_recommend_1v1_pay_cnt
    select
        t1.teacher_id
        ,count(distinct t2.student_id) as cnt1
    from
        tmp_teacher_student   t1
    inner join
        (select   -- 被别人推荐的学生
            id as student_id
            ,recommended
        from newuuabc.student_user
        where flag = 1
        and disable = 0
        and recommended > 0
        )   t2
    on  t1.student_id = t2.recommended
    inner join
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (1, 2)  -- 1:1课时
        and school_hour > 0
        union
        select distinct
            student_user_id as student_id
        from newuuabc.appoint_course
        where course_type = 3  -- 正式课
        -- and status = 3  -- 已经上课
        -- and disabled = 0  -- 正常
        and class_appoint_course_id = 0  -- 1:1
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180926 and 20181025
        )   t4
    on  t2.student_id = t4.student_id
    inner join
        (select  -- 首次付费日期
            student_id
            ,date(convert_tz(from_unixtime(coalesce(sucess_at, update_at)), '+00:00', '+08:00')) as contract_date
        from newuuabc.contract
        where is_del = 1
        and contract_type = 1
        and ((status = 3
            and date(convert_tz(from_unixtime(update_at), '+00:00', '+08:00')) between 20180926 and 20181025
            )
            or  (status = 4
                and date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between 20180926 and 20181025
                )
            )
        group by student_id
        )   t5
    on  t2.student_id = t5.student_id
    where t1.data_date = t5.contract_date
    group by t1.teacher_id
    order by t1.order_id
    ;

-- 所带学员推荐1v4新生付费人数：
--    首次付费日期还是注册日期在统计周期内？

    drop table if exists teacher_recommend_1v4_pay_cnt;
    create temporary table teacher_recommend_1v4_pay_cnt
    (
        teacher_id int
        ,cnt1 int
    );
    insert into teacher_recommend_1v4_pay_cnt
    select
        t1.teacher_id
        ,count(distinct t2.student_id) as cnt1
    from
        tmp_teacher_student   t1
    inner join
        (select   -- 被别人推荐的学生
            id as student_id
            ,recommended
        from newuuabc.student_user
        where flag = 1
        and disable = 0
        and recommended > 0
        )   t2
    on  t1.student_id = t2.recommended
    inner join
        (select distinct
            student_id
        from newuuabc.school_hour
        where subject_id in (7, 8)  -- 1:4课时
        and school_hour > 0
        union
        select distinct
            student_user_id as student_id
        from newuuabc.appoint_course
        where course_type = 3  -- 正式课
        and status = 3  -- 已经上课
        and disabled = 0  -- 正常
        and class_appoint_course_id <> 0  -- 1:4
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180926 and 20181025
        union
        select distinct
            student_id
        from classbooking.student_class
        where status = 3  -- 已完成
        and date(from_unixtime(start_time)) between 20180926 and 20181025
        )   t4
    on  t2.student_id = t4.student_id
    inner join
        (select  -- 首次付费日期
            student_id
            ,date(convert_tz(from_unixtime(coalesce(sucess_at, update_at)), '+00:00', '+08:00')) as contract_date
        from newuuabc.contract
        where is_del = 1
        and contract_type = 1
        and ((status = 3
            and date(convert_tz(from_unixtime(update_at), '+00:00', '+08:00')) between 20180926 and 20181025
            )
            or  (status = 4
                and date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between 20180926 and 20181025
                )
            )
        group by student_id
        )   t5
    on  t2.student_id = t5.student_id
    where t1.data_date = t5.contract_date
    group by t1.teacher_id
    order by t1.order_id
    ;



select
    t0.teacher_id as '班主任老师'
    ,t0.job_number as '班主任工号'
    ,t0.teacher_name as '班主任名字'
    ,t1.cnt1         as '20180926带1v1学员数'
    ,t1_1.cnt1       as '20181025带1v1学员数'
    ,t2.cnt1         as '20180926带1v4学员数'
    ,t2_1.cnt1       as '20181025带1v4学员数'
    ,t3.cnt1         as '所带1v1学员完成课时数'
    ,t4.cnt1         as '所带1v4付费学员完成课时数'
    ,t5.cnt1         as '所带1v4免费20课时学员完成课时数'
    ,t6.cnt1         as '所带学员完成素质课课时数'
    ,t7.amt1         as '所带学员续费金额'
    ,t8.cnt1         as '来自至慧渠道的视听学员付费人数'
    ,t9.cnt1         as '所带学员推荐1v1新生付费人数'
    ,t10.cnt1        as '所带学员推荐1v4新生付费人数'
from bi.tmp_teacher_20181129 t0
left join
    teacher_1v1_student_cnt_0926  t1
on  t0.teacher_id = t1.teacher_id
left join
    teacher_1v1_student_cnt_1025    t1_1
on  t0.teacher_id = t1_1.teacher_id
left join
    teacher_1v4_student_cnt_0926  t2
on  t0.teacher_id = t2.teacher_id
left join
    teacher_1v4_student_cnt_1025    t2_1
on  t0.teacher_id = t2_1.teacher_id
left join
    teacher_1v1_course_cnt  t3
on  t0.teacher_id = t3.teacher_id
left join
    teacher_1v4_course_cnt  t4
on  t0.teacher_id = t4.teacher_id
left join
    (select
        teacher_id
        ,sum(cnt1) as cnt1
    from teacher_free_course_cnt
    group by teacher_id
    )  t5
on  t0.teacher_id = t5.teacher_id
left join
    teacher_quality_course_cnt  t6
on  t0.teacher_id = t6.teacher_id
left join
    teacher_continue_pay_amt  t7
on  t0.teacher_id = t7.teacher_id
left join
    teacher_zhihui_pay_cnt  t8
on  t0.teacher_id = t8.teacher_id
left join
    teacher_recommend_1v1_pay_cnt  t9
on  t0.teacher_id = t9.teacher_id
left join
    teacher_recommend_1v4_pay_cnt  t10
on  t0.teacher_id = t10.teacher_id
order by t0.order_id
;



