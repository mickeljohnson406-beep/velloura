# Velloura Store v0.2

A mobile-first React/Vite boutique storefront.

## Implemented
- Responsive premium storefront and category filtering
- Search
- Six placeholder products
- Product detail view
- Size and colour selection
- Persistent local cart (localStorage)
- Quantity controls and cart drawer
- Checkout/delivery form
- Local development order capture + reference number
- Explicitly no live payment yet

## Run
```bash
npm install
npm run dev
```

## Production blockers
1. Merchant payment provider/account
2. Firebase/backend project configuration
3. Real product catalogue, prices, stock and imagery
4. Shipping/returns rules
5. velloura.co.zw DNS access

## Next engineering milestone
Replace local product/order storage with Firebase/Firestore, add authentication/admin inventory, server-side orders, payment callbacks and production deployment.
