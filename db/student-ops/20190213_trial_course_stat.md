# 1月15号到现在试听课的数据


**需求来源**

提出人: 刘侃<kan.liu@uuabc.com>

部门:

**拉取周期**
临时

**用途**


**详细**
1月15号到现在试听课的数据，开放了多少节，取消了多少节，一共多少节，参加了多少人。然后每个人的付费状态以及付费时间
（我需要看一下参加试听课的学员是否是已付费学员）


**SQL**

```sql
select
    date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) as date1
    ,count(distinct t1.id) as cnt1
    ,count(distinct case when t1.disabled = 1 then t1.id else null end) as cnt2
    ,count(distinct case when t1.disabled = 0 then t1.id else null end) as cnt3
    ,count(distinct case when t1.disabled = 0 and t2.status = 3 and t2.disabled = 0 and t3.flag = 1 and t3.disable = 0 then t3.id else null end) as cnt4
    ,count(distinct case when t1.disabled = 0 and t2.status = 3 and t2.disabled = 0 and t3.flag = 1 and t3.disable = 0 and t4.student_id is not null then t2.student_user_id else null end) as cnt5
from newuuabc.class_appoint_course t1
left join
    newuuabc.appoint_course t2
on  t1.id = t2.class_appoint_course_id
left join
    newuuabc.student_user t3
on  t2.student_user_id = t3.id
left join
    (select distinct
        a1.student_id
    from newuuabc.contract a1
    where a1.status = 4
    and a1.contract_amount > 0
    )   t4
on  t3.id = t4.student_id
where t1.course_type = 1
and date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between '2019-01-15' and '2019-02-11'
and t1.id <> 0
group by date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00'))
;

select
    date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) as date1
    ,t4.student_name
    ,t4.contract_name
    ,round(t4.contract_amount, 2)
    ,t4.create_at
    ,t4.pay_status
from newuuabc.class_appoint_course t1
inner join
    newuuabc.appoint_course t2
on  t1.id = t2.class_appoint_course_id
and t2.status = 3
and t2.disabled = 0
inner join
    newuuabc.student_user t3
on  t2.student_user_id = t3.id
and t3.disable = 0
and t3.flag = 1
inner join
    (select
        a1.student_id
        ,a3.name as student_name
        ,a1.template_id
        ,a2.name as contract_name
        ,a1.contract_amount / 100 as contract_amount
        ,case when a1.status = 4 then '已付费' else '未付费' end as pay_status
        ,convert_tz(from_unixtime(a1.create_at), '+00:00', '+08:00') as create_at
    from newuuabc.contract a1
    left join
        newuuabc.contract_template a2
    on  a1.template_id = a2.id
    left join
        newuuabc.student_user a3
    on  a1.student_id = a3.id
    where a1.contract_amount > 0
    )   t4
on  t3.id = t4.student_id
where t1.course_type = 1
and date(convert_tz(from_unixtime(t1.start_time), '+00:00', '+08:00')) between '2019-01-15' and '2019-02-11'
;
```

**备注**

