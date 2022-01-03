# Development

This page describes the protocol adopted for the AMDC firmware code development.

The AMDC firmware code base uses: [git](https://git-scm.com/) for version control; [semantic versioning](https://semver.org/) for release labeling.

```{tip}
Read about **semantic versioning** on the main **[semver.org](https://semver.org/)** website.
This greatly helps to explain the concepts below.
```

## Development

All development intended to impact a future release is done on topic branches from the latest `develop` branch.
This applies to bug fixes, feature additions, and/or major changes.
The `develop` branch is **not stable** -- the latest commits to `develop` might yield unstable code which is still in testing.

Regular open-source development practice is followed -- pull requests (PRs) are used to review new code and then eventually are merged into `develop`.
Merges into `develop` should use `Squash + Merge` via GitHub's online interface.
Each PR should be small enough to reasonably review -- if a PR has too many files changed or covers too large of scope, the developer will be asked to reduce the PR size by creating multiple smaller PRs.

## Releases

Per semantic versioning, there are three types of releases:

1. Major
2. Minor
3. Bug fix

To create a release, a snapshot of the code is taken and labeled as: `vA.B.C` where `A` denotes the *major* release number, `B` denotes the *minor* number, and `C` denotes the *bug fix* number. For example, a release might be called `v1.0.0` or `v1.5.12`.

### Release Branch

A so-called **release branch** refers to a labeled major and minor release, but unspecified bug fix.
The naming pattern is: `vA.B.x` where `A` and `B` are numbers and `x` denotes any bug fix number.
For example, the initial release branch is called `v1.0.x`.

### Procedure

The procedure for creating a new release is mostly common for all three types (major, minor, bug fix):

1. Ensure development has stablized on the `develop` branch
2. Ensure thorough testing of the latest `develop` branch code
3. Create a final commit to `develop` where the `./CHANGELOG.md` file is updated with documentation about the new release
4. Create a `git tag` pointing to the commit from Step 3 which is labeled according to semantic versioning (e.g., `v1.5.12`)
5. On GitHub, create a Release that has the same name as the tag (`vA.B.C`) and the description should be the changelog contents.

Now, depending on which type of release, the procedure differs:

#### Bug Fix

*After following the previous common steps 1-5, the last commit of `develop` should be tagged with a release label of the form: `vA.B.C`.*

For a new bug fix release, a release branch should already exist.
To publish the bug fix, simply merge the bug fix from `develop` into the appropriate release branches.
This should be done via a PR on GitHub and the PR should perform a regular merge commit, not a `Squash + Merge`.


```{attention}
You might need to merge the bug fix into multiple release branches, depending on how widespread the bug is.

Always merge in one direction, from `develop` to the release branches.
```

Occasionally, a bug might need to be fixed in a previous release branch, but does not exist in the latest `develop` branch.
In this case, do not change `develop` -- simply fix the bug where it needs to be fixed.
Then, create the `git tag` for the new bug fix release local to the specific release branch commit.
Finally, do not forget to create the GitHub Release per the above common Step 5.

#### Minor or Major

For a new minor or major release, a new release branch needs to be created.

*After following the previous common steps 1-5, the last commit of `develop` should be tagged with a release label of the form:*

- Minor: `vA.B.0`
- Major: `vA.0.0`

Then:

1. Create a new release branch from `develop` and call it `vA.B.x`
2. Update GitHub's default repo branch to be the latest release branch which was just created
3. Update the documentation website to reflect the minor or major (breaking) changes
