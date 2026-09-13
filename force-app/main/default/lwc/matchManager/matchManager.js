import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMatches from '@salesforce/apex/MatchController.getMatches';
import createMatch from '@salesforce/apex/MatchController.createMatch';
import assignPlayers from '@salesforce/apex/MatchController.assignPlayers';
import updateScore from '@salesforce/apex/MatchController.updateScore';
import updateMatchResult from '@salesforce/apex/MatchController.updateMatchResult';

const COLUMNS = [
    { label: 'Match', fieldName: 'Name' },
    { label: 'Tournament', fieldName: 'tournamentName' },
    { label: 'Game', fieldName: 'gameName' },
    { label: 'Date', fieldName: 'Match_Date__c', type: 'date' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Winner', fieldName: 'winnerName' }
];

export default class MatchManager extends LightningElement {
    columns = COLUMNS;
    wiredMatchesResult;

    resultOptions = [
        { label: 'Win', value: 'Win' },
        { label: 'Lose', value: 'Lose' },
        { label: 'Draw', value: 'Draw' }
    ];

    newMatchName = '';
    newTournamentId = '';
    newGameId = '';

    selectedMatchId = '';
    playerIdsToAssign = '';

    scoreMatchPlayerId = '';
    scoreValue = 0;
    scoreResult = 'Win';

    winnerMatchId = '';
    winnerPlayerId = '';

    @wire(getMatches, { tournamentId: null })
    wiredMatches(result) {
        this.wiredMatchesResult = result;
    }

    get matches() {
        const data = (this.wiredMatchesResult && this.wiredMatchesResult.data) || [];
        return data.map((m) => ({
            ...m,
            tournamentName: m.Tournament__r ? m.Tournament__r.Name : '',
            gameName: m.Game__r ? m.Game__r.Name : '',
            winnerName: m.Winner__r ? m.Winner__r.Name : ''
        }));
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    async handleCreateMatch() {
        try {
            await createMatch({
                matchName: this.newMatchName,
                tournamentId: this.newTournamentId,
                gameId: this.newGameId,
                matchDate: new Date().toISOString()
            });
            this.showToast('Success', 'Match created.', 'success');
            await refreshApex(this.wiredMatchesResult);
        } catch (e) {
            this.handleError(e, 'Unable to create match.');
        }
    }

    async handleAssignPlayers() {
        const playerIds = this.playerIdsToAssign
            .split(',')
            .map((id) => id.trim())
            .filter((id) => id);
        try {
            await assignPlayers({ matchId: this.selectedMatchId, playerIds });
            this.showToast('Success', 'Players assigned.', 'success');
            await refreshApex(this.wiredMatchesResult);
        } catch (e) {
            this.handleError(e, 'Unable to assign players.');
        }
    }

    async handleUpdateScore() {
        try {
            await updateScore({
                matchPlayerId: this.scoreMatchPlayerId,
                score: this.scoreValue,
                result: this.scoreResult
            });
            this.showToast('Success', 'Score updated.', 'success');
        } catch (e) {
            this.handleError(e, 'Unable to update score.');
        }
    }

    async handleDeclareWinner() {
        try {
            await updateMatchResult({ matchId: this.winnerMatchId, winnerId: this.winnerPlayerId });
            this.showToast('Success', 'Winner declared and match completed.', 'success');
            await refreshApex(this.wiredMatchesResult);
        } catch (e) {
            this.handleError(e, 'Unable to declare winner.');
        }
    }

    handleError(e, fallback) {
        const message = (e && e.body && e.body.message) || fallback;
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
