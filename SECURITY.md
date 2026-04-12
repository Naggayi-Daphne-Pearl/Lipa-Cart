# Security Policy

## Supported versions

Only the `main` branch of Lipa-Cart is actively supported with security
updates. If you are running an older fork or snapshot, please rebase onto the
latest `main` before reporting.

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you believe you have found a security vulnerability in Lipa-Cart, report it
privately by:

1. Opening a [private security advisory](https://github.com/Naggayi-Daphne-Pearl/Lipa-Cart/security/advisories/new)
   on GitHub, **or**
2. Emailing the maintainer directly (contact details on the GitHub profile).

Please include:

- A description of the vulnerability and its potential impact.
- Steps to reproduce or a proof-of-concept, if available.
- Any suggested mitigation.

You can expect an initial acknowledgement within a few business days. We will
keep you informed of progress toward a fix and coordinate disclosure timing
with you.

## Scope

In scope:

- The Flutter client application (screens, providers, services, routing).
- Authentication, authorization, token storage, and session handling on
  mobile and web.
- Payment, checkout, order, and KYC flows.
- Handling of personally identifiable information (phone numbers, addresses,
  delivery details) and secure storage on device.
- CI/CD and deployment configuration files in this repository.

Out of scope:

- Vulnerabilities in upstream dependencies — report those to their respective
  projects. We track these via Dependabot.
- Vulnerabilities in the Lipa-Cart backend — report those against the
  [Lipa-Cart-Backend](https://github.com/Naggayi-Daphne-Pearl/Lipa-Cart-Backend)
  repository.
- Social engineering, physical attacks, or denial-of-service testing against
  production infrastructure.
- Issues in third-party integrations (Firebase, Sentry, map providers, mobile
  money gateways) that are not caused by our integration code.

## What we ask

- Do not exploit the vulnerability beyond what is necessary to demonstrate it.
- Do not access, modify, or delete data belonging to other users.
- Give us a reasonable amount of time to investigate and fix the issue before
  public disclosure.

Thank you for helping keep Lipa-Cart and its users safe.
