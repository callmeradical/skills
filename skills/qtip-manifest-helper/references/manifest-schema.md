# Subject Manifest Schema

The Subject Manifest is the "Identity Card" for a software project being evaluated by **qtip**.

## Schema Details

```typescript
export const SubjectManifestSchema = z.object({
  projectId: z.string(),          // Unique ID for the project (e.g., "smith")
  repoUrl: z.string().url(),      // Optional: URL to the repository
  commit: z.string(),             // Optional: Current commit hash
  environment: z.string(),        // Environment name (e.g., "qa", "ci", "prod")
  interfaces: z.array(z.object({
    type: z.enum(['api', 'cli', 'ui', 'logs']),
    baseUrl: z.string().url()     // Required for 'api' and 'ui' types
  })),
  observability: z.object({
    logs: z.object({
      type: z.enum(['file', 'url']),
      path: z.string()            // Required for 'file' type
    })
  }).optional(),
  capabilities: z.array(z.string()) // Tags used to resolve scenarios (e.g., ["auth", "billing"])
});
```

## Example Manifest

```json
{
  "projectId": "identity-service",
  "environment": "qa",
  "interfaces": [
    {
      "type": "api",
      "baseUrl": "https://qa.identity.example.com"
    }
  ],
  "capabilities": ["auth", "token-exchange"]
}
```
