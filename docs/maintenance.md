# Registry And Source Maintenance

The scheduled source review runs on the first day of every month and can also be
started manually from GitHub Actions. It validates repository structure and checks
external links. A green run proves reachability and structure, not installer safety.

## Human Review Checklist

1. Review failed links and distinguish temporary rate limiting from moved/deleted sources.
2. Read upstream release notes for high-impact panels, cores, and tunnel managers.
3. Recheck installer redirects and every secondary download performed by a bootstrap script.
4. Update `reviewed_at`, `last_source_review`, statuses, and notes only after inspection.
5. Mark abandoned or replaced projects `deprecated`; do not silently remove attribution.
6. Run `python3 scripts/validate.py`, inspect the diff, and request review.

Automation must not download and execute installers, modify upstream repositories,
or create issues automatically. A maintainer decides how to resolve every finding.
