/**
 * LeaderboardBatch
 * Runs daily (see LeaderboardBatchSchedule / scheduled job "GameHub Leaderboard Batch").
 * 1. Recalculates each player's Rank__c from Total_Score__c.
 * 2. Generates a Top 100 leaderboard snapshot, logged for the Gaming Analytics Dashboard.
 */
public with sharing class LeaderboardBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer processedCount = 0;
    public static final Integer TOP_N = 100;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Total_Score__c, Rank__c FROM Player__c ORDER BY Total_Score__c DESC NULLS LAST'
        );
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<sObject> toUpdate = new List<sObject>();

        for (sObject p : scope) {
            processedCount++;
            Decimal newRank = processedCount;
            Decimal currentRank = (Decimal)p.get('Rank__c');
            if (currentRank != newRank) {
                sObject playerToUpdate = Schema.getGlobalDescribe().get('Player__c').newSObject(p.Id);
                playerToUpdate.put('Rank__c', newRank);
                toUpdate.add(playerToUpdate);
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        List<sObject> top100 = Database.query(
            'SELECT Id, Name, Username__c, Total_Score__c, Rank__c FROM Player__c ORDER BY Rank__c ASC NULLS LAST LIMIT :TOP_N'
        );

        System.debug('LeaderboardBatch complete. Players processed: ' + processedCount
            + '. Top 100 snapshot size: ' + top100.size());
    }
}
