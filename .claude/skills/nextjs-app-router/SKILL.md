---
name: nextjs-app-router
description: Enforce correct Next.js App Router patterns — server/client separation, data fetching, route handlers. Use when building or modifying Next.js pages, components, or API routes.
---

# Next.js App Router

Implement and modify Next.js App Router code correctly.

## Rules

- Default to server components unless interactivity is required
- Use client components only when needed (state, effects, browser APIs)
- Keep data fetching on the server when possible
- Use route handlers for API endpoints
- Do not mix client/server logic unnecessarily

## Patterns

### Server Component
- Fetch data directly in component
- No useEffect or client-side fetching unless required
- async/await at the component level

### Client Component
- Only when: user interaction, browser APIs, local state needed
- Mark with `"use client"` at file top
- Keep as small/leaf-level as possible

### Route Handlers
- Located in `/app/api/*/route.ts`
- Handle backend logic, validation, and responses
- Use NextRequest/NextResponse

## Anti-Patterns (block these)
- Overusing `"use client"`
- Fetching data in client when server can do it
- Mixing UI and business logic in one file
- Creating unnecessary API routes for server-side logic
- Using `useEffect` for data that could be fetched server-side
