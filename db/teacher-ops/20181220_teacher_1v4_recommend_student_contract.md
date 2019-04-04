# 1v4班主任所带学员推荐学员每周购买合同信息


**需求来源**

提出人: "王艺霏"<yifei.wang@uuabc.com>;

部门:

**拉取周期**
每周一

**用途**
       为统计每周班主任转介绍工作进度及数据统计等，需自今日起每周拉取的转介绍数据。具体维度如下：

      【被推荐人ID】【被推荐人姓名】【合同包名称】【付费金额】【所属顾问】【所属班主任】【推荐人ID】【推荐人姓名】【所属顾问】【所属班主任】

注：1.所属顾问及所属班主任分别为被推荐人和推荐人的；
       2.合同包名称及付费金额为被推荐人的1v4销售合同，付费金额为实际付款金额。
**详细**

```
```

**SQL**

```sql
set @start_date := 周一;  -- 替换时间
set @end_date := 周天; -- 替换时间
SELECT
    a1.id
    ,a1.name
--    ,a5.id
    ,a6.name
    ,a6.amount
    ,a5.contract_amount
    ,coalesce(a4.truename, '') as assign_consultant
    ,coalesce(a3.truename, '') as assign_teacher
    ,a2.id
    ,a2.name
    ,a2.assign_consultant
    ,a2.assign_teacher
from newuuabc.student_user  a1
inner join
    (SELECT
        t1.id
        ,t1.name
        ,coalesce(t3.truename, '') as assign_consultant
        ,t2.truename as assign_teacher
    from
        newuuabc.student_user t1
    inner join
        (SELECT
            masterid
            ,truename
        from newuuabc.admin
        where masterid in (401 ,581 ,618 ,399 ,388 ,446 ,445 ,611 ,600 ,493 ,460 ,461 ,447 ,468)
        )   t2
    on  t1.assign_teacher = t2.masterid
    left join
        newuuabc.admin  t3
    on  t1.assign_consultant = t3.masterid
    where t1.flag = 1
    and t1.disable = 0
    )   a2
on  a1.recommended = a2.id
left join
    newuuabc.admin  a3
on  a1.assign_teacher = a3.masterid
left join
    newuuabc.admin  a4
on  a1.assign_consultant = a4.masterid
left join
    newuuabc.contract   a5
on  a1.id = a5.student_id
and a5.contract_type = 1
and a5.is_del = 1
and a5.contract_amount > 0
and a5.status in (3, 4)
left join
    newuuabc.contract_template a6
on  a5.template_id = a6.id
where a1.flag = 1
and a1.disable = 0
and date(from_unixtime(a1.create_time)) between @start_date and @end_date
;

```

**备注**

