// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

codeunit 11356 "Empl. Entry-Edit NL"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Empl. Entry-Edit", OnBeforeEmplLedgEntryModify, '', false, false)]
    local procedure OnBeforeEmplLedgEntryModify(var EmplLedgEntry: Record "Employee Ledger Entry"; FromEmplLedgEntry: Record "Employee Ledger Entry")
    begin
        if EmplLedgEntry.Open then
            EmplLedgEntry."Transaction Mode Code" := FromEmplLedgEntry."Transaction Mode Code";
    end;
}