/**
 * GameController
 * Backs the gameCatalog LWC's @wire(getGames) call, with an optional category filter.
 */
public with sharing class GameController {

    @AuraEnabled(cacheable=true)
    public static List<Game__c> getGames(String category) {
        String query =
            'SELECT Id, Name, Game_Category__c, Max_Players__c, Game_Mode__c, ' +
            'Release_Date__c, Status__c FROM Game__c WHERE Status__c = \'Active\' ';
        if (String.isNotBlank(category)) {
            query += 'AND Game_Category__c = :category ';
        }
        query += 'WITH SECURITY_ENFORCED ORDER BY Name ASC';
        return Database.query(query);
    }
}
