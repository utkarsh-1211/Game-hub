/**
 * TournamentTrigger
 * When a Tournament__c transitions to Completed, marks the top-scoring
 * Tournament_Registration__c as Winner and issues that player a Trophy Reward__c
 * tied to the tournament's prize pool.
 */
trigger TournamentTrigger on Tournament__c (after update) {
    List<Id> completedTournamentIds = new List<Id>();

    for (sObject t : Trigger.new) {
        sObject oldT = Trigger.oldMap.get(t.Id);
        if ((String)t.get('Tournament_Status__c') == 'Completed' && (String)oldT.get('Tournament_Status__c') != 'Completed') {
            completedTournamentIds.add(t.Id);
        }
    }

    if (completedTournamentIds.isEmpty()) {
        return;
    }

    Map<Id, sObject> tournamentsById = new Map<Id, sObject>(Database.query(
        'SELECT Id, Prize_Pool__c FROM Tournament__c WHERE Id IN :completedTournamentIds'
    ));

    Map<Id, List<sObject>> regsByTournament = new Map<Id, List<sObject>>();
    List<sObject> registrations = Database.query(
        'SELECT Id, Tournament__c, Player__c, Score__c, Status__c ' +
        'FROM Tournament_Registration__c WHERE Tournament__c IN :completedTournamentIds ' +
        'ORDER BY Score__c DESC NULLS LAST'
    );
    for (sObject reg : registrations) {
        Id tId = (Id)reg.get('Tournament__c');
        if (!regsByTournament.containsKey(tId)) {
            regsByTournament.put(tId, new List<sObject>());
        }
        regsByTournament.get(tId).add(reg);
    }

    List<sObject> regsToUpdate = new List<sObject>();
    List<sObject> rewardsToInsert = new List<sObject>();

    for (Id tournamentId : regsByTournament.keySet()) {
        List<sObject> regs = regsByTournament.get(tournamentId);
        if (regs.isEmpty()) {
            continue;
        }
        sObject winnerReg = regs[0];
        winnerReg.put('Status__c', 'Winner');
        regsToUpdate.add(winnerReg);

        sObject newReward = Schema.getGlobalDescribe().get('Reward__c').newSObject();
        newReward.put('Name', 'Tournament Champion');
        newReward.put('Player__c', winnerReg.get('Player__c'));
        newReward.put('Tournament__c', tournamentId);
        newReward.put('Reward_Type__c', 'Trophy');
        newReward.put('Points_Awarded__c', tournamentsById.get(tournamentId).get('Prize_Pool__c'));
        newReward.put('Reward_Date__c', Date.today());
        rewardsToInsert.add(newReward);
    }

    if (!regsToUpdate.isEmpty()) {
        update regsToUpdate;
    }
    if (!rewardsToInsert.isEmpty()) {
        insert rewardsToInsert;
    }
}
