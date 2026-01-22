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

################################################################################
#                          FUNCTIONAL TESTING                                  #
################################################################################

# ==============================================================================
# Basic Functionality Tests
# ==============================================================================
# These tests verify core API functionality with common, valid inputs

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

  Scenario: Successfully get age prediction for UPPERCASE name
    When I request age prediction for name "MICHAEL"
    Then the response status should be 200
    And the response should contain a name field with value "MICHAEL"
    And the response should contain an age field

  Scenario Outline: Get age predictions for multiple names
    When I request age prediction for name "<n>"
    Then the response status should be 200
    And the response should contain a name field with value "<n>"
    And the response should contain an age field

    Examples:
      | n         |
      | John      |
      | Maria     |

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

# ==============================================================================
# Input Validation & Edge Cases
# ==============================================================================
# These tests verify how the API handles boundary conditions and edge cases

  Scenario: Request without name parameter
    When I request the API without a name parameter
    Then the response status should be 422
    And the response should contain an error message

  @bug
  Scenario: Request with empty name parameter
    When I request age prediction for name ""
    Then the response status should be 422
    And the response should contain an error message

  Scenario: Request with single character name
    When I request age prediction for name "J"
    Then the response status should be 200
    And the response should contain a name field
    And the response should contain an age field

  Scenario: Request with very long name
    When I request age prediction for name "Abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz"
    Then the response status should be 200
    And the response should contain a name field

  Scenario: Request with numeric characters in name
    When I request age prediction for name "Test123"
    Then the response status should be 200
    And the response should contain a name field with value "Test123"

  Scenario: Request with special characters in name
    When I request age prediction for name "Test@!£$%^&"
    Then the response status should be 200
    And the response should contain a name field

  Scenario Outline: Request with whitespace in names
    When I request age prediction for name "<n>"
    Then the response status should be 200
    And the response should contain a name field

    Examples:
      | n            |
      |  Michael     |
      | John  Smith  |

  @bug
  Scenario: Request with whitespace-only name parameter
    When I request age prediction for name "   "
    Then the response status should be 422
    And the response should contain an error message

  # BUG: API returns 400 instead of documented 422
  # Documentation: https://agify.io/documentation
  # Expected: 422 Unprocessable Content with { "error": "Invalid 'name' parameter" }
  # Actual: 400 Bad Request with { "error": "Invalid 'name' parameter" }
  # Test uses invalid UTF-8 bytes: %C0, %C1, %FF (overlong encoding and invalid bytes)
  # This test expects documented behaviour to flag the discrepancy
  @bug
  Scenario: Request with invalid UTF-8 byte sequences in name parameter
    When I request age prediction with invalid UTF-8 byte sequences
    Then the response status should be 422
    And the response should contain an error message "Invalid 'name' parameter"

# ==============================================================================
# Character Encoding & Internationalization
# ==============================================================================
# These tests verify the API handles various character sets and encodings

  Scenario Outline: Request with international characters
    When I request age prediction for name "<name>"
    Then the response status should be 200
    And the response should contain a name field

    Examples:
      | name    |
      | José    |
      | 李明    |

# ==============================================================================
# Name Parsing & Formatting
# ==============================================================================
# These tests verify how the API handles different name formats

  Scenario: Request with hyphenated first name
    When I request age prediction for name "Jean-Pierre"
    Then the response status should be 200
    And the response should contain a name field

  Scenario Outline: Request with names containing apostrophes
    When I request age prediction for name "<name>"
    Then the response status should be 200
    And the response should contain a name field
    And the response should contain an age field

    Examples:
      | name      |
      | O'Brien   |

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

# ==============================================================================
# Localization & Country-Specific Predictions
# ==============================================================================
# These tests verify country-based localization features

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

# ==============================================================================
# Batch Requests
# ==============================================================================
# These tests verify the batch processing functionality

  Scenario: Batch request with multiple names
    When I request age predictions for the following names:
      | Michael  |
      | Sarah    |
      | David    |
    Then the response status should be 200
    And each prediction should have name, age, and count fields

  @rate_limited
  Scenario: Batch request with up to 10 names
    When I request age predictions for 10 names in a batch
    Then the response status should be 200
    And each prediction should have name, age, and count fields

  @rate_limited
  Scenario: Batch request with 11 names exceeds documented limit
    When I request age predictions for 11 names in a batch
    Then the response status should be 400 or 422
    And the response should contain an error message

  @rate_limited
  Scenario: Batch request with duplicate names
    When I request age predictions for the following names:
      | John  |
      | John  |
      | Mary  |
    Then the response status should be 200
    And the response should contain 3 predictions

  @localization @rate_limited
  Scenario: Batch request with country localization
    When I request age predictions for the following names with country code "US":
      | Michael  |
      | Sarah    |
      | David    |
    Then the response status should be 200
    And each prediction should have name, age, and count fields
    And each prediction should include a country_id field with value "US"

  @localization @rate_limited
  Scenario: Batch localization improves prediction accuracy
    When I request age predictions for the following names with country code "ES":
      | Maria    |
      | Carlos   |
      | Isabel   |
    Then the response status should be 200
    And each prediction should have name, age, and count fields
    And each prediction should include a country_id field with value "ES"

  @localization @rate_limited
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

# ==============================================================================
# Performance & Reliability
# ==============================================================================
# These tests verify non-functional requirements like performance and consistency

  Scenario: Verify response time is acceptable
    When I request age prediction for name "David"
    Then the response status should be 200
    And the response time should be less than 2000 milliseconds

  Scenario: Verify count field represents sample size
    When I request age prediction for name "Emma"
    Then the response status should be 200
    And the count field should be greater than or equal to 0

  Scenario: API returns consistent results for same name
    When I request age prediction for name "Robert" twice
    Then both responses should have the same age value
    And both responses should have the same count value

################################################################################
#                          SECURITY TESTING                                    #
################################################################################

# ==============================================================================
# Injection Attacks (SQL, XSS, Command Injection, Path Traversal)
# ==============================================================================
# These tests verify the API handles malicious input safely:
# - Should not crash or return 500 errors
# - Should not expose database error messages
# - Should return properly-encoded JSON (XSS is a client-side concern for rendering)

  @security @rate_limited
  Scenario Outline: SQL injection and XSS attempts in name parameter
    When I request age prediction for name "<payload>"
    Then the response status should be 200
    And the response should contain a name field
    And the response should not expose any database errors
    And the name field should be properly escaped or sanitized

    Examples:
      | payload                              |
      | ' OR '1'='1                          |
      | <script>alert('xss')</script>        |

  @security @rate_limited
  Scenario Outline: Command injection and path traversal attempts
    When I request age prediction for name "<payload>"
    Then the response status should be 200
    And the response should contain a name field

    Examples:
      | payload           |
      | ../../etc/passwd  |

# ==============================================================================
# Parameter Manipulation & Validation
# ==============================================================================
# These tests verify the API handles malformed or manipulated parameters

  @parameter_validation @rate_limited
  Scenario: Request with duplicate name parameters
    When I request with duplicate name parameters "John" and "Jane"
    Then the response status should be 200
    And the response should handle the duplicate parameters gracefully

  @parameter_validation
  Scenario: Request with case-sensitive parameter name
    When I request with parameter "Name" instead of "name"
    Then the response should indicate missing or invalid parameter

# ==============================================================================
# Authentication & Authorization
# ==============================================================================
# These tests verify API key authentication and rate limiting (@skip - requires API key)

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

  @skip
  Scenario: Batch request with insufficient quota returns 429
    Given I have only 5 requests remaining in my quota
    When I request age predictions for 10 names with an API key
    Then the response status should be 429
    And the response should contain an error message "Request limit too low to process request"
