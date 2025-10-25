begin
grant insert (title, description, difficulty, category, geometry_data, solution,
-- Deprecated migration retained for historical reference.
-- The base schema in problems_schema.sql already preserves status values and
-- grants insert privileges on the status column.
-- No action required when bootstrapping a fresh environment.
