// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Purchases.Document;

/// <summary>
/// This table is used to link records together.
/// Used by purchase draft historical mapping algorithm:
/// - EDocPurchaseHistMappping.Codeunit.al
/// 
/// To link a draft purchase line to a purchase line, or draft purchase header to a purchase header. 
/// When posting the invoice the link is removed and the history stored in "E-Doc. Purchase Line History"
/// </summary>
table 6141 "E-Doc. Record Link"
{

    DataClassification = CustomerContent;
    Caption = 'E-Doc. Record Link';
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    Access = Internal;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            AutoIncrement = true;
        }
        field(2; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(4; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5; "Target Table No."; Integer)
        {
            Caption = 'Target Table No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6; "Target SystemId"; Guid)
        {
            Caption = 'Target SystemId';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(K1; "Target Table No.", "Target SystemId")
        {
        }
        key(K2; "E-Document Entry No.")
        {
        }

    }

    internal procedure InsertEDocumentHeaderLink(EDocumentPurchaseHeader: Record "E-Document Purchase Header"; PurchaseHeader: Record "Purchase Header")
    begin
        InsertLinkBetweenEDocumentRecords(Database::"E-Document Purchase Header", EDocumentPurchaseHeader.SystemId, Database::"Purchase Header", PurchaseHeader.SystemId, EDocumentPurchaseHeader."E-Document Entry No.");
    end;

    internal procedure InsertEDocumentLineLink(EDocumentPurchaseLine: Record "E-Document Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
        InsertLinkBetweenEDocumentRecords(Database::"E-Document Purchase Line", EDocumentPurchaseLine.SystemId, Database::"Purchase Line", PurchaseLine.SystemId, EDocumentPurchaseLine."E-Document Entry No.");
    end;

    local procedure InsertLinkBetweenEDocumentRecords(SourceTableNo: Integer; SourceSystemId: Guid; TargetTableNo: Integer; TargetSystemId: Guid; EDocumentEntryNo: Integer)
    var
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        // We clear any existing link, the only valid links should be the ones we are creating now
        EDocRecordLink.SetRange("Source Table No.", SourceTableNo);
        EDocRecordLink.SetRange("Source SystemId", SourceSystemId);
        EDocRecordLink.SetRange("Target Table No.", TargetTableNo);
        EDocRecordLink.DeleteAll();

        // We create the new link
        EDocRecordLink."E-Document Entry No." := EDocumentEntryNo;
        EDocRecordLink."Source Table No." := SourceTableNo;
        EDocRecordLink."Source SystemId" := SourceSystemId;
        EDocRecordLink."Target Table No." := TargetTableNo;
        EDocRecordLink."Target SystemId" := TargetSystemId;
        EDocRecordLink.Insert();
    end;

}