# project_is_dead
A simple neural network that can determine whether a Github repo is still active,
or if it has faded into obscurity.

It accounts for:
* Number of stars
* Number of forks
* Number of commits in the past year
* Time since last commit (whether it is > 1 month)

Training data resides in `samples.json`. Feel free to fork and add
more samples!!!

## Running
Replace the `.env.example` with a `.env` file and a Github API token.

Run this Dart script to train the AI and then start a simple REPL:

```bash
dart bin/main.dart
```

Then just enter, `<owner/repo-name>` when prompted.