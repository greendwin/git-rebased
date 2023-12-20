git rebased
===========

This script provides a safe way to rebase feature branches for distributed teams.
It stores additional branches that links rebased branches together. 
This allows to avoid dangerous `git reset --hard` and tricky rebases on edited history.


## Motivation

Imagine following scenario:

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

Your teammate (2) wants to push his changes, but he can't do this easily without additional work, because `A` and `A'` are different commits.

`git rebased` solves this problem by using additional "backup" branches, linking rebased commits with their old versions.


## Solution

When you (1) want to push a rebased branch instead of `git push --force` you can use:
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

Now, your teammate (2) can rebase his work on top of rebased `feature`:

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

At this point he can push his changes `C` to `feature` without any problems.
