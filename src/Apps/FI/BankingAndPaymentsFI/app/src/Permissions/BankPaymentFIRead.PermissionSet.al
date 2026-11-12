// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Reports;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Service.Document;

permissionset 13587 "BANK PAYMENT FI READ"
{
    Assignable = true;
    Caption = 'BANK PAYMENT FI READ';
    Permissions =
#if not CLEAN30
                  codeunit "Banking Payments Feature FI" = X,
#endif
                  codeunit "Bank Nos Check FI" = X,
                  page "Payment Method Codes FI" = X,
                  codeunit "SEPA CT pain.001.001.09 FI" = X,
                  report "SEPA CT pain.001.001.09 FI" = X,
                  codeunit "Export SEPA Payment File FI" = X,
                  report "Export SEPA Payment File FI" = X,
                  page "Apply Ref. Payment FI" = X,
                  page "Bank Payments to send FI" = X,
                  tabledata "Foreign Payment Types FI" = R,
                  table "Foreign Payment Types FI" = X,
                  page "Ref. Payment - Export FI" = X,
                  tabledata "Ref. Payment - Exported FI" = R,
                  table "Ref. Payment - Exported FI" = X,
                  tabledata "Ref. Payment Export Buffer FI" = R,
                  table "Ref. Payment Export Buffer FI" = X,
                  page "Ref. Payment - Import FI" = X,
                  report "Ref. Payment Imported FI" = X,
                  tabledata "Ref. Payment - Imported FI" = R,
                  table "Ref. Payment - Imported FI" = X,
                  codeunit "Ref. Payment Management FI" = X,
                  report "Suggest Bank Payments FI" = X,
                  report "Export Ref. Payment -  LMP FI" = X,
                  report "Export Ref. Payment -  LUM FI" = X,
                  report "Import Ref. Payment FI" = X,
                  report "Payment FI" = X,
                  page "Bank Reference File Setup FI" = X,
                  page "Input Dialog FI" = X,
                  tabledata "Reference File Setup FI" = R,
                  table "Reference File Setup FI" = X,
                  codeunit "Service Payment References FI" = X,
                  codeunit "Banking Payments Events FI" = X,
                  codeunit "Banking Payments Posting FI" = X,
                  codeunit "Suggest Vendor Payments FI" = X,
                  report "Suggest Vendor Payments" = X,
                  codeunit "Banking Payments References FI" = X,
                  codeunit "Banking Payments Tags FI" = X;
}
