// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AdvancePayments;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Navigate;

codeunit 31068 "Post Preview Handler CZZ"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterBindSubscription', '', false, false)]
    local procedure GenJnlPostPreviewOnAfterBindSubscription()
    begin
        TryBindPostPreviewEventHandler();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnAfterUnbindSubscription', '', false, false)]
    local procedure GenJnlPostPreviewOnAfterUnbindSubscription()
    begin
        TryUnbindPostPreviewEventHandler();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterFillDocumentEntry', '', false, false)]
    local procedure PostingPreviewEventHandlerOnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry")
    var
        PostPreviewEventHandlerCZZ: Codeunit "Post.Preview Event Handler CZZ";
    begin
        PostPreviewEventHandlerCZZ.InsertAllDocumentEntry(DocumentEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterShowEntries', '', false, false)]
    local procedure PostingPreviewEventHandlerOnAfterShowEntries(TableNo: Integer)
    var
        PostPreviewEventHandlerCZZ: Codeunit "Post.Preview Event Handler CZZ";
    begin
        PostPreviewEventHandlerCZZ.ShowEntries(TableNo);
    end;

    local procedure TryBindPostPreviewEventHandler(): Boolean
    var
        PostPreviewEventHandlerCZZ: Codeunit "Post.Preview Event Handler CZZ";
    begin
        PostPreviewEventHandlerCZZ.ClearBuffer();
        exit(BindSubscription(PostPreviewEventHandlerCZZ));
    end;

    local procedure TryUnbindPostPreviewEventHandler(): Boolean
    var
        PostPreviewEventHandlerCZZ: Codeunit "Post.Preview Event Handler CZZ";
    begin
        exit(UnbindSubscription(PostPreviewEventHandlerCZZ));
    end;
}
