import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getPlayerDetails from '@salesforce/apex/PlayerController.getPlayerDetails';
import getRecentMatches from '@salesforce/apex/PlayerController.getRecentMatches';
import getPlayerRewards from '@salesforce/apex/PlayerController.getPlayerRewards';

const MATCH_COLUMNS = [
    { label: 'Match', fieldName: 'matchName' },
    { label: 'Game', fieldName: 'gameName' },
    { label: 'Date', fieldName: 'matchDate', type: 'date' },
    { label: 'Score', fieldName: 'score', type: 'number' },
    { label: 'Result', fieldName: 'result' }
];

const REWARD_COLUMNS = [
    { label: 'Reward', fieldName: 'Name' },
    { label: 'Type', fieldName: 'Reward_Type__c' },
    { label: 'Points', fieldName: 'Points_Awarded__c', type: 'number' },
    { label: 'Date', fieldName: 'Reward_Date__c', type: 'date' }
];

export default class PlayerDashboard extends LightningElement {
    @api playerId;

    matchColumns = MATCH_COLUMNS;
    rewardColumns = REWARD_COLUMNS;

    player;
    error;
    wiredMatchesResult;
    wiredRewardsResult;

    @wire(getPlayerDetails, { playerId: '$playerId' })
    wiredPlayer({ data, error }) {
        if (data) {
            this.player = data;
            this.error = undefined;
        } else if (error) {
            this.error = this.reduceError(error);
        }
    }

    @wire(getRecentMatches, { playerId: '$playerId', maxResults: 10 })
    wiredMatches(result) {
        this.wiredMatchesResult = result;
    }

    @wire(getPlayerRewards, { playerId: '$playerId' })
    wiredRewards(result) {
        this.wiredRewardsResult = result;
    }

    get recentMatches() {
        const data = this.wiredMatchesResult && this.wiredMatchesResult.data;
        if (!data) return [];
        return data.map((mp) => ({
            id: mp.Id,
            matchName: mp.Match__r ? mp.Match__r.Name : '',
            gameName: mp.Match__r && mp.Match__r.Game__r ? mp.Match__r.Game__r.Name : '',
            matchDate: mp.Match__r ? mp.Match__r.Match_Date__c : null,
            score: mp.Score__c,
            result: mp.Result__c
        }));
    }

    get rewards() {
        return (this.wiredRewardsResult && this.wiredRewardsResult.data) || [];
    }

    get hasError() {
        return !!this.error;
    }

    get isLoaded() {
        return !!this.player;
    }

    async handleRefresh() {
        await Promise.all([
            refreshApex(this.wiredMatchesResult),
            refreshApex(this.wiredRewardsResult)
        ]);
    }

    reduceError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Unknown error loading player dashboard.';
    }
}
