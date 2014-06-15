Feature: Init

  In order to manage docroot
  As a developer using Cucumber
  I want to use the deploy steps to deploy to local

  @announce
  @no-clobber
  @init
  Scenario: Local force init
    Given I run `docman init sample-docroot https://github.com/aroq/dm-test-docroot-config.git -f`
    Then the exit status should be 0
    Then the following directories should exist:
      | sample-docroot |
      | sample-docroot/config |

  @announce
  @no-clobber
  @init
  Scenario: Local interactive init
    Given I run `docman init sample-docroot https://github.com/aroq/dm-test-docroot-config.git` interactively
    And I type "yes"
    Then the exit status should be 0
    Then the following directories should exist:
      | sample-docroot |
      | sample-docroot/config |

