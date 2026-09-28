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

## Automated Community Review

`.github/workflows/community-review.yml` runs weekly and writes the current open
Issue and Pull Request counts to the GitHub Actions job summary. It is read-only and
does not post comments, merge changes, or close community work.

## Personal Fork Synchronization

`.github/workflows/sync-personal-fork.yml` runs only in
`Emadhabibnia1385/vpnopsnyx`. It fast-forwards `main` from
`nyxon-tech/vpnopsnyx`; it never force-pushes or overwrites divergent work. A failed
fast-forward requires a human to review the fork's unique commits and conflicts.

## Latest Manual Review

On 2026-09-28, the public GitHub API reported no open Issues or Pull Requests. The
latest Quality and manually dispatched Scheduled Source Review runs both completed
successfully. This is a point-in-time maintenance result, not a permanent guarantee.
