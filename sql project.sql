create database bank_project;
use bank_project;

select * from customer_income;

set autocommit=off;
start transaction;

-- creating grade based on applicant_income
create table monthly_grades as select *,
case
when applicantincome > 15000 then'Grade A'
when applicantincome > 9000 then 'Grade B'
when applicantincome > 5000 then 'Middle Class Customer'
else 'Low Class'
end as Grades,
case 
when applicantIncome < 5000 and property_area = 'Rural' then 3
when applicantIncome < 5000 and property_area = 'Semi Rural' then 3.5
when applicantIncome < 5000 and property_area = 'Urban' then 5 
when applicantIncome < 5000 and property_area = 'Semi Urban' then 2.5
else 7
end as monthly_interest_percentage from customer_income;

select * from monthly_grades ; -- table 1

-- creating row level trigger for loan amount and statement level trigger for cibil score
create table loan_detial ( loan_id varchar (10),customer_id varchar (15),loan_amount text (25),
 loan_amount_term int, cibil_score int, primary key (loan_id));
drop table loan_detial  ;
select * from loan_detial ;
-- row level trigger

delimiter //
create trigger loanamount before insert on loan_detial for each row
begin 
if new.loan_amount is null then set new.loan_amount = 'Loan Still Processing';
end if;	
end //
delimiter ;
show triggers;
drop trigger loanamount;

insert into loan_detial (loan_id,customer_id ,loan_amount,
 loan_amount_term , cibil_score) select  loan_id,customer_id,loan_amount ,
 loan_amount_term , cibil_score from loan_status;

select * from loan_detial;

--   ##statement level trigger for cibil score
-- primary table 
create table cibil_score_1( loan_id varchar (10),customer_id varchar (15),loan_amount text (25),
 loan_amount_term int, cibil_score int, primary key (loan_id));
drop table cibil_score_1;
select * from cibil_score_1;
select count(*) from loan_status;

-- secondaty table
create table cibil_score_2(loan_id varchar(40), loan_amount varchar(100),
cibil_score int, cibil_score_status varchar(100));
desc cibil_score;
drop table cibil_score_2;

select * from cibil_score_2;

-- statement level trigger 

Delimiter //
create trigger cibil_score_trigger after insert on cibil_score_1 for each row
begin
insert into  cibil_score_2 (loan_id, loan_amount, cibil_score, cibil_score_status)
values (new.loan_id,new.loan_amount,new.cibil_score,
case
when new.cibil_score > 900 then 'High cibil score'
when new.cibil_score > 750 then 'No penalty'
when new.cibil_score > 0 then 'Penalty customers'
else 'Reject customers (Cannot apply loan)'
end);
end //
Delimiter ;
show triggers;
drop trigger  cibil_score_trigger;
select * from cibil_score_2; -- table 2
 --  ## insert on primary table

insert into cibil_score_1(loan_id,customer_id ,loan_amount,
 loan_amount_term , cibil_score) select  loan_id,customer_id,loan_amount ,
 loan_amount_term , cibil_score from loan_detial;

--   ##  deleting the loan still processing and reject customers
delete from cibil_score_2 where loan_amount= 'loan still processing';
delete from cibil_score_2 where cibil_score_status='Reject customers (Cannot apply loan)'; 

select * from cibil_score_2;
select count(*) from cibil_score_2;
-- Update loan as integers
alter table cibil_score_2 modify loan_amount int;

-- caluclation monthly interest
create table monthly_interests
select g.*,c.loan_amount,c.cibil_score,c.cibil_score_status,
case 
when applicantIncome<5000 and Property_Area = "rural" then (c.loan_amount *(3/100))
when applicantIncome<5000 and Property_Area = "rural" then (c.loan_amount *(3.5/100))
when applicantIncome<5000 and Property_Area = "urban" then (c.loan_amount * (5/100))
when applicantIncome<5000 and Property_Area = "semi urban" then (c.loan_amount* (2.5/100))
else (c.loan_amount*(7/100))
end as monthly_interest_calc from  monthly_grades g inner join cibil_score_2 c  on c.loan_id=g.loan_id;

select * from monthly_interests ;
-- annual intererst calculation
create table annual_interests as select *,monthly_interest_calc*12 
as anuual_interest_calc from monthly_interests ;
select * from annual_interests;-- table 3

-- customer info table 
-- Update gender and age based on customer id 
select * from customer_det; -- table - 4 

update customer_det
set Gender = case
when `Customer id` in ('IP43006', 'IP43016', 'IP43508', 'IP43577', 'IP43589', 'IP43593') then 'Female'
when `Customer id` in ('IP43018', 'IP43038') then 'Male'
else Gender
end,
Age = case 
when `Customer ID` = 'IP43007' then 45
when `Customer ID` = 'IP43009' then  32
else Age
end;

select * from monthly_grades;
select* from annual_interests ;
select* from cibil_score_2;
select * from customer_det;
select * from country_state;
select * from region_info;

-- Join all the 5 tables without repeating the fields - output 1 
drop table output_1;

create table output_1 select mg.loan_id,mg.`customer id`,mg.applicantincome,mg.coapplicantincome,mg.property_area,mg.loan_status,mg.grades,
mg.monthly_interest_percentage, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from monthly_grades  mg
inner join annual_interests ai on mg.loan_id=ai.loan_id
inner join cibil_score_2 c on ai.loan_id=c.loan_id
inner join customer_det d on mg.`customer id`=d.`customer id`
inner join country_state cs on mg.`customer id`=cs.customer_id
inner join region_info r on r.region_id=cs.region_id;

select * from output_1;
select count(*) from output_1;

-- output 2 
-- find the mismatch details using joins - output 2

select * from region_info;
select * from country_state;
select * from customer_det;
--   #####################
create table output_2 select r.*,cs.customer_id,cs.customer_name,cs.postal_code,cs.segment,cs.state,
cd.gender,cd.age,cd.married,cd.education,cd.self_employed from region_info r 
left join country_state cs on r.region_id=cs.region_id
left join customer_det cd on r.region_id=cd.region_id where cs.customer_id is null;

select * from output_2;

-- Filter high cibil score - output 3

create table output_3 select mg.loan_id,mg.`customer id`,mg.applicantincome,mg.coapplicantincome,mg.property_area,mg.loan_status,mg.grades,
mg.monthly_interest_percentage, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from monthly_grades mg
inner join annual_interests ai on mg.loan_id=ai.loan_id
inner join cibil_score_2 c on ai.loan_id=c.loan_id
inner join customer_det d on mg.`customer id`=d.`customer id`
inner join country_state cs on mg.`customer id`=cs.customer_id
inner join region_info r on r.region_id=cs.region_id where ai.cibil_score_status = "High cibil score";

select * from output_3;
select count(*) from output_3 ;

-- Filter home office and corporate - output 4

create table output_4 select mg.loan_id,mg.`customer id`,mg.applicantincome,mg.coapplicantincome,mg.property_area,mg.loan_status,mg.grades,
mg.monthly_interest_percentage, ai.loan_amount,ai.cibil_score,ai.cibil_score_status,ai.monthly_interest_calc,ai.anuual_interest_calc,
cs.region_id,cs.postal_code,cs.segment,cs.state,d.gender,d.age,d.married,d.education,d.self_employed from monthly_grades  mg
inner join annual_interests ai on mg.loan_id=ai.loan_id
inner join cibil_score_2 c on ai.loan_id=c.loan_id
inner join customer_det d on mg.`customer id`=d.`customer id`
inner join country_state cs on mg.`customer id`=cs.customer_id
inner join region_info r on r.region_id=cs.region_id where segment in("Home office", "corporate");

select * from output_4;
select count(*) from output_4;

-- Store all the outputs as procedure
drop procedure final_output;
delimiter // 
create procedure final_output ()
select * from annual_interests;
select * from monthly_grades ;
select * from cibil_score_2;
select * from country_state;
select * from customer_det;
select * from customer_income;
select * from loan_detial;
select * from loan_status;
select * from monthly_interest;
select* from region_info;
select * from output_1;
select * from output_2;
select * from output_3;
select * from output_4;
end //
delimiter ;

call final_output();

