# SRP Billing

SRP Billing is a FiveM billing resource for QBCore. It provides player and job invoices, company-to-company (B2B) invoices, configurable job templates, commission tracking, an ox_inventory receipt item, a shared receipt UI, and an in-game invoice archive.

## Contents

- [Requirements](#requirements)
- [Build the NUI](#build-the-nui)
- [Install on a FiveM server](#install-on-a-fivem-server)
- [Database](#database)
- [Configuration](#configuration)
- [Features and permissions](#features-and-permissions)
- [In-game usage](#in-game-usage)
- [Invoice and payment flow](#invoice-and-payment-flow)
- [Troubleshooting](#troubleshooting)

## Requirements

### Server resources

- FiveM server with **QBCore**
- `qb-core`
- `ox_lib`
- `oxmysql`
- `ox_target`
- `ox_inventory`
- `Renewed-Banking`
- MySQL/MariaDB database configured for oxmysql

Start these resources before `srp-billing`. Society accounts referenced in `Config.Societies` must already exist in Renewed-Banking.

### Build tools

- Node.js and npm, for building the React/Vite NUI
- Lua 5.4 support (enabled in the resource manifest)

## Build the NUI

From the resource's `web` directory:

```powershell
cd path\to\srp-billing\web
npm install
npm run build
```

Vite writes the production UI to `web/dist`. Deploy the complete resource including this generated directory; the manifest serves `web/dist/index.html`, its assets, and images. Rebuild after changing files under `web/src`.

## Install on a FiveM server

1. Copy the `srp-billing` folder into your server resources, for example `resources/[local]/srp-billing`.
2. Build the NUI as described above, or use the included `web/dist` if it is current.
3. Configure the `oxmysql` connection in the server configuration and import [`schema.sql`](./schema.sql) into that database.
4. Register the receipt item in ox_inventory's item definitions. Example:

   ```lua
   ['billing_receipt'] = {
       label = 'Billing Receipt',
       weight = 0,
       stack = false,
       close = true,
       description = 'A paid invoice receipt',
       client = {
           export = 'srp-billing.useReceipt'
       }
   }
   ```

   The item name must match `Config.ReceiptItem`. If you change that config value, use the same name in the inventory definition.
5. Edit `config.lua` for your society job names, banking accounts, grades, commission percentages, kiosk location, and limits.
6. Ensure resources start in dependency order in `server.cfg`:

   ```cfg
   ensure qb-core
   ensure ox_lib
   ensure oxmysql
   ensure ox_target
   ensure ox_inventory
   ensure Renewed-Banking
   ensure srp-billing
   ```

   Use the exact resource folder names installed on your server.
7. (Optional) Give billing administrator access using the configured ACE permission:

   ```cfg
   add_ace group.admin billing.admin allow
   ```

   Add the relevant player/group to `group.admin` using your server's normal ACE setup. QBCore players with the `admin` permission are also recognized.
8. Restart the server or start `srp-billing` after dependencies and database are ready.

## Database

SRP Billing stores its records in the same MySQL/MariaDB database used by oxmysql. Import `schema.sql` once before first use. All tables use InnoDB; there is no separate database service or application server.

| Table | Purpose |
|---|---|
| `billing_invoices` | Invoice type, sender/recipient, society accounts, item lines, amounts, due date, status, and timestamps |
| `billing_templates` | Society-owned templates with saved labels, quantities, prices, title, and discount |
| `billing_commissions` | Commission records created when eligible job/B2B invoices are settled |
| `billing_society_transfers` | B2B debtor-to-creditor ledger entries |
| `billing_settings` | Shared UI theme settings |

Invoice statuses are `pending`, `processing`, `paid`, and `cancelled`. `processing` is a temporary fail-closed state while settlement is underway. If an external banking operation succeeds but the final database transaction fails, the resource logs the case and deliberately leaves the invoice in `processing`; reconcile it against bank records before making manual changes to avoid duplicate transfers.

Society balances are **not** stored in these tables. They are managed by Renewed-Banking. Invoice payments and commission payouts use QBCore money functions or Renewed-Banking exports according to invoice type.

## Configuration

Edit [`config.lua`](./config.lua):

- `Config.Locale`: `en` or `it`.
- `Config.Command`: command used to open billing; default is `/billing`.
- `Config.AdminAce`: ACE permission name for administrators.
- `Config.ReceiptItem`: ox_inventory item name; default `billing_receipt`.
- `Config.ReceiptViewDistance`: distance in game units at which nearby players see a used receipt; default `5.0`.
- `Config.ReceiptUseCooldownSeconds`: receipt-use rate limit per player.
- `Config.Limits`: amount, text, item-count, archive, due-date, and invoice-cooldown limits.
- `Config.DefaultDueDays`: due date used when none is provided.
- `Config.Payments`: QBCore cash/bank account names.
- `Config.Theme`: initial UI colors, used until a shared theme is saved.
- `Config.Kiosks`: locations, ped models, and labels for invoice kiosks.
- `Config.Societies`: job-to-society rules.

Each society entry supports:

```lua
mechanic = {
    label = 'MECHANIC',
    account = 'mechanic', -- account name in Renewed-Banking
    canBill = true,
    canCreateB2B = true,
    canManageTemplates = true,
    templateGrade = 6, -- minimum job grade allowed to manage templates
    bossGrade = 6, -- minimum job grade allowed to manage B2B/commissions
    commissionPercent = 10
}
```

Use the actual job names and grades defined by your QBCore server. The configured society account must exist in Renewed-Banking. `canBill` enables job billing and templates; `canCreateB2B` enables B2B issuance for authorized bosses. Billing admins can select any configured society in the UI, but cannot select an account that is not configured.

The banking adapter expects `addAccountMoney(account, amount)` and `removeAccountMoney(account, amount)` exports from Renewed-Banking. If your server uses a different banking API, adapt `societyCall` in [`server/main.lua`](./server/main.lua).

## Features and permissions

### Player invoices

- Players can issue an invoice to a nearby player using manually entered item lines and prices, or a manual amount.
- Item labels, quantities, unit prices, discounts, due dates, and invoice totals are validated server-side.
- The recipient pays with cash or bank, as configured.
- The issuing player must be online when a personal invoice is paid so the server can credit their bank account.

### Job invoices and templates

- A job invoice is issued to a nearby player on behalf of the sender's society.
- Job invoices require a saved template owned by that society. The server loads the saved template and does not trust client-sent prices, title, or discount; the issuer can adjust line quantities.
- Only users meeting `templateGrade` (or authorized billing admins) can create/update or delete templates. Employees allowed to bill can select and use the templates.
- On settlement, the society account receives the invoice payment net of the configured commission.

### Company-to-company (B2B) invoices

- An authorized society boss or billing admin can invoice another configured society.
- B2B invoices use manually entered item lines/prices and a selected debtor society; the server validates the data and society permissions.
- Payment is made from the debtor society account through Renewed-Banking. The paying boss/admin must be online to initiate settlement.
- The transfer is recorded in `billing_society_transfers`.

### Commissions

- Eligible settled job/B2B invoices create commission records using the sender society's `commissionPercent`.
- Society bosses can view and pay available commissions for their own society; billing admins can select any configured society.
- The employee must be online to receive a commission payout.

### Receipts and archive

- Successful payment gives the payer one `billing_receipt` inventory item. For B2B, this is the boss/admin who performed payment.
- Using the item opens a read-only receipt view for the user and nearby players within `Config.ReceiptViewDistance`. The server verifies the item in the used slot and retrieves the paid invoice from the database before sharing it.
- If inventory insertion fails (for example, no free slot), payment remains settled; the error is logged and the payer is notified.
- The billing menu also provides a searchable, status-filtered invoice archive. Results are bounded by `Config.Limits.MaxArchiveRows`.
- Administrators can see the global invoice archive, cancel any pending invoice, manage any configured society, and save the shared UI theme.

## In-game usage

### Open billing

- Run `/billing` (or the command configured in `Config.Command`).
- Use an `ox_target` interaction on a nearby player to open the create-invoice screen with that player's server ID filled in.
- Use a configured kiosk ped to open the pending-invoice view.

### Create an invoice

1. Open **New invoice** and choose Player, Job, or Company invoice. Available types depend on your job/rank or admin access.
2. Select/enter the recipient. Player and Job invoices require a nearby player; Company invoices require a configured debtor society.
3. Add a title and item lines. Player and Company invoices allow direct item labels, quantities, unit prices, and a discount. Job invoices require a saved society template.
4. Review the live receipt preview, subtotal, and total; set an optional due date.
5. Submit the invoice. The recipient receives a notification when online.

### Pay an invoice

- Open **Invoices** or use a kiosk, select a pending invoice, and choose cash or bank when the invoice is payable by a player.
- B2B invoices are payable by a boss of the debtor society or a billing admin; payment debits the debtor society account.
- On successful settlement, the payer receives a receipt item and both payer and issuer are notified when online.

### Use/share the receipt item

Use `billing_receipt` from ox_inventory. The receipt is shown on your screen and on nearby players' screens. It is read-only and can be closed using the close button or Escape. Viewing it does not pay, cancel, or alter the invoice.

### Manage templates and commissions

- Authorized template managers open **Job templates** to create, update, or delete their society's templates.
- Society bosses open **Commissions** to review and pay available commission records.
- Admins select a society from **Manage society** before working with its templates, invoices, or commissions.

## Invoice and payment flow

1. The NUI calls a client callback; the client forwards it with `lib.callback.await`.
2. Server handlers in [`server/main.lua`](./server/main.lua) resolve player identity/job and re-check permissions, proximity, amounts, item lines, and society accounts.
3. The server stores invoices/templates in MySQL. Client-side preview values are not authoritative.
4. Payment claims an invoice with a conditional `pending -> processing` update before any money is moved, preventing concurrent claims.
5. The resource debits the payer and credits the personal issuer or society. A failed credit triggers a compensating refund where possible.
6. Invoice status and related commission/B2B ledger entries are finalized in an oxmysql transaction.
7. After settlement is committed, the receipt item is added and transaction notifications are sent.

## Troubleshooting

- **NUI does not open or is blank:** confirm `web/dist` exists and was built; check the resource console for dependency or asset errors.
- **Database errors on startup/use:** import `schema.sql` into the database used by oxmysql and verify the connection is active.
- **Society billing or payouts fail:** check `Config.Societies` job/account names and confirm the account exists in Renewed-Banking.
- **Receipt item is missing:** register `Config.ReceiptItem` in ox_inventory, include `client.export = 'srp-billing.useReceipt'`, and ensure the payer has a free inventory slot.
- **Admin controls are missing:** verify the player has QBCore `admin` permission or the configured ACE permission.
- **Invoice remains `processing`:** inspect resource/server logs and reconcile with the banking ledger before changing its status. Do not reset it blindly; that could allow duplicate payment.

## Limits and notes

- Cancellations are allowed only while an invoice is pending and are rechecked server-side.
- Job/B2B invoice prices, discounts, totals, permissions, and society accounts are server-validated.
- The receipt barcode is a visual invoice reference, not a payment credential.
- English and Italian locales are included in `locales/`; add translations to both the locale key set and UI translations when introducing another language.
