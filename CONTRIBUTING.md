# Contributing

Contributions are welcomed. 

## Working groups

The develop of the Ottawa Data Model mostly occurs with informal working groups are created as needed to improve metadata sections. These working groups are time-limited and follow an agile development approach. Please feel free to suggest of offer hosting a working group in GitHub issues or discussions. 

Working groups propose changes through a pull request to `dev`. Initial review for the PR is from previous contributors. Following there is a pull request from `dev` to `main` for proposed changes to the next version of the Ottawa Data Model. 

We aim for a one-week community review period from `dev` to `main` during the initial agile development period. We welcome community review from anyone in the wastewater surveillance community. The ODM must work for your needed to be successful. Please `watch` this GH repo to ensure you are aware of proposed changed. 

## Repo Organization

### Naming Conventions

* Use [kebab-case](https://www.theserverside.com/definition/Kebab-case#:~:text=Kebab%20case%20%2D%2D%20or%20kebab,properly%20convey%20a%20resource's%20meaning.) when naming files and folder making sure to use lower case

### Git Workflow

This repo follows the [git feature branch workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow)

* The main branch (master or main) should always have the latest public/working/correct/buildable version of the documentation
* As much as possible avoid commiting directly to master/main. Instead new features, bug fixes etc. should be worked on a seperate branch and then a PR should be made to dev. The dev branch should have the next version that the team is working towards. When the dev branch is ready to be released to the public, a PR should be made to master/main and merged in.
* When a new version is released, the commit that has the new version should be tagged with the version number

### New Version Checklist

* Update the files in the [dictionary-tables](https://github.com/PHES-ODM/PHES-ODM/tree/main/dictionary-tables) folder. Each file should have the new version number attached at the end. For example, if the new version is `3.1.0`, then the `ODM_parts.csv` file should be copied as `ODM_parts_v3.1.0.csv`.