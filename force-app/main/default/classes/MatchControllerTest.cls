@isTest
private class MatchControllerTest {

    @TestSetup
    static void setup() {
        Player__c p1 = new Player__c(Name = 'Alpha', Email__c = 'alpha@example.com', Username__c = 'alpha', Total_Score__c = 0);
        Player__c p2 = new Player__c(Name = 'Bravo', Email__c = 'bravo@example.com', Username__c = 'bravo', Total_Score__c = 0);
        insert new List<Player__c>{ p1, p2 };

        Game__c game = new Game__c(Name = 'Rocket League Clone', Game_Category__c = 'Sports', Status__c = 'Active');
        insert game;

        Tournament__c tournament = new Tournament__c(
            Name = 'Cup Series',
            Game__c = game.Id,
            Start_Date__c = Date.today(),
            Tournament_Status__c = 'Active'
        );
        insert tournament;
    }

    @isTest
    static void testCreateMatchAndAssignPlayers() {
        Tournament__c tournament = [SELECT Id FROM Tournament__c LIMIT 1];
        Game__c game = [SELECT Id FROM Game__c LIMIT 1];
        List<Id> playerIds = new List<Id>();
        for (Player__c p : [SELECT Id FROM Player__c]) {
            playerIds.add(p.Id);
        }

        Test.startTest();
        Id matchId = MatchController.createMatch('Semifinal', tournament.Id, game.Id, Datetime.now());
        MatchController.assignPlayers(matchId, playerIds);
        Test.stopTest();

        List<Match_Player__c> mps = [SELECT Id FROM Match_Player__c WHERE Match__c = :matchId];
        System.assertEquals(2, mps.size());
    }

    @isTest
    static void testUpdateScoreAndDeclareWinner() {
        Tournament__c tournament = [SELECT Id FROM Tournament__c LIMIT 1];
        Game__c game = [SELECT Id FROM Game__c LIMIT 1];
        List<Player__c> players = [SELECT Id FROM Player__c];

        Id matchId = MatchController.createMatch('Final', tournament.Id, game.Id, Datetime.now());
        MatchController.assignPlayers(matchId, new List<Id>{ players[0].Id, players[1].Id });

        Match_Player__c mp = [SELECT Id FROM Match_Player__c WHERE Match__c = :matchId AND Player__c = :players[0].Id LIMIT 1];

        Test.startTest();
        MatchController.updateScore(mp.Id, 21, 'Win');
        MatchController.updateMatchResult(matchId, players[0].Id);
        Test.stopTest();

        Match__c updatedMatch = [SELECT Status__c, Winner__c FROM Match__c WHERE Id = :matchId];
        System.assertEquals('Completed', updatedMatch.Status__c);
        System.assertEquals(players[0].Id, updatedMatch.Winner__c);

        Player__c winner = [SELECT Total_Score__c FROM Player__c WHERE Id = :players[0].Id];
        System.assertEquals(21, winner.Total_Score__c, 'MatchTrigger should roll the score up to the player');
    }

    @isTest
    static void testCreateMatchMissingFieldsThrows() {
        Boolean threw = false;
        Test.startTest();
        try {
            MatchController.createMatch(null, null, null, null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();
        System.assertEquals(true, threw);
    }
}
