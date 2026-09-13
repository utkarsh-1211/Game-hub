/**
 * MatchTrigger
 * When a Match__c is marked Completed, rolls each participating Match_Player__c's
 * Score__c into the corresponding Player__c.Total_Score__c.
 */
trigger MatchTrigger on Match__c (after update) {
    List<Id> completedMatchIds = new List<Id>();

    for (Match__c m : Trigger.new) {
        Match__c oldM = Trigger.oldMap.get(m.Id);
        if (m.Status__c == 'Completed' && oldM.Status__c != 'Completed') {
            completedMatchIds.add(m.Id);
        }
    }

    if (completedMatchIds.isEmpty()) {
        return;
    }

    Map<Id, Decimal> scoreDeltaByPlayer = new Map<Id, Decimal>();
    for (Match_Player__c mp : [
        SELECT Player__c, Score__c
        FROM Match_Player__c
        WHERE Match__c IN :completedMatchIds
    ]) {
        if (mp.Player__c == null) {
            continue;
        }
        Decimal delta = (mp.Score__c == null ? 0 : mp.Score__c);
        Decimal running = scoreDeltaByPlayer.containsKey(mp.Player__c) ? scoreDeltaByPlayer.get(mp.Player__c) : 0;
        scoreDeltaByPlayer.put(mp.Player__c, running + delta);
    }

    if (scoreDeltaByPlayer.isEmpty()) {
        return;
    }

    Map<Id, Player__c> playersById = new Map<Id, Player__c>([
        SELECT Id, Total_Score__c
        FROM Player__c
        WHERE Id IN :scoreDeltaByPlayer.keySet()
    ]);

    List<Player__c> toUpdate = new List<Player__c>();
    for (Id playerId : scoreDeltaByPlayer.keySet()) {
        Player__c p = playersById.get(playerId);
        if (p == null) {
            continue;
        }
        p.Total_Score__c = (p.Total_Score__c == null ? 0 : p.Total_Score__c) + scoreDeltaByPlayer.get(playerId);
        toUpdate.add(p);
    }

    if (!toUpdate.isEmpty()) {
        update toUpdate;
    }
}
