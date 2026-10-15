# Velloura Payments — EcoCash and InnBucks

Velloura accepts online payments through EcoCash and InnBucks only.

## Security architecture

Payment credentials must never be stored in the React/Vite frontend or committed to GitHub.

The intended production flow is:

1. Customer creates a Velloura order.
2. Velloura backend initiates a payment with the selected provider.
3. The provider confirms the payment through its approved server-side mechanism/callback.
4. Velloura verifies the provider response server-side.
5. Only after verification is the order `payment_status` changed to `paid`.

The browser must never be trusted to mark an order as paid.

## EcoCash

EcoCash publicly documents merchant accounts and merchant payments. Its channel-partner terms also describe Push Transactions, where an integrated merchant initiates a transaction to an EcoCash customer for confirmation.

Production API credentials/endpoints must come from EcoCash merchant onboarding. Do not invent or hard-code undocumented endpoints.

Merchant onboarding: https://ecocash.co.zw/merchants/
Partner portal: https://partnerapplications.ecocash.co.zw/

## InnBucks

InnBucks publicly offers merchant/business solutions and documents API integration for some business/agent services, but Velloura must use only payment API documentation and credentials officially issued for the merchant account.

Production API credentials/endpoints must come from InnBucks merchant onboarding. Do not invent or hard-code undocumented endpoints.

Business site: https://innbucks.co.zw/
Contact/support: https://innbucks.co.zw/index.php/home/contact

## Activation dependency

Live payment processing cannot be safely activated until Velloura has approved merchant/API credentials from each provider. Once supplied, store secrets in the backend/Supabase secrets environment, implement provider-specific server-side functions, callback verification, transaction logging and idempotency, then enable the payment controls in checkout.
