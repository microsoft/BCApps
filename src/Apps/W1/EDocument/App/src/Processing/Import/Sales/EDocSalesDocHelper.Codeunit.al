// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.EServices.EDocument.Processing;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;

/// <summary>
/// Shared logic for creating BC sales documents (orders and blanket orders) from e-document draft data.
/// </summary>
codeunit 6427 "E-Doc. Sales Doc. Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Dimension Set Tree Node" = im,
                  tabledata "Dimension Set Entry" = im;

    /// <summary>
    /// Creates a Sales Line from a staged E-Document Sales Line record.
    /// </summary>
    procedure CreateSalesLineFromDraft(SalesHeader: Record "Sales Header"; EDocSalesLine: Record "E-Document Sales Line"; HasTotalDiscount: Boolean; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        EDocRecordLink: Record "E-Doc. Record Link";
        DimensionManagement: Codeunit DimensionManagement;
        SalesLineCombinedDimensions: array[10] of Integer;
        GlobalDim1, GlobalDim2 : Code[20];
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine."Unit of Measure Code" := CopyStr(EDocSalesLine."[BC] Unit of Measure", 1, MaxStrLen(SalesLine."Unit of Measure Code"));
        SalesLine."Variant Code" := EDocSalesLine."[BC] Variant Code";
        SalesLine.Type := EDocSalesLine."[BC] Sales Line Type";
        SalesLine.Validate("No.", EDocSalesLine."[BC] Sales Line No.");
        if (SalesLine.Type = SalesLine.Type::"G/L Account") and HasTotalDiscount then
            SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Description := EDocSalesLine.Description;

        if EDocSalesLine."[BC] Item Reference No." <> '' then
            SalesLine.Validate("Item Reference No.", EDocSalesLine."[BC] Item Reference No.");

        SalesLine.Validate(Quantity, EDocSalesLine.Quantity);
        SalesLine.Validate("Unit Price", EDocSalesLine."Unit Price");
        if EDocSalesLine."Line Discount Amount" > 0 then
            SalesLine.Validate("Line Discount Amount", EDocSalesLine."Line Discount Amount");

        SalesLineCombinedDimensions[1] := SalesLine."Dimension Set ID";
        SalesLineCombinedDimensions[2] := EDocSalesLine."[BC] Dimension Set ID";
        SalesLine.Validate("Dimension Set ID", DimensionManagement.GetCombinedDimensionSetID(SalesLineCombinedDimensions, GlobalDim1, GlobalDim2));
        SalesLine.Validate("Shortcut Dimension 1 Code", EDocSalesLine."[BC] Shortcut Dimension 1 Code");
        SalesLine.Validate("Shortcut Dimension 2 Code", EDocSalesLine."[BC] Shortcut Dimension 2 Code");
        SalesLine.Insert();
        EDocRecordLink.InsertEDocumentSalesLineLink(EDocSalesLine, SalesLine);
    end;

    /// <summary>
    /// Returns true if every staged sales line has a sales line type and item number set.
    /// </summary>
    procedure AllDraftLinesHaveTypeAndNumber(EDocSalesHeader: Record "E-Document Sales Header"): Boolean
    var
        EDocSalesLine: Record "E-Document Sales Line";
    begin
        EDocSalesLine.SetLoadFields("[BC] Sales Line Type", "[BC] Sales Line No.");
        EDocSalesLine.ReadIsolation(IsolationLevel::ReadCommitted);
        EDocSalesLine.SetRange("E-Document Entry No.", EDocSalesHeader."E-Document Entry No.");
        if not EDocSalesLine.FindSet() then
            exit(true);
        repeat
            if EDocSalesLine."[BC] Sales Line Type" = EDocSalesLine."[BC] Sales Line Type"::" " then
                exit(false);
            if EDocSalesLine."[BC] Sales Line No." = '' then
                exit(false);
        until EDocSalesLine.Next() = 0;
        exit(true);
    end;

    /// <summary>
    /// Sets the E-Document Link on the Sales Header and copies document attachments from the E-Document.
    /// </summary>
    procedure FinalizeCreatedDocument(EDocument: Record "E-Document"; var SalesHeader: Record "Sales Header")
    var
        DocumentAttachmentMgt: Codeunit "Document Attachment Mgmt";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
    begin
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
        SalesHeader.TestField("No.");
        SalesHeader."E-Document Link" := EDocument.SystemId;
        SalesHeader.Modify();

        DocumentAttachmentMgt.CopyAttachments(EDocument, SalesHeader);
        DocumentAttachmentMgt.DeleteAttachedDocuments(EDocument);

        EDocImpSessionTelemetry.SetBool('Document Created', TryCheckSalesDocumentExists(SalesHeader));
    end;

    /// <summary>
    /// Copies document attachments back from the Sales Header to the E-Document and clears the E-Document Link.
    /// </summary>
    procedure RevertCreatedDocument(EDocument: Record "E-Document")
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachmentMgt: Codeunit "Document Attachment Mgmt";
    begin
        SalesHeader.SetRange("E-Document Link", EDocument.SystemId);
        if not SalesHeader.FindFirst() then
            exit;

        DocumentAttachmentMgt.CopyAttachments(SalesHeader, EDocument);
        DocumentAttachmentMgt.DeleteAttachedDocuments(SalesHeader);

        Clear(SalesHeader."E-Document Link");
        SalesHeader.Modify();
    end;

    [TryFunction]
    procedure TryCheckSalesDocumentExists(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("No.");
    end;

    procedure GetLastSalesLineNo(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetLoadFields("Line No.");
        SalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        if SalesLine.FindLast() then
            exit(SalesLine."Line No.");

        exit(0);
    end;
}
