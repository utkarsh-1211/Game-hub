@isTest
private class LeaderboardBatchTest {

    @TestSetup
    static void setup() {
        List<sObject> players = new List<sObject>();

        sObject p1 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p1.put('Name', 'Batch High');
        p1.put('Email__c', 'bh@example.com');
        p1.put('Username__c', 'bh');
        p1.put('Total_Score__c', 200);
        players.add(p1);

        sObject p2 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p2.put('Name', 'Batch Mid');
        p2.put('Email__c', 'bm@example.com');
        p2.put('Username__c', 'bm');
        p2.put('Total_Score__c', 100);
        players.add(p2);

        sObject p3 = Schema.getGlobalDescribe().get('Player__c').newSObject();
        p3.put('Name', 'Batch Low');
        p3.put('Email__c', 'bl@example.com');
        p3.put('Username__c', 'bl');
        p3.put('Total_Score__c', 5);
        players.add(p3);

        insert players;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        Database.executeBatch(new LeaderboardBatch(), 200);
        Test.stopTest();

        List<sObject> ranked = Database.query('SELECT Name, Rank__c FROM Player__c ORDER BY Rank__c ASC');
        System.assertEquals('Batch High', (String)ranked[0].get('Name'));
        System.assertEquals(1, (Decimal)ranked[0].get('Rank__c'));
        System.assertEquals(3, (Decimal)ranked[2].get('Rank__c'));
    }
}
