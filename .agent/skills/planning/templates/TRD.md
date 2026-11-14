---
title:
status: draft            # draft | approved | superseded
prd: docs/product/PRD.md
approved_by:
approved_at:
---
<!-- Tier L only. How it will work. In an existing system, write the deltas
     from what is there, not the whole system again. Leave out any section
     this change does not touch. -->

# TRD: <name>

## Technical goals and constraints

## Stack
<!-- What is already in use (from recon). Anything new: why, and what was
     rejected. A new dependency needs an ADR if it is hard to remove. -->

## Design
<!-- Components and boundaries, and the path of one request through them. -->

## Data model
<!-- New and changed tables or documents, keys, indexes, migrations and how
     existing rows are handled. -->

## API
<!-- Routes or messages, request and response shape, error shape. -->

## Auth and permissions
<!-- Who may do what. Reuse the existing pattern or say why not. -->

## Failure modes
<!-- What breaks, how it is noticed (logs, metrics), how it recovers. -->

## Testing
<!-- What is tested at which level, and what is knowingly not tested. -->

## Rollout
<!-- Order of deploys and migrations, flags, how to roll back. -->

## Technical risks and open questions
