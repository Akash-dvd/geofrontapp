-- Migration to convert constraint and proof fields to text for Supabase compatibility.
-- Updates scalar/object constraints and proof columns and refreshes pg_graphql metadata.

begin;

alter table public.problems
    alter column scalar_constraints type text using scalar_constraints::text,
    alter column object_constraints type text using object_constraints::text,
    alter column scalar_proof type text using scalar_proof::text,
    alter column object_proof type text using object_proof::text;

commit;

do $$
begin
  perform graphql.rebuild_schema();
exception
  when undefined_function then
    raise notice 'pg_graphql extension unavailable; run `select graphql.rebuild_schema();` manually once it is installed.';
end
$$;
