// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Foundation.Navigate;
using Microsoft.Service.Ledger;

codeunit 6498 "Serv. Posting Preview Subscr."
{
    var
        TempServiceLedgerEntry: Record "Service Ledger Entry" temporary;
        TempWarrantyLedgerEntry: Record "Warranty Ledger Entry" temporary;
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnGetEntries', '', true, false)]
    local procedure GetEntriesOnGetEntries(TableNo: Integer; var RecRef: RecordRef)
    begin
        GetAllTables();
        case TableNo of
            Database::"Service Ledger Entry":
                RecRef.GETTABLE(TempServiceLedgerEntry);
            Database::"Warranty Ledger Entry":
                RecRef.GETTABLE(TempWarrantyLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterShowEntries', '', true, false)]
    local procedure ShowEntriesOnAfterShowEntries(TableNo: Integer)
    begin
        GetAllTables();
        case TableNo of
            Database::"Service Ledger Entry":
                Page.Run(Page::"Service Ledger Entries Preview", TempServiceLedgerEntry);
            Database::"Warranty Ledger Entry":
                Page.Run(Page::"Warranty Ledg. Entries Preview", TempWarrantyLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterFillDocumentEntry', '', true, false)]
    local procedure FillDocumentEntryOnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry")
    begin
        GetAllTables();
        PostingPreviewEventHandler.InsertDocumentEntry(TempServiceLedgerEntry, DocumentEntry);
        PostingPreviewEventHandler.InsertDocumentEntry(TempWarrantyLedgerEntry, DocumentEntry);
    end;

    local procedure GetAllTables()
    var
        ServPostingPreviewHandler: Codeunit "Serv. Posting Preview Handler";
    begin
        ServPostingPreviewHandler.GetTempServiceLedgerEntry(TempServiceLedgerEntry);
        ServPostingPreviewHandler.GetTempWarrantyLedgerEntry(TempWarrantyLedgerEntry);
    end;
}
