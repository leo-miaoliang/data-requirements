# 外教老师列表


**需求来源**

提出人: 柯雁影<yanying.ke@uuabc.com>

部门:

**拉取周期**
临时

**用途**


**详细**

```
```

**SQL**

```sql
select
    id
    ,english_name
    ,case when is_old = 1 then '列表1'
        when is_old = 2 then '列表2'
        else 'unknown'
    end as type1
    ,case when comment like '%百分说%' then 1 else 0 end as is_100
from newuuabc.teacher_user_new
where status = 3
and type = 1
and disable = 1
;

SELECT
    bui.id
    ,tun.english_name
    ,IF(COALESCE(position('百分说' IN tun.comment), 0) > 0, 1, 0) AS is_Ibest
    ,bui.status
FROM sishu.bk_user_info AS bui
INNER JOIN sishu.bk_user AS bu
    ON bui.uid = bu.uid
INNER JOIN newuuabc.teacher_user_new AS tun
    ON bu.uuid = tun.uuid
WHERE bui.status IN (1, 2) -- 离职的老师: 将来根据离职日期来判断，拉取当月离职的老师
AND bui.dpid IN (SELECT id FROM sishu.bk_department WHERE parentid = 24)
AND tun.disable = 1 AND tun.status = 3 AND tun.type = 1
;
```

**备注**

