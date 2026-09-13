/**
 * TournamentController
 * Backs the tournamentList (Tournament Explorer) LWC and the gameCatalog LWC's
 * "view tournaments for game" action.
 */
public with sharing class TournamentController {

    @AuraEnabled(cacheable=true)
    public static List<Tournament__c> getTournaments(Id gameId) {
        String query =
            'SELECT Id, Name, Game__c, Game__r.Name, Start_Date__c, End_Date__c, ' +
            'Max_Players__c, Tournament_Status__c, Prize_Pool__c ' +
            'FROM Tournament__c ';
        if (gameId != null) {
            query += 'WHERE Game__c = :gameId ';
        }
        query += 'WITH SECURITY_ENFORCED ORDER BY Start_Date__c ASC';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static List<Tournament__c> getActiveTournaments() {
        return [
            SELECT Id, Name, Game__c, Game__r.Name, Start_Date__c, End_Date__c,
                   Max_Players__c, Tournament_Status__c, Prize_Pool__c
            FROM Tournament__c
            WHERE Tournament_Status__c IN ('Upcoming', 'Active')
            WITH SECURITY_ENFORCED
            ORDER BY Start_Date__c ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Tournament_Registration__c> getPlayerTournaments(Id playerId) {
        if (playerId == null) {
            throw new AuraHandledException('A player Id is required.');
        }
        return [
            SELECT Id, Tournament__c, Tournament__r.Name, Tournament__r.Tournament_Status__c,
                   Tournament__r.Start_Date__c, Registration_Date__c, Status__c, Score__c
            FROM Tournament_Registration__c
            WHERE Player__c = :playerId
            WITH SECURITY_ENFORCED
            ORDER BY Registration_Date__c DESC
        ];
    }

    /**
     * Registers a player into a tournament. Enforces the tournament's Max_Players__c cap
     * and prevents duplicate registrations.
     */
    @AuraEnabled
    public static Id joinTournament(Id playerId, Id tournamentId) {
        if (playerId == null || tournamentId == null) {
            throw new AuraHandledException('Both playerId and tournamentId are required.');
        }

        Tournament__c tournament = [
            SELECT Id, Max_Players__c, Tournament_Status__c
            FROM Tournament__c
            WHERE Id = :tournamentId
            LIMIT 1
        ];

        if (tournament.Tournament_Status__c == 'Completed') {
            throw new AuraHandledException('This tournament has already completed.');
        }

        Integer existingCount = [
            SELECT COUNT()
            FROM Tournament_Registration__c
            WHERE Tournament__c = :tournamentId
        ];
        if (tournament.Max_Players__c != null && existingCount >= tournament.Max_Players__c) {
            throw new AuraHandledException('This tournament is full.');
        }

        Integer duplicate = [
            SELECT COUNT()
            FROM Tournament_Registration__c
            WHERE Tournament__c = :tournamentId AND Player__c = :playerId
        ];
        if (duplicate > 0) {
            throw new AuraHandledException('You are already registered for this tournament.');
        }

        Tournament_Registration__c registration = new Tournament_Registration__c(
            Player__c = playerId,
            Tournament__c = tournamentId,
            Registration_Date__c = Date.today(),
            Status__c = 'Registered'
        );

        try {
            insert registration;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to join tournament: ' + e.getMessage());
        }
        return registration.Id;
    }
}
