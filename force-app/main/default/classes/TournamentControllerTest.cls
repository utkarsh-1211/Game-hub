@isTest
private class TournamentControllerTest {

    @TestSetup
    static void setup() {
        Player__c player = new Player__c(Name = 'Reg Player', Email__c = 'reg@example.com', Username__c = 'reguser');
        insert player;

        Game__c game = new Game__c(Name = 'Star Strategy', Game_Category__c = 'Strategy', Status__c = 'Active');
        insert game;

        Tournament__c tournament = new Tournament__c(
            Name = 'Winter Open',
            Game__c = game.Id,
            Start_Date__c = Date.today(),
            Max_Players__c = 1,
            Tournament_Status__c = 'Upcoming'
        );
        insert tournament;
    }

    @isTest
    static void testGetTournaments() {
        Game__c game = [SELECT Id FROM Game__c LIMIT 1];
        Test.startTest();
        List<Tournament__c> results = TournamentController.getTournaments(game.Id);
        Test.stopTest();
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testGetActiveTournaments() {
        Test.startTest();
        List<Tournament__c> results = TournamentController.getActiveTournaments();
        Test.stopTest();
        System.assertEquals(1, results.size());
    }

    @isTest
    static void testJoinTournamentSuccess() {
        Player__c player = [SELECT Id FROM Player__c LIMIT 1];
        Tournament__c tournament = [SELECT Id FROM Tournament__c LIMIT 1];

        Test.startTest();
        Id regId = TournamentController.joinTournament(player.Id, tournament.Id);
        Test.stopTest();

        System.assertNotEquals(null, regId);
        List<Tournament_Registration__c> regs = TournamentController.getPlayerTournaments(player.Id);
        System.assertEquals(1, regs.size());
    }

    @isTest
    static void testJoinTournamentFullThrows() {
        Player__c player = [SELECT Id FROM Player__c LIMIT 1];
        Tournament__c tournament = [SELECT Id FROM Tournament__c LIMIT 1];

        Player__c secondPlayer = new Player__c(Name = 'Player 2', Email__c = 'p2@example.com', Username__c = 'p2user');
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
        Player__c player = [SELECT Id FROM Player__c LIMIT 1];
        Tournament__c tournament = [SELECT Id FROM Tournament__c LIMIT 1];
        tournament.Max_Players__c = 5;
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
