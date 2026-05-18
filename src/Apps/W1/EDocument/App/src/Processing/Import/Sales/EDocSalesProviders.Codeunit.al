// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Log;

codeunit 6409 "E-Doc. Sales Providers" implements ICustomerProvider, ISalesLineProvider
{
    Access = Internal;

    var
        NoBuyerInformationErr: Label 'There is no buyer information in the source document. Verify that the source document is a sales order, and if it''s not, consider deleting this E-Document.';
        ItemRefBySellerIdReasonMsg: Label 'Item was matched by seller item no. %1.', Comment = '%1 - Seller Item Id';
        ItemRefByGtinReasonMsg: Label 'Item was matched by GTIN %1.', Comment = '%1 - GTIN';
        ItemRefByStdIdReasonMsg: Label 'Item was matched by standard item id (bar code) %1.', Comment = '%1 - Standard Item Id';
        ItemRefByBuyerIdReasonMsg: Label 'Item was matched by buyer item reference for customer %1.', Comment = '%1 - Customer No.';
        ItemRefSourceMsg: Label 'Item Reference %1', Comment = '%1 - Item Reference No.';
        ItemSourceMsg: Label 'Item %1', Comment = '%1 - Item No.';

    /// <summary>
    /// Resolves the customer for an inbound sales order. Tries, in order: Customer.GLN matched
    /// directly, Service Participant matched by buyer GLN, Customer."VAT Registration No." matched
    /// by buyer VAT ID, and Customer.Name exact match. Logs a warning when no buyer identification
    /// data is present in the document. Returns an empty record if no match is found.
    /// </summary>
    /// <param name="EDocument">The E-Document record containing buyer identification data.</param>
    /// <returns>The matching Customer record, or an empty record if no match is found.</returns>
    procedure GetCustomer(EDocument: Record "E-Document") Customer: Record Customer
    var
        EDocSalesHeader: Record "E-Document Sales Header";
        EDocErrorHelper: Codeunit "E-Document Error Helper";
        EDocumentImportHelper: Codeunit "E-Document Import Helper";
        ServiceParticipant: Record "Service Participant";
        EDocumentHasNoBuyerInformation: Boolean;
    begin
        EDocSalesHeader.GetFromEDocument(EDocument);

        EDocumentHasNoBuyerInformation :=
            (EDocSalesHeader."Buyer GLN" = '') and
            (EDocSalesHeader."Buyer VAT Id" = '') and
            (EDocSalesHeader."Buyer Company Id" = '') and
            (EDocSalesHeader."Buyer Company Name" = '') and
            (EDocSalesHeader."Buyer Address" = '') and
            (EDocSalesHeader."Buyer External Id" = '');

        if EDocumentHasNoBuyerInformation then begin
            if EDocument."Read into Draft Impl." <> "E-Doc. Read into Draft"::"Blank Draft" then
                EDocErrorHelper.LogWarningMessage(EDocument, EDocSalesHeader, EDocSalesHeader.FieldNo("[BC] Customer No."), NoBuyerInformationErr);
            exit;
        end;

        if EDocSalesHeader."Buyer GLN" <> '' then begin
            Customer.SetRange(GLN, EDocSalesHeader."Buyer GLN");
            if Customer.FindFirst() then
                exit;
            Clear(Customer);

            ServiceParticipant.SetRange("Participant Type", ServiceParticipant."Participant Type"::Customer);
            ServiceParticipant.SetRange("Participant Identifier", EDocSalesHeader."Buyer GLN");
            ServiceParticipant.SetRange(Service, EDocument.GetEDocumentService().Code);
            if not ServiceParticipant.FindFirst() then begin
                ServiceParticipant.SetRange(Service);
                if ServiceParticipant.FindFirst() then;
            end;
            if Customer.Get(ServiceParticipant.Participant) then
                exit;
        end;

        if EDocSalesHeader."Buyer External Id" <> '' then begin
            Clear(Customer);
            ServiceParticipant.SetRange("Participant Type", ServiceParticipant."Participant Type"::Customer);
            ServiceParticipant.SetRange("Participant Identifier", EDocSalesHeader."Buyer External Id");
            ServiceParticipant.SetRange(Service, EDocument.GetEDocumentService().Code);
            if not ServiceParticipant.FindFirst() then begin
                ServiceParticipant.SetRange(Service);
                if ServiceParticipant.FindFirst() then;
            end;
            if Customer.Get(ServiceParticipant.Participant) then
                exit;
        end;

        if EDocSalesHeader."Buyer VAT Id" <> '' then begin
            Clear(Customer);
            Customer.SetRange("VAT Registration No.", CopyStr(EDocSalesHeader."Buyer VAT Id", 1, MaxStrLen(Customer."VAT Registration No.")));
            if Customer.FindFirst() then
                exit;
        end;

        if EDocSalesHeader."Buyer Company Name" <> '' then begin
            Clear(Customer);
            if Customer.Get(EDocumentImportHelper.FindCustomerByNameAndAddress(EDocSalesHeader."Buyer Company Name", EDocSalesHeader."Buyer Address")) then
                exit;
        end;

        Clear(Customer);
    end;

    /// <summary>
    /// Resolves the Business Central item for a sales order draft line. Tries, in order:
    /// seller item ID matched directly to Item."No.", standard item ID matched via Item Reference
    /// (Bar Code/GTIN), and buyer item ID matched via Item Reference (Customer). Records telemetry
    /// and activity log reasoning for each successful match. Leaves the line type and number blank
    /// if no match is found.
    /// </summary>
    /// <param name="EDocumentSalesLine">The sales line record to resolve in place.</param>
    procedure GetSalesLine(var EDocumentSalesLine: Record "E-Document Sales Line")
    var
        EDocument: Record "E-Document";
        EDocSalesHeader: Record "E-Document Sales Header";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        EDocActivityLogSession: Codeunit "E-Doc. Activity Log Session";
        ActivityLog: Codeunit "Activity Log Builder";
        Item: Record Item;
        ItemReference: Record "Item Reference";
    begin
        EDocument.Get(EDocumentSalesLine."E-Document Entry No.");
        EDocSalesHeader.GetFromEDocument(EDocument);

        if EDocumentSalesLine."Seller Item Id" <> '' then
            if Item.Get(CopyStr(EDocumentSalesLine."Seller Item Id", 1, MaxStrLen(Item."No."))) then begin
                EDocumentSalesLine."[BC] Sales Line Type" := "Sales Line Type"::Item;
                EDocumentSalesLine.Validate("[BC] Sales Line No.", Item."No.");
                EDocImpSessionTelemetry.SetLineBool(EDocumentSalesLine.SystemId, 'Seller Item Id', true);
                SetActivityLog(EDocumentSalesLine.SystemId, EDocumentSalesLine.FieldNo("[BC] Sales Line No."), StrSubstNo(ItemRefBySellerIdReasonMsg, Item."No."), Item, Page::"Item Card", StrSubstNo(ItemSourceMsg, Item."No."), ActivityLog);
                EDocActivityLogSession.Set(EDocActivityLogSession.SellerItemIdTok(), ActivityLog);
                exit;
            end;

        if EDocumentSalesLine."Standard Item Id" <> '' then begin
            Item.SetRange(GTIN, CopyStr(EDocumentSalesLine."Standard Item Id", 1, MaxStrLen(Item.GTIN)));
            if Item.FindFirst() then begin
                EDocumentSalesLine."[BC] Sales Line Type" := "Sales Line Type"::Item;
                EDocumentSalesLine.Validate("[BC] Sales Line No.", Item."No.");
                EDocImpSessionTelemetry.SetLineBool(EDocumentSalesLine.SystemId, 'GTIN', true);
                SetActivityLog(EDocumentSalesLine.SystemId, EDocumentSalesLine.FieldNo("[BC] Sales Line No."), StrSubstNo(ItemRefByGtinReasonMsg, Item.GTIN), Item, Page::"Item Card", StrSubstNo(ItemSourceMsg, Item."No."), ActivityLog);
                EDocActivityLogSession.Set(EDocActivityLogSession.GtinTok(), ActivityLog);
                exit;
            end;
            Clear(Item);

            if GetSalesLineItemRef(EDocumentSalesLine, Enum::"Item Reference Type"::"Bar Code", '', CopyStr(EDocumentSalesLine."Standard Item Id", 1, MaxStrLen(ItemReference."Reference No.")), ItemReference) then begin
                EDocumentSalesLine."[BC] Sales Line Type" := "Sales Line Type"::Item;
                EDocumentSalesLine.Validate("[BC] Sales Line No.", ItemReference."Item No.");
                EDocumentSalesLine.Validate("[BC] Unit of Measure", ItemReference."Unit of Measure");
                EDocumentSalesLine.Validate("[BC] Variant Code", ItemReference."Variant Code");
                EDocumentSalesLine.Validate("[BC] Item Reference No.", ItemReference."Reference No.");
                EDocImpSessionTelemetry.SetLineBool(EDocumentSalesLine.SystemId, 'Item Reference', true);
                SetActivityLog(EDocumentSalesLine.SystemId, EDocumentSalesLine.FieldNo("[BC] Sales Line No."), StrSubstNo(ItemRefByStdIdReasonMsg, ItemReference."Reference No."), ItemReference, Page::"Item References", StrSubstNo(ItemRefSourceMsg, ItemReference."Reference No."), ActivityLog);
                EDocActivityLogSession.Set(EDocActivityLogSession.StandardItemIdTok(), ActivityLog);
                exit;
            end;
        end;

        if (EDocumentSalesLine."Buyer Item Id" <> '') and (EDocSalesHeader."[BC] Customer No." <> '') then
            if GetSalesLineItemRef(EDocumentSalesLine, Enum::"Item Reference Type"::Customer, EDocSalesHeader."[BC] Customer No.", CopyStr(EDocumentSalesLine."Buyer Item Id", 1, MaxStrLen(ItemReference."Reference No.")), ItemReference) then begin
                EDocumentSalesLine."[BC] Sales Line Type" := "Sales Line Type"::Item;
                EDocumentSalesLine.Validate("[BC] Sales Line No.", ItemReference."Item No.");
                EDocumentSalesLine.Validate("[BC] Unit of Measure", ItemReference."Unit of Measure");
                EDocumentSalesLine.Validate("[BC] Variant Code", ItemReference."Variant Code");
                EDocumentSalesLine.Validate("[BC] Item Reference No.", ItemReference."Reference No.");
                EDocImpSessionTelemetry.SetLineBool(EDocumentSalesLine.SystemId, 'Item Reference', true);
                SetActivityLog(EDocumentSalesLine.SystemId, EDocumentSalesLine.FieldNo("[BC] Sales Line No."), StrSubstNo(ItemRefByBuyerIdReasonMsg, EDocSalesHeader."[BC] Customer No."), ItemReference, Page::"Item References", StrSubstNo(ItemRefSourceMsg, ItemReference."Reference No."), ActivityLog);
                EDocActivityLogSession.Set(EDocActivityLogSession.BuyerItemRefTok(), ActivityLog);
            end;
    end;

    local procedure GetSalesLineItemRef(EDocumentSalesLine: Record "E-Document Sales Line"; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]; ReferenceNo: Code[50]; var ItemReference: Record "Item Reference"): Boolean
    var
        Item: Record Item;
    begin
        ItemReference.SetRange("Reference Type", ReferenceType);
        ItemReference.SetRange("Reference Type No.", ReferenceTypeNo);
        ItemReference.SetRange("Reference No.", ReferenceNo);
        ItemReference.SetRange("Unit of Measure", EDocumentSalesLine."[BC] Unit of Measure");
        ItemReference.SetFilter("Starting Date", '<= %1', WorkDate());
        ItemReference.SetFilter("Ending Date", '>= %1 | %2', WorkDate(), 0D);
        if ItemReference.FindSet() then
            repeat
                if ItemReference.HasValidUnitOfMeasure() then
                    exit(true);
            until ItemReference.Next() = 0;

        ItemReference.SetRange("Unit of Measure", '');
        if ItemReference.FindSet() then
            repeat
                if ItemReference.HasValidUnitOfMeasure() then
                    exit(true);
            until ItemReference.Next() = 0;

        ItemReference.SetRange("Unit of Measure");
        if ItemReference.FindFirst() then
            if Item.Get(ItemReference."Item No.") then
                exit(true);
    end;

    local procedure SetActivityLog(SystemId: Guid; FieldNo: Integer; Reasoning: Text[250]; RecordRef: RecordRef; PageId: Integer; RefTitle: Text[250]; ActivityLog: Codeunit "Activity Log Builder")
    begin
        ActivityLog
            .Init(Database::"E-Document Sales Line", FieldNo, SystemId)
            .SetExplanation(Reasoning)
            .SetReferenceSource(PageId, RecordRef)
            .SetReferenceTitle(RefTitle);
    end;
}
