# Custom Managers Reference

Comprehensive guide to creating custom managers for files not natively supported by Renovate.

## Understanding Custom Managers

Custom managers extend Renovate to handle proprietary file formats, custom conventions, and unsupported file types.

## Regex Custom Managers

### Basic Structure

```json
{
  "customManagers": [
    {
      "customType": "regex",
      "description": "Process custom environment files",
      "managerFilePatterns": ["/\.env$/"],
      "matchStrings": [
        ".*?_VERSION=(?<currentValue>.*)\\s"
      ]
    }
  ]
}
```

### Required Fields

- **customType**: "regex" or "jsonata"
- **managerFilePatterns**: Array of regex/glob patterns
- **matchStrings**: Regex with named capture groups

### Required Capture Groups

Each matchString must capture:
- **datasource**: Where to fetch versions (or use datasourceTemplate)
- **depName** or **packageName**: Dependency identifier
- **currentValue**: The current version

### Template Fields

```json
{
  "matchStrings": ["IMAGE=(?<depName>.*?):(?<currentValue>.*?)\\s"],
  "datasourceTemplate": "docker",
  "depNameTemplate": "{{{org}}}/{{{repo}}}",
  "versioningTemplate": "semver"
}
```

### Match Strings Strategy

- **any** (default): Each pattern matches independently
- **recursive**: Chain patterns, narrowing search
- **combination**: Combine multiple lines into one dependency

## Common Patterns

### Environment Variables with Comments
```json
{
  "customManagers": [
    {
      "customType": "regex",
      "managerFilePatterns": ["/\.env$/"],
      "matchStrings": [
        "(?<depName>[A-Z_]+_VERSION)=(?<currentValue>[^\\s]+)\\s*#\\s*renovate:\\s*datasource=(?<datasource>.*?)\\s"
      ]
    }
  ]
}
```

### Dockerfile with Comments
```json
{
  "customManagers": [
    {
      "customType": "regex",
      "managerFilePatterns": ["/^Dockerfile$/"],
      "matchStrings": [
        "# renovate: datasource=(?<datasource>.*?) depName=(?<depName>.*?)\\s*FROM .*?:(?<currentValue>.*?)\\s"
      ]
    }
  ]
}
```

## JSONata Custom Managers

```json
{
  "customManagers": [
    {
      "customType": "jsonata",
      "fileFormat": "yaml",
      "managerFilePatterns": ["values.yaml"],
      "matchStrings": [
        "image.{$.depName: repository, $.currentValue: tag}"
      ]
    }
  ]
}
```

## Debugging

Enable debug logging to troubleshoot:
```json
{
  "logLevel": "debug"
}
```
