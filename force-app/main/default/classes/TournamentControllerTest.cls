@isTest
private class TournamentControllerTest {

    @TestSetup
    static void setup() {
        sObject player = Schema.getGlobalDescribe().get('Player__c').newSObject();
        player.put('Name', 'Reg Player');
        player.put('Email__c', 'reg@example.com');
        player.put('Username__c', 'reguser');
        insert player;

        sObject game = Schema.getGlobalDescribe().get('Game__c').newSObject();
        game.put('Name', 'Star Strategy');
        game.put('Game_Category__c', 'Strategy');
        game.put('Status__c', 'Active');
        insert game;

        sObject tournament = Schema.getGlobalDescribe().get('Tournament__c').newSObject();
        tournament.put('Name', 'Winter Open');
        tournament.put('Game__c', game.Id);
        tournament.put('Start_Date__c', Date.today());
        tournament.put('Max_Players__c', 1);
        tournament.put('Tournament_Status__c', 'Upcoming');
        insert tournament;
    }

    @isTest
    static void testGetTournaments() {
        sObject game = Database.query('SELECT Id FROM Game__c LIMIT 1');
        Test.startTest();
        List<sObject> results = TournamentController.getTournaments(game.Id);
        Test.stopTest();
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testGetActiveTournaments() {
        Test.startTest();
        List<sObject> results = TournamentController.getActiveTournaments();
        Test.stopTest();
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testJoinTournamentSuccess() {
        sObject player = Database.query('SELECT Id FROM Player__c LIMIT 1');
        sObject tournament = Database.query('SELECT Id FROM Tournament__c LIMIT 1');

        Test.startTest();
        Id regId = TournamentController.joinTournament(player.Id, tournament.Id);
        Test.stopTest();

        System.assertNotEquals(null, regId);
        List<sObject> regs = TournamentController.getPlayerTournaments(player.Id);
        System.assertEquals(1, regs.size());
    }

    @isTest
    static void testJoinTournamentFullThrows() {
        sObject player = Database.query('SELECT Id FROM Player__c LIMIT 1');
        sObject tournament = Database.query('SELECT Id FROM Tournament__c LIMIT 1');

        sObject secondPlayer = Schema.getGlobalDescribe().get('Player__c').newSObject();
        secondPlayer.put('Name', 'Player 2');
        secondPlayer.put('Email__c', 'p2@example.com');
        secondPlayer.put('Username__c', 'p2user');
        insert secondPlayer;

        TournamentController.joinTournament(player.Id, tournament.Id); // fills max (1)

        Boolean threw = false;
        Test.startTest();
        try {
            TournamentController.joinTournament(secondPlayer.Id, tournament.Id);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw, 'Tournament at capacity should throw');
    }

    @isTest
    static void testJoinTournamentDuplicateThrows() {
        sObject player = Database.query('SELECT Id FROM Player__c LIMIT 1');
        sObject tournament = Database.query('SELECT Id FROM Tournament__c LIMIT 1');
        tournament.put('Max_Players__c', 5);
        update tournament;

        TournamentController.joinTournament(player.Id, tournament.Id);

        Boolean threw = false;
        Test.startTest();
        try {
            TournamentController.joinTournament(player.Id, tournament.Id);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw, 'Duplicate registration should throw');
    }
}
