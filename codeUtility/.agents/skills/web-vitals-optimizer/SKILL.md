---
name: web-vitals-optimizer
description: Audit and optimize Core Web Vitals (LCP, CLS, INP, FID, TTFB) for Web apps, Next.js, and React. Trigger when user requests performance optimization, fixing page speed, reducing layout shift, or improving Core Web Vitals.
---

# Core Web Vitals Optimizer Skill

Optimize web application speed, rendering performance, and user interaction responsiveness.

## Core Web Vitals Metrics & Targets

- **LCP (Largest Contentful Paint)**: < 2.5s
- **CLS (Cumulative Layout Shift)**: < 0.1
- **INP (Interaction to Next Paint)**: < 200ms
- **TTFB (Time to First Byte)**: < 800ms

## Optimization Strategies

### 1. LCP (Largest Contentful Paint)
- Priority load hero images with `priority` / `fetchpriority="high"`.
- Use modern image formats (`.webp`, `.avif`).
- Preload critical fonts and CSS.

### 2. CLS (Cumulative Layout Shift)
- Always specify `width` and `height` (or aspect-ratio) on `<img>`, `<iframe>`, and video elements.
- Reserve layout space for dynamic ads/banners to prevent content jumping.
- Use `font-display: swap` with matching fallback fonts.

### 3. INP (Interaction to Next Paint)
- Break heavy JS execution tasks using `requestAnimationFrame` or `setTimeout`.
- Defer non-critical scripts (`defer`, `async`, or Next.js `next/script` `strategy="lazyOnload"`).
- Minimize re-render scope using React `useCallback`, `useMemo`, and atomic state management.

### 4. Bundle & Asset Optimization
- Dynamically import large client-only components (`React.lazy` or Next.js `dynamic()`).
- Tree-shake icon libraries and heavy dependencies.
