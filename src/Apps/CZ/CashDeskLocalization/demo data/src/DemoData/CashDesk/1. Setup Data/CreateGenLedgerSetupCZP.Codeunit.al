// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.CashDesk;

using Microsoft.DemoData.Foundation;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 31343 "Create Gen. Ledger Setup CZP"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateGeneralLedgerSetup();
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CreateNoSeriesCZ: Codeunit "Create No. Series CZ";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Cash Desk Nos. CZP", CreateNoSeriesCZ.CashDesk());
        GeneralLedgerSetup.Modify(true);
    end;
}
