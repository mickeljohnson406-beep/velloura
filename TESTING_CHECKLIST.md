# Velloura User Acceptance Testing Checklist

Do not use real payment details. Online payments are not part of this test build.

Tester: ____________________
Date: ____________________
Device / browser: ____________________

Mark each test PASS or FAIL. For every FAIL, record what happened, what you expected, and attach a screenshot if possible.

## Customer account
- Create a new customer account — account is created without an unexplained error.
- Log in with the new account — customer is signed in.
- Log out — session ends.
- Wrong password — login is rejected with a useful error.
- Request forgotten-password reset — request is accepted.
- Open newest reset link and set a new password — password changes successfully.
- Log in with the new password — customer is signed in.
- Refresh while signed in — session remains valid.

## Storefront and catalogue
- Open storefront — products and images load.
- Browse Women, Men, Shoes and Accessories — correct category products appear.
- Search for a product — matching products appear.
- Open product — name, image, price and description are correct.
- Select available size and colour — selection works.
- Out-of-stock option — cannot be purchased.

## Cart
- Add product — correct variant appears.
- Increase/decrease quantity — subtotal updates.
- Exceed available stock — prevented.
- Reduce quantity to zero — item disappears.
- Refresh with items in cart — cart remains available.

## Checkout and orders
- Checkout as guest — order is created and reference displayed.
- Checkout while signed in — order is linked to customer.
- Required delivery field empty — submission is blocked.
- Attempt more than available stock — order is rejected.
- Successful order — purchased stock decreases.
- Customer account after order — customer sees their own order.
- Customer A must never see Customer B's orders.

## Admin access and security
- Normal customer — ADMIN control is unavailable.
- Normal customer cannot access admin data/actions.
- Designated admin — ADMIN control appears.
- Admin dashboard — metrics, orders and inventory load.

## Product administration
- Add product with price, description and category.
- Upload product image.
- Add size/colour/stock variant.
- New active product appears automatically on storefront.
- Change price and confirm storefront updates.
- Change stock and confirm availability updates.
- Replace product image.
- Delete product image without crashing.
- Hide/deactivate product and confirm it disappears from storefront.

## Order administration
- Order manager loads.
- Order details show correct customer, delivery and items.
- Change order status and refresh — saved status remains.
- Customer sees the appropriate status for their order.

## Responsive testing
Test at minimum on one phone and one desktop browser.
- No horizontal overflow or broken mobile layout.
- Mobile navigation works.
- Mobile product/cart/checkout controls are usable.
- Desktop storefront layout is correct.
- Refresh major screens and confirm application recovers correctly.

## Bug report format
For every failure send: test name, PASS/FAIL, device/browser, exact steps, expected result, actual result, exact error message, and screenshot if available.

## Release rule
Velloura is not production-ready while any critical authentication, authorization, checkout, stock, order, or admin test is failing.
