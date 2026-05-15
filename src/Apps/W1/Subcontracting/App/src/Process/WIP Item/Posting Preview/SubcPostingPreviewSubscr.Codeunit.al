// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Navigate;

codeunit 99001566 "Subc. Posting Preview Subscr."
{
    var
        TempSubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry" temporary;
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnGetEntries, '', true, false)]
    local procedure GetEntriesOnGetEntries(TableNo: Integer; var RecRef: RecordRef)
    begin
        GetAllTables();
        case TableNo of
            Database::"Subcontractor WIP Ledger Entry":
                RecRef.GetTable(TempSubcontractorWIPLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterShowEntries, '', true, false)]
    local procedure ShowEntriesOnAfterShowEntries(TableNo: Integer)
    begin
        GetAllTables();
        case TableNo of
            Database::"Subcontractor WIP Ledger Entry":
                Page.Run(Page::"Subc. WIP Ledger Entries", TempSubcontractorWIPLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", OnAfterFillDocumentEntry, '', true, false)]
    local procedure FillDocumentEntryOnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry")
    begin
        GetAllTables();
        PostingPreviewEventHandler.InsertDocumentEntry(TempSubcontractorWIPLedgerEntry, DocumentEntry);
    end;

    local procedure GetAllTables()
    var
        SubcPostingPreviewHandler: Codeunit "Subc. Pst. Prev. Event Handler";
    begin
        SubcPostingPreviewHandler.GetTempSubcontractorWIPLedgerEntry(TempSubcontractorWIPLedgerEntry);
    end;
}
