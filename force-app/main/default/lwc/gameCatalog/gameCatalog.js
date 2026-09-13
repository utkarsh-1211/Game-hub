import { LightningElement, wire } from 'lwc';
import getGames from '@salesforce/apex/GameController.getGames';
import getTournaments from '@salesforce/apex/TournamentController.getTournaments';

const CATEGORIES = [
    { label: 'All Categories', value: '' },
    { label: 'FPS', value: 'FPS' },
    { label: 'RPG', value: 'RPG' },
    { label: 'Strategy', value: 'Strategy' },
    { label: 'Sports', value: 'Sports' }
];

export default class GameCatalog extends LightningElement {
    categoryOptions = CATEGORIES;
    selectedCategory = '';
    selectedGameId;
    tournaments = [];
    error;

    @wire(getGames, { category: '$selectedCategory' })
    games;

    get gameList() {
        return (this.games && this.games.data) || [];
    }

    get hasGames() {
        return this.gameList.length > 0;
    }

    get showTournaments() {
        return !!this.selectedGameId;
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
    }

    async handleViewTournaments(event) {
        const gameId = event.currentTarget.dataset.id;
        this.selectedGameId = gameId;
        try {
            this.tournaments = await getTournaments({ gameId });
            this.error = undefined;
        } catch (e) {
            this.error = (e && e.body && e.body.message) || 'Unable to load tournaments.';
            this.tournaments = [];
        }
    }
}
