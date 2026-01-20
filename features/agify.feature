Feature: Agify.io API
  As a user of the agify.io service
  I want to query names and receive age predictions
  So that I can estimate ages based on names

  # Complete API Error Code Coverage:
  # - 200: Success (multiple tests)
  # - 401: Unauthorized - Invalid API key (@skip)
  # - 402: Payment Required - Expired subscription (@skip)
  # - 422: Unprocessable Content - Missing name parameter (active)
  # - 422: Unprocessable Content - Invalid name parameter (active - API BUG: returns 400)
  # - 429: Too Many Requests - Request limit reached (@skip)
  # - 429: Too Many Requests - Batch limit too low (@skip)

  Background:
    Given the agify.io API is available

  Scenario: Successfully get age prediction for a common name
    When I request age prediction for name "Michael"
    Then the response status should be 200
    And the response should contain a name field with value "Michael"
    And the response should contain an age field
    And the response should contain a count field

  Scenario: Successfully get age prediction for a lowercase name
    When I request age prediction for name "sarah"
    Then the response status should be 200
    And the response should contain a name field with value "sarah"
    And the age should be a positive integer or null

  Scenario Outline: Get age predictions for multiple names
    When I request age prediction for name "<name>"
    Then the response status should be 200
    And the response should contain a name field with value "<name>"
    And the response should contain an age field

    Examples:
      | name      |
      | John      |
      | Maria     |
      | Wei       |
      | Mohammed  |

  Scenario: Handle uncommon or rare name
    When I request age prediction for name "Zyxwvut"
    Then the response status should be 200
    And the response should contain a name field
    And the age field might be null
    And the count should be a non-negative integer

  Scenario: Validate response structure for valid request
    When I request age prediction for name "Jennifer"
    Then the response status should be 200
    And the response should have the following structure:
      | field | type   |
      | name  | string |
      | age   | number |
      | count | number |

  Scenario: Request with hyphenated first name
    When I request age prediction for name "Jean-Pierre"
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Request with accented characters
    When I request age prediction for name "José"
    Then the response status should be 200
    And the response should contain a name field
    And the response should contain an age field

  Scenario: Request with umlauts
    When I request age prediction for name "Müller"
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Request with Cyrillic characters
    When I request age prediction for name "Дмитрий"
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Request with Chinese characters
    When I request age prediction for name "李明"
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Request with numeric characters in name
    When I request age prediction for name "Test123"
    Then the response status should be 200
    And the response should contain a name field with value "Test123"

  Scenario: Request with full name (first and last)
    When I request age prediction for name "John Smith"
    Then the response status should be 200
    And the response should contain a name field
    And the response should contain an age field

  Scenario: API extracts first name from full name
    When I request age prediction for name "Sarah Johnson"
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Full name with multiple parts
    When I request age prediction for name "Maria Elena Garcia"
    Then the response status should be 200
    And the response should contain a name field
    And the response should contain an age field

  Scenario: Request without name parameter
    When I request the API without a name parameter
    Then the response status should be 422
    And the response should contain an error message

  Scenario: Request with empty name parameter
    When I request age prediction for name ""
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Verify response time is acceptable
    When I request age prediction for name "David"
    Then the response status should be 200
    And the response time should be less than 2000 milliseconds

  Scenario: Request with very long name
    When I request age prediction for name "Abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Verify count field represents sample size
    When I request age prediction for name "Emma"
    Then the response status should be 200
    And the count field should be greater than or equal to 0

  Scenario: API returns consistent results for same name
    When I request age prediction for name "Robert" twice
    Then both responses should have the same age value
    And both responses should have the same count value

  @localization
  Scenario: Request with country localization
    When I request age prediction for name "Michael" with country code "US"
    Then the response status should be 200
    And the response should contain a name field
    And the response should contain a country_id field with value "US"

  @localization
  Scenario: Localization affects age prediction
    When I request age prediction for name "Wei" with country code "CN"
    Then the response status should be 200
    And the response should contain a country_id field with value "CN"

  @localization
  Scenario Outline: Localization with different countries
    When I request age prediction for name "John" with country code "<country>"
    Then the response status should be 200
    And the response should contain a country_id field with value "<country>"

    Examples:
      | country |
      | US      |
      | GB      |
      | AU      |
      | CA      |

  @localization
  Scenario: Invalid country code handling
    When I request age prediction for name "Sarah" with country code "XX"
    Then the response status should be 200
    And the response should contain a name field

  @localization
  Scenario: Country code is case insensitive
    When I request age prediction for name "Emma" with country code "us"
    Then the response status should be 200
    And the response should contain a country_id field

  @localization
  Scenario: Localized request may have different count
    When I request age prediction for name "Maria" with country code "ES"
    And I request age prediction for name "Maria" without country code
    Then both responses should contain valid age and count fields

  @skip
  Scenario: Valid API key allows requests
    When I request age prediction for name "Sarah" with a valid API key
    Then the response status should be 200
    And the response should contain a name field
    And the response headers should include rate limit information

  @skip
  Scenario: Invalid API key returns 401 error
    When I request age prediction for name "John" with an invalid API key
    Then the response status should be 401
    And the response should contain an error message "Invalid API key"

  @skip
  Scenario: Expired subscription returns 402 error
    When I request age prediction for name "Emma" with an expired API key
    Then the response status should be 402
    And the response should contain an error message "Subscription is not active"

  @skip
  Scenario: API key increases rate limit
    When I request age prediction for name "Michael" with a valid API key
    Then the response status should be 200
    And the X-Rate-Limit-Limit header should be greater than 100

  @skip
  Scenario: Rate limit headers are present with API key
    When I request age prediction for name "David" with a valid API key
    Then the response status should be 200
    And the response should include the following headers:
      | header                  |
      | X-Rate-Limit-Limit      |
      | X-Rate-Limit-Remaining  |
      | X-Rate-Limit-Reset      |

  @skip
  Scenario: Exceeding rate limit returns 429 error
    Given I have made the maximum allowed requests with my API key
    When I request age prediction for name "Test"
    Then the response status should be 429
    And the response should contain an error message "Request limit reached"

  # Batch Request Tests
  Scenario: Batch request with multiple names
    When I request age predictions for the following names:
      | Michael  |
      | Sarah    |
      | David    |
    Then the response status should be 200
    And each prediction should have name, age, and count fields

  Scenario: Batch request with up to 10 names
    When I request age predictions for 10 names in a batch
    Then the response status should be 200
    And each prediction should have name, age, and count fields

  @localization
  Scenario: Batch request with country localization
    When I request age predictions for the following names with country code "US":
      | Michael  |
      | Sarah    |
      | David    |
    Then the response status should be 200
    And each prediction should have name, age, and count fields
    And each prediction should include a country_id field with value "US"

  @localization
  Scenario: Batch localization improves prediction accuracy
    When I request age predictions for the following names with country code "ES":
      | Maria    |
      | Carlos   |
      | Isabel   |
    Then the response status should be 200
    And each prediction should have name, age, and count fields
    And each prediction should include a country_id field with value "ES"

  @localization
  Scenario: Same names with different countries in batch
    When I request batch predictions for 3 names with country code "CN"
    Then the response status should be 200
    And each prediction should include a country_id field with value "CN"

  # API Limitation: Cannot specify different country codes per name in single batch
  # The country_id parameter applies to ALL names in the batch
  # To get predictions for names from different countries, use separate requests:
  # - Batch 1: US names with country_id=US
  # - Batch 2: ES names with country_id=ES
  # - Batch 3: CN names with country_id=CN

  @skip
  Scenario: Batch request with insufficient quota returns 429
    Given I have only 5 requests remaining in my quota
    When I request age predictions for 10 names with an API key
    Then the response status should be 429
    And the response should contain an error message "Request limit too low to process request"

  # Invalid Name Parameter Test
  # BUG: API returns 400 instead of documented 422
  # Documentation: https://agify.io/documentation
  # Expected: 422 Unprocessable Content with { "error": "Invalid 'name' parameter" }
  # Actual: 400 Bad Request with { "error": "Invalid 'name' parameter" }
  # This test expects documented behaviour to flag the discrepancy
  @bug
  Scenario: Request with invalid UTF8 in name parameter
    When I request age prediction with an invalid name parameter
    Then the response status should be 422
    And the response should contain an error message "Invalid 'name' parameter"
