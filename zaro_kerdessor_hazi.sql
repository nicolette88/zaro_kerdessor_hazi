show databases;
use employees;

-- 1. Feladat 
-- Kérdezd le az átlagos jövedelmént a férfi és női dolgozóknak minden részlegben (a lekérdezést nem, és dept_no alapján csoportosítst)
select employees.gender, dept_no, avg(employees.salaries.salary) as avarage_salary
from employees.employees
join employees.salaries using(emp_no)
join employees.dept_emp using(emp_no)
group by gender, dept_no;

-- 2. Feladat 
-- Keresd meg a legalacsonyabb értékű részleg (department) számot a dept_emp táblában, majd a legmagasabbat is.
select min(dept_no) as 'Legalacsonyabb értékű részleg', max(dept_no) as  'Legmagasabbat értékű részleg'
from dept_emp;

-- 3. Feladat
-- Kérdezd le az alábbi mezők értékeit minden dolgozónak akinél a dolgozói szám 
-- (employee number) nem nagyobb mint 10040:
-- Employee number
-- A legalacsonyabb részleg szám azok közül amely részlegekben a dolgozó dolgozott (segítség: használj subquery-t ennek az értéknek a lekérdezéséhez, a dept_emp táblából)
-- Egy manager oszlop aminek az értéke 110022 ha az employee number alacsonyabb vagy egyenlő 10020-al, és 110039 abban az esetben ha az employee number 10021 és 10040 közé esik (ezeket is beleértve)
select emp.emp_no, min(dept_emp.dept_no) as dept_no,
case 
	when emp.emp_no <= 10020 then 110022
	else 110039
    end as manager
from employees as emp
	inner join dept_emp on emp.emp_no = dept_emp.emp_no
where emp.emp_no <= 10040
group by emp.emp_no;

-- 4. Feladat 
-- Készíts egy lekérdezést azokról a dolgozókról akik 2000-ben lettek felvéve
select * from employees 
where year(hire_date) = 2000;

-- 5. Feladat
-- ! Hogy ne legyen túl lassú a lekérdezés, elég csak az első 10 eredményt kiíratni. (limit 10;)
-- Készíts egy listát minden dolgozóról akik a titles tábla alapján "engineer"-ek.
select * from titles
where title like '%Engineer%'
limit 10;

-- Készíts egy másik listát a senior engineer-ekről is.
select * from titles
where title like '%Senior Engineer%'
limit 10;

-- 6. Feladat
-- Készíts egy procedúrát (last_dept) ami egy employee number alapján visszadja hogy az adott dolgozó melyik részlegen dolgozott utoljára. Hívd meg a procedúrát a 10010-es dolgozóra. 
-- Ha jól dolgoztál az eredmény az kell hogy legyen hogy a 10010-es dolgozó a "Quality Management" osztályon dolgozott (department number 6)
-- készítsünk egy procedúrát ami az összes dolgozó átlagfizetését kiszámolja
drop procedure if exists last_dept;
delimiter $$
-- függvény készítés bemeneti paraméterrel ami szám
create procedure last_dept(in p_emp_no integer)
begin
	-- megjelenítendő adatok
	select demp.emp_no, dep.dept_name, demp.dept_no
	from dept_emp as demp
		inner join departments as dep on demp.dept_no = dep.dept_no
	 where demp.emp_no = p_emp_no and demp.from_date = (
		select max(from_date)
		from dept_emp
		where emp_no = p_emp_no
        )
	group by demp.emp_no;
end$$
delimiter ;
-- függvény hívás a 10010-es dolgozóra
call last_dept(10010);

-- 7. Feladat 
-- Hány szerződést regisztráltak a salaries táblában amelynek a hossza több volt mint egy év és az értéke több mint $100 000 ?
-- Tipp: Hasonlítsd össze a start és end date közötti különbségeket.
select count(salary) as 'Salaries táblában'
from salaries
where datediff(to_date, from_date) > 365 and salary >= 100000;

-- 8. Feladat
-- Készíts egy trigger-t ami ellenőrzi hogy egy dolgozó felvételének dátuma nagyobb e mint a jelenlegi dátum. Ha ez igaz, állítsd a felvétel dátumát a mai dátumra. Formázd a dátumot megfelelően (YY-mm-dd).
-- Ha a trigger elkészült futtasd az alábbi kódot hogy megnézd sikerült e a triggert elkészíteni:
-- use employees;
-- insert employees values('999904', '1970-01-31', 'John', 'Johnson', 'M', '2025-01-01');
-- select * from employees order by emp_no desc limit 10;
drop trigger if exists trigger_emp_hire_date;
delimiter $$
create trigger trigger_emp_hire_date
before insert on employees
for each row
begin
	declare actualDate date;
	if new.hire_date > current_date() then
		-- Error Code 1292-őt kaptam (YY-mm-dd) formátumnál ezért váltottam (%Y-%m-%d)-ra
		SELECT DATE_FORMAT(current_date(), '%Y-%m-%d') INTO actualDate;
		set new.hire_date = actualDate;
	end if;
end$$
delimiter ;

-- ellenőrzés
use employees;
insert employees values('999907', '1970-01-31', 'John', 'Johnson', 'M', '2025-01-01');
select * from employees order by emp_no desc limit 10;

-- 9. Feladat
-- Készíts egy függvényt ami a megkeresi a legmagasabb fizetését egy adott dolgozónak (employee no. alapján). Próbáld ki a függvényt a 11356-as számú dolgozón.
-- Készíts egy másik függvényt ami pedig a legalacsonyabb fizetést találja meg hasonlóan employee no. alapján. 

-- Maximum kesesés
use employees;
-- megoldás arra amiért nem fudott létrehozni függvényt:  https://www.programmerall.com/article/6794692399/
set global log_bin_trust_function_creators=TRUE;
drop function if exists f_highest_salary;
delimiter $$
-- függvény készítés be/kimeneti paraméterrel ami szám
create function f_highest_salary(p_emp_no integer) returns integer
begin
	declare hi_salary integer;
    select max(salaries.salary)
	into hi_salary 
	from employees
		inner join salaries using(emp_no)
	where emp_no = p_emp_no;
	return hi_salary;
end$$
delimiter ;

-- fv. futtatás
select f_highest_salary(11356);

-- Minimum keresés
drop function if exists f_lowest_salary;
delimiter $$
-- függvény készítés be/kimeneti paraméterrel ami szám
create function f_lowest_salary(p_emp_no integer) returns integer
begin
	declare lo_salary integer;
    select min(salaries.salary)
	into lo_salary 
	from employees
		inner join salaries using(emp_no)
	where emp_no = p_emp_no;
	return lo_salary;
end$$
delimiter ;

-- fv. futtatás
select f_lowest_salary(11356);



-- 10. Feladat
-- Az előző feladat alapján készíts egy új függvényt amely egy második paramétert is felhasznál. Ez a paraméter egy karaktersorozat legyen. Ha a karaktersorozat értéke 'min', akkor a legalacsonyabb fizetést keresse, ha 'max' akkor a legmagasabbat. Ehhez a feladathoz használd fel a 9. feladatban készített függvény logikáját. 
-- Ha a függvény második paramétere nem 'min' és nem is 'max' akkor minden más esetben a függvény a legmagasabb és legalacsonyabb fizetés különbségét adja vissza.
drop function if exists f_multiparam_salary;
delimiter $$
-- függvény készítés be/kimeneti paraméterrel ami szám & string
create function f_multiparam_salary(p_emp_no integer, p_string varchar(256)) returns integer
begin
	declare multiparam_salary integer;
    select
		case
			when p_string = 'min' then min(salaries.salary)
			when p_string = 'max' then max(salaries.salary)
			else max(salaries.salary) - min(salaries.salary)
		end as result
		
	into multiparam_salary 
	from employees
		inner join salaries using(emp_no)
	where emp_no = p_emp_no
    group by emp_no;
    
	return multiparam_salary;
end$$
delimiter ;
    
-- fv. futtatás
select f_multiparam_salary(11356, 'min') as 'Legalacsonyabb fizetés';
select f_multiparam_salary(11356, 'max') as 'Legmagasabb fizetés';
select f_multiparam_salary(11356, 'none') as 'Legmagasabb és legalacsonyabb fizetés különbsége';
