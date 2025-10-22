**Context / Current Setup:**
I have a web version of a **Flutter app hosted on Firebase Hosting**. Authentication is provided by **Firebase Auth**. My backend stack looks like this:

* **Hasura** sits in front of **Supabase Postgres** and exposes an auto-generated GraphQL API.
* Hasura also calls:

  * a **local backend (solver)** exposed via **Cloudflare Tunnel**, and
  * the **OpenAI** LLM API for inference/enrichment.
* Cloudflare handles DNS and the tunnel endpoints for my local services.
* The current request flow is: `Flutter Web (Firebase Auth) → Hasura → { Supabase Postgres, local solver via Tunnel, OpenAI }`.

**Goal / Desired Change:**
I want to simplify and move to an **edge-first architecture** where Cloudflare hosts the static Flutter site and a **single Cloudflare Worker** acts as the authenticated gateway that routes requests to three channels:

1. **Supabase (pg_graphql)** — GraphQL over Postgres (Supabase Postgres).
2. **LLM (OpenAI)** — forwarded LLM calls (with per-user rate-limiting).
3. **Solver (local server)** — routed through **Cloudflare Tunnel** to my local backend.

Authentication and authorization for database access will be handled by **Supabase Auth**. Important auth detail: **the Supabase project uses HS256 JWTs signed by `SUPABASE_JWT_SECRET`** for validation, so the Worker must verify those JWTs (locally or via Supabase) before proxying `/graphql` requests. The `/llm` and `/solver` routes do not require authentication at the Worker layer and simply forward requests to their upstream services.

High-level desired architecture:

                  └--> Cloudflare Worker (edge gateway)
                     ├-> /graphql  -> pg_graphql -> Supabase Postgres (token required)
                     ├-> /llm      -> OpenAI API (optional rate-limiting)
                     └-> /solver   -> Cloudflare Tunnel -> local solver
                                          ├-> /graphql  -> pg_graphql -> Supabase Postgres
                                          ├-> /llm      -> OpenAI API (rate-limited, audited)
                                          └-> /solver   -> Cloudflare Tunnel -> local solver
```

**Constraints / Requirements (optional):**

* Must use **Supabase Auth** as the identity provider going forward (tokens are HS256 signed using `SUPABASE_JWT_SECRET`).
* Flutter web client should require **minimal changes** (preferably just swapping endpoint URLs and using Supabase client or attaching the Supabase access token).
* Prefer **DB-enforced RLS** (use `auth.uid()` in policies) — Worker should forward or present tokens to pg_graphql in a way Postgres can use them.
* Keep secrets safe (store SUPABASE_JWT_SECRET, SUPABASE_SERVICE_ROLE, OPENAI_KEY as Worker secrets).
* Optional: Worker can implement **per-user rate limits** or logging for LLM calls, but authentication is only enforced for `/graphql`.
* Aim to remain on free/low-cost tier where practical (Workers free tier + Supabase free tier), but accept OpenAI costs as needed.

**Questions / What I need from you:**

1. Confirm this target architecture is sound and list any **security gaps** or attack vectors (e.g., token forging, service-role leakage).
2. Provide an **auth flow** that details how the Worker validates Supabase JWTs (local HS256 verification vs. Supabase `/auth/v1/user` check) and how to forward or mint tokens so `auth.uid()` works for `pg_graphql`.
3. Provide the exact **Cloudflare Worker skeleton** (JS) that:

   * verifies Supabase HS256 JWTs (using `SUPABASE_JWT_SECRET`) or calls Supabase to validate tokens for `/graphql` requests only,
   * routes requests to `/graphql`, `/llm`, `/solver`,
   * injects required headers for `/graphql` (e.g., `x-user-id`) and optionally adds rate-limits/logging for `/llm`,
   * uses Worker secrets for keys.
4. Provide **Supabase SQL examples** to enable RLS and column-level access for a sample table (`posts`) that rely on `auth.uid()` for reads/writes.
5. Provide **recommendations for safe key management** (where to store `SUPABASE_JWT_SECRET`, service role key, OpenAI key), and the minimal permissions the Worker should have.
6. Provide a **migration checklist** to move from current stack (Firebase Auth + Hasura) → new stack (Supabase Auth + Worker + pg_graphql + Tunnel) with zero/low downtime (domain/DNS steps, swapping endpoints, test verification).
7. Optionally, include code snippets for:

   * minting short-lived Supabase-compatible JWTs (if the Worker must mint tokens for any reason), and
   * a sample rate-limiter strategy (token bucket / per-user counters) for LLM endpoints in the Worker.