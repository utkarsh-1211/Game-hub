import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getActiveTournaments from '@salesforce/apex/TournamentController.getActiveTournaments';
import joinTournament from '@salesforce/apex/TournamentController.joinTournament';

export default class TournamentList extends LightningElement {
    @api playerId;

    wiredTournamentsResult;
    joiningId;

    @wire(getActiveTournaments)
    wiredTournaments(result) {
        this.wiredTournamentsResult = result;
    }

    get tournaments() {
        return (this.wiredTournamentsResult && this.wiredTournamentsResult.data) || [];
    }

    get hasTournaments() {
        return this.tournaments.length > 0;
    }

    async handleJoin(event) {
        const tournamentId = event.currentTarget.dataset.id;
        if (!this.playerId) {
            this.showToast('Error', 'No player Id is set on this page.', 'error');
            return;
        }
        this.joiningId = tournamentId;
        try {
            await joinTournament({ playerId: this.playerId, tournamentId });
            this.showToast('Success', 'You have joined the tournament!', 'success');
            await refreshApex(this.wiredTournamentsResult);
        } catch (e) {
            const message = (e && e.body && e.body.message) || 'Unable to join tournament.';
            this.showToast('Error', message, 'error');
        } finally {
            this.joiningId = undefined;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
