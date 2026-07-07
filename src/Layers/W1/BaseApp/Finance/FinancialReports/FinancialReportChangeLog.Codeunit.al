// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Diagnostics;

/// <summary>
/// Ensures that all Financial Report configuration tables are always tracked by the Change Log,
/// regardless of the Change Log Setup, by subscribing to Change Log Management extensibility events.
/// </summary>
codeunit 8396 "Financial Report Change Log"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Log Management", 'OnAfterIsAlwaysLoggedTable', '', false, false)]
    local procedure OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean)
    begin
        if TableID in
            [Database::"Acc. Schedule Name",
             Database::"Financial Report",
             Database::"Financial Report User Filters",
             Database::"Column Layout Name",
             Database::"Fin. Report Excel Template",
             Database::"Financial Report Schedule",
             Database::"Financial Report Export Log",
             Database::"Financial Report Recipient",
             Database::"Financial Report Package",
             Database::"Fin. Report Package Report",
             Database::"Fin. Report Package Schedule",
             Database::"Fin. Report Package Recipient",
             Database::"Fin. Rep. Package Export Log",
             Database::"Financial Report Audit Log",
             Database::"Financial Report Category",
             Database::"Financial Report Status"]
        then
            AlwaysLogTable := true;
    end;
}
