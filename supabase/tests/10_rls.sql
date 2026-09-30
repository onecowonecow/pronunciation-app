\set ON_ERROR_STOP on
create temp table _r(ok boolean, msg text);
insert into auth.users(id) values ('00000000-0000-0000-0000-00000000000a'),('00000000-0000-0000-0000-00000000000b');
grant usage on schema public, auth to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on _r to authenticated; grant insert on _r to authenticated;

do $$ begin
  assert (select count(*) from profiles)=2, 'signup trigger creates profiles';
  assert (select count(*) from entitlements)=2, 'signup trigger creates entitlements';
end $$;

insert into attempts(user_id,mode,overall,result_json) values ('00000000-0000-0000-0000-00000000000a','scripted',80,'{}');
insert into xp_events(user_id,amount,reason,week) values ('00000000-0000-0000-0000-00000000000a',10,'practice','2026-09-28');
update profiles set is_public=true, display_name='Ann' where id='00000000-0000-0000-0000-00000000000a';

set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000b';
do $$ begin
  assert (select count(*) from attempts)=0, 'B cannot see A attempts';
  assert (select count(*) from profiles)=1, 'B sees only own profile';
  begin insert into attempts(user_id,mode,overall,result_json) values ('00000000-0000-0000-0000-00000000000b','free',99,'{}');
    assert false, 'client insert into attempts must fail';
  exception when insufficient_privilege then null; end;
end $$;
do $$ declare n int; begin
  update entitlements set premium=true; get diagnostics n = row_count;
  assert n=0, 'client cannot flip premium (no update policy)';
end $$;
do $$ begin
  assert (select count(*) from weekly_leaderboard)=1, 'leaderboard shows public users';
  assert (select xp from weekly_leaderboard)=10, 'leaderboard xp';
end $$;
reset role;

-- free-tier cap
do $$ declare a int; begin
  a := consume_daily_words('00000000-0000-0000-0000-00000000000a','2026-09-30',15,20); assert a=15;
  a := consume_daily_words('00000000-0000-0000-0000-00000000000a','2026-09-30',15,20); assert a=5, 'only 5 left';
  a := consume_daily_words('00000000-0000-0000-0000-00000000000a','2026-09-30',3,20); assert a=0;
  a := consume_daily_words('00000000-0000-0000-0000-00000000000a','2026-10-01',3,20); assert a=3, 'new day resets';
end $$;
select 'RLS + cap tests passed' as result;
