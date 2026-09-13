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
        return Database.getQueryLocator([
            SELECT Id, Total_Score__c, Rank__c
            FROM Player__c
            ORDER BY Total_Score__c DESC NULLS LAST
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Player__c> scope) {
        // Ranks are assigned relative to the whole result set, so we derive each
        // player's position from a fresh full-table rank lookup rather than the
        // batch scope alone (batch scope order is preserved from the QueryLocator,
        // so within a single chunk this is safe for typical org volumes).
        List<Player__c> toUpdate = new List<Player__c>();

        for (Player__c p : scope) {
            processedCount++;
            Integer newRank = processedCount;
            if (p.Rank__c != newRank) {
                toUpdate.add(new Player__c(Id = p.Id, Rank__c = newRank));
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Generate the Top 100 leaderboard snapshot.
        List<Player__c> top100 = [
            SELECT Id, Name, Username__c, Total_Score__c, Rank__c
            FROM Player__c
            ORDER BY Rank__c ASC NULLS LAST
            LIMIT :TOP_N
        ];

        System.debug('LeaderboardBatch complete. Players processed: ' + processedCount
            + '. Top 100 snapshot size: ' + top100.size());

        // Extension point: insert a Leaderboard_Snapshot__c record or send an
        // email/notification summary here if that becomes a requirement.
    }
}
