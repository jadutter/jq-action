# Complete:

1. add pre-commit hooks to test docker image and workflow commands
1. add installer/setup script to setup git hooks? (husky)
1. reorganize git history
    - one version where jq is explicitly built (debian)
    - one version where jq is imported (alpine)

# To Do:

1. fix entrypoint.sh to handle multi-line output
1. consolidate test-workflows and merge into develop
1. bring alpine and debian up to date with develop
1. try to get action to work with other environments: Windows, Mac, ect
1. clean up README.md/make a CONTRIBUTING.md to CLEARLY explain how the action can be used vs how to develop and work on the repository
1. verify hooks work on Mac and Windows
1. branch versions for jq on windows, and jq on mac...?
1. refactor precommit hook for testing an image to be identical(/use) github workflow tests
