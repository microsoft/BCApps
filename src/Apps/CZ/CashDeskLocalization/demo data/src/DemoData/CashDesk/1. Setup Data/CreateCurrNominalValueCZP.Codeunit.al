// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.CashDesk;

using Microsoft.DemoData.Localization;

codeunit 31468 "Create Curr. Nominal Value CZP"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoCashDeskCZP: Codeunit "Contoso Cash Desk CZP";
        i: Integer;
    begin
        for i := 0 to 3 do begin
            ContosoCashDeskCZP.InsertCurrencyNominalValue('', 1 * Power(10, i mod 4));
            ContosoCashDeskCZP.InsertCurrencyNominalValue('', 2 * Power(10, i mod 4));
            ContosoCashDeskCZP.InsertCurrencyNominalValue('', 5 * Power(10, i mod 4));
        end;
    end;
}