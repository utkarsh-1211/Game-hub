/**
 * TournamentController
 * Backs the tournamentList (Tournament Explorer) LWC and the gameCatalog LWC's
 * "view tournaments for game" action.
 */
public with sharing class TournamentController {

    @AuraEnabled(cacheable=true)
    public static List<sObject> getTournaments(Id gameId) {
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
    public static List<sObject> getActiveTournaments() {
        return Database.query(
            'SELECT Id, Name, Game__c, Game__r.Name, Start_Date__c, End_Date__c, ' +
            'Max_Players__c, Tournament_Status__c, Prize_Pool__c ' +
            'FROM Tournament__c WHERE Tournament_Status__c IN (\'Upcoming\', \'Active\') ' +
            'WITH SECURITY_ENFORCED ORDER BY Start_Date__c ASC'
        );
    }

    @AuraEnabled(cacheable=true)
    public static List<sObject> getPlayerTournaments(Id playerId) {
        if (playerId == null) {
            throw new AuraHandledException('A player Id is required.');
        }
        return Database.query(
            'SELECT Id, Tournament__c, Tournament__r.Name, Tournament__r.Tournament_Status__c, ' +
            'Tournament__r.Start_Date__c, Registration_Date__c, Status__c, Score__c ' +
            'FROM Tournament_Registration__c WHERE Player__c = :playerId ' +
            'WITH SECURITY_ENFORCED ORDER BY Registration_Date__c DESC'
        );
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

        List<sObject> tournaments = Database.query(
            'SELECT Id, Max_Players__c, Tournament_Status__c FROM Tournament__c WHERE Id = :tournamentId LIMIT 1'
        );
        if (tournaments.isEmpty()) {
            throw new AuraHandledException('Tournament not found.');
        }
        sObject tournament = tournaments[0];

        if ((String)tournament.get('Tournament_Status__c') == 'Completed') {
            throw new AuraHandledException('This tournament has already completed.');
        }

        List<sObject> existingRegs = Database.query(
            'SELECT Id FROM Tournament_Registration__c WHERE Tournament__c = :tournamentId'
        );
        Decimal maxPlayers = (Decimal)tournament.get('Max_Players__c');
        if (maxPlayers != null && existingRegs.size() >= maxPlayers) {
            throw new AuraHandledException('This tournament is full.');
        }

        List<sObject> duplicates = Database.query(
            'SELECT Id FROM Tournament_Registration__c WHERE Tournament__c = :tournamentId AND Player__c = :playerId'
        );
        if (!duplicates.isEmpty()) {
            throw new AuraHandledException('You are already registered for this tournament.');
        }

        sObject registration = Schema.getGlobalDescribe().get('Tournament_Registration__c').newSObject();
        registration.put('Player__c', playerId);
        registration.put('Tournament__c', tournamentId);
        registration.put('Registration_Date__c', Date.today());
        registration.put('Status__c', 'Registered');

        try {
            insert registration;
        } catch (DmlException e) {
            throw new AuraHandledException('Unable to join tournament: ' + e.getMessage());
        }
        return registration.Id;
    }
}
