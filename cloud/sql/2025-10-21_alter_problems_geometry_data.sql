-- Migration to store GeoDraw constructions as plain text and refresh pg_graphql metadata.
-- Applies the geometry_data column type change and rebuilds the GraphQL schema cache.

begin;

alter table public.problems
    alter column geometry_data type text
    using geometry_data::text;

commit;

do $$
begin
    perform graphql.rebuild_schema();
exception
    when undefined_function then
        -- pg_graphql extension is absent or outdated; continue without failing migration.
        null;
end
$$;

-- PS C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp\cloud\scripts>  .\refresh_pg_graphql.ps1 -ProjectRef ahcndokbcggdymszuhpn -ServiceRoleKey "REDACTED"
-- Triggering pg_g