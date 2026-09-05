---
layout: post
title: Why traceability matters — the password hash nobody broke
date: 2026-09-05 10:00:00 +0200
description: Salted SHA-256 is unbreakable, and an admin can still log in as any user in four steps without breaking it. What hashing protects, what it does not, and the one trigger that lets you notice.
tags: [Security, Traceability, Identity, Explainer]
---

Passwords are stored as a salted hash. Nobody can reverse SHA-256, so the passwords are safe. Both statements are true, and neither one stops the attack below.

## Four steps, no cryptography

An administrator with write access to the `users` table wants to act as Ana.

1. Copy Ana's current `password_hash` and `salt` somewhere safe.
2. Overwrite them with the hash and salt of a password the admin knows.
3. Log in as Ana with that password. The application hashes it, compares, and lets them in.
4. Do whatever Ana can do, then put the original hash and salt back.

Nothing was broken. The hash function did exactly its job. Ana's password is still secret. And yet someone acted in her name, and the next morning the table looks exactly as it did the day before.

## What hashing actually protects

Hashing protects **confidentiality**: whoever steals the table cannot read the passwords. It says nothing about **integrity**, whether the stored value is still the one Ana set, and nothing about **accountability**, who touched it. We tend to hear "the passwords are hashed" as "the login is secure", and that is the gap the four steps walk through.

This is a design fact, not a bug. A credential store that one role can both read and rewrite, with no record kept, has no way to tell a password reset from an impersonation. No stronger algorithm changes that. No technology fixes bad design, it can only mitigate it.

## The mitigation: make the write leave a trace

You cannot stop the administrator from writing. You can make sure the write is seen. A trigger on the table that holds the credentials, writing to an audit table the same role cannot quietly edit, is enough to turn a silent swap into an event.

```sql
create table users_credential_audit (
  id           bigserial primary key,
  user_id      bigint      not null,
  changed_at   timestamptz not null default now(),
  changed_by   text        not null default current_user,
  client_addr  inet        default inet_client_addr(),
  old_hash     text,
  new_hash     text
);

create or replace function audit_credential_change() returns trigger as $$
begin
  if new.password_hash is distinct from old.password_hash
     or new.salt is distinct from old.salt then
    insert into users_credential_audit (user_id, old_hash, new_hash)
    values (old.id, old.password_hash, new.password_hash);
  end if;
  return new;
end;
$$ language plpgsql;

create trigger trg_audit_credential_change
  after update of password_hash, salt on users
  for each row execute function audit_credential_change();
```

Now the four steps produce two rows: one when the hash is swapped in, one when it is swapped back. Each row says which database user did it, from where, and when. Correlate that with your application's own log of password resets and the rule is simple: **a credential change with no matching reset request is an incident.**

## Three details that decide whether it works

- **The audit table must not be deletable by the role it watches.** Revoke `delete` and `update` on it, or ship the rows out of the database to a log system as they arrive. An audit log the attacker can edit is a diary, not evidence.
- **Log the hash, not the password.** The audit row stores what changed, never the plain text. Confidentiality still holds.
- **Someone has to look.** A trigger records. Detection happens when a person or an alert compares the audit table with the reset log. Without that, you have evidence for the post-mortem but no warning.

## The point

Identity tells you who is acting. Security decides what they may do. Traceability is the only one of the three that can tell you, afterwards, what actually happened. The hash was never the weak point. The silence around it was.
