\c testdb;

select count(*) from incometest."Summary" ;

delete from incometest."Summary" where "incomeDate" < (NOW() - INTERVAL '10 DAY')::date;

select count(*) from incometest."Summary";
