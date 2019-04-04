# 车次学生列表


**需求来源**

提出人: 王艺霏<yifei.wang@uuabc.com>

部门:

**拉取周期**
临时

**用途**


**详细**



**SQL**

```sql
select
    t1.train_id
    ,t7.name
    ,t1.student_id
--  ,t1.status
    ,t2.name as student_name
    ,t2.phone
    ,case when t3.student_id is not null then '是' else '否' end is_pay
    ,t4.school_hour
    ,t5.truename
--  ,case when t6.id is null then 1 else 0 end as is_true
from
    (select
        train_id
        ,student_id
        ,status
    from classbooking.passenger
--  where train_id in (71, 120)
    where status = 1
    )   t1
left join
    newuuabc.student_user t2
on  t1.student_id = t2.id
left join
    (select distinct
        student_id
    from newuuabc.contract
    where status = 4
    and contract_type = 1
    and contract_amount > 0
    )   t3
on  t1.student_id = t3.student_id
left join
    newuuabc.school_hour t4
on  t1.student_id = t4.student_id
and t4.subject_id = 7
left join
    newuuabc.admin t5
on  t2.assign_teacher = t5.masterid
inner join
    newuuabc.student_user t6
on  t1.student_id = t6.id
and t6.flag = 1
and t6.disable = 0
inner join
    classschedule.train t7
on  t1.train_id = t7.train_id
and t7.status = 1
;
```

**备注**

