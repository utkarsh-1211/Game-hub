/**
 * TournamentTrigger
 * When a Tournament__c transitions to Completed, marks the top-scoring
 * Tournament_Registration__c as Winner and issues that player a Trophy Reward__c
 * tied to the tournament's prize pool.
 */
trigger TournamentTrigger on Tournament__c (after update) {
    List<Id> completedTournamentIds = new List<Id>();

    for (Tournament__c t : Trigger.new) {
        Tournament__c oldT = Trigger.oldMap.get(t.Id);
        if (t.Tournament_Status__c == 'Completed' && oldT.Tournament_Status__c != 'Completed') {
            completedTournamentIds.add(t.Id);
        }
    }

    if (completedTournamentIds.isEmpty()) {
        return;
    }

    Map<Id, Tournament__c> tournamentsById = new Map<Id, Tournament__c>([
        SELECT Id, Prize_Pool__c
        FROM Tournament__c
        WHERE Id IN :completedTournamentIds
    ]);

    Map<Id, List<Tournament_Registration__c>> regsByTournament = new Map<Id, List<Tournament_Registration__c>>();
    for (Tournament_Registration__c reg : [
        SELECT Id, Tournament__c, Player__c, Score__c, Status__c
        FROM Tournament_Registration__c
        WHERE Tournament__c IN :completedTournamentIds
        ORDER BY Score__c DESC NULLS LAST
    ]) {
        if (!regsByTournament.containsKey(reg.Tournament__c)) {
            regsByTournament.put(reg.Tournament__c, new List<Tournament_Registration__c>());
        }
        regsByTournament.get(reg.Tournament__c).add(reg);
    }

    List<Tournament_Registration__c> regsToUpdate = new List<Tournament_Registration__c>();
    List<Reward__c> rewardsToInsert = new List<Reward__c>();

    for (Id tournamentId : regsByTournament.keySet()) {
        List<Tournament_Registration__c> regs = regsByTournament.get(tournamentId);
        if (regs.isEmpty()) {
            continue;
        }
        Tournament_Registration__c winnerReg = regs[0];
        winnerReg.Status__c = 'Winner';
        regsToUpdate.add(winnerReg);

        rewardsToInsert.add(new Reward__c(
            Name = 'Tournament Champion',
            Player__c = winnerReg.Player__c,
            Tournament__c = tournamentId,
            Reward_Type__c = 'Trophy',
            Points_Awarded__c = tournamentsById.get(tournamentId).Prize_Pool__c,
            Reward_Date__c = Date.today()
        ));
    }

    if (!regsToUpdate.isEmpty()) {
        update regsToUpdate;
    }
    if (!rewardsToInsert.isEmpty()) {
        insert rewardsToInsert;
    }
}
