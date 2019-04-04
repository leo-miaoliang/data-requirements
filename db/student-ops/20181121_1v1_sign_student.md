# 2017年8月8号 - 2017年11月26号购买1-1课程包的学员信息 


**需求来源**

提出人: 黄海<hai.huang@uuabc.com>

部门:

**拉取周期**

临时

**用途**


**详细**

```
请协助提供2017年8月8号 - 2017年11月26号购买1-1课程包的学员信息：
合同金额为： 9900 / 19800 / 39600
表头信息包括： 学员ID / 姓名 / 手机号码
```

**SQL**

```sql
select
    t1.student_id
    ,t2.name
    ,t2.phone
from
    (select distinct
        student_id
    from newuuabc.contract
    where contract_type = 1
    and status in (3, 4)
    and contract_amount in (990000, 1980000, 3960000)
    and date(convert_tz(from_unixtime(sucess_at), '+00:00', '+08:00')) between 20170808 and 20171126
    -- and date(convert_tz(from_unixtime(create_at), '+00:00', '+08:00')) between 20170808 and 20171126
    )   t1
inner join
    newuuabc.student_user t2
on  t1.student_id = t2.id
and t2.flag = 1
and t2.disable = 0
;
```

**备注**

