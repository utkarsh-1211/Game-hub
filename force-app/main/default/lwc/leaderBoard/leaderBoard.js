import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getTopPlayers from '@salesforce/apex/LeaderboardController.getTopPlayers';
import getTournamentRanking from '@salesforce/apex/LeaderboardController.getTournamentRanking';
import calculateRankings from '@salesforce/apex/LeaderboardController.calculateRankings';

const GLOBAL_COLUMNS = [
    { label: 'Rank', fieldName: 'Rank__c', type: 'number' },
    { label: 'Player', fieldName: 'Name' },
    { label: 'Username', fieldName: 'Username__c' },
    { label: 'Country', fieldName: 'Country__c' },
    { label: 'Total Score', fieldName: 'Total_Score__c', type: 'number' }
];

const TOURNAMENT_COLUMNS = [
    { label: 'Player', fieldName: 'playerName' },
    { label: 'Score', fieldName: 'Score__c', type: 'number' },
    { label: 'Status', fieldName: 'Status__c' }
];

export default class LeaderBoard extends LightningElement {
    globalColumns = GLOBAL_COLUMNS;
    tournamentColumns = TOURNAMENT_COLUMNS;

    tournamentIdFilter = '';
    tournamentRanking = [];

    wiredTopPlayersResult;

    @wire(getTopPlayers, { maxResults: 100 })
    wiredTopPlayers(result) {
        this.wiredTopPlayersResult = result;
    }

    get topPlayers() {
        return (this.wiredTopPlayersResult && this.wiredTopPlayersResult.data) || [];
    }

    get showTournamentRanking() {
        return this.tournamentRanking.length > 0;
    }

    handleTournamentIdChange(event) {
        this.tournamentIdFilter = event.target.value;
    }

    async handleLoadTournamentRanking() {
        if (!this.tournamentIdFilter) return;
        const data = await getTournamentRanking({ tournamentId: this.tournamentIdFilter });
        this.tournamentRanking = data.map((r) => ({
            ...r,
            playerName: r.Player__r ? r.Player__r.Name : ''
        }));
    }

    async handleRecalculate() {
        await calculateRankings();
        await refreshApex(this.wiredTopPlayersResult);
    }
}
