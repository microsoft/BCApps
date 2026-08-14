// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.DataAdministration;

codeunit 6927 "Expense Activity Retention"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        AddActivityLogToAllowedTables();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", OnRefreshAllowedTables, '', false, false)]
    local procedure AddActivityLogToAllowedTables()
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        ActivityLogRecordRef: RecordRef;
        TableFilters: JsonArray;
    begin
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ActivityLogRecordRef.GetTable(ExpenseActivityLogEntry);
        RetenPolAllowedTables.AddTableFilterToJsonArray(
            TableFilters,
            Enum::"Retention Period Enum"::"Never Delete",
            ExpenseActivityLogEntry.FieldNo("Occurred At"),
            false,
            false,
            ActivityLogRecordRef);

        RetenPolAllowedTables.AddAllowedTable(
            Database::"Expense Activity Log Entry",
            ExpenseActivityLogEntry.FieldNo("Occurred At"),
            TableFilters);
    end;
}
