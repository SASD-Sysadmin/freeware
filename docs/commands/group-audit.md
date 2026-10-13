# group-audit

[Deutsch](group-audit.de.md) · [Project](../../README.md)

`group-audit` validates a local Unix `/etc/group`-style file without changing it. It does not fetch, update, or validate complete memberships through NSS, LDAP, NIS, or NIS+.

```sh
./bin/group-audit
./bin/group-audit --file ./group.sample
```

It verifies four colon-separated fields, a simple group name and an unsigned 32-bit decimal GID. It reports duplicate group names, shared GIDs, unexpected additional GID 0 groups, invalid membership tokens, and duplicate members. Shared GIDs and repeated memberships are warnings: they can be intentional, so review them manually. Invalid records and invalid member tokens are errors. NIS `+` / `-` compatibility directives are **skipped with an explicit warning**. It does not require every listed member to appear in `/etc/passwd`, because a member may come from NSS or another domain.

Output summary: groups read, number of distinct GIDs, warning and error counts. Exit 0 if no structural errors (warnings are allowed), 1 if invalid records or members are found, 2 for incorrect options, and 3 for unreadable input or unavailable bundled module. Perl core modules and `SASD::Freeware::Account` are required; no account database is modified.
