import { initializeApp } from 'firebase-admin/app';
initializeApp();

export { onReviewCreated } from './triggers/onReviewCreated';
export { onOrderStatusChanged } from './triggers/onOrderStatusChanged';
export { onUserWrite } from './triggers/onUserWrite';
export { autoCancelOrders } from './scheduled/autoCancelOrders';
export { placeOrder } from './callable/placeOrder'; // from Phase 3.2
