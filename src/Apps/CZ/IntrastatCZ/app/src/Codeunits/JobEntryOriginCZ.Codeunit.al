// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Projects.Project.Ledger;

codeunit 31164 "Job Entry Origin CZ" implements "Intrastat Posted Origin CZ"
{
    Access = Internal;

    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10]
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetLoadFields("Country/Reg. of Orig. Code CZ");
        if JobLedgerEntry.Get(IntrastatReportLine."Source Entry No.") then
            exit(JobLedgerEntry."Country/Reg. of Orig. Code CZ");
    end;
}
