# Package Rules Reference

Comprehensive guide to creating and using package rules in Renovate.

## Understanding Package Rules

Package rules apply configuration based on matching conditions. Rules are evaluated in order, with later rules potentially overriding earlier ones.

**Key concepts**:
- Multiple match conditions within one rule = AND logic
- Multiple rules with same settings = first match wins
- `addLabels` vs `labels`: add vs replace

## Match Conditions

### matchUpdateTypes

Control behavior based on update type:

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["major-update"]
    },
    {
      "matchUpdateTypes": ["minor"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["pin"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["digest"],
      "automerge": true
    }
  ]
}
```

**Available types**: `major`, `minor`, `patch`, `pin`, `digest`, `rollback`, `bump`

### matchDepTypes

Match by dependency type:

```json
{
  "packageRules": [
    {
      "matchDepTypes": ["dependencies"],
      "automerge": false
    },
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true
    },
    {
      "matchDepTypes": ["peerDependencies"],
      "automerge": false
    },
    {
      "matchDepTypes": ["optionalDependencies"],
      "automerge": true
    }
  ]
}
```

**Available types**: Varies by manager (npm: dependencies, devDependencies, peerDependencies, optionalDependencies; etc.)

### matchManagers

Match by package manager:

```json
{
  "packageRules": [
    {
      "matchManagers": ["npm"],
      "automerge": true
    },
    {
      "matchManagers": ["dockerfile", "docker-compose"],
      "groupName": "docker updates"
    },
    {
      "matchManagers": ["github-actions"],
      "commitMessageTopic": "{{depName}} action"
    },
    {
      "matchManagers": ["maven", "gradle"],
      "automerge": false
    }
  ]
}
```

**Available managers**: `npm`, `yarn`, `pnpm`, `dockerfile`, `docker-compose`, `github-actions`, `gitlabci`, `maven`, `gradle`, `cargo`, `pipenv`, `poetry`, `composer`, `nuget`, `go-modules`, and many more.

### matchPackageNames

Match exact package names:

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["react", "react-dom"],
      "groupName": "react packages"
    },
    {
      "matchPackageNames": ["typescript"],
      "followTag": "insiders"
    },
    {
      "matchPackageNames": ["node"],
      "enabled": false
    }
  ]
}
```

### matchPackagePatterns

Match packages by regex patterns:

```json
{
  "packageRules": [
    {
      "matchPackagePatterns": ["^@types/"],
      "groupName": "typescript types"
    },
    {
      "matchPackagePatterns": ["^@angular/", "^@nestjs/"],
      "groupName": "angular and nestjs packages"
    },
    {
      "matchPackagePatterns": ["*test*", "*spec*"],
      "automerge": true
    }
  ]
}
```

**Pattern syntax**:
- `^@types/` - Starts with @types/
- `*test*` - Contains "test"
- `^eslint` - Starts with "eslint"
- `\.css$` - Ends with .css

### matchCategories

Match by dependency category (manager-defined):

```json
{
  "packageRules": [
    {
      "matchCategories": ["ci", "cd"],
      "groupName": "CI/CD updates"
    },
    {
      "matchCategories": ["js"],
      "automerge": true
    }
  ]
}
```

**Available categories**: Varies by manager (e.g., ci, cd, js, css, etc.)

### matchLanguages

Match by programming language:

```json
{
  "packageRules": [
    {
      "matchLanguages": ["python"],
      "automerge": true
    },
    {
      "matchLanguages": ["javascript", "typescript"],
      "groupName": "JS/TS updates"
    }
  ]
}
```

### matchDatasources

Match by datasource:

```json
{
  "packageRules": [
    {
      "matchDatasources": ["docker"],
      "automerge": true
    },
    {
      "matchDatasources": ["npm"],
      "schedule": ["every weekend"]
    },
    {
      "matchDatasources": ["github-tags"],
      "versioning": "loose"
    }
  ]
}
```

**Available datasources**: `docker`, `npm`, `pypi`, `maven`, `go`, `cargo`, `nuget`, `github-tags`, `github-releases`, and many more.

### matchCurrentVersion

Match specific current versions:

```json
{
  "packageRules": [
    {
      "matchCurrentVersion": ">= 0.0.0 < 1.0.0",
      "enabled": false
    },
    {
      "matchCurrentVersion": ">= 3.0.0",
      "automerge": true
    }
  ]
}
```

### matchSourceUrlPrefixes

Match by source URL:

```json
{
  "packageRules": [
    {
      "matchSourceUrlPrefixes": ["https://github.com/vercel/"],
      "automerge": true
    },
    {
      "matchSourceUrlPrefixes": ["https://github.com/facebook/"],
      "automerge": false
    }
  ]
}
```

## Combining Match Conditions

Multiple match conditions in one rule use AND logic:

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

This rule only matches npm packages that are:
- In devDependencies
- Being patch updated
- All three conditions must be true

## Configurable Fields

### automerge

Control automatic merging:

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    },
    {
      "matchPackageNames": ["critical-package"],
      "automerge": false
    }
  ]
}
```

### automergeType

Set automerge strategy:

```json
{
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "automerge": true,
      "automergeType": "branch"
    }
  ]
}
```

**Options**: `pr` (default), `branch`, `pr-comment`

### groupName

Group updates together:

```json
{
  "packageRules": [
    {
      "matchPackagePatterns": ["^@types/"],
      "groupName": "typescript types"
    }
  ]
}
```

Result: All @types/ updates go into one PR.

### groupSlug

Customize branch name:

```json
{
  "packageRules": [
    {
      "matchPackagePatterns": ["^@types/"],
      "groupName": "typescript types",
      "groupSlug": "ts-types"
    }
  ]
}
```

Result: Branch named `renovate/ts-types` instead of `renovate/typescript-types`.

### labels

Add or replace labels:

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "labels": ["major-update", "needs-review"]
    },
    {
      "matchDepTypes": ["devDependencies"],
      "addLabels": ["dev-dep"]  // Adds to existing labels
    }
  ]
}
```

### schedule

Set specific schedules:

```json
{
  "packageRules": [
    {
      "matchManagers": ["dockerfile"],
      "schedule": ["before 3am on Monday"]
    },
    {
      "matchDepTypes": ["devDependencies"],
      "schedule": ["every weekend"]
    }
  ]
}
```

### versioning

Set versioning strategy:

```json
{
  "packageRules": [
    {
      "matchDatasources": ["github-tags"],
      "versioning": "loose"
    },
    {
      "matchPackageNames": ["electron"],
      "versioning": "electron"
    }
  ]
}
```

**Available**: `semver`, `semver-coerced`, `loose`, `npm`, `maven`, `gradle`, `cargo`, `poetry`, `node`, `electron`, etc.

### commitMessageTopic

Customize commit message topic:

```json
{
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "commitMessageTopic": "{{depName}} action"
    },
    {
      "matchPackagePatterns": ["^@types/"],
      "commitMessageTopic": "TS types for {{depName}}"
    }
  ]
}
```

### extractVersion

Extract specific version format:

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["some-java-package"],
      "extractVersion": "^(?<version>\\d+\\.\\d+\\.\\d+)"
    }
  ]
}
```

### allowedVersions

Restrict which versions are allowed:

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["node"],
      "allowedVersions": ">= 18"
    },
    {
      "matchPackageNames": ["python"],
      "allowedVersions": ">= 3.9 < 4.0"
    }
  ]
}
```

### followTag

Follow a specific tag:

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

### registryUrls

Set custom registry URLs:

```json
{
  "packageRules": [
    {
      "matchDatasources": ["docker"],
      "registryUrls": ["https://registry.example.com"]
    }
  ]
}
```

## Advanced Patterns

### Separate major from non-major

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["major"]
    },
    {
      "matchUpdateTypes": ["minor", "patch", "digest"],
      "automerge": true
    }
  ]
}
```

### Group by organization

```json
{
  "packageRules": [
    {
      "matchSourceUrlPrefixes": ["https://github.com/vuejs/"],
      "groupName": "vue packages"
    },
    {
      "matchSourceUrlPrefixes": ["https://github.com/facebook/"],
      "groupName": "facebook packages"
    }
  ]
}
```

### Development vs production

```json
{
  "packageRules": [
    {
      "matchDepTypes": ["devDependencies"],
      "automerge": true,
      "groupName": "dev deps"
    },
    {
      "matchDepTypes": ["dependencies"],
      "automerge": false
    }
  ]
}
```

### Docker-specific rules

```json
{
  "packageRules": [
    {
      "matchManagers": ["dockerfile"],
      "matchUpdateTypes": ["major"],
      "automerge": false
    },
    {
      "matchManagers": ["dockerfile"],
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true,
      "groupName": "docker non-major"
    }
  ]
}
```

### Disable specific packages

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["deprecated-package"],
      "enabled": false
    },
    {
      "matchPackagePatterns": ["^deprecated-"],
      "enabled": false
    }
  ]
}
```

### Force upgrades for outdated packages

```json
{
  "packageRules": [
    {
      "matchCurrentVersion": "< 2.0.0",
      "matchPackageNames": ["important-package"],
      "automerge": false,
      "labels": ["outdated", "security-risk"]
    }
  ]
}
```

### Semantic grouping

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["major"],
      "groupName": "all major dependencies"
    },
    {
      "matchDepTypes": ["devDependencies"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "dev dependencies (non-major)"
    }
  ]
}
```

## Rule Priority

Rules are evaluated in order:

1. **First match wins**: Once a package matches a rule, subsequent rules are skipped
2. **More specific rules first**: Place specific rules before general ones
3. **Global config applies first**: Then package rules override

Example of correct ordering:

```json
{
  "packageRules": [
    {
      "matchPackageNames": ["very-specific-package"],
      "automerge": false  // Most specific, evaluated first
    },
    {
      "matchPackagePatterns": ["^@scope/"],
      "automerge": true  // Less specific
    },
    {
      "matchManagers": ["npm"],
      "automerge": true  // Least specific, evaluated last
    }
  ]
}
```

## Debugging Package Rules

Use these techniques to debug rule matching:

1. **Enable verbose logging**:
```json
{
  "logLevel": "debug"
}
```

2. **Use descriptive group names**:
```json
{
  "packageRules": [
    {
      "matchPackagePatterns": ["^@types/"],
      "groupName": "[DEBUG] TypeScript types"
    }
  ]
}
```

3. **Check Dependency Dashboard**: Look for which rules applied to which packages

4. **Test with single rule**: Temporarily disable other rules to isolate behavior

## Common Pitfalls

### Conflicting rules

```json
{
  "packageRules": [
    {
      "matchManagers": ["npm"],
      "automerge": true  // This applies first
    },
    {
      "matchPackageNames": ["important-package"],
      "automerge": false  // Never evaluated if npm matches first!
    }
  ]
}
```

**Fix**: More specific rule first:
```json
{
  "packageRules": [
    {
      "matchPackageNames": ["important-package"],
      "automerge": false  // Specific first
    },
    {
      "matchManagers": ["npm"],
      "automerge": true  // General second
    }
  ]
}
```

### Overly broad patterns

```json
{
  "packageRules": [
    {
      "matchPackagePatterns": ["*"],  // Matches EVERYTHING
      "automerge": true  // DANGEROUS
    }
  ]
}
```

**Fix**: Use specific patterns or explicit lists.

### Misunderstanding AND vs OR

```json
{
  "packageRules": [
    {
      "matchUpdateTypes": ["major", "minor"],  // AND logic with other match fields
      "matchDepTypes": ["dependencies", "devDependencies"],  // AND logic
      "automerge": true
    }
  ]
}
```

This matches: `(major OR minor) AND (dependencies OR devDependencies)`

### Forgetting to enable managers

```json
{
  "packageRules": [
    {
      "matchManagers": ["dockerfile"],
      "automerge": true  // Won't work if dockerfile not enabled!
    }
  ]
}
```

**Fix**: Enable the manager:
```json
{
  "extends": ["docker"],  // Enable dockerfile manager
  "packageRules": [
    {
      "matchManagers": ["dockerfile"],
      "automerge": true
    }
  ]
}
```
