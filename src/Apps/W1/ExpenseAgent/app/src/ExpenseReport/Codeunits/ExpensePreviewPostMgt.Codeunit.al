// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Navigate;

codeunit 6997 "Expense Preview Post Mgt."
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        NoEntriesToShowMsg: Label 'Preview Posting of Expense Document is completed with no errors. However, the Show Entries page will not open because no ledger entries are created for this document.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnBeforeShowAllEntries', '', false, false)]
    local procedure OnBeforeShowAllEntries(var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean; var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    var
        TempPreviewDocumentEntry: Record "Document Entry" temporary;
    begin
        PostingPreviewEventHandler.FillDocumentEntry(TempPreviewDocumentEntry);
        if not TempPreviewDocumentEntry.IsEmpty() then
            exit;

        Message(NoEntriesToShowMsg);
        IsHandled := true;
    end;

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