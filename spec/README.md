@nrser/qb/spec Directory
==============================================================================

RSpec test suite. Used not only for the Ruby code but also as a driver for testing the rest of the project - Ansible roles, plugins, etc.

Structured to mirror the project root, so tests for `//lib/qb/role` go in `//spec/lib/qb/role`; tests for `//roles/qb/role/qb` go in `//spec/roles/qb/role`, etc.

Test files / "fixtures" are in `//test`. Temporary files created in tests should go in `//tmp`.
