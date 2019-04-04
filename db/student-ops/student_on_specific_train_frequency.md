# 车次频率更改数据支持


**需求来源**

提出人: 王艺霏<yifei.wang@uuabc.com>

部门:

**拉取周期**

临时

**用途**


**详细**

```
背景：
    0625-0723所有语言线四次课频的暑期班，已最终确定，统一更改每趟车次频率为一周两节。
    班主任需求0625-0723车次上的付费&非付费（非付费为剩余课时数为2课时和大于3课时的）正在上课的学生名单，统一安排电话告知家长开学后的上课计划。

所需名单来源：
    车次为：0625-0723所有四次课频的语言课（）
    学生为：每趟车上付费学员&非付费学员
          注：付费学生必须满足实际支付金额大于0
                非付费要求在车上的，且剩余课时为2课时和3课时以上的学员，即不包括0、1、3课时的学生

所需名单维度：
   【车次ID】【车次名称】【学生ID】【学生姓名】【手机号码】【是否付费】【剩余课时】【所属督导】【所属顾问】

    由于该批学生下周需正常约课上课，所以需求比较紧急！麻烦请在明天9月5日12点前给出名单。
```

**SQL**

```sql
DROP TABLE IF EXISTS tmp_train;

CREATE TEMPORARY TABLE tmp_train(
	SELECT t.train_id, t.name, FROM_UNIXTIME(t.start_date) AS start_date
	FROM classschedule.train AS t
	WHERE t.frequency = 4 AND t.status = 1
		AND t.start_date >= UNIX_TIMESTAMP('2018-06-25')
		AND t.start_date <= UNIX_TIMESTAMP('2018-07-23')
		AND t.finish_date IS NULL
);

DROP TABLE IF EXISTS tmp_paid_student;

CREATE TEMPORARY TABLE tmp_paid_student(
	SELECT
	    DISTINCT ct.student_id, 'Y' AS is_paid
	FROM newuuabc.contract ct
	    INNER JOIN newuuabc.contract_payment cp on ct.id = cp.contract_id
	    	AND cp.total_fee > 0
	    	AND cp.is_success = 2
)

DROP TABLE IF EXISTS tmp_free_student;

CREATE TEMPORARY TABLE tmp_free_student (
	SELECT su.id AS student_id, 'N' AS is_paid
	FROM newuuabc.student_user AS su
		INNER JOIN newuuabc.school_hour AS sh
			ON su.id = sh.student_id
				AND sh.subject_id IN (7, 8)
				AND (sh.school_hour = 2 OR sh.school_hour > 3)
	WHERE su.id NOT IN (SELECT student_id FROM tmp_paid_student)
);


SELECT tt.train_id AS `车次ID`
	, tt.name AS `车次名称`
	, tt.start_date AS `发车时间`
	, ts.student_id AS `学生ID`
	, su.name AS `学生姓名`
	, su.phone AS `手机号码`
	, ts.is_paid AS `是否付费`
	, sh.school_hour AS `剩余课时`
	, a1.truename AS `所属督导`
	, a2.truename AS `所属顾问`
FROM classbooking.passenger AS p
	INNER JOIN tmp_train AS tt
		ON p.train_id = tt.train_id
	INNER JOIN (
		SELECT * FROM tmp_paid_student
		UNION ALL
		SELECT * FROM tmp_free_student
	) AS ts
		ON p.student_id = ts.student_id
	INNER JOIN newuuabc.student_user AS	su
		ON ts.student_id = su.id
	INNER JOIN newuuabc.school_hour AS sh
		ON sh.student_id = p.student_id
			AND sh.subject_id IN (7, 8)
			AND sh.school_hour > 0
	LEFT JOIN newuuabc.admin AS a1
		ON su.assign_teacher = a1.masterid
	LEFT JOIN newuuabc.admin AS a2
		ON su.assign_consultant = a2.masterid
WHERE p.status = 1 AND su.flag = 1

```

**备注**

