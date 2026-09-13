@isTest
private class GameControllerTest {

    @TestSetup
    static void setup() {
        insert new List<Game__c>{
            new Game__c(Name = 'Battle Royale X', Game_Category__c = 'FPS', Status__c = 'Active'),
            new Game__c(Name = 'Kingdom Quest', Game_Category__c = 'RPG', Status__c = 'Active'),
            new Game__c(Name = 'Retired Racer', Game_Category__c = 'Sports', Status__c = 'Retired')
        };
    }

    @isTest
    static void testGetGamesNoFilter() {
        Test.startTest();
        List<Game__c> results = GameController.getGames(null);
        Test.stopTest();
        System.assertEquals(2, results.size(), 'Only Active games should be returned');
    }

    @isTest
    static void testGetGamesWithCategoryFilter() {
        Test.startTest();
        List<Game__c> results = GameController.getGames('RPG');
        Test.stopTest();
        System.assertEquals(1, results.size());
        System.assertEquals('Kingdom Quest', results[0].Name);
    }
}
