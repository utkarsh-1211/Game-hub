/**
 * PlayerController
 * Apex controller backing the playerDashboard LWC.
 * Exposes read access to the running player's profile, recent matches and rewards,
 * plus a method for the Match trigger / batch to update a player's total score.
 */
public with sharing class PlayerController {

    @AuraEnabled(cacheable=true)
    public static sObject getPlayerDetails(Id playerId) {
        if (playerId == null) {
            throw new AuraHandledException('A player Id is required.');
        }
        List<sObject> players = Database.query(
            'SELECT Id, Name, Email__c, Username__c, Skill_Level__c, ' +
            'Total_Score__c, Rank__c, Country__c, Join_Date__c ' +
            'FROM Player__c WHERE Id = :playerId WITH SECURITY_ENFORCED LIMIT 1'
        );
        if (players.isEmpty()) {
            throw new AuraHandledException('Player not found.');
        }
        return players[0];
    }

    @AuraEnabled(cacheable=true)
    public static sObject getPlayerProfile(Id playerId) {
        return getPlayerDetails(playerId);
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> getRecentMatches(Id playerId, Integer maxResults) {
        if (playerId == null) {
            throw new AuraHandledException('A player Id is required.');
        }
        Integer lim = (maxResults == null || maxResults <= 0) ? 10 : maxResults;
        return Database.query(
            'SELECT Id, Score__c, Result__c, ' +
            'Match__c, Match__r.Name, Match__r.Match_Date__c, Match__r.Status__c, ' +
            'Match__r.Game__c, Match__r.Game__r.Name ' +
            'FROM Match_Player__c WHERE Player__c = :playerId ' +
            'WITH SECURITY_ENFORCED ORDER BY Match__r.Match_Date__c DESC LIMIT :lim'
        );
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> getPlayerRewards(Id playerId) {
        if (playerId == null) {
            throw new AuraHandledException('A player Id is required.');
        }
        return Database.query(
            'SELECT Id, Name, Reward_Type__c, Points_Awarded__c, Reward_Date__c, ' +
            'Tournament__c, Tournament__r.Name ' +
            'FROM Reward__c WHERE Player__c = :playerId ' +
            'WITH SECURITY_ENFORCED ORDER BY Reward_Date__c DESC'
        );
    }

    /**
     * Adds delta points to a player's running Total_Score__c.
     * Used by MatchTrigger after a match result is recorded.
     */
    @AuraEnabled
    public static void updatePlayerScore(Id playerId, Decimal scoreDelta) {
        if (playerId == null || scoreDelta == null) {
            return;
        }
        List<sObject> players = Database.query(
            'SELECT Id, Total_Score__c FROM Player__c WHERE Id = :playerId LIMIT 1'
        );
        if (!players.isEmpty()) {
            sObject player = players[0];
            Decimal currentScore = (Decimal)player.get('Total_Score__c');
            player.put('Total_Score__c', (currentScore == null ? 0 : currentScore) + scoreDelta);
            try {
                update player;
            } catch (DmlException e) {
                throw new AuraHandledException('Unable to update player score: ' + e.getMessage());
            }
        }
    }
}
