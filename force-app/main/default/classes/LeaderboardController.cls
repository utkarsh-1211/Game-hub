/**
 * LeaderboardController
 * Backs the leaderBoard LWC: top players, global ranking, tournament-scoped ranking.
 * Rank__c on Player__c is normally refreshed nightly by LeaderboardBatch, but
 * calculateRankings() can be invoked on demand (e.g. after an admin correction).
 */
public with sharing class LeaderboardController {

    @AuraEnabled(cacheable=true)
    public static List<sObject> getTopPlayers(Integer maxResults) {
        Integer lim = (maxResults == null || maxResults <= 0) ? 100 : maxResults;
        return Database.query(
            'SELECT Id, Name, Username__c, Country__c, Skill_Level__c, Total_Score__c, Rank__c ' +
            'FROM Player__c WITH SECURITY_ENFORCED ORDER BY Total_Score__c DESC NULLS LAST LIMIT :lim'
        );
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> getTournamentRanking(Id tournamentId) {
        if (tournamentId == null) {
            throw new AuraHandledException('A tournament Id is required.');
        }
        return Database.query(
            'SELECT Id, Player__c, Player__r.Name, Player__r.Username__c, Score__c, Status__c ' +
            'FROM Tournament_Registration__c WHERE Tournament__c = :tournamentId ' +
            'WITH SECURITY_ENFORCED ORDER BY Score__c DESC NULLS LAST'
        );
    }

    /**
     * Recalculates every player's Rank__c based on Total_Score__c (1 = highest score).
     * Same logic used nightly by LeaderboardBatch; exposed here for on-demand recalculation
     * from the admin Leaderboard component.
     */
    @AuraEnabled
    public static void calculateRankings() {
        List<sObject> players = Database.query(
            'SELECT Id, Total_Score__c, Rank__c FROM Player__c ORDER BY Total_Score__c DESC NULLS LAST'
        );

        List<sObject> toUpdate = new List<sObject>();
        Decimal rank = 1;
        for (sObject p : players) {
            Decimal currentRank = (Decimal)p.get('Rank__c');
            if (currentRank != rank) {
                p.put('Rank__c', rank);
                toUpdate.add(p);
            }
            rank++;
        }

        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
            } catch (DmlException e) {
                throw new AuraHandledException('Unable to recalculate rankings: ' + e.getMessage());
            }
        }
    }
}
