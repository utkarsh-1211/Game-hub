@isTest
private class LeaderboardControllerTest {

    @TestSetup
    static void setup() {
        List<sObject> players = new List<sObject>();

        sObject p1 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p1.put('Name', 'High Scorer');
        p1.put('Email__c', 'high@example.com');
        p1.put('Username__c', 'high');
        p1.put('Total_Score__c', 100);
        players.add(p1);

        sObject p2 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p2.put('Name', 'Mid Scorer');
        p2.put('Email__c', 'mid@example.com');
        p2.put('Username__c', 'mid');
        p2.put('Total_Score__c', 50);
        players.add(p2);

        sObject p3 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p3.put('Name', 'Low Scorer');
        p3.put('Email__c', 'low@example.com');
        p3.put('Username__c', 'low');
        p3.put('Total_Score__c', 10);
        players.add(p3);

        insert players;

        sObject game = Schema.getGlobalDescribe().get('Game__c').newSObject();
        game.put('Name', 'Chess Masters');
        game.put('Game_Category__c', 'Strategy');
        game.put('Status__c', 'Active');
        insert game;

        sObject tournament = Schema.getGlobalDescribe().get('Tournament__c').newSObject();
        tournament.put('Name', 'Grand Prix');
        tournament.put('Game__c', game.Id);
        tournament.put('Start_Date__c', Date.today());
        insert tournament;

        sObject tr1 = Schema.getGlobalDescribe().get('Tournament_Registration__c').newSObject();
        tr1.put('Player__c', players[0].Id);
        tr1.put('Tournament__c', tournament.Id);
        tr1.put('Score__c', 30);
        insert tr1;

        sObject tr2 = Schema.getGlobalDescribe().get('Tournament_Registration__c').newSObject();
        tr2.put('Player__c', players[1].Id);
        tr2.put('Tournament__c', tournament.Id);
        tr2.put('Score__c', 20);
        insert tr2;
    }

    @isTest
    static void testGetTopPlayers() {
        Test.startTest();
        List<sObject> top = LeaderboardController.getTopPlayers(2);
        Test.stopTest();
        System.assertEquals(2, top.size());
        System.assertEquals('High Scorer', (String)top[0].get('Name'));
    }

    @isTest
    static void testGetTournamentRanking() {
        sObject tournament = Database.query('SELECT Id FROM Tournament__c LIMIT 1');
        Test.startTest();
        List<sObject> ranking = LeaderboardController.getTournamentRanking(tournament.Id);
        Test.stopTest();
        System.assertEquals(2, ranking.size());
        System.assertEquals(30, (Decimal)ranking[0].get('Score__c'));
    }

    @isTest
    static void testCalculateRankings() {
        Test.startTest();
        LeaderboardController.calculateRankings();
        Test.stopTest();

        List<sObject> ranked = Database.query('SELECT Name, Rank__c FROM Player__c ORDER BY Rank__c ASC');
        System.assertEquals('High Scorer', (String)ranked[0].get('Name'));
        System.assertEquals(1, (Decimal)ranked[0].get('Rank__c'));
        System.assertEquals(3, (Decimal)ranked[2].get('Rank__c'));
    }
}
