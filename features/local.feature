Feature: Docroot management

  In order to manage docroot
  As a developer using Cucumber
  I want to use the deploy steps to deploy to local

  @announce
  @no-clobber
  Scenario: Local force init
    Given I run `docman init sample-docroot https://github.com/aroq/dm-test-docroot-config.git -f`
    Then the exit status should be 0
    Then the following directories should exist:
      | sample-docroot |
      | sample-docroot/config |

  @announce
  @no-clobber
  Scenario: Local interactive init
    Given I run `docman init sample-docroot https://github.com/aroq/dm-test-docroot-config.git` interactively
    And I type "yes"
    Then the exit status should be 0
    Then the following directories should exist:
      | sample-docroot |
      | sample-docroot/config |

  @announce
  @no-clobber
  Scenario: Local build development
    Given I cd to "sample-docroot"
    Then I run `docman build local development`
    Then the exit status should be 0
    Then the following directories should exist:
      | master |
      | master/docroot |
      | master/docroot/sites |
      | master/hooks |
      | master/profiles |
      | master/profiles/sample_profile |
      | master/projects/sample_project1 |
      | master/projects/sample_project2 |

  @announce
  @no-clobber
  Scenario: Local push into project1 develop
    Given I cd to "sample-docroot/master/projects/sample_project1"
    And I run `git checkout develop`
    And I run `git pull origin develop`
    Then the exit status should be 0
    And I store in "name" value "test"
    And I check stored value of "name" should contain "test"
    And I create file with random name in "filename" content in "random_name"
    Given a file named "develop.txt" with:
      """
      test content

      """
    And I run `git add -A`
    And I run `git commit -m "Test commit to develop"`
    And I run `git push origin develop`
    Then the exit status should be 0
