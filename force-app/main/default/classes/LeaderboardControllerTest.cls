@isTest
private class LeaderboardControllerTest {

    @TestSetup
    static void setup() {
        List<Player__c> players = new List<Player__c>();
        players.add(new Player__c(Name = 'High Scorer', Email__c = 'high@example.com', Username__c = 'high', Total_Score__c = 100));
        players.add(new Player__c(Name = 'Mid Scorer', Email__c = 'mid@example.com', Username__c = 'mid', Total_Score__c = 50));
        players.add(new Player__c(Name = 'Low Scorer', Email__c = 'low@example.com', Username__c = 'low', Total_Score__c = 10));
        insert players;

        Game__c game = new Game__c(Name = 'Chess Masters', Game_Category__c = 'Strategy', Status__c = 'Active');
        insert game;

        Tournament__c tournament = new Tournament__c(Name = 'Grand Prix', Game__c = game.Id, Start_Date__c = Date.today());
        insert tournament;

        insert new Tournament_Registration__c(Player__c = players[0].Id, Tournament__c = tournament.Id, Score__c = 30);
        insert new Tournament_Registration__c(Player__c = players[1].Id, Tournament__c = tournament.Id, Score__c = 20);
    }

    @isTest
    static void testGetTopPlayers() {
        Test.startTest();
        List<Player__c> top = LeaderboardController.getTopPlayers(2);
        Test.stopTest();
        System.assertEquals(2, top.size());
        System.assertEquals('High Scorer', top[0].Name);
    }

    @isTest
    static void testGetTournamentRanking() {
        Tournament__c tournament = [SELECT Id FROM Tournament__c LIMIT 1];
        Test.startTest();
        List<Tournament_Registration__c> ranking = LeaderboardController.getTournamentRanking(tournament.Id);
        Test.stopTest();
        System.assertEquals(2, ranking.size());
        System.assertEquals(30, ranking[0].Score__c);
    }

    @isTest
    static void testCalculateRankings() {
        Test.startTest();
        LeaderboardController.calculateRankings();
        Test.stopTest();

        List<Player__c> ranked = [SELECT Name, Rank__c FROM Player__c ORDER BY Rank__c ASC];
        System.assertEquals('High Scorer', ranked[0].Name);
        System.assertEquals(1, ranked[0].Rank__c);
        System.assertEquals(3, ranked[2].Rank__c);
    }
}
