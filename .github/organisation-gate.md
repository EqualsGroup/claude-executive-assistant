# Organisation quality gate

The organisation can require this repository's public AI quality workflow in
other repositories through a ruleset. The workflow assesses pull request diffs
and review feedback through GitHub's API without checking out or executing pull
request code.

The source repository's local workflow registration can be disabled while the
organisation's required workflow continues to run in covered repositories.
GitHub documents disabling the individual workflow in the source repository as
one option for running a ruleset workflow in other repositories. This keeps
central enforcement available without a duplicate local run in the source
repository.

See [GitHub's ruleset workflow troubleshooting guidance](https://docs.github.com/en/enterprise-cloud%40latest/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/troubleshooting-rules#supported-directory).
