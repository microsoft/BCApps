// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148355 "Exp. Attachments API Race Hook"
{
    // Deletes a marked expense after the Expenses API has read it and before its attachments are expanded.
    // The subscriber is static so that it also runs in the web service session that serves the test request.

    [EventSubscriber(ObjectType::Page, Page::"Expenses API", 'OnAfterGetRecordEvent', '', false, false)]
    local procedure DeleteMarkedExpenseOnAfterGetRecord(var Rec: Record Expense)
    var
        Expense: Record Expense;
    begin
        if Rec.Description <> DeleteWhileReadMarker() then
            exit;

        if Expense.GetBySystemId(Rec.SystemId) then
            Expense.Delete(true);
    end;

    procedure DeleteWhileReadMarker(): Text[100]
    begin
        exit('EXPENSE ATTACHMENTS API RACE: DELETE WHILE READ');
    end;
}
