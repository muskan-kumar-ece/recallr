# Card network implementation

## Scope
Editable personal cards, public card pages, QR imports, shareable contact cards,
user-created categories and a shared Save & Organize flow. Includes resolution of
the 28 findings from the repository audit.

## Delivery checkpoints
- [ ] Theme-aware UI and persisted appearance
- [ ] Category repository, management and reusable save picker
- [ ] Card editor, public projection, sharing and QR import
- [ ] Reliable capture lifecycle and media viewer
- [ ] Canonical contact/follow-up data and real entity screens
- [ ] Payment verification and billing lifecycle
- [ ] Emulator, Flutter, backend and build verification

## Data boundaries
Card drafts and categories belong to their user. Public cards contain only the
fields explicitly published through the card editor. Private notes, categories,
captures and relationship intelligence never enter the public projection.
Imports are idempotent by source-card identity and preserve personal annotations.

## Release prerequisites
Deploy new functions, rules, indexes and Hosting rewrites together after local
verification. Public card URLs use the configured Hosting origin. Native verified
links require the actual application signing fingerprints and Apple team ID.
No live deployment is part of local implementation without confirmation.
