@isTest
private class MatchControllerTest {

    @TestSetup
    static void setup() {
        sObject p1 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p1.put('Name', 'Alpha');
        p1.put('Email__c', 'alpha@example.com');
        p1.put('Username__c', 'alpha');
        p1.put('Total_Score__c', 0);

        sObject p2 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p2.put('Name', 'Bravo');
        p2.put('Email__c', 'bravo@example.com');
        p2.put('Username__c', 'bravo');
        p2.put('Total_Score__c', 0);

        insert new List<sObject>{ p1, p2 };

        sObject game = Schema.getGlobalDescribe().get('Game__c').newSObject();
        game.put('Name', 'Rocket League Clone');
        game.put('Game_Category__c', 'Sports');
        game.put('Status__c', 'Active');
        insert game;

        sObject tournament = Schema.getGlobalDescribe().get('Tournament__c').newSObject();
        tournament.put('Name', 'Cup Series');
        tournament.put('Game__c', game.Id);
        tournament.put('Start_Date__c', Date.today());
        tournament.put('Tournament_Status__c', 'Active');
        insert tournament;
    }

    @isTest
    static void testCreateMatchAndAssignPlayers() {
        sObject tournament = Database.query('SELECT Id FROM Tournament__c LIMIT 1');
        sObject game = Database.query('SELECT Id FROM Game__c LIMIT 1');
        List<Id> playerIds = new List<Id>();
        for (sObject p : Database.query('SELECT Id FROM Player__c')) {
            playerIds.add(p.Id);
        }

        Test.startTest();
        Id matchId = MatchController.createMatch('Semifinal', tournament.Id, game.Id, Datetime.now());
        MatchController.assignPlayers(matchId, playerIds);
        Test.stopTest();

        List<sObject> mps = Database.query('SELECT Id FROM Match_Player__c WHERE Match__c = \'' + matchId + '\'');
        System.assertEquals(2, mps.size());
    }

    @isTest
    static void testUpdateScoreAndDeclareWinner() {
        sObject tournament = Database.query('SELECT Id FROM Tournament__c LIMIT 1');
        sObject game = Database.query('SELECT Id FROM Game__c LIMIT 1');
        List<sObject> players = Database.query('SELECT Id FROM Player__c');

        Id matchId = MatchController.createMatch('Final', tournament.Id, game.Id, Datetime.now());
        MatchController.assignPlayers(matchId, new List<Id>{ players[0].Id, players[1].Id });

        sObject mp = Database.query('SELECT Id FROM Match_Player__c WHERE Match__c = \'' + matchId + '\' AND Player__c = \'' + players[0].Id + '\' LIMIT 1');

        Test.startTest();
        MatchController.updateScore(mp.Id, 21, 'Win');
        MatchController.updateMatchResult(matchId, players[0].Id);
        Test.stopTest();

        sObject updatedMatch = Database.query('SELECT Status__c, Winner__c FROM Match__c WHERE Id = \'' + matchId + '\'');
        System.assertEquals('Completed', (String)updatedMatch.get('Status__c'));
        System.assertEquals(players[0].Id, (Id)updatedMatch.get('Winner__c'));

        sObject winner = Database.query('SELECT Total_Score__c FROM Player__c WHERE Id = \'' + players[0].Id + '\'');
        System.assertEquals(21, (Decimal)winner.get('Total_Score__c'), 'MatchTrigger should roll the score up to the player');
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
