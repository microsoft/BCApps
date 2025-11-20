// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Foundation.Navigate;

codeunit 99000798 "Mfg. Posting Preview Subscr."
{
    var
        TempCapacityLedgerEntry: Record "Capacity Ledger Entry" temporary;
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnGetEntries', '', false, false)]
    local procedure GetEntriesOnGetEntries(TableNo: Integer; var RecRef: RecordRef)
    begin
        GetAllTables();
        case TableNo of
            Database::"Capacity Ledger Entry":
                RecRef.GETTABLE(TempCapacityLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterShowEntries', '', false, false)]
    local procedure ShowEntriesOnAfterShowEntries(TableNo: Integer)
    begin
        GetAllTables();
        case TableNo of
            Database::"Capacity Ledger Entry":
                Page.Run(Page::"Capacity Ledger Entries", TempCapacityLedgerEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Preview Event Handler", 'OnAfterFillDocumentEntry', '', false, false)]
    local procedure FillDocumentEntryOnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry")
    begin
        GetAllTables();
        PostingPreviewEventHandler.InsertDocumentEntry(TempCapacityLedgerEntry, DocumentEntry);
    end;

    local procedure GetAllTables()
    var
        MfgPostingPreviewHandler: Codeunit "Mfg. Posting Preview Handler";
    begin
        MfgPostingPreviewHandler.GetTempCapacityLedgerEntry(TempCapacityLedgerEntry);
    end;
}
