git rebased-push
================

Push rebased branch storing migration history to backup branch.


## Roadmap

### MS-0 - prototype

- [x] rework to script to commands `git rebased push`, `git rebased pull`, etc.
- [x] add command `git rebased pull` that rebases current branch on top of `backup~`

### MS-1 - v0.1.0

- [ ] move roadmap out of README.md
- [ ] write detailed description
- [ ] add installation instructions
- [ ] publish on github

### Backlog

- [ ] add command `git rebased cleanup` that removes unused backup branches (without matching original branch)
- [ ] TBD: rewrite this to python and make installable from `pipx`
