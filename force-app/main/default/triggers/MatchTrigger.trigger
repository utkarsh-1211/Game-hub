/**
 * MatchTrigger
 * When a Match__c is marked Completed, rolls each participating Match_Player__c's
 * Score__c into the corresponding Player__c.Total_Score__c.
 */
trigger MatchTrigger on Match__c (after update) {
    List<Id> completedMatchIds = new List<Id>();

    for (sObject m : Trigger.new) {
        sObject oldM = Trigger.oldMap.get(m.Id);
        if ((String)m.get('Status__c') == 'Completed' && (String)oldM.get('Status__c') != 'Completed') {
            completedMatchIds.add(m.Id);
        }
    }

    if (completedMatchIds.isEmpty()) {
        return;
    }

    Map<Id, Decimal> scoreDeltaByPlayer = new Map<Id, Decimal>();
    List<sObject> matchPlayers = Database.query(
        'SELECT Player__c, Score__c FROM Match_Player__c WHERE Match__c IN :completedMatchIds'
    );
    for (sObject mp : matchPlayers) {
        Id pId = (Id)mp.get('Player__c');
        if (pId == null) {
            continue;
        }
        Decimal scoreVal = (Decimal)mp.get('Score__c');
        Decimal delta = (scoreVal == null ? 0 : scoreVal);
        Decimal running = scoreDeltaByPlayer.containsKey(pId) ? scoreDeltaByPlayer.get(pId) : 0;
        scoreDeltaByPlayer.put(pId, running + delta);
    }

    if (scoreDeltaByPlayer.isEmpty()) {
        return;
    }

    Set<Id> pIds = scoreDeltaByPlayer.keySet();
    Map<Id, sObject> playersById = new Map<Id, sObject>(Database.query(
        'SELECT Id, Total_Score__c FROM Player__c WHERE Id IN :pIds'
    ));

    List<sObject> toUpdate = new List<sObject>();
    for (Id playerId : scoreDeltaByPlayer.keySet()) {
        sObject p = playersById.get(playerId);
        if (p == null) {
            continue;
        }
        Decimal currentScore = (Decimal)p.get('Total_Score__c');
        p.put('Total_Score__c', (currentScore == null ? 0 : currentScore) + scoreDeltaByPlayer.get(playerId));
        toUpdate.add(p);
    }

    if (!toUpdate.isEmpty()) {
        update toUpdate;
    }
}
