




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



drop table if exists tmp_assign_teacher_t2;
create temporary table tmp_assign_teacher_t2
(
    job_number varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci
    ,order_id int
    ,assign_teacher int
    ,truename varchar(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci
);
insert into tmp_assign_teacher_t2
select
    t2.job_number
    ,t1.order_id
    ,t2.masterid
    ,t2.truename
from tmp_assign_teacher_t1 t1
left join
    newuuabc.admin  t2
on  t1.truename = t2.truename
;

-- 需要用那一天的学生来代表督导老师一整月的学生
drop table if exists tmp_student_user;
create temporary table tmp_student_user as
select
    *
from bi.student_user_his
where partition_key = 20180912
;

-- 1v1跟1v4是指学生签订合同的类别吗？还是学生注册的时候注册的类型？
-- 如果是按签订合同来计算的话，假设学生没有签订合同就不算了吗？

-- 7月30日带1v1学员数：
   -- 7月30日这个学生是指派给这个督导的

   -- # 拉取数据当天1:1课时有剩余或者指定日期有上过课的学生，按这些学生取拉取数据时的督导老师


    drop table if exists cn_teacher_stat_01;
    create temporary table cn_teacher_stat_01
    (
        assign_teacher int
        ,truename varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into cn_teacher_stat_01
    select
        t0.assign_teacher
        ,t0.truename
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        tmp_assign_teacher_t2 t0
    left join
        (select
            id as student_id
            ,assign_teacher
        from tmp_student_user
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        -- and assign_teacher <> 0  -- 课程顾问
        )   t1
    on  t0.assign_teacher = t1.assign_teacher
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
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180827 and 20180827  -- 上课日期
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.assign_teacher
        ,t0.truename
        ,t0.job_number
    order by t0.order_id
    ;


-- 8月26日带1v1学员数：
--    8月26日这个学生是指派给这个督导的
    drop table if exists cn_teacher_stat_01_1;
    create temporary table cn_teacher_stat_01_1
    (
        assign_teacher int
        ,truename varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into cn_teacher_stat_01_1
    select
        t0.assign_teacher
        ,t0.truename
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        tmp_assign_teacher_t2 t0
    left join
        (select
            id as student_id
            ,assign_teacher
        from tmp_student_user
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        -- and assign_teacher <> 0  -- 课程顾问
        )   t1
    on  t0.assign_teacher = t1.assign_teacher
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
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180923 and 20180923  -- 上课日期
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.assign_teacher
        ,t0.truename
        ,t0.job_number
    order by t0.order_id
    ;

-- 7月30日带1v4学员数：
--    7月30日这个学生是指派给这个督导的

    drop table if exists cn_teacher_stat_02;
    create temporary table cn_teacher_stat_02
    (
        assign_teacher int
        ,truename varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into cn_teacher_stat_02
    select
        t0.assign_teacher
        ,t0.truename
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        tmp_assign_teacher_t2   t0
    left join
        (select
            id as student_id
            ,assign_teacher
        from tmp_student_user
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        and assign_teacher <> 0  -- 课程顾问
        )   t1
    on  t0.assign_teacher = t1.assign_teacher
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
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180827 and 20180827
        union
        select distinct
            student_id
        from classbooking.student_class
        -- where status = 3  -- 已完成
        -- and date(from_unixtime(start_time)) between 20180827 and 20180827
        where date(from_unixtime(start_time)) between 20180827 and 20180827
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.assign_teacher
        ,t0.truename
        ,t0.job_number
    order by t0.order_id
    ;

-- 8月26日带1v4学员数：
--    8月26日这个学生是指派给这个督导的

    drop table if exists cn_teacher_stat_02_1;
    create temporary table cn_teacher_stat_02_1
    (
        assign_teacher int
        ,truename varchar(30)
        ,job_number varchar(30)
        ,cnt1 int
    );
    insert into cn_teacher_stat_02_1
    select
        t0.assign_teacher
        ,t0.truename
        ,t0.job_number
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from
        tmp_assign_teacher_t2   t0
    left join
        (select
            id as student_id
            ,assign_teacher
        from tmp_student_user
        where flag = 1  -- 真实用户
        and disable = 0  -- 不禁用
        -- and assign_teacher <> 0  -- 课程顾问
        )   t1
    on  t0.assign_teacher = t1.assign_teacher
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
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180923 and 20180923
        union
        select distinct
            student_id
        from classbooking.student_class
        -- where status = 3  -- 已完成
        -- and date(from_unixtime(start_time)) between 20180923 and 20180923
        where date(from_unixtime(start_time)) between 20180923 and 20180923
        )   t2
    on  t1.student_id = t2.student_id
    group by t0.assign_teacher
        ,t0.truename
        ,t0.job_number
    order by t0.order_id
    ;



-- 所带1v1学员完成课时数：

--    每天指派给这个督导的学生完成的课程数之和（有上课就算完成）

    drop table if exists cn_teacher_stat_03;
    create temporary table cn_teacher_stat_03
    (
        assign_teacher int
        ,cnt1 int
    );
    insert into cn_teacher_stat_03
    select
        t0.assign_teacher
        ,sum(case when t2.id is not null then 1 else 0 end) as cnt1
    from tmp_assign_teacher_t2 t0
    left join
        tmp_student_user  t1
    on  t0.assign_teacher = t1.assign_teacher
    and t1.flag = 1
    and t1.disable = 0
    left join
        newuuabc.appoint_course     t2
    on  t1.id = t2.student_User_id
    and t2.disabled = 0  -- 这个条件有问题
    and t2.course_type = 3
    and t2.class_appoint_course_id = 0
    and date(convert_tz(from_unixtime(t2.start_time), '+00:00', '+08:00')) between 20180827 and 20180923
    group by t0.assign_teacher
    order by t0.order_id
    ;


    -- appoint_sourse.status = 3
    -- and appoint_sourse.disabled = 0
    -- and appoint_course.course_type = 3
    -- and appoint_course.class_appoint_course_id = 0
    -- and student_user.flag = 1


-- 所带1v4付费学员完成课时数

--    7月30号至8月26号，有合同付费金额大于0的学员，合计这些学员的1：4完成课时

    drop table if exists cn_teacher_stat_04;
    create temporary table cn_teacher_stat_04
    (
        assign_teacher int
        ,cnt1 int
    );
    insert into cn_teacher_stat_04
    select
        t1.assign_teacher
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt1
    from tmp_assign_teacher_t2  t1
    left join
        tmp_student_user   t3
    on  t1.assign_teacher = t3.assign_teacher
    and t3.flag = 1
    and t3.disable = 0
    and t3.type = 2
    left join
        (select
            student_user_id as student_id
            ,id
        from newuuabc.appoint_course
        where disabled = 0
        and course_type = 3
        and class_appoint_course_id <> 0
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180827 and 20180923
        union all
        select
            student_id
            ,student_class_id as id
        from classbooking.student_class
        where status = 3
        and date(from_unixtime(start_time)) between 20180827 and 20180923
        )     t2
    on  t3.id = t2.student_id
    group by t1.assign_teacher
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


    drop table if exists cn_teacher_stat_05;
    create temporary table cn_teacher_stat_05
    (
        assign_teacher int
        ,cnt1 int
    );
    insert into cn_teacher_stat_05
    select
        t0.assign_teacher
        ,sum(coalesce(t5.cnt, 0))
    from tmp_assign_teacher_t2 t0
    left join
        (select
            t5.assign_teacher
            ,count(*) as cnt
        from classbooking.student_class t1
        inner join
            newuuabc.product_consume t2
        on  t1.student_class_id = t2.key
        and t1.student_id = t2.stuId
        inner join
            newuuabc.contract t3
        on  t2.contractId = t3.id
        inner join
            newuuabc.contract_template t4
        on  t3.template_id = t4.id
        and t4.id in (295, 404, 349)
        inner join
            tmp_student_user t5
        on  t1.student_id = t5.id
        and t5.flag = 1
        and t5.disable = 0
        where t1.status = 3
        and date(from_unixtime(t1.start_time)) between 20180827 and 20180923
        group by t5.assign_teacher
        )   t5
    on  t0.assign_teacher = t5.assign_teacher
    group by t0.assign_teacher
    ;

    insert into cn_teacher_stat_05
    select
        t0.assign_teacher
        ,sum(coalesce(t5.cnt, 0))
    from tmp_assign_teacher_t2 t0
    left join
        (select
            t2.assign_teacher
            ,count(*) as cnt
        from newuuabc.appoint_course t1
        inner join
            tmp_student_user t2
        on t1.student_user_id = t2.id
        and t2.flag = 1
        and t2.disable = 0
        inner join
            newuuabc.contract t3
        on  t1.contract_id = t3.id
        inner join
            newuuabc.contract_template t4
        on  t3.template_id = t4.id
        and t4.id in (295, 404, 349)
        where date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between 20180827 and 20180923
        group by t2.assign_teacher
        )   t5
    on  t0.assign_teacher = t5.assign_teacher
    group by t0.assign_teacher
    ;

-- 所带学员完成素质课课时数

    drop table if exists cn_teacher_stat_06;
    create temporary table cn_teacher_stat_06
    (
        assign_teacher int
        ,cnt1 int
    );
    insert into cn_teacher_stat_06
    select
        t0.assign_teacher
        ,sum(case when t2.student_id is not null then 1 else 0 end) as cnt
    from tmp_assign_teacher_t2 t0
    left join
        tmp_student_user   t1
    on  t0.assign_teacher = t1.assign_teacher
    and t1.flag = 1
    and t1.disable = 0
    left join
        classbooking.student_class     t2
    on  t1.id = t2.student_id
    and t2.status = 3
    and t2.class_type = 5
    and date(from_unixtime(t2.start_time)) between 20180827 and 20180923
    group by t0.assign_teacher
    ;

    -- 新：
    --     student_class.status = 3
    --     and student_user.flag = 1
    --     and student_user.type = 2
    --     and student_class.class_type= 5(素质课)
    -- 新1：4才有素质课

-- 所带学员续费金额
--    统计周期内学员的续费金额之和？

--    7月30号至8月26号，有进行续费的学员，金额总和

    drop table if exists cn_teacher_stat_07;
    create temporary table cn_teacher_stat_07
    (
        assign_teacher int
        ,amt1 double
    );
    insert into cn_teacher_stat_07
    select
        t0.assign_teacher
        ,sum(coalesce(t3.total_fee, 0) / 100) as amt1
    from tmp_assign_teacher_t2 t0
    left join
        tmp_student_user t1
    on  t0.assign_teacher = t1.assign_teacher
    and t1.flag = 1
    and t1.disable = 0
    left join
        newuuabc.contract   t2
    on  t1.id = t2.student_id
    and t2.is_del = 1
    and t2.contract_type = 1
    and t2.attribute = 2
    and ((t2.status = 3
        and date(convert_tz(from_unixtime(update_at), '+00:00', '+08:00')) between 20180827 and 20180923
        )
        or  (t2.status = 4
            and date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between 20180827 and 20180923
            )
        )
    left join
        (select
            contract_id
            ,sum(total_fee) as total_fee
        from newuuabc.contract_payment
        where is_success = 2
        group by contract_id
        )   t3
    on  t2.id = t3.contract_id
    group by t0.assign_teacher
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

--    7月30号至8月26号付费的来自至慧渠道的学员，归属到当前督导

    drop table if exists cn_teacher_stat_08;
    create temporary table cn_teacher_stat_08
    (
        assign_teacher int
        ,cnt1 int
    );
    insert into cn_teacher_stat_08
    select
        t0.assign_teacher
        ,count(distinct case when t2.id is not null
                    and t4.contract_id is not null
                    then t1.id else null end) as cnt1
    from
        tmp_assign_teacher_t2 t0
    left join
        (select
            id
            ,channel
            ,type
            ,assign_teacher
        from tmp_student_user
        where flag = 1
        and disable = 0
        -- and type = 1
        )   t1
    on  t0.assign_teacher = t1.assign_teacher
    left join
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
    on  t1.channel = t2.id
    left join
        (select
            id
            ,student_id
        from newuuabc.contract
        where is_del = 1  -- 正常
        and contract_type = 1  -- 销售合同
        and ((status = 3
            and date(convert_tz(from_unixtime(update_at), '+00:00', '+08:00')) between 20180827 and 20180923
            )
            or  (status = 4
                and date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between 20180827 and 20180923
                )
            )
        )   t3
    on  t1.id = t3.student_id
    left join
        (select distinct
            contract_id
        from newuuabc.contract_payment
        where is_success = 2
        and total_fee > 0
        )   t4
    on  t3.id = t4.contract_id
    group by t0.assign_teacher
    order by t0.order_id
    ;


-- 所带学员推荐1v1新生付费人数：
--    首次付费日期还是注册日期在统计周期内？

    drop table if exists cn_teacher_stat_09;
    create temporary table cn_teacher_stat_09
    (
        assign_teacher int
        ,cnt1 int
    );
    insert into cn_teacher_stat_09
    select
        t0.assign_teacher
        ,coalesce(t6.cnt1, 0) as cnt1
    from tmp_assign_teacher_t2  t0
    left join
        (select
            t2.assign_teacher
            ,count(*) as cnt1
        from
            (select
                id
                ,name
                ,recommended
            from tmp_student_user  t1
            where flag = 1
            and disable = 0
            and recommended > 0
            )   t1
        inner join
            newuuabc.student_user   t2
        on  t1.recommended = t2.id
        and t2.flag = 1
        and t2.disable = 0
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
            and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180827 and 20180923
            )   t4
        on  t1.id = t4.student_id
        inner join
            (select distinct
                student_id
            from newuuabc.contract
            where is_del = 1
            and contract_type = 1
            and ((status = 3
                and date(convert_tz(from_unixtime(update_at), '+00:00', '+08:00')) between 20180827 and 20180923
                )
                or  (status = 4
                    and date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between 20180827 and 20180923
                    )
                )
            )   t5
        on  t1.id = t5.student_id
        group by t2.assign_teacher
        )   t6
    on  t0.assign_teacher = t6.assign_teacher
    order by t0.order_id
    ;

-- 所带学员推荐1v4新生付费人数：
--    首次付费日期还是注册日期在统计周期内？

    drop table if exists cn_teacher_stat_10;
    create temporary table cn_teacher_stat_10
    (
        assign_teacher int
        ,cnt1 int
    );
    insert into cn_teacher_stat_10

    select
        t0.assign_teacher
        ,coalesce(t6.cnt1, 0) as cnt1
    from tmp_assign_teacher_t2 t0
    left join
        (select
            t2.assign_teacher
            ,count(*) as cnt1
        from
            (select
                id
                ,name
                ,recommended
            from tmp_student_user  t1
            where flag = 1
            and disable = 0
            and recommended > 0
            )   t1
        inner join
            newuuabc.student_user   t2
        on  t1.recommended = t2.id
        and t2.flag = 1
        and t2.disable = 0
        and t2.assign_teacher <> 0
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
            and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) between 20180827 and 20180923
            union
            select distinct
                student_id
            from classbooking.student_class
            where status = 3  -- 已完成
            and date(from_unixtime(start_time)) between 20180827 and 20180923
            )   t4
        on  t1.id = t4.student_id
        inner join
            (select distinct
                student_id
            from newuuabc.contract
            where is_del = 1
            and contract_type = 1
            and ((status = 3
                and date(convert_tz(from_unixtime(update_at), '+00:00', '+08:00')) between 20180827 and 20180923
                )
                or  (status = 4
                    and date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between 20180827 and 20180923
                    )
                )
            )   t5
        on  t1.id = t5.student_id
        group by t2.assign_teacher
        )   t6
    on  t0.assign_teacher = t6.assign_teacher
    order by t0.order_id
    ;



select
    t0.assign_teacher  -- 班主任老师
    ,t0.job_number     -- 班主任工号
    ,t0.truename       -- 班主任名字
    ,t1.cnt1           -- 7月30日带1v1学员数
    ,t1_1.cnt1         -- 8月26日带1v1学员数
    ,t2.cnt1           -- 7月30日带1v4学员数
    ,t2_1.cnt1         -- 8月26日带1v4学员数
    ,t3.cnt1           -- 所带1v1学员完成课时数
    ,t4.cnt1           -- 所带1v4付费学员完成课时数
    ,t5.cnt1           -- 所带1v4免费20课时学员完成课时数
    ,t6.cnt1           -- 所带学员完成素质课课时数
    ,t7.amt1           -- 所带学员续费金额
    ,t8.cnt1           -- 来自至慧渠道的视听学员付费人数
    ,t9.cnt1           -- 所带学员推荐1v1新生付费人数
    ,t10.cnt1          -- 所带学员推荐1v4新生付费人数
from tmp_assign_teacher_t2 t0
left join
    cn_teacher_stat_01  t1
on  t0.assign_teacher = t1.assign_teacher
left join
    cn_teacher_stat_01_1    t1_1
on  t0.assign_teacher = t1_1.assign_teacher
left join
    cn_teacher_stat_02  t2
on  t0.assign_teacher = t2.assign_teacher
left join
    cn_teacher_stat_02_1    t2_1
on  t0.assign_teacher = t2_1.assign_teacher
left join
    cn_teacher_stat_03  t3
on  t0.assign_teacher = t3.assign_teacher
left join
    cn_teacher_stat_04  t4
on  t0.assign_teacher = t4.assign_teacher
left join
    (select
        assign_teacher
        ,sum(cnt1) as cnt1
    from cn_teacher_stat_05
    group by assign_teacher
    )  t5
on  t0.assign_teacher = t5.assign_teacher
left join
    cn_teacher_stat_06  t6
on  t0.assign_teacher = t6.assign_teacher
left join
    cn_teacher_stat_07  t7
on  t0.assign_teacher = t7.assign_teacher
left join
    cn_teacher_stat_08  t8
on  t0.assign_teacher = t8.assign_teacher
left join
    cn_teacher_stat_09  t9
on  t0.assign_teacher = t9.assign_teacher
left join
    cn_teacher_stat_10  t10
on  t0.assign_teacher = t10.assign_teacher
order by t0.order_id
;



