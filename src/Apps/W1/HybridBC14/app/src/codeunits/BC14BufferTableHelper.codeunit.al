// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

codeunit 50178 "BC14 Buffer Table Helper"
{
    /// <summary>
    /// Returns the List Page ID for a given buffer table ID.
    /// Returns 0 if no dedicated page exists.
    /// </summary>
    procedure GetListPageIdForTable(TableId: Integer): Integer
    begin
        case TableId of
            Database::"BC14 Customer":
                exit(Page::"BC14 Customer List");
            Database::"BC14 Vendor":
                exit(Page::"BC14 Vendor List");
            Database::"BC14 Item":
                exit(Page::"BC14 Item List");
            Database::"BC14 G/L Account":
                exit(Page::"BC14 G/L Account List");
            Database::"BC14 G/L Entry":
                exit(Page::"BC14 G/L Entry List");
            Database::"BC14 Posted Sales Inv Header":
                exit(Page::"BC14 Posted Sales Inv List");
            else
                exit(0);
        end;
    end;

    /// <summary>
    /// Opens the buffer table record for editing.
    /// Returns true if successful, false if no page is available.
    /// </summary>
    procedure OpenBufferRecord(SourceTableId: Integer; SourceRecordId: RecordId): Boolean
    var
        PageId: Integer;
    begin
        PageId := GetListPageIdForTable(SourceTableId);
        if PageId = 0 then
            exit(false);

        OpenBufferRecordByTableId(SourceTableId, SourceRecordId);
        exit(true);
    end;

    local procedure OpenBufferRecordByTableId(SourceTableId: Integer; SourceRecordId: RecordId)
    var
        BC14Customer: Record "BC14 Customer";
        BC14Vendor: Record "BC14 Vendor";
        BC14Item: Record "BC14 Item";
        BC14GLAccount: Record "BC14 G/L Account";
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
    begin
        case SourceTableId of
            Database::"BC14 Customer":
                if BC14Customer.Get(SourceRecordId) then
                    Page.RunModal(Page::"BC14 Customer List", BC14Customer);
            Database::"BC14 Vendor":
                if BC14Vendor.Get(SourceRecordId) then
                    Page.RunModal(Page::"BC14 Vendor List", BC14Vendor);
            Database::"BC14 Item":
                if BC14Item.Get(SourceRecordId) then
                    Page.RunModal(Page::"BC14 Item List", BC14Item);
            Database::"BC14 G/L Account":
                if BC14GLAccount.Get(SourceRecordId) then
                    Page.RunModal(Page::"BC14 G/L Account List", BC14GLAccount);
            Database::"BC14 G/L Entry":
                if BC14GLEntry.Get(SourceRecordId) then
                    Page.RunModal(Page::"BC14 G/L Entry List", BC14GLEntry);
            Database::"BC14 Posted Sales Inv Header":
                if BC14PostedSalesInvHeader.Get(SourceRecordId) then
                    Page.RunModal(Page::"BC14 Posted Sales Inv List", BC14PostedSalesInvHeader);
        end;
    end;
}
