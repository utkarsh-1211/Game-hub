import { LightningElement, api, wire } from 'lwc';
import getPlayerRewards from '@salesforce/apex/PlayerController.getPlayerRewards';

export default class RewardPanel extends LightningElement {
    @api playerId;

    @wire(getPlayerRewards, { playerId: '$playerId' })
    rewards;

    get rewardList() {
        return (this.rewards && this.rewards.data) || [];
    }

    get hasRewards() {
        return this.rewardList.length > 0;
    }

    get badgeVariant() {
        return 'success';
    }
}
