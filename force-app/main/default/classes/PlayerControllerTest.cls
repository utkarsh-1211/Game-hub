@isTest
private class PlayerControllerTest {

    @TestSetup
    static void setup() {
        sObject player = Schema.getGlobalDescribe().get('Player__c').newSObject();
        player.put('Name', 'Test Player');
        player.put('Email__c', 'test.player@example.com');
        player.put('Username__c', 'testplayer1');
        player.put('Skill_Level__c', 'Beginner');
        player.put('Total_Score__c', 10);
        player.put('Country__c', 'USA');
        player.put('Join_Date__c', Date.today());
        insert player;

        sObject game = Schema.getGlobalDescribe().get('Game__c').newSObject();
        game.put('Name', 'Arena Clash');
        game.put('Game_Category__c', 'FPS');
        game.put('Status__c', 'Active');
        insert game;

        sObject tournament = Schema.getGlobalDescribe().get('Tournament__c').newSObject();
        tournament.put('Name', 'Spring Cup');
        tournament.put('Game__c', game.Id);
        tournament.put('Start_Date__c', Date.today());
        tournament.put('Tournament_Status__c', 'Upcoming');
        insert tournament;

        sObject match = Schema.getGlobalDescribe().get('Match__c').newSObject();
        match.put('Name', 'Round 1');
        match.put('Tournament__c', tournament.Id);
        match.put('Game__c', game.Id);
        match.put('Match_Date__c', Datetime.now());
        match.put('Status__c', 'Scheduled');
        insert match;

        sObject mp = Schema.getGlobalDescribe().get('Match_Player__c').newSObject();
        mp.put('Match__c', match.Id);
        mp.put('Player__c', player.Id);
        mp.put('Score__c', 5);
        insert mp;

        sObject r = Schema.getGlobalDescribe().get('Reward__c').newSObject();
        r.put('Name', 'First Blood');
        r.put('Player__c', player.Id);
        r.put('Reward_Type__c', 'Badge');
        r.put('Points_Awarded__c', 10);
        r.put('Reward_Date__c', Date.today());
        insert r;
    }

    @isTest
    static void testGetPlayerDetails() {
        sObject player = Database.query('SELECT Id FROM Player__c LIMIT 1');
        Test.startTest();
        sObject result = PlayerController.getPlayerDetails(player.Id);
        Test.stopTest();
        System.assertEquals(player.Id, result.Id, 'Should return the requested player');
    }

    @isTest
    static void testGetPlayerDetailsNullId() {
        Boolean threw = false;
        try {
            PlayerController.getPlayerDetails(null);
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assertEquals(true, threw, 'Null playerId should throw');
    }

    @isTest
    static void testGetRecentMatches() {
        sObject player = Database.query('SELECT Id FROM Player__c LIMIT 1');
        Test.startTest();
        List<sObject> results = PlayerController.getRecentMatches(player.Id, 5);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one recorded match');
    }

    @isTest
    static void testGetPlayerRewards() {
        sObject player = Database.query('SELECT Id FROM Player__c LIMIT 1');
        Test.startTest();
        List<sObject> rewards = PlayerController.getPlayerRewards(player.Id);
        Test.stopTest();
        System.assertEquals(1, rewards.size(), 'Should return the one recorded reward');
    }

    @isTest
    static void testUpdatePlayerScore() {
        sObject player = Database.query('SELECT Id, Total_Score__c FROM Player__c LIMIT 1');
        Test.startTest();
        PlayerController.updatePlayerScore(player.Id, 15);
        Test.stopTest();
        sObject updated = Database.query('SELECT Total_Score__c FROM Player__c WHERE Id = \'' + player.Id + '\'');
        System.assertEquals(25, (Decimal)updated.get('Total_Score__c'), 'Score should increase by delta');
    }
}
