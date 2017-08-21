import 'dart:math' as math;
import 'package:meta/meta.dart';

double isDeadNeuron(
  List<double> weightedInputs) {
  // Weighted sum of inputs...
  var sum = weightedInputs.reduce((a, b) => a + b);

  // Normalize this, so that it's between 0 and 1.
  return 1 / (1 + math.pow(math.E, -1 * sum));
}

double isDeadNeuronOld(
  List<double> weights, {
  @required int stargazersCount,
  @required int forksCount,
  @required int commitsThisYear,
  @required int timeSinceLastCommit,
}) {
  // Weighted sum of inputs...
  var sum = (starsNeuron(stargazersCount) * weights[0]) +
      (forksNeuron(forksCount) * weights[1]) +
      (commitsNeuron(commitsThisYear) * weights[2]) +
      (timeSinceLastCommitNeuron(timeSinceLastCommit) * weights[3]);

  // Normalize this, so that it's between 0 and 1.
  var sigmoid = 1 / (1 + math.pow(math.E, -1 * sum));
  return sigmoid;
}

/// Less than 100 stars
double starsNeuron(int stargazersCount) => stargazersCount < 100 ? 1.0 : 0.0;

/// Less than 5 forks
double forksNeuron(int forksCount) => forksCount < 5 ? 1.0 : 0.0;

/// Less than one commit per week
double commitsNeuron(int commitsThisYear) => commitsThisYear < 52 ? 1.0 : 0.0;

/// A month or more without a commit
double timeSinceLastCommitNeuron(int milliseconds) =>
    milliseconds >= const Duration(days: 30).inMilliseconds ? 1.0 : 0.0;
