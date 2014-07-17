Feature: Docroot management - git_target

  In order to manage docroot
  As a developer using Cucumber
  I want to use the deploy steps to deploy to local

  @announce
  @no-clobber
  @build
  @git_target
  Scenario: git_target build development
    Given I cd to "sample-docroot"
    Then I run `docman build git_target development`
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

  @announce
  @no-clobber
  @git_target
  @develop
  @deploy
  Scenario: git_target deploy sample project 1 develop
    Given I cd to "sample-docroot"
    Then I run `docman deploy git_target sample_project1 branch develop`
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
  @git_target
  @deploy
  @master
  @sample_project2
  Scenario: git_target deploy sample project 2 master
    Given I cd to "sample-docroot"
    Then I run `docman deploy git_target sample_project2 branch master`
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
  @git_target
  @master
  @deploy
  @sites
  Scenario: git_target deploy sites master
    Given I cd to "sample-docroot"
    Then I run `docman deploy git_target sites branch master`
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
