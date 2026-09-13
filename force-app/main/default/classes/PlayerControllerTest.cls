@isTest
private class PlayerControllerTest {

    @TestSetup
    static void setup() {
        Player__c player = new Player__c(
            Name = 'Test Player',
            Email__c = 'test.player@example.com',
            Username__c = 'testplayer1',
            Skill_Level__c = 'Beginner',
            Total_Score__c = 10,
            Country__c = 'USA',
            Join_Date__c = Date.today()
        );
        insert player;

        Game__c game = new Game__c(Name = 'Arena Clash', Game_Category__c = 'FPS', Status__c = 'Active');
        insert game;

        Tournament__c tournament = new Tournament__c(
            Name = 'Spring Cup',
            Game__c = game.Id,
            Start_Date__c = Date.today(),
            Tournament_Status__c = 'Upcoming'
        );
        insert tournament;

        Match__c match = new Match__c(
            Name = 'Round 1',
            Tournament__c = tournament.Id,
            Game__c = game.Id,
            Match_Date__c = Datetime.now(),
            Status__c = 'Scheduled'
        );
        insert match;

        insert new Match_Player__c(Match__c = match.Id, Player__c = player.Id, Score__c = 5);
        insert new Reward__c(Name = 'First Blood', Player__c = player.Id, Reward_Type__c = 'Badge', Points_Awarded__c = 10, Reward_Date__c = Date.today());
    }

    @isTest
    static void testGetPlayerDetails() {
        Player__c player = [SELECT Id FROM Player__c LIMIT 1];
        Test.startTest();
        Player__c result = PlayerController.getPlayerDetails(player.Id);
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
        Player__c player = [SELECT Id FROM Player__c LIMIT 1];
        Test.startTest();
        List<Match_Player__c> results = PlayerController.getRecentMatches(player.Id, 5);
        Test.stopTest();
        System.assertEquals(1, results.size(), 'Should return the one recorded match');
    }

    @isTest
    static void testGetPlayerRewards() {
        Player__c player = [SELECT Id FROM Player__c LIMIT 1];
        Test.startTest();
        List<Reward__c> rewards = PlayerController.getPlayerRewards(player.Id);
        Test.stopTest();
        System.assertEquals(1, rewards.size(), 'Should return the one recorded reward');
    }

    @isTest
    static void testUpdatePlayerScore() {
        Player__c player = [SELECT Id, Total_Score__c FROM Player__c LIMIT 1];
        Test.startTest();
        PlayerController.updatePlayerScore(player.Id, 15);
        Test.stopTest();
        Player__c updated = [SELECT Total_Score__c FROM Player__c WHERE Id = :player.Id];
        System.assertEquals(25, updated.Total_Score__c, 'Score should increase by delta');
    }
}
