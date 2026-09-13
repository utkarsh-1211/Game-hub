/**
 * MatchController
 * Backs the matchManager (admin) LWC: create matches, assign players, update scores,
 * declare a winner.
 */
public with sharing class MatchController {

    @AuraEnabled(cacheable=true)
    public static List<sObject> getMatches(Id tournamentId) {
        String query =
            'SELECT Id, Name, Tournament__c, Tournament__r.Name, Game__c, Game__r.Name, ' +
            'Match_Date__c, Winner__c, Winner__r.Name, Status__c ' +
            'FROM Match__c ';
        if (tournamentId != null) {
            query += 'WHERE Tournament__c = :tournamentId ';
        }
        query += 'WITH SECURITY_ENFORCED ORDER BY Match_Date__c DESC';
        return Database.query(query);
    }

    @AuraEnabled
    public static Id createMatch(String matchName, Id tournamentId, Id gameId, Datetime matchDate) {
        if (String.isBlank(matchName) || tournamentId == null || gameId == null) {
            throw new AuraHandledException('Match name, tournament and game are required.');
        }
        sObject match = Schema.getGlobalDescribe().get('Match__c').newSObject();
        match.put('Name', matchName);
        match.put('Tournament__c', tournamentId);
        match.put('Game__c', gameId);
        match.put('Match_Date__c', (matchDate != null ? matchDate : Datetime.now()));
        match.put('Status__c', 'Scheduled');

        try {
            insert match;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to create match: ' + e.getMessage());
        }
        return match.Id;
    }

    /**
     * Assigns a list of player Ids to a match by creating Match_Player__c junction records.
     */
    @AuraEnabled
    public static void assignPlayers(Id matchId, List<Id> playerIds) {
        if (matchId == null || playerIds == null || playerIds.isEmpty()) {
            throw new AuraHandledException('A match and at least one player are required.');
        }

        Set<Id> existingPlayerIds = new Set<Id>();
        List<sObject> existingMps = Database.query(
            'SELECT Player__c FROM Match_Player__c WHERE Match__c = :matchId'
        );
        for (sObject mp : existingMps) {
            existingPlayerIds.add((Id)mp.get('Player__c'));
        }

        List<sObject> toInsert = new List<sObject>();
        for (Id playerId : playerIds) {
            if (!existingPlayerIds.contains(playerId)) {
                sObject mp = Schema.getGlobalDescribe().get('Match_Player__c').newSObject();
                mp.put('Match__c', matchId);
                mp.put('Player__c', playerId);
                mp.put('Score__c', 0);
                toInsert.add(mp);
            }
        }

        if (!toInsert.isEmpty()) {
            try {
                insert toInsert;
            } catch (DmlException e) {
                throw new AuraHandledException('Unable to assign players: ' + e.getMessage());
            }
        }
    }

    /**
     * Updates a single Match_Player__c score/result. Triggers MatchTrigger to roll up
     * to the player's Total_Score__c once the match is marked Completed.
     */
    @AuraEnabled
    public static void updateScore(Id matchPlayerId, Decimal score, String result) {
        if (matchPlayerId == null) {
            throw new AuraHandledException('A match player record Id is required.');
        }
        sObject mp = Schema.getGlobalDescribe().get('Match_Player__c').newSObject(matchPlayerId);
        mp.put('Score__c', score);
        if (String.isNotBlank(result)) {
            mp.put('Result__c', result);
        }
        try {
            update mp;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to update score: ' + e.getMessage());
        }
    }

    /**
     * Declares the winner of a match, marks it Completed, and creates a Trophy reward.
     * Tournament_Trigger listens for tournament-level completions separately.
     */
    @AuraEnabled
    public static void updateMatchResult(Id matchId, Id winnerId) {
        if (matchId == null || winnerId == null) {
            throw new AuraHandledException('A match and winner are required.');
        }
        sObject match = Schema.getGlobalDescribe().get('Match__c').newSObject(matchId);
        match.put('Winner__c', winnerId);
        match.put('Status__c', 'Completed');
        try {
            update match;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to declare winner: ' + e.getMessage());
        }
    }
}
