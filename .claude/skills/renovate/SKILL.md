---
name: renovate
description: This skill should be used when the user asks to "configure renovate", "create renovate config", "setup renovate.json", "fix renovate configuration", "automerge dependencies with renovate", or mentions Renovate bot configuration, dependency update automation, or package rules.
version: 1.0.0
---

## Purpose

Configure Renovate to automate dependency updates in repositories. Create and maintain `renovate.json` configuration files with presets, package rules, custom managers, and advanced automation strategies.

## When to Use This Skill

Use this skill when:
- Creating a new Renovate configuration from scratch
- Configuring automerge strategies for dependency updates
- Setting up package rules for specific dependency types
- Defining custom managers for proprietary file formats
- Troubleshooting why Renovate isn't creating expected PRs
- Configuring grouped updates or dependency schedules
- Setting up custom datasources or regex managers

## Core Workflow

### Step 1: Choose Configuration Location

Select the appropriate file location for the Renovate configuration:

**Priority order** (Renovate stops at first match):
1. `renovate.json`
2. `renovate.json5`
3. `.github/renovate.json` or `.github/renovate.json5`
4. `.gitlab/renovate.json` or `.gitlab/renovate.json5`
5. `.renovaterc`, `.renovaterc.json`, `.renovaterc.json5`
6. `package.json` (within a `"renovate"` section) - **deprecated**

**Recommendation**: Use `.github/renovate.json` for GitHub repositories or `renovate.json` for general use.

**Note**: Renovate supports JSONC (JSON with comments) in `.json` files, which is preferred over `.json5` for adding comments.

### Step 2: Start with Presets

Begin with shareable config presets to avoid reinventing functionality:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"]
}
```

**Common base presets**:
- `config:recommended` - Sane defaults for most projects
- `:disableRateLimiting` - For self-hosted instances
- `:dependencyDashboard` - Enable dependency dashboard (included in recommended)
- `:disableDependencyDashboard` - Disable dashboard
- `:automergeAll` - Automerge all updates (use with caution)
- `:automergeBranch` - Automerge using branches instead of PRs
- `:automergeDigest` - Automerge digest updates
- `:automergePatch` - Automerge patch updates
- `:automergeMinor` - Automerge minor updates
- `:automergeTypes` - Automerge all types except major
- `:semanticPrefixFix` - Use semantic commit style with "fix:" prefix
- `:semanticPrefixChore` - Use "chore:" prefix
- `docker` - Enable Docker file support
- `github-actions` - Enable GitHub Actions support

**Combine presets**:
```json
{
  "extends": [
    "config:recommended",
    ":automergePatch",
    "docker",
    "github-actions"
  ]
}
```

### Step 3: Configure Basic Settings

Set essential configuration options:

**Branch management**:
```json
{
  "branchPrefix": "renovate/",
  "branchConcurrentLimit": 3,
  "prConcurrentLimit": 3
}
```

**Semantic commits**:
```json
{
  "semanticCommits": "auto",
  "semanticCommitType": "chore",
  "semanticCommitScope": "deps"
}
```

**Scheduling**:
```json
{
  "schedule": ["every weekend"],
  "timezone": "America/New_York"
}
```

**Schedule options**:
- `"every weekend"` - Saturday and Sunday
- `"before 3am on Monday"` - Specific time
- `["after 10pm", "before 6am"]` - Nightly window
- `"on the first day of the month"` - Monthly

**Automerge configuration**:
```json
{
  "automerge": true,
  "automergeType": "pr",
  "automergeStrategy": "auto",
  "automergeSchedule": ["every weekend"]
}
```

### Step 4: Define Package Rules

Use `packageRules` to apply configuration to specific dependencies:

**Match by update type**:
```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["major"],
      "automerge": false
    }
  ]
}
```

**Match by dependency type**:
```json
{
  "packageRules": [
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    },
    {
      "matchDepTypes": ["dependencies"],
      "automerge": false
    }
  ]
}
```

**Match by package name patterns**:
```json
{
  "packageRules": [
    {
      "matchPackageNames": ["eslint", "prettier"],
      "automerge": true
    },
    {
      "matchPackagePatterns": ["^@angular/", "^@nestjs/"],
      "groupName": "angular packages"
    }
  ]
}
```

**Match by manager**:
```json
{
  "packageRules": [
    {
      "matchManagers": ["dockerfile", "docker-compose"],
      "automerge": true,
      "groupName": "docker dependencies"
    },
    {
      "matchManagers": ["github-actions"],
      "commitMessageTopic": "{{depName}} action"
    }
  ]
}
```

**Combine multiple match conditions** (AND logic):
```json
{
  "packageRules": [
    {
      "matchManagers": ["npm"],
      "matchDepTypes": ["devDependencies"],
      "matchUpdateTypes": ["patch"],
      "automerge": true
    }
  ]
}
```

**Group dependencies**:
```json
{
  "packageRules": [
    {
      "matchPackagePatterns": ["^@types/"],
      "groupName": "typescript types",
      "groupSlug": "ts-types"
    },
    {
      "matchPackageNames": ["react", "react-dom"],
      "groupName": "react packages"
    }
  ]
}
```

### Step 5: Configure Custom Managers

Create custom managers for files not natively supported:

**Regex manager for ENV files**:
```json
{
  "customManagers": [
    {
      "customType": "regex",
      "description": "Process ENV-style version variables",
      "managerFilePatterns": ["/\\.env$/", "/\\.env\\..*$/"],
      "matchStrings": [
        "(?<depName>[A-Z_]+_VERSION)=(?<currentValue>[^\\s]+)\\s*#\\s*(?<datasource>.*?)/(?<packageName>.*?)\\s"
      ],
      "datasourceTemplate": "{{#if datasource}}{{{datasource}}}{{else}}github-releases{{/if}}",
      "versioningTemplate": "semver"
    }
  ]
}
```

**JSONata manager for complex files**:
```json
{
  "customManagers": [
    {
      "customType": "jsonata",
      "fileFormat": "yaml",
      "managerFilePatterns": ["values.yaml"],
      "matchStrings": [
        "image: {'repository': repo, 'tag': version}"
      ]
    }
  ]
}
```

**Combination strategy for multi-line dependencies**:
```json
{
  "customManagers": [
    {
      "customType": "regex",
      "managerFilePatterns": ["/^Dockerfile$/"],
      "matchStringsStrategy": "combination",
      "matchStrings": [
        "FROM (?<depName>\\S+):(?<currentValue>\\S+).*\\n",
        "ARG .*?_VERSION=(?<currentValue>\\S+).*\\n"
      ]
    }
  ]
}
```

### Step 6: Configure Labels and Assignees

Add organization and workflow automation:

**Labels**:
```json
{
  "labels": ["dependencies"],
  "addLabels": ["renovate"],
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "addLabels": ["major-update"]
    }
  ]
}
```

**Reviewers and assignees**:
```json
{
  "reviewers": ["team:backend"],
  "assignees": ["@maintainer"],
  "assigneesFromCodeOwners": true
}
```

### Step 7: Advanced Configuration

**Configure constraints**:
```json
{
  "constraints": {
    "node": ">= 18.0.0",
    "python": ">=3.9"
  }
}
```

**Version extraction**:
```json
{
  "packageRules": [
    {
      "matchPackageNames": ["some-package"],
      "extractVersion": "^(?<version>v\\d+\\.\\d+)"
    }
  ]
}
```

**Follow specific tags**:
```json
{
  "packageRules": [
    {
      "matchPackageNames": ["typescript"],
      "followTag": "insiders"
    }
  ]
}
```

**Dependency dashboard approval**:
```json
{
  "dependencyDashboardApproval": true,
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "dependencyDashboardApproval": true
    }
  ]
}
```

**Custom commit messages**:
```json
{
  "commitMessagePrefix": "chore(deps):",
  "commitMessageAction": "update",
  "commitMessageExtra": "to {{newVersion}}",
  "commitMessageTopic": "{{depName}}"
}
```

### Step 8: Validate and Test

**Validate configuration**:
1. Check JSON syntax is valid
2. Use Renovate's JSON schema: `$schema` field
3. Run Renovate in dry-run mode if available
4. Check the Dependency Dashboard for any config warnings

**Common issues**:
- **No PRs created**: Check `enabled` isn't `false`, verify schedule, check rate limits
- **Wrong registry**: Configure `hostRules` for authentication
- **Custom manager not working**: Verify regex patterns, check matchStrings syntax
- **Grouping not working**: Ensure `groupName` is consistent across rules
- **Automerge failing**: Check branch protection rules, status checks, platform automerge settings

## Additional Resources

### Reference Files

For detailed configuration options and patterns:
- **`references/presets.md`** - Comprehensive list of all Renovate presets
- **`references/package-rules.md`** - Advanced package rule patterns and examples
- **`references/custom-managers.md`** - Deep dive into regex and JSONata managers
- **`references/host-rules.md`** - Authentication and registry configuration
- **`references/troubleshooting.md`** - Common issues and solutions

### Example Files

Working configurations in `examples/`:
- **`examples/basic.json`** - Minimal starter configuration
- **`examples/monorepo.json`** - Configuration for multi-package repositories
- **`examples/docker-heavy.json`** - Docker-focused configuration
- **`examples/strict-automerge.json`** - Aggressive automerge strategy

### Quick Reference Templates

**Minimal configuration**:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"]
}
```

**Automerge non-major**:
```json
{
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch", "digest"],
      "automerge": true
    }
  ]
}
```

**Docker + GitHub Actions**:
```json
{
  "extends": ["config:recommended", "docker", "github-actions"],
  "packageRules": [
    {
      "matchManagers": ["dockerfile", "docker-compose", "github-actions"],
      "automerge": true
    }
  ]
}
```

**Full-featured**:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended", ":automergePatch"],
  "schedule": ["every weekend"],
  "labels": ["dependencies"],
  "assigneesFromCodeOwners": true,
  "packageRules": [
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    },
    {
      "matchManagers": ["dockerfile", "github-actions"],
      "automerge": true
    }
  ]
}
```
