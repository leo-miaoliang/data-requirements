# 班主任1on1学员信息统计


**需求来源**

提出人: 胡新星<xinxing.hu@uuabc.com>

部门:

**拉取周期**
每日（11点）


**用途**


**详细**

```
班主任ID - 班主任姓名 - 负责学员数 - 在读学员数 - 停课学员数 - 未开课学员数 - 结课学员数 - 今日接收学员 - 进入续费期学员数 - 今日续费学员数 - 今日续费金额 - 今日转介绍学员数 - 转介绍学员今日签约数 - 今日课时消耗 - 今日学生失约课时 - 当天学生绑定车位数 - 今日取消课时 - 学生账户人工返还课时数 - 今日退费人数 - 今日退费金额
```

**SQL**

```sql
-- ---------------------------------------
-- Basic


drop procedure if exists bi.teacher_stat_1on1_new;

delimiter //
create procedure bi.teacher_stat_1on1_new(in in_stat_date date)
begin

set @stat_date := in_stat_date;

-- 班主任对应的1对1学员
-- 学员已付费（未退费）的合同中若存在1对1主课课时数，那么该学员算是对应班主任的1对1学员
drop table if exists tmp_students;
create temporary table tmp_students (
    select
        a1.masterid as teacher_id
        ,a1.truename as teacher_name
        ,su.id as student_id
        ,su.name as student_name
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
    where a1.masterid in (329, 343, 380, 398, 505, 504)   -- 只需要这几个老师的数据
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
    and t2.`week` = dayofweek(@stat_date) - 1
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
        and date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) <= @stat_date
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
    where date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) > @stat_date
    and ac.class_appoint_course_id = 0   -- 1:1
    and ac.disabled = 0  -- 0正常
    and ac.course_type = 3  -- 3 正式课
    and ac.subject_id = 1
    and ac.status < 3  -- 课程状态：0 待约课；1 约课中 2上课中 3已经上课
    group by ac.student_user_id
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
            ,sum(case when partition_key = date_format(@stat_date, '%y%m%d') then flag else 0 end) as flag
            ,sum(case when partition_key = date_format(@stat_date, '%y%m%d') then disable else 0 end) as disable
            ,sum(case when partition_key = date_format(@stat_date, '%y%m%d') then assign_teacher else 0 end) as assign_teacher1
            ,sum(case when partition_key = date_format(date_sub(@stat_date, interval 1 day), '%y%m%d') then assign_teacher else 0 end) as assign_teacher2
        from bi.student_user_his
        where partition_key between date(date_sub(@stat_date, interval 1 day)) and @stat_date
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
        ,count(*) as total_student_cnt
        -- 开课学员 最近三周有上过正式课 且 剩余课时大于0
        ,sum(case when tlc.student_id is not null
                and coalesce(tlc.last_class_date, '2000-01-01') >= date_sub(@stat_date, interval 21 day)
                and (coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0)) > 0
            then 1 else 0 end
            ) as active_student_cnt
        -- 停课学员 最近三周没上过正式课 且 剩余课时大于0
        ,sum(case when tlc.student_id is not null
                and coalesce(tlc.last_class_date, '2000-01-01') < date_sub(@stat_date, interval 21 day)
                and coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0) > 0
            then 1 else 0 end
            ) as inactive_student_cnt
        -- 未开课学员 课时大于0，没上过正式课
        ,sum(case when coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0) > 0
                and tlc.student_id is null
            then 1 else 0 end
            ) as unstart_cnt
        -- 结课学员 上过正式课，当前正式课时为0
        ,sum(case when coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0) = 0
                and tlc.student_id is not null
            then 1 else 0 end
            ) as class_over_student_cnt
        -- 进入续费期学员 上过正式课，正式课时小于等于12节
        ,sum(case when tc.student_id is not null
                and (coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0)) > 0
                and (coalesce(tc.sh, 0) + coalesce(tbc.booked_cnt, 0)) <= 12
            then 1 else 0 end
            ) as class_less_student_cnt
        -- 新分配学员数
        ,sum(case when ttc.student_id is not null then 1 else 0 end) as new_assign_cnt
        -- 学员绑定车位数
        ,sum(coalesce(tscb.bind_cnt, 0)) as bind_cnt
    from tmp_students as ts
    left join tmp_last_class as tlc
    on  ts.student_id = tlc.student_id
    left join tmp_remain_class as tc
    on  ts.student_id = tc.student_id
    left join tmp_teacher_changed as ttc
    on  ts.student_id = ttc.student_id
    left join tmp_booked_class as tbc
    on  ts.student_id = tbc.student_id
    left join tmp_student_class_bind tscb
    on  ts.student_id = tscb.student_id
    group by ts.teacher_id, ts.teacher_name
);


-- 学员当天续签销售合同
drop table if exists tmp_stat_contract;
create temporary table tmp_stat_contract (
    select
        ts.teacher_id
        ,count(*) as contract_cnt
        -- , sum(contract_amount) / 100 as contract_amt
        ,sum(case when c.`attribute` = 2 and date(from_unixtime(c.sucess_at)) = @stat_date then 1 else 0 end) as renew_contract_cnt
        ,sum(case when c.`attribute` = 2 and date(from_unixtime(c.sucess_at)) = @stat_date then a.total else 0 end) / 100 as renew_contract_amt
    from newuuabc.contract as c
    inner join tmp_students as ts
    on  c.student_id = ts.student_id
    inner join
        (select
            contract_id
            ,sum(total_fee) as total
        from newuuabc.contract_payment
        where is_success = 2
        group by contract_id
        )   as a
    on  c.id = a.contract_id
    where c.is_del = 1
    and c.contract_type = 1
    and c.status = 4
    group by ts.teacher_id
);


-- select * from newuuabc.student_user where id = 133144 and flag = 1 and disable = 0;
-- select * from newuuabc.contract where student_id = 133144 and is_del = 1 and status in (3, 4) and contract_type = 1;
-- select * from newuuabc.contract_details where contract_id in (
--      select id from newuuabc.contract where student_id = 133144 and is_del = 1 and status in (3, 4) and contract_type = 1
--  ) and subject_id = 1 and total > 0;


-- -------------------------------------------------------------------------------

-- 学员当天推荐的新学员数
drop table if exists tmp_rcmd_students;
create temporary table tmp_rcmd_students (
    select
        ts.teacher_id
        ,count(*) as rcmd_cnt
    from newuuabc.student_user as su
    inner join tmp_students as ts
    on su.recommended = ts.student_id
    where su.flag = 1
    and su.disable = 0
    and date(from_unixtime(su.create_time)) = @stat_date
    group by ts.teacher_id
);

-- 被推荐学员当天签订合同数
drop table if exists tmp_rcmd_signed_student;
create temporary table tmp_rcmd_signed_student (
    select
        ts.teacher_id
        ,count(distinct su.id) as signed_cnt
    from newuuabc.student_user as su
    inner join tmp_students as ts
    on  su.recommended = ts.student_id
    inner join newuuabc.contract as c
    on  su.id = c.student_id
    and c.is_del = 1
    and c.status = 4  -- 已付费
    and c.contract_type = 1  -- 销售合同
    and date(from_unixtime(c.sucess_at)) = @stat_date
    and c.contract_amount > 0
    where su.flag = 1
    and su.disable = 0
    group by ts.teacher_id
);


-- -----------------------------------------------------------------------------

-- 学员当天消耗课时数
drop table if exists tmp_deduct_class;
create temporary table tmp_deduct_class (
    select
        ts.teacher_id
        ,sum(d.deduct_cnt) as deduct_cnt
    from tmp_students as ts
    inner join
        (select
            ac.id
            ,ac.student_user_id as student_id
            ,1 as deduct_cnt
        from newuuabc.appoint_course as ac
        inner join newuuabc.contract as c
        on  ac.contract_id = c.id
        where ac.class_appoint_course_id = 0
        and (ac.disabled = 0
            or  (ac.disabled = 1 and ac.cancel_type = 1)
            )
        and date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) = @stat_date
        and ac.course_type = 3
        group by ac.id, ac.student_user_id
        )   as d
    on  ts.student_id = d.student_id
    group by ts.teacher_id
);


-- 学员取消课时数
drop table if exists tmp_cancelled;
create temporary table tmp_cancelled (
    select
        ts.teacher_id
        ,count(*) as cancelled_cnt
        ,count(if(a.cancel_type = 1, 1, null)) as cancelled_by_student_cnt
    from tmp_students as ts
    inner join
        (select
            student_user_id as student_id
            ,cancel_type
        from newuuabc.appoint_course as ac
        where ac.class_appoint_course_id = 0
        and ac.disabled = 1
        and date(convert_tz(from_unixtime(ac.start_time), '+00:00', '+08:00')) = @stat_date
        and ac.course_type = 3
        )   as a
    on  ts.student_id = a.student_id
    group by ts.teacher_id
);

-- 学员账户人工返还课时数
drop table if exists tmp_return_coupon;
create temporary table tmp_return_coupon (
    select
        ts.teacher_id
        ,sum(a.change_num) as return_coupon_cnt
    from tmp_students as ts
    inner join
        (select
            shr.student_user_id as student_id
            ,shr.change_num
        from newuuabc.student_hours_record as shr
            -- where shr.change_type in (2, 3, 5, 6, 7, 8, 9, 12)
        where shr.change_type in (6, 7, 8, 9)
        and shr.subject_id = 1
        and date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) = @stat_date
        )   as a
    on  ts.student_id = a.student_id
    group by ts.teacher_id
);

-- ------------------------------------------------------------------------------
-- 学员当天退款合同
drop table if exists tmp_refund;
create temporary table tmp_refund (
    select
        ts.teacher_id
        ,count(*) as refund_cnt
        ,sum(a.refund_fee_cmt) as refund_fee_cmt
    from tmp_students as ts
    inner join
        (select
            c.student_id
            ,sum(cr.fee / 100) as refund_fee_cmt
        from newuuabc.contract_refund as cr
        inner join newuuabc.contract as c
        on  cr.contract_id = c.id
        and c.contract_type = 1  -- 销售合同
        and c.is_del = 1  -- 正常
        and c.status = 7  -- 已退费
        inner join newuuabc.contract_details as cd
        on  c.id = cd.contract_id
        and cd.subject_id = 1  -- 1对1主课
        and cd.total > 0  -- 课时大于0
        where cr.status = 1  -- 退款成功
        and date(convert_tz(from_unixtime(cr.refund_time), '+00:00', '+08:00')) = @stat_date  -- 推款日期
        group by c.student_id
        )   as a
    on ts.student_id = a.student_id
    group by ts.teacher_id
);

-- 学员当天所上素质课时数
drop table if exists tmp_quality_class;
create temporary table tmp_quality_class(
    select
        t1.teacher_id
        ,count(*) as quality_class_cnt
    from tmp_students t1
    inner join
        classbooking.student_class t2
    on  t1.student_id = t2.student_id
    and t2.status = 3
    and t2.class_type = 5
    and date(from_unixtime(t2.start_time)) = @stat_dat
    group by t1.teacher_id
);

-- -----------------------------------------------------------------------------


select
    tss.teacher_id as `班主任id`
    ,tss.teacher_name as `班主任姓名`
    ,tss.total_student_cnt as `负责学员数`
    ,tss.active_student_cnt as `在读学员数`
    ,tss.inactive_student_cnt as `停课学员数`
    ,tss.unstart_cnt as `未开课学员数`
    ,tss.class_over_student_cnt as `结课学员数`
    ,tss.new_assign_cnt as `今日接收学员`
    -- , contract_cnt as `销售合同数`
    -- , contract_amt as `销售合同金额总数`
    ,tss.class_less_student_cnt as `进入续费期学员数`
    ,renew_contract_cnt as `今日续费学员数`
    ,renew_contract_amt as `今日续费金额`
    ,coalesce(trs.rcmd_cnt, 0) as `今日转介绍学员数`
    ,coalesce(trss.signed_cnt, 0) as `转介绍学员今日签约数`
    ,coalesce(tdc.deduct_cnt, 0) as `今日课时消耗`
    -- , coalesce(price_amt, 0) as `课时生产现金`
    ,coalesce(tc.cancelled_by_student_cnt, 0) as `今日学生失约课时`
    ,coalesce(tss.bind_cnt, 0) as `当天学生绑定车位数`
    ,coalesce(tc.cancelled_cnt, 0) as `今日取消课时`
    ,coalesce(trc.return_coupon_cnt, 0) as `学生账户人工返还课时数`
    ,coalesce(tr.refund_cnt, 0) as `今日退费人数`
    ,coalesce(tr.refund_fee_cmt, 0) as `今日退费金额`
    ,coalesce(tqc.quality_class_cnt, 0) as '今日素质课时'
from tmp_stat_student as tss
left join tmp_stat_contract as tsc
on  tss.teacher_id = tsc.teacher_id
left join tmp_rcmd_students as trs
on  tss.teacher_id = trs.teacher_id
left join tmp_rcmd_signed_student as trss
on  tss.teacher_id = trss.teacher_id
left join tmp_deduct_class as tdc
on  tss.teacher_id = tdc.teacher_id
left join tmp_cancelled as tc
on  tss.teacher_id = tc.teacher_id
left join tmp_return_coupon as trc
on  tss.teacher_id = trc.teacher_id
left join tmp_refund as tr
on  tss.teacher_id = tr.teacher_id
left join tmp_quality_class as tqc
on  tss.teacher_id = tqc.teacher_id
;
-- ------------------------------------------------------------------------------
end //
delimiter ;

-- 班主任ID
-- 班主任姓名
-- 负责学员数
-- 在读学员数
-- 停课学员数
-- 未开课学员数
-- 结课学员数
-- 今日接收学员
-- 进入续费期学员数
-- 今日续费学员数
-- 今日续费金额
-- 今日转介绍学员数
-- 转介绍学员今日签约数
-- 今日课时消耗
-- 今日学生失约课时
-- 当天学生绑定车位数
-- 今日取消课时
-- 学生账户人工返还课时数
-- 今日退费人数
-- 今日退费金额


```

**备注**

