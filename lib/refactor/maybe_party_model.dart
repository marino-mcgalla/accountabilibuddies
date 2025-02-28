class Party {
  final String id;
  final String name;
  final String ownerId;
  final List<String> members;
  final Map<String, List<Goal>> userGoals;

  Party({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.userGoals,
  });

  // Convert Party to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'members': members,
      'userGoals': userGoals.map((key, value) =>
          MapEntry(key, value.map((goal) => goal.toMap()).toList())),
    };
  }

  // Create Party from Map
  factory Party.fromMap(Map<String, dynamic> data) {
    return Party(
      id: data['id'],
      name: data['name'],
      ownerId: data['ownerId'],
      members: List<String>.from(data['members']),
      userGoals: (data['userGoals'] as Map<String, dynamic>).map((key, value) =>
          MapEntry(
              key,
              (value as List)
                  .map((goalData) => Goal.fromMap(goalData))
                  .toList())),
    );
  }
}

class Goal {
  final String id;
  final String name;
  final Map<String, String> completions; // Track completion status for each day

  Goal({required this.id, required this.name, required this.completions});

  // Convert Goal to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'completions': completions,
    };
  }

  // Create Goal from Map
  factory Goal.fromMap(Map<String, dynamic> data) {
    return Goal(
      id: data['id'],
      name: data['name'],
      completions: Map<String, String>.from(data['completions']),
    );
  }
}

final sampleParty = Party(
  id: "party123",
  name: "Accountabilibuddies",
  ownerId: "Reno",
  members: ["Reno", "Kev", "Bobby"],
  userGoals: {
    "Reno": [
      Goal(
        id: "goal1",
        name: "Buy Cake",
        completions: {
          "2023-10-01": "completed",
          "2023-10-02": "skipped",
        },
      ),
      Goal(
        id: "goal2",
        name: "Send Invitations",
        completions: {
          "2023-10-01": "planned",
          "2023-10-02": "completed",
        },
      ),
    ],
    "Kev": [
      Goal(
        id: "goal3",
        name: "Decorate Venue",
        completions: {
          "2023-10-01": "not_completed",
          "2023-10-02": "completed",
        },
      ),
      Goal(
        id: "goal4",
        name: "Prepare Games",
        completions: {
          "2023-10-01": "completed",
          "2023-10-02": "completed",
        },
      ),
    ],
    "Bobby": [
      Goal(
        id: "goal5",
        name: "Arrange Music",
        completions: {
          "2023-10-01": "planned",
          "2023-10-02": "not_completed",
        },
      ),
      Goal(
        id: "goal6",
        name: "Buy Drinks",
        completions: {
          "2023-10-01": "completed",
          "2023-10-02": "completed",
        },
      ),
    ],
  },
);
