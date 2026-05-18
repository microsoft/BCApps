// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Document;
using System.Telemetry;

/// <summary>
/// Creates a BC Sales Order or Blanket Order from an inbound Peppol Order e-document draft.
/// </summary>
codeunit 6405 "E-Doc. Create Sales Order" implements IEDocumentFinishDraft, IEDocumentCreateSalesOrder
{
    Access = Internal;

    var
        Telemetry: Codeunit Telemetry;
        DraftLineDoesNotContainTypeAndNumberErr: Label 'One of the draft lines do not contain the type and number. Please, specify these fields manually.';
        DuplicateSalesOrderErr: Label 'A sales order with external document number %1 already exists for customer %2.', Comment = '%1 = External Document No., %2 = Customer No.';

    /// <summary>
    /// Creates a BC sales document from the e-document draft by delegating to the customizations interface.
    /// </summary>
    procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId
    var
        SalesHeader: Record "Sales Header";
        EDocSalesDocHelper: Codeunit "E-Doc. Sales Doc. Helper";
        ICreateSalesOrder: Interface IEDocumentCreateSalesOrder;
    begin
        ICreateSalesOrder := EDocImportParameters."Processing Customizations";
        SalesHeader := ICreateSalesOrder.CreateSalesOrder(EDocument);
        EDocSalesDocHelper.FinalizeCreatedDocument(EDocument, SalesHeader);
        exit(SalesHeader.RecordId);
    end;

    /// <summary>
    /// Reverts the BC sales document creation and moves attachments back to the e-document.
    /// </summary>
    procedure RevertDraftActions(EDocument: Record "E-Document")
    var
        EDocSalesDocHelper: Codeunit "E-Doc. Sales Doc. Helper";
    begin
        EDocSalesDocHelper.RevertCreatedDocument(EDocument);
    end;

    /// <summary>
    /// Default implementation: creates a Sales Header and Sales Lines from the staged draft data.
    /// </summary>
    procedure CreateSalesOrder(EDocument: Record "E-Document"): Record "Sales Header"
    var
        EDocSalesHeader: Record "E-Document Sales Header";
        EDocSalesLine: Record "E-Document Sales Line";
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        EDocSalesDocHelper: Codeunit "E-Doc. Sales Doc. Helper";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesLineNo: Integer;
    begin
        EDocSalesHeader.GetFromEDocument(EDocument);
        EDocSalesHeader.TestField("E-Document Entry No.");

        if not EDocSalesDocHelper.AllDraftLinesHaveTypeAndNumber(EDocSalesHeader) then begin
            Telemetry.LogMessage('', 'Draft line does not contain type or number', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All);
            Error(DraftLineDoesNotContainTypeAndNumberErr);
        end;

        CheckForDuplicateSalesOrder(EDocSalesHeader);

        SalesHeader."Document Type" := "Sales Document Type"::Order;
        SalesHeader.Validate("Sell-to Customer No.", EDocSalesHeader."[BC] Customer No.");
        SalesHeader."External Document No." := CopyStr(EDocSalesHeader."Buyer Order No.", 1, MaxStrLen(SalesHeader."External Document No."));
        if EDocSalesHeader."Document Date" <> 0D then
            SalesHeader.Validate("Document Date", EDocSalesHeader."Document Date");
        if EDocSalesHeader."Requested Delivery Date" <> 0D then
            SalesHeader.Validate("Requested Delivery Date", EDocSalesHeader."Requested Delivery Date");
        if EDocSalesHeader."Customer Reference" <> '' then
            SalesHeader."Your Reference" := CopyStr(EDocSalesHeader."Customer Reference", 1, MaxStrLen(SalesHeader."Your Reference"));
        SalesHeader.Insert(true);

        GLSetup.GetRecordOnce();
        if EDocSalesHeader."Currency Code" <> GLSetup.GetCurrencyCode('') then
            SalesHeader.Validate("Currency Code", EDocSalesHeader."Currency Code");
        if EDocSalesHeader.Note <> '' then
            SalesHeader.SetWorkDescription(EDocSalesHeader.Note);
        SalesHeader.Modify();

        SalesLineNo := EDocSalesDocHelper.GetLastSalesLineNo(SalesHeader."Document Type", SalesHeader."No.");
        EDocSalesLine.GetFromEDocument(EDocument);
        if EDocSalesLine.FindSet() then
            repeat
                SalesLineNo += 10000;
                EDocSalesDocHelper.CreateSalesLineFromDraft(SalesHeader, EDocSalesLine, EDocSalesHeader."Total Discount" > 0, SalesLineNo);
            until EDocSalesLine.Next() = 0;

        SalesHeader.Modify();
        SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(EDocSalesHeader."Total Discount", SalesHeader);
        exit(SalesHeader);
    end;

    local procedure CheckForDuplicateSalesOrder(EDocSalesHeader: Record "E-Document Sales Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        if EDocSalesHeader."Buyer Order No." = '' then
            exit;
        SalesHeader.SetRange("Sell-to Customer No.", EDocSalesHeader."[BC] Customer No.");
        SalesHeader.SetRange("External Document No.", EDocSalesHeader."Buyer Order No.");
        SalesHeader.SetFilter("Document Type", '%1|%2', "Sales Document Type"::Order, "Sales Document Type"::"Blanket Order");
        if not SalesHeader.IsEmpty() then begin
            Telemetry.LogMessage('', StrSubstNo(DuplicateSalesOrderErr, EDocSalesHeader."Buyer Order No.", EDocSalesHeader."[BC] Customer No."), Verbosity::Error, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All);
            Error(DuplicateSalesOrderErr, EDocSalesHeader."Buyer Order No.", EDocSalesHeader."[BC] Customer No.");
        end;
    end;
}
