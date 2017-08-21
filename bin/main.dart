import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:github/src/common.dart';
import 'package:github/server.dart';
import 'package:project_is_dead/project_is_dead.dart';

main() async {
  // Create Github client
  dotenv.load();
  var gh = new GitHub(
      auth: new Authentication.withToken(dotenv.env['GITHUB_TOKEN']));

  // Load samples
  var sampleFile = new File.fromUri(Platform.script.resolve('samples.json'));
  Map<String, int> sampleMap = JSON.decode(await sampleFile.readAsString());
  Map<List<int>, int> trainingSet = {};
  var now = new DateTime.now();
  var rnd = new math.Random(1);

  // TODO: Multi-thread this
  for (var slug in sampleMap.keys) {
    var repo =
        await gh.repositories.getRepository(new RepositorySlug.full(slug));
    var data = [
      repo.stargazersCount,
      repo.forksCount,
      await commitsThisYear(slug, gh),
      now.millisecondsSinceEpoch - repo.pushedAt.millisecondsSinceEpoch,
    ];
    trainingSet[data] = sampleMap[slug];
    print('$slug => $data');
  }

  double randomWeight() => (-1 + rnd.nextInt(3)).toDouble();

  var weights = new List.generate(4, (_) => randomWeight());

  var inputs = [
    starsNeuron,
    forksNeuron,
    commitsNeuron,
    timeSinceLastCommitNeuron,
  ];

  double isDead(Repository repo, int commitsThisYear) {
    return isDeadNeuron([
      starsNeuron(repo.stargazersCount) * weights[0],
      forksNeuron(repo.forksCount) * weights[1],
      commitsNeuron(commitsThisYear) * weights[2],
      timeSinceLastCommitNeuron(now.millisecondsSinceEpoch -
              repo.pushedAt.millisecondsSinceEpoch) *
          weights[3],
    ]);
  }

  double sigmoidGradient(double output) => output * (1 - output);

  // Now, train the algorithm.

  int m = 20000;
  for (int i = 0; i < m; i++) {
    var pct = (i * 100.0 / m).toStringAsFixed(2);
    stdout.write('\rTraining $pct%...');

    trainingSet.forEach((data, isDead) {
      var j = 0;
      var computed = isDeadNeuron(
        weights.map<double>((x) => x * inputs[j](data[j++])).toList(),
      );
      var error = isDead - computed;

      // Make an adjustment based on how off we were...
      // adjustment = error * input * sigmoidGradient(computed);
      var gradient = error * sigmoidGradient(computed);

      for (int i = 0; i < weights.length; i++) {
        weights[i] += inputs[i](data[i]) * gradient;
      }
    });
  }

  print('\rTraining complete.');
  print('Weights: $weights');
  print('Stargazers: ${weights[0]}');
  print('Forks: ${weights[1]}');
  print('# Commits this Year: ${weights[2]}');
  print('Time since Last Commit: ${weights[3]}');

  while (true) {
    stdout.write("Enter the slug of a repo to check if it is alive: ");
    var slug = stdin.readLineSync();
    var repo =
        await gh.repositories.getRepository(new RepositorySlug.full(slug));
    var dead = isDead(repo, await commitsThisYear(slug, gh));
    print('Result: $dead');
    var repoIsDead = dead > 0.5
        ? true
        : false;

    if (repoIsDead)
      print('$slug is dead!!! RIP.');
    else
      print('$slug is doing just fine.');
  }
}

Future<int> commitsThisYear(String slug, GitHub gh) async {
  var activityResponse =
      await gh.request('GET', '/repos/$slug/stats/commit_activity');
  var untyped = JSON.decode(activityResponse.body);

  if (untyped is Map) {
    // Empty commit history
    return 0;
  } else if (untyped is! List) {
    print(activityResponse.body);
    throw 'Could not fetch activity of $slug.';
  }

  List<Map<String, dynamic>> activity = untyped;

  // Add up the total commits over the past year
  return activity.fold<int>(0, (sum, map) {
    return sum + map['total'];
  });
}
