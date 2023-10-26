git rebased-push
================

Push rebased branch storing migration history to backup branch.


## Roadmap

- [ ] rework to script with commands `git rebased push`, `git rebased pull`, etc.
- [ ] add command `git rebased pull` that rebases current branch on top of `backup~`
- [ ] add command `git rebased cleanup` that removes unused backup branches (without matching original branch)

- [ ] TBD: rewrite this to python and make installable from `pipx`
