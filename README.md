git rebased
===========

Safe way to rebase feature branches for distributed teams.
This script stores backup branches for each branch that is being rebased.

This way, if someone else has continued working on the branch that you are rebasing, he can rebase his work on top of your rebased branch.


## Motivation

Imagine this scenario:

You (1) and your teammate (2) are working on the same feature branch.

```
... - X <- master
       \
        A - B <- feature (1) (2)
```

You decided to edit commit `A` and rebase `feature` branch, but your teammate is still working on the old version of the `feature` branch.

```
... - X <- master
      |\
      | A - B - C <- (2)
       \
        A' - B' <- feature (1)
```

Your teammate wants to push his changes, but he can't do this without additional work, because `A` and `A'` are different commits.

`git rebased` solves this problem by creating backup branches for each branch that is being rebased.


## Solution

When you want to push a rebased branch instead of `git push --force` you should use:
```bash
git rebased push
```

This will create additional `backup/feature` branch that links old commits to the new ones.

```
... - X <- master
      |\
      | A - B - C <- (2)
       \    |
        A' --- B' <- feature (1)
             \  \
              ---* <- backup/feature
```

Now, your teammate can rebase his work on top of rebased `feature`:

```bash
git rebased pull
```

After this he will have:
```
... - X <- master
       \
        A' - B' <- feature (1)
              \
               C' <- (2)
```
