@isTest
private class LeaderboardBatchTest {

    @TestSetup
    static void setup() {
        List<Player__c> players = new List<Player__c>();
        players.add(new Player__c(Name = 'Batch High', Email__c = 'bh@example.com', Username__c = 'bh', Total_Score__c = 200));
        players.add(new Player__c(Name = 'Batch Mid', Email__c = 'bm@example.com', Username__c = 'bm', Total_Score__c = 100));
        players.add(new Player__c(Name = 'Batch Low', Email__c = 'bl@example.com', Username__c = 'bl', Total_Score__c = 5));
        insert players;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new LeaderboardBatch(), 200);
        Test.stopTest();

        List<Player__c> ranked = [SELECT Name, Rank__c FROM Player__c ORDER BY Rank__c ASC];
        System.assertEquals('Batch High', ranked[0].Name);
        System.assertEquals(1, ranked[0].Rank__c);
        System.assertEquals(3, ranked[2].Rank__c);
    }
}
