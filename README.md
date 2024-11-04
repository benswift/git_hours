# GitHours

An elixir port of [git-hours](https://github.com/kimmobrunfeldt/git-hours), or
at least something close to it conceptually.

## Usage

Run this script in a git repository to get a summary of the time you've spent
(on the current branch, at least).

Currently the UX is super-basic; just change the `GitHours.calculate/1` call at
the bottom of the file.

## TODO

Honestly this is just to scratch an itch. So no timeline on if (or when) I'll
get to any of it.

- turn it into a proper CLI tool (or mix task)
- add a way to specify the branch, date range, time window, etc. (currently
  that's all do-able by hacking the script directly)
- return json output (rather than just printing to the console)

## Author

Ben Swift

## Licence

MIT
