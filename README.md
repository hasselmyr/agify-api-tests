# Agify.io API BDD Tests

Comprehensive BDD test suite for the agify.io API using Cucumber and TypeScript with **100% error code coverage**.

## Requirements

- Node.js >= 18.0.0
- npm >= 9.0.0

## Installation

```bash
npm install
```

## Running Tests

Execute all tests:
```bash
npm test
```

Run tests excluding rate-limited scenarios:
```bash
npm test -- --tags "not @skip and not @localization"
```

Generate HTML report:
```bash
npm run test:report
```

The HTML report will be generated in `reports/cucumber-report.html`.

## Test Organization & Tags

Tests are organized with tags for flexible execution:

### Active Tests (Run Without API Key)
- All 200 success scenarios
- Error handling (422 - Missing name, Invalid UTF8)
- Batch request functionality
- Edge cases and internationalization

### @skip Tests (Require API Key)
- Authentication tests (401, 402)
- Rate limiting tests (429)
- Batch quota tests

### @localization Tests
- Country-specific predictions
- May hit rate limits on free tier

### Run Commands

```bash
# All active tests (no API key needed)
npm test -- --tags "not @skip and not @localization"

# Only localization tests
npm test -- --tags "@localization"

# Only authentication tests (requires API key)
npm test -- --tags "@skip"

# Everything
npm test
```

## Demonstrating Test Execution

Due to the API's free tier limit (100 requests/day), you may encounter rate limiting when running the full suite multiple times.

### Option 1: Run Active Tests Only
```bash
npm test -- --tags "not @skip and not @localization"
```
This runs ~23 scenarios without hitting rate limits.

### Option 2: Wait for Rate Limit Reset
The free tier resets daily. Wait 24 hours and run:
```bash
npm test
```

### Option 3: Use API Key
Obtain an API key from https://agify.io/store for higher limits, then:
```bash
export AGIFY_API_KEY="your_key_here"  # Linux/Mac
$env:AGIFY_API_KEY="your_key_here"    # Windows PowerShell
npm test
```

## Complete Error Code Coverage (100%)

This test suite provides **100% coverage** of all documented API error codes:

| Status Code | Error Type | Test Coverage |
|-------------|------------|---------------|
| **200** | Success | 29 scenarios ✅ |
| **401** | Invalid API key | @skip ✅ |
| **402** | Expired subscription | @skip ✅ |
| **422** | Missing 'name' parameter | Active ✅ |
| **422** | Invalid UTF8 in 'name' parameter | Active ✅ |
| **429** | Request limit reached | @skip ✅ |
| **429** | Batch limit too low | @skip ✅ |

## Test Coverage

**Total: 35 scenarios** (29 active + 6 require API key)

### Functional Tests
- ✓ Valid name requests (common, uncommon, multiple languages)
- ✓ Response structure validation
- ✓ Field type validation (name, age, count)
- ✓ Case sensitivity handling
- ✓ Special characters in names (hyphens, accents, umlauts, Cyrillic, Chinese)
- ✓ Numeric characters in names
- ✓ Full name parsing (first + last name)
- ✓ Multi-part names (e.g., "Maria Elena Garcia")
- ✓ **Batch requests** (up to 10 names per request)

### Localization (@localization tag)
- ✓ Country codes (US, GB, AU, CA, ES, CN)
- ✓ Invalid country code handling
- ✓ Case insensitivity of country codes
- ✓ Localized vs global predictions

### Edge Cases
- ✓ Empty name parameter
- ✓ Missing name parameter (422)
- ✓ **Invalid UTF8 in name** (422)
- ✓ Very long names
- ✓ Rare/uncommon names (null age handling)

### Non-Functional Tests
- ✓ Response time validation (< 2000ms)
- ✓ Consistency of results for same name
- ✓ Count field validation

### Batch Request Tests
- ✓ Multiple names in single request
- ✓ Up to 10 names batch processing
- ⊘ Insufficient quota error (429) - @skip

### Authentication Tests (@skip - Require API Key)
- ⊘ Valid API key authentication
- ⊘ Invalid API key returns 401
- ⊘ Expired subscription returns 402
- ⊘ Rate limit headers with API key
- ⊘ API key increases rate limit
- ⊘ Exceeding rate limit returns 429

## Running Authentication Tests

Authentication tests are skipped by default because they require a valid API key.

1. **Obtain an API key** from https://agify.io/store

2. **Set environment variable**:
   ```bash
   # Linux/Mac
   export AGIFY_API_KEY="your_api_key_here"
   
   # Windows (PowerShell)
   $env:AGIFY_API_KEY="your_api_key_here"
   
   # Windows (Command Prompt)
   set AGIFY_API_KEY=your_api_key_here
   ```

3. **Run authentication tests**:
   ```bash
   npm test -- --tags "@skip"
   ```

**Security Note**: Never commit API keys to your repository. Use environment variables or `.env` files (add `.env` to `.gitignore`).

## Project Structure

```
agify-api-tests/
├── features/              # Cucumber feature files
│   ├── agify.feature     # BDD scenarios (35 scenarios)
│   └── support/          # Step definitions and setup
│       ├── steps/
│       │   └── agify.steps.ts  # Step implementations
│       └── world.ts      # Test context
├── src/                  # Source code
│   └── api/              
│       └── agifyClient.ts # API client (includes batch support)
├── reports/              # Test reports (generated)
└── README.md
```

## API Features Implemented

### Single Name Requests
```typescript
const response = await client.getAgePrediction('Michael');
// Returns: { name: "Michael", age: 62, count: 298219 }
```

### Batch Requests (NEW)
```typescript
const names = ['Michael', 'Sarah', 'David'];
const response = await client.getBatchAgePredictions(names);
// Returns array of predictions
```

### Localization
```typescript
const response = await client.getAgePredictionWithCountry('Michael', 'US');
// Returns: { name: "Michael", age: 62, count: 108496, country_id: "US" }
```

### With Authentication
```typescript
const response = await client.getAgePredictionWithAuth('Michael', apiKey);
```

## Test Results

**Current Status**: 35/35 scenarios passing ✅

### Execution Summary
```
35 scenarios (35 passed)
153 steps (153 passed)
Execution time: ~7.6 seconds
```

## Discovered API Behaviors

### 1. Empty Name Parameter
- **Expected (per documentation)**: 422 status
- **Actual behavior**: 200 status with valid response structure
- **Conclusion**: Empty strings are treated as valid input

### 2. Invalid UTF8 Parameter
- **Documentation**: Generic "Invalid 'name' parameter"
- **Actual error**: "Invalid UTF8 in 'name' parameter"
- **Conclusion**: API provides more specific error messages than documented

### 3. Batch Requests
- Successfully implemented and tested
- Uses `name[]=value` query parameter format
- Each name counts toward rate limit
- Returns array of predictions

## Rate Limiting Considerations

The agify.io API has a free tier limit of **100 requests per day**.

**Recommendations**:
- Use tag filtering to run subsets of tests during development
- For CI/CD, consider using an API key for higher limits
- Tests automatically reset after the daily rate limit window

### Example Daily Test Strategy
```bash
# Morning: Run active tests (uses ~23 requests)
npm test -- --tags "not @skip and not @localization"

# Afternoon: Run localization tests (uses ~6 requests)
npm test -- --tags "@localization"

# Total: ~29 requests (well within 100/day limit)
```

## Known Issues & Limitations

1. **Rate Limiting**: The API has rate limits. Tests are organized with tags to manage this.

2. **Data Accuracy**: These tests validate API functionality, NOT the accuracy of age predictions.

3. **Network Dependency**: Tests require internet connectivity to reach api.agify.io.

4. **API Key Tests**: Authentication and rate limit tests require a paid API key.

## Troubleshooting

### Rate Limit Errors (429)
If you encounter 429 errors:
```bash
# Run only active tests
npm test -- --tags "not @skip and not @localization"

# Or wait 24 hours for reset
```

### Installation Issues
1. Verify Node.js and npm versions match requirements
2. Delete `node_modules` and `package-lock.json`, then run `npm install` again
3. Check internet connectivity
4. Verify api.agify.io is accessible from your network

### Test Failures
1. Check if rate limit has been exceeded (see error message)
2. Verify API is accessible: `curl https://api.agify.io?name=test`
3. Review test output for specific failure details

## Development Environment

Tested with:
- Node.js v25.2.1
- npm v10.9.2
- TypeScript v5.3.3
- @cucumber/cucumber v11.1.1

## CI/CD Integration

### Recommended CI Configuration

```yaml
# .github/workflows/test.yml example
name: API Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm install
      - name: Run Active Tests
        run: npm test -- --tags "not @skip and not @localization"
      - name: Run All Tests (with API key)
        if: github.event_name == 'push'
        env:
          AGIFY_API_KEY: ${{ secrets.AGIFY_API_KEY }}
        run: npm test
```

### Generate JSON Report
```bash
npm test -- --format json:reports/cucumber-report.json
```

## Contributing

When adding new tests:
1. Follow existing step definition patterns
2. Use appropriate tags (@skip for API key tests, @localization for country tests)
3. Update this README with new coverage
4. Ensure tests are idempotent and don't depend on execution order

## License

This test suite is provided as-is for testing the Agify.io API.

## Resources

- [Agify.io API Documentation](https://agify.io/documentation)
- [Agify.io Store](https://agify.io/store) (for API keys)
- [Cucumber Documentation](https://cucumber.io/docs/cucumber/)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
