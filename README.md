# Smart School DRC Hub 2

Smart School DRC Hub 2 is a school-management application for primary and secondary schools in the Democratic Republic of the Congo. The project includes a React web application with French and English interface support and role-oriented school workflows.

## Project status

The current application is built with React, TypeScript, TanStack Start, Vite, and Supabase. It includes frontend routes and screens for school administration, teachers, students, and platform administration, alongside Supabase integrations and server functions. The presence of a screen does not mean that every workflow is complete or ready for production; backend coverage and operational readiness still need to be verified feature by feature.

The planned target architecture is **Node.js, Express, and MySQL**. That backend migration is not complete: the application still contains Supabase client integrations, Supabase migrations, and Supabase-specific authentication and storage assumptions. The checked-in MySQL schema and mapping are planning drafts, not an implemented or validated replacement backend.

## Current technology

| Area | Current setup |
| --- | --- |
| Language | TypeScript |
| UI | React 19 |
| Application framework and routing | TanStack Start v1 and TanStack Router (file-based routes) |
| Development and build tool | Vite 8 |
| Data and authentication integration | Supabase JavaScript client (`@supabase/supabase-js`) |
| Database migrations | Supabase/PostgreSQL SQL files in `supabase/migrations/` |
| Styling | Tailwind CSS v4, configured through `src/styles.css` and the Vite setup |
| UI components | shadcn/ui components built on Radix UI primitives, in `src/components/ui/` |
| Server-side application code | TanStack Start server functions and server routes |

Additional libraries are listed in `package.json`.

### Planned target backend

The intended migration target is Node.js with Express and MySQL. Express API routes, a MySQL application database, authentication and authorization services, and replacement file-storage and server-processing services are planned work. They are not represented as completed functionality in this repository. The proposed schema and migration notes are in [`migration-planning/`](migration-planning/).

## Requirements

- Node.js `^20.19.0` or `>=22.12.0` (the Vite version in the lockfile declares this requirement)
- npm (the repository includes `package-lock.json`)
- Git

## Local setup

Clone the repository and enter its directory. Replace the placeholder URL with the repository URL you use:

```sh
git clone https://github.com/DavidSIMBI/smart-school-drc-hub2.git
cd smart-school-drc-hub2
```

Create your local environment file from the example:

```sh
cp .env.example .env
```

Set the Supabase project values in `.env` for the current integration. Do not commit `.env` or put private server credentials in `VITE_*` variables; Vite-exposed variables are available to browser code.

Start the development server:

```sh
npm run dev
```

The configured development server is available at <http://localhost:8080>.

## Available npm scripts

| Command | Purpose |
| --- | --- |
| `npm run dev` | Start the Vite development server |
| `npm run build` | Create a production build |
| `npm run build:dev` | Build using development mode settings |
| `npm run preview` | Preview the production build locally |
| `npm run lint` | Run ESLint |
| `npm run format` | Format files with Prettier |

## Environment variables

The checked-in `.env.example` documents the variables used by the current Supabase browser client:

| Variable | Purpose |
| --- | --- |
| `VITE_SUPABASE_URL` | Supabase project URL |
| `VITE_SUPABASE_PUBLISHABLE_KEY` | Supabase publishable/anonymous client key |
| `VITE_SUPABASE_PROJECT_ID` | Supabase project reference |

Keep service-role keys, signing secrets, and other private credentials server-side. Do not expose them through `VITE_*` variables.

## Repository layout

```text
src/
  assets/                    Images used by the interface
  components/                Shared site, dashboard, and UI components
  integrations/supabase/     Current Supabase client and auth integration
  lib/                       Shared logic and TanStack Start server functions
  routes/                    File-based pages and API routes
  router.tsx                 Router setup
  server.ts                  Server entry wrapper
  start.ts                   TanStack Start setup
  styles.css                 Tailwind CSS v4 styles and theme tokens
supabase/
  config.toml                Supabase local configuration
  migrations/                Checked-in PostgreSQL migration history
migration-planning/
  README.md                  Draft migration status and schema decisions
  schema-mapping.md          Draft source-to-target mapping and open questions
  schema.mysql.sql           Proposed MySQL DDL; not applied
package.json                 Dependencies and npm scripts
vite.config.ts               Vite and TanStack Start configuration
tsconfig.json                TypeScript configuration
.env.example                 Environment variable template
```

`src/routeTree.gen.ts` is generated by the TanStack Router tooling; do not edit it manually.

## Backend migration roadmap

The repository contains early planning artifacts for a possible Supabase-to-MySQL migration. `migration-planning/README.md` describes the MySQL schema as a draft and says it has not been applied to a database. The mapping identifies unresolved decisions and calls for checking the checked-in migration history against the live Supabase schema before implementation.

Before treating the planned Node.js, Express, and MySQL architecture as operational, the work still includes confirming the source schema and data, finalizing identity and session migration, implementing API authorization and school isolation, translating database behavior, replacing storage and external-service integrations, and validating migration and application behavior. See [`BACKEND_FEATURES_TO_IMPLEMENT_LATER.md`](BACKEND_FEATURES_TO_IMPLEMENT_LATER.md) for the frontend-facing backend requirements and [`migration-planning/`](migration-planning/) for the current draft artifacts.

No claim is made here that this migration is complete, that the application has passed a particular test suite, or that it is deployed to production.
