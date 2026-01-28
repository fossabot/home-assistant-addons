# Renovate Presets Reference

Comprehensive guide to all available Renovate presets for configuration inheritance.

## Base Presets

### config:recommended

The starting point for most configurations. Includes sensible defaults:
- Enables Dependency Dashboard
- Groups monorepo packages together
- Filters out unstable releases
- Enables semantic commits in auto mode
- Sets reasonable rate limits

```json
{
  "extends": ["config:recommended"]
}
```

### config:base

Minimal preset with basic functionality:
- No dependency dashboard
- No semantic commits
- No grouping
- Basic scheduling only

Use when you want full control over your configuration.

## Automerge Presets

### :automergeAll

Automerge all updates (use with caution):

```json
{
  "extends": [":automergeAll"]
}
```

**Warning**: This automerges major version updates, which can introduce breaking changes.

### :automergeBranch

Automerge using branch strategy instead of PRs:

```json
{
  "extends": [":automergeBranch"]
}
```

Renovate will:
- Create branches directly
- Wait for tests to pass
- Merge if up-to-date and green
- Only raise PR if tests fail or timeout

### :automergeDigest

Automerge digest updates only:

```json
{
  "extends": [":automergeDigest"]
}
```

Digest updates are typically low-risk (same version, different hash).

### :automergeMinor

Automerge minor and patch updates:

```json
{
  "extends": [":automergeMinor"]
}
```

Excludes major updates which may have breaking changes.

### :automergePatch

Automerge patch updates only:

```json
{
  "extends": [":automergePatch"]
}
```

Most conservative automerge strategy.

### :automergeTypes

Automerge all types except major:

```json
{
  "extends": [":automergeTypes"]
}
```

Combines minor, patch, pin, digest, and rollback automerge.

## Semantic Commit Presets

### :semanticPrefixFix

Use semantic commit style with "fix:" prefix:

```json
{
  "extends": [":semanticPrefixFix"]
}
```

Result: `fix(deps): update dependency to v2.0.0`

### :semanticPrefixChore

Use "chore:" prefix (most common):

```json
{
  "extends": [":semanticPrefixChore"]
}
```

Result: `chore(deps): update dependency to v2.0.0`

### :semanticPrefixFixDepsChoreOthers

Combined prefix strategy:

```json
{
  "extends": [":semanticPrefixFixDepsChoreOthers"]
}
```

### :noSemanticPrefix

Disable semantic commit prefixes:

```json
{
  "extends": [":noSemanticPrefix"]
}
```

Result: `Update dependency to v2.0.0`

## Dependency Dashboard Presets

### :dependencyDashboard

Enable the Dependency Dashboard issue:

```json
{
  "extends": [":dependencyDashboard"]
}
```

Creates a curated issue showing all pending, open, and closed PRs.

### :disableDependencyDashboard

Disable the Dependency Dashboard:

```json
{
  "extends": [":disableDependencyDashboard"]
}
```

## Rate Limiting Presets

### :disableRateLimiting

Disable Renovate's internal rate limits:

```json
{
  "extends": [":disableRateLimiting"]
}
```

**Only use for self-hosted instances** where you control the API limits.

## Grouping Presets

### :groupMonorepoPackages

Group packages from the same monorepo:

```json
{
  "extends": [":groupMonorepoPackages"]
}
```

Reduces PR noise by combining related packages.

### :groupAll

Group all updates into a single PR:

```json
{
  "extends": [":groupAll"]
}
```

**Use with caution** - can create large, difficult-to-review PRs.

### :groupAllButMajor

Group all updates except major:

```json
{
  "extends": [":groupAllButMajor"]
}
```

### :groupTests

Group test-related dependencies:

```json
{
  "extends": [":groupTests"]
}
```

Combines packages matching `*test*`, `*spec*`, `*mocha*`, etc.

## Separation Presets

### :separateMajorReleases

Create separate PRs for each major version:

```json
{
  "extends": [":separateMajorReleases"]
}
```

### :separateMinorReleases

Create separate PRs for each minor version:

```json
{
  "extends": [":separateMinorReleases"]
}
```

### :separatePatchReleases

Create separate PRs for each patch version:

```json
{
  "extends": [":separatePatchReleases"]
}
```

### :separateMultipleMajorReleases

Create separate PRs for each major version when updating from an old version:

```json
{
  "extends": [":separateMultipleMajorReleases"]
}
```

## Label Presets

### :labelPrHeld

Apply `renovate/hold` label when PR is held:

```json
{
  "extends": [":labelPrHeld"]
}
```

### :labelUnpublished

Apply labels for unpublished releases:

```json
{
  "extends": [":labelUnpublished"]
}
```

## Stability Presets

### :unpublishSafe

Configure Renovate to treat pre-release versions correctly:

```json
{
  "extends": [":unpublishSafe"]
}
```

### :ignoreUnstable

Ignore unstable releases:

```json
{
  "extends": [":ignoreUnstable"]
}
```

### :respectLatest

Respect the `latest` field on npm packages:

```json
{
  "extends": [":respectLatest"]
}
```

## Timeout Presets

### :prHourlyLimit

Set PR creation rate limit (e.g., 2 per hour):

```json
{
  "extends": [":prHourlyLimit2"]
}
```

Available limits: 1, 2, 3, 4, 5, 10, 15, 20, 30, 40, 50, 60.

### :prConcurrentLimit

Set maximum concurrent PRs:

```json
{
  "extends": [":prConcurrentLimit10"]
}
```

Available limits: 0, 1, 2, 3, 4, 5, 7, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100.

## Manager-Specific Presets

### docker

Enable Docker-related managers:

```json
{
  "extends": ["docker"]
}
```

Enables: `dockerfile`, `docker-compose`, `dockerfile`, `helmv3`, `kubernetes`, `circleci`, `github-actions`, `gitlabci`, `azure-pipelines`, `bitbucket-pipelines`

### github-actions

Enable GitHub Actions support:

```json
{
  "extends": ["github-actions"]
}
```

### npm

Enable npm-specific configuration:

```json
{
  "extends": ["npm"]
}
```

### maven

Enable Maven support:

```json
{
  "extends": ["maven"]
}
```

### gradle

Enable Gradle support:

```json
{
  "extends": ["gradle"]
}
```

## Combining Presets

Combine multiple presets for comprehensive configuration:

```json
{
  "extends": [
    "config:recommended",
    ":automergePatch",
    ":automergeDigest",
    ":separateMajorReleases",
    ":groupMonorepoPackages",
    "docker",
    "github-actions"
  ]
}
```

**Order matters**: Later presets override earlier ones if they conflict.

## Custom Presets

Create shareable presets within your organization:

```json
{
  "extends": ["local>org/renovate-config"]
}
```

Or from a repository:

```json
{
  "extends": ["github>org/renovate-config"]
}
```

Or from a npm package:

```json
{
  "extends": ["npm:@org/renovate-config"]
}
```

## Preset Priority

Understanding how presets combine:

1. **Base presets** set foundation
2. **Specific presets** add features
3. **Local configuration** overrides everything
4. **packageRules** apply on top

Example of override behavior:

```json
{
  "extends": [
    ":automergeAll",      // Sets automerge: true for all
    ":automergePatch"     // Overrides to only patch
  ],
  "automerge": false      // Final override: no automerge
}
```
