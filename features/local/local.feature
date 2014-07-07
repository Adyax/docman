Feature: Docroot management - Local

  In order to manage docroot
  As a developer using Cucumber
  I want to use the deploy steps to deploy to local

  @announce
  @no-clobber
  @local
  @build
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
      | master/docroot/profiles/sample_profile |
    Then the following files should exist:
      | master/docroot/CHANGELOG.txt |
    Then I remove the file "master/docroot/profiles/sample_profile"
    Then the following directories should not exist:
      | master/docroot/profiles/sample_profile |
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
      | master/docroot/profiles/sample_profile |

#  @announce
#  @no-clobber
#  @deploy
#  Scenario: Local push into project1 develop
#    Given I cd to "sample-docroot/master/projects/sample_project1"
#    And I run `git reset --hard & git clean -f -d`
#    And I run `git checkout develop`
#    And I run `git pull origin develop`
#    Then the exit status should be 0
#    And I store in "name" value "test"
#    And I check stored value of "name" should contain "test"
##    And I create file with random name in "filename" content in "random_name"
#    Given a file named "develop.txt" with:
#      """
#      test content
#
#      """
#    And I run `git add -A`
#    And I run `git commit -m "Test commit to develop"`
#    And I run `git push origin develop`
#    Then the exit status should be 0

  @announce
  @no-clobber
  @local
  @deploy
  Scenario: Local deploy sample project 1 develop
    Given I cd to "sample-docroot"
    Then I run `docman deploy local sample_project1 branch develop`
    Then the exit status should be 0
    Then the following directories should exist:
      | master/projects/sample_project1 |

  @announce
  @no-clobber
  @local
  @deploy
  @master
  @sample_project2
  Scenario: Local deploy sample project 2 master
    Given I cd to "sample-docroot"
    Then I run `docman deploy local sample_project2 branch master`
    Then the exit status should be 0
    Then the following directories should exist:
      | master/projects/sample_project1 |
      | master/projects/sample_project2 |
