---
name: semgrep-security
description: Scan code for security vulnerabilities, hardcoded secrets, SQL injection, XSS, SSRF, and broken authorization before committing or deploying code. Trigger when user requests security audit, vulnerability scan, secret check, or code hardening.
---

# Semgrep Security & Vulnerability Audit Skill

Use this skill to audit code for security flaws, hardcoded credentials, and common OWASP Top 10 vulnerabilities.

## Core Security Rules

### 1. Hardcoded Credentials & Secrets
- Never commit API keys, JWT secrets, passwords, or private keys.
- Store credentials in `.env` or secret manager (`process.env.SECRET`).

### 2. Injection Prevention (SQLi & Command Injection)
- Always use parameterized queries or ORM bindings (Prisma, Drizzle, Kysely, Postgres).
- Never concatenate unvalidated user inputs directly into raw SQL strings or shell commands.

### 3. XSS (Cross-Site Scripting)
- Sanitize HTML inputs (DOMPurify, sanitize-html).
- Avoid `dangerouslySetInnerHTML` in React / Next.js without strict sanitization.

### 4. SSRF & Path Traversal
- Validate URLs before fetching external endpoints.
- Sanitize file paths using `path.basename()` to prevent `../` directory traversal.

## Verification & Audit Workflow
1. Scan changed files for credentials and risky function calls.
2. Verify all user-controllable input channels.
3. Confirm `.env.local` or `.env` is listed in `.gitignore`.
