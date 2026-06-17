# Cloud Save Decision

Current build decision: local-save-first, cloud-ready.

The app stores gameplay progress locally through `LocalSaveRepository`. The
save payload includes schema version, checksum, ledger, purchases, collections,
events, renovation state, and content compatibility so a future cloud adapter
can sync without changing gameplay code.

`CloudSaveRepository` intentionally fails closed until a backend is configured.
This prevents accidental no-op cloud saves from being mistaken for real sync.

Before production cloud save is enabled, the backend adapter must provide:

- authenticated player identity mapping;
- server-authoritative purchase and entitlement merge;
- ledger-based wallet merge without duplicate grants;
- higher-progress conflict handling;
- latest-write-wins settings merge;
- collection union merge;
- automated tests for interrupted sync and duplicate reward prevention.
