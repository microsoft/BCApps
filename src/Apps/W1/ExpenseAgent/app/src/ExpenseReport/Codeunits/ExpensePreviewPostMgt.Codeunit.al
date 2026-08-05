// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Preview;

codeunit 6997 "Expense Preview Post Mgt."
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        ExpenseReportHeader.Copy(RecVar);

        ExpenseReportPost.SetPreviewMode(true);
        Result := ExpenseReportPost.Run(ExpenseReportHeader);
    end;
}