// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AdvancePayments;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Navigate;

codeunit 31069 "Post.Preview Event Handler CZZ"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        TempSalesAdvLetterEntryCZZ: Record "Sales Adv. Letter Entry CZZ" temporary;
        TempPurchAdvLetterEntryCZZ: Record "Purch. Adv. Letter Entry CZZ" temporary;

    [EventSubscriber(ObjectType::Table, Database::"Sales Adv. Letter Entry CZZ", 'OnAfterInsertEvent', '', false, false)]
    local procedure SalesAdvLetterEntryOnAfterInsertEvent(var Rec: Record "Sales Adv. Letter Entry CZZ")
    begin
        if Rec.IsTemporary() then
            exit;

        TempSalesAdvLetterEntryCZZ := Rec;
        TempSalesAdvLetterEntryCZZ."Document No." := '***';
        TempSalesAdvLetterEntryCZZ.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Adv. Letter Entry CZZ", 'OnAfterInsertEvent', '', false, false)]
    local procedure PurchAdvLetterEntryOnAfterInsertEvent(var Rec: Record "Purch. Adv. Letter Entry CZZ")
    begin
        if Rec.IsTemporary() then
            exit;

        TempPurchAdvLetterEntryCZZ := Rec;
        TempPurchAdvLetterEntryCZZ."Document No." := '***';
        TempPurchAdvLetterEntryCZZ.Insert();
    end;

    procedure ClearBuffer()
    begin
        if not TempSalesAdvLetterEntryCZZ.IsEmpty() then
            TempSalesAdvLetterEntryCZZ.DeleteAll();
        if not TempPurchAdvLetterEntryCZZ.IsEmpty() then
            TempPurchAdvLetterEntryCZZ.DeleteAll();
    end;

    procedure InsertAllDocumentEntry(var DocumentEntry: Record "Document Entry")
    var
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
    begin
        PostingPreviewEventHandler.InsertDocumentEntry(TempSalesAdvLetterEntryCZZ, DocumentEntry);
        PostingPreviewEventHandler.InsertDocumentEntry(TempPurchAdvLetterEntryCZZ, DocumentEntry);
    end;

    procedure ShowEntries(TableNo: Integer)
    begin
        case TableNo of
            Database::"Sales Adv. Letter Entry CZZ":
                Page.Run(Page::"Sales Adv. Letter Entries CZZ", TempSalesAdvLetterEntryCZZ);
            Database::"Purch. Adv. Letter Entry CZZ":
                Page.Run(Page::"Purch. Adv. Letter Entries CZZ", TempPurchAdvLetterEntryCZZ);
        end;
    end;
}
