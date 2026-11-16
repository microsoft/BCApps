// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Sales.Receivables;

permissionset 3347 "Payables Ag. - Excl."
{
    Access = Internal;
    Caption = 'Payables Agent - Excluded', Comment = 'Payables Agent is a term, and should not be translated.';
    Permissions =
        tabledata "VAT Entry" = Rm,
        tabledata "Bank Account Ledger Entry" = rm,
        tabledata "Check Ledger Entry" = r,
        tabledata "Cust. Ledger Entry" = r,
        tabledata "G/L Entry" = rm;
}
