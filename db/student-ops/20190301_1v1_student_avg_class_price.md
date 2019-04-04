# 1v1有剩余课是学生平均课时单价


**需求来源**

提出人: 帖嫚丽<manli.tie@uuabc.com>

部门:

**拉取周期**
临时

**用途**


**详细**
D 、学生姓名、注册号码、所属班主任、学员名下一对一销售合同名称、每个销售合同中一对一课时、实际付费金额以及课时单价； 因合同和额外有赠送的课时，另需要再给到每个销售合同中一对一的总课时（包含赠送课时）、实际付费金额以及课时单价


**SQL**

```sql
select
    t1.student_id
    ,t1.student_name
    ,t1.phone
    ,t1.teacher_id
    ,t4.truename as teacher_name
    ,t2.cnt1 as remain_class_cnt
    ,t3.contract_id
    ,t3.contract_name
    ,round(t3.contract_amount / 100, 0) as contract_amount
    ,round(t3.coupon_fee / 100, 0) as coupon_fee
    ,t3.total
    ,round((t3.contract_amount - coalesce(t3.coupon_fee, 0)) / 100 / t3.total, 2) as contract_amount_avg1
    ,t3.total + t3.free_total
    ,round((t3.contract_amount - coalesce(t3.coupon_fee, 0)) / 100 / (t3.total + t3.free_total), 2) as contract_amount_avg1
    ,case when t3.student_id is null then ''
        when t3.student_id is not null and coalesce(t3.remain, 0) + coalesce(t3.free, 0) = 0 then '已结课'
        when t3.student_id is not null and coalesce(t3.total, 0) + coalesce(t3.free_total, 0) <> coalesce(t3.remain, 0) + coalesce(t3.free, 0) then '已开课'
        when t3.student_id is not null and coalesce(t3.total, 0) + coalesce(t3.free_total, 0) = coalesce(t3.remain, 0) + coalesce(t3.free, 0) then '未开课'
    end as contract_status
    ,t3.total
    ,t3.remain
    ,t3.free_total
    ,t3.free
from
    (select
        id as student_id
        ,name as student_name
        ,phone
        ,assign_teacher as teacher_id
    from newuuabc.student_user
    where assign_teacher in (329, 380, 398, 504, 505, 631, 343)
    and disable = 0
    and flag = 1
    )   t1
left join
    (select
        t1.student_id
        ,sum(t1.cnt1) as cnt1
    from
        (select
            student_id
            ,sum(school_hour) as cnt1
        from newuuabc.school_hour
        where subject_id in (1, 2)
        group by student_id
        union all
        select
            student_user_id as student_id
            ,count(1) as cnt1
        from newuuabc.appoint_course
        where class_appoint_course_id = 0
        and disabled = 0
        and date(convert_tz(from_unixtime(start_time), '+00:00', '+08:00')) > '2019-02-28'
        group by student_user_id
        )   t1
    group by t1.student_id
    having sum(t1.cnt1) > 0
    )   t2
on  t1.student_id = t2.student_id
left join
    (select
        t1.student_id
        ,t1.id as contract_id
        ,t3.name as contract_name
        ,t1.contract_amount
        ,t4.coupon_fee
        ,t2.total
        ,t2.remain
        ,t2.free
        ,t2.free_total
    from newuuabc.contract t1
    left join
        newuuabc.contract_details t2
    on  t1.id = t2.contract_id
    and t2.subject_id = 1
    left join
        newuuabc.contract_template t3
    on  t1.template_id = t3.id
    left join
        (select
            contract_id
            ,sum(card_coupons_fee) as coupon_fee
        from newuuabc.contract_payment
        where is_success = 2
        group by contract_id
        )   t4
    on  t1.id = t4.contract_id
    where t1.contract_type = 1
    and t1.status = 4
    )   t3
on  t1.student_id = t3.student_id
left join
    newuuabc.admin t4
on  t1.teacher_id = t4.masterid
where t2.student_id is not null
order by t1.student_id asc
;
```

**备注**

