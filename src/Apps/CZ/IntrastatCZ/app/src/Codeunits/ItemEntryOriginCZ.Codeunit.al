// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Inventory.Ledger;

codeunit 31163 "Item Entry Origin CZ" implements "Intrastat Posted Origin CZ"
{
    Access = Internal;

    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetLoadFields("Country/Reg. of Orig. Code CZ");
        if ItemLedgerEntry.Get(IntrastatReportLine."Source Entry No.") then
            exit(ItemLedgerEntry."Country/Reg. of Orig. Code CZ");
    end;
}
