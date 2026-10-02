// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.EServices.EDocument.Processing;
using Microsoft.EServices.EDocument.Processing.Import.Sales;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Peppol;
using Microsoft.Peppol.Response;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Utilities;

/// <summary>
/// Builds a PEPPOL Order Response message payload for an inbound Sales Order that was read into draft.
/// Core-hosted implementation for the "PEPPOL Order Response" message type; delegates the XML
/// construction to the PEPPOL app's pure builder, passing only primitives.
/// When the order is accepted, the created sales order is compared with the order the buyer sent, so that
/// changed quantities, units, delivery dates and net prices, backorders, removed lines and lines the seller added
/// are reported as a conditional acceptance.
/// </summary>
codeunit 6434 "E-Doc. PEPPOL Msg. Builder" implements IEDocMessageBuilder, IEDocResponseMessageBuilder
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        TempOrderSalesLine: Record "Sales Line" temporary;
        HasDraftLinks: Boolean;
        UnitAmountPrecision: Decimal;
        SalesLineNoByDraftLine: Dictionary of [Guid, Integer];
        AcceptedTok: Label 'AP', Locked = true;
        AcknowledgedTok: Label 'AB', Locked = true;
        ConditionallyAcceptedTok: Label 'CA', Locked = true;
        LineAcceptedTok: Label '5', Locked = true;
        LineAddedTok: Label '1', Locked = true;
        LineChangedTok: Label '3', Locked = true;
        LineNotAcceptedTok: Label '7', Locked = true;
        MissingEndpointSchemeErr: Label 'The order response cannot be created because the electronic address %1 of %2 has no Peppol scheme. Specify the %3 on %4 %5, or use a GLN with %6.', Comment = '%1 = electronic address (e.g. a VAT registration no.), %2 = company or customer name, %3 = VAT Scheme field caption, %4 = Country/Region table caption, %5 = country/region code, %6 = Use GLN in Electronic Document field caption';
        RejectedTok: Label 'RE', Locked = true;
        UnorderedLinesNoteTxt: Label 'The seller added lines that were not in the order: %1', Comment = '%1 = list of added lines, e.g. 1908-S LONDON Swivel Chair, blue (2 PCS)';
        UnorderedLineTxt: Label '%1 %2 (%3 %4)', Comment = '%1 = item or account no., %2 = description, %3 = quantity, %4 = unit of measure code', Locked = true;
        CreatedSalesLineNos: List of [Integer];

    procedure BuildMessage(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob")
    begin
        BuildResponseMessage(EDocument, ResponseType, TempBlob);
    end;

    procedure BuildResponseMessage(EDocument: Record "E-Document"; RequestedResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob") ResponseType: Enum "E-Doc. Response Type"
    var
        EDocSalesHeader: Record "E-Document Sales Header";
        GLSetup: Record "General Ledger Setup";
        TempAddedLine: Record "Name/Value Buffer" temporary;
        SalesHeader: Record "Sales Header";
        PEPPOLOrderRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        HasSalesOrder: Boolean;
        CurrencyCode: Code[10];
        ResponseCode: Code[10];
        UnorderedLines: List of [Integer];
        OrderReferenceId: Text;
        ResponseId: Text;
        SalesOrderId: Text;
    begin
        EDocSalesHeader.GetFromEDocument(EDocument);

        OrderReferenceId := EDocSalesHeader."Buyer Order No.";
        if OrderReferenceId = '' then
            OrderReferenceId := Format(EDocSalesHeader."E-Document Entry No.");
        ResponseId := OrderReferenceId;

        // An acceptance is conditional only when the sales order differs from the order; CA without lines breaks PEPPOL-T76-R007
        ResponseType := RequestedResponseType;
        if ResponseType = "E-Doc. Response Type"::"Conditionally Accepted" then
            ResponseType := "E-Doc. Response Type"::Accepted;

        CurrencyCode := EDocSalesHeader."Currency Code";
        HasSalesOrder := GetSalesOrder(EDocument, SalesHeader);
        if HasSalesOrder then begin
            ResponseId := SalesHeader."No.";
            SalesOrderId := SalesHeader."No.";
            CurrencyCode := SalesHeader."Currency Code";
            if ResponseType = "E-Doc. Response Type"::Accepted then begin
                LoadSalesOrder(EDocSalesHeader."E-Document Entry No.", SalesHeader);
                CollectAddedLines(EDocSalesHeader, TempAddedLine, UnorderedLines);
                // CA must carry response lines, so it needs order lines to answer
                if HasOrderLines(EDocSalesHeader) and
                   (HasSellerChanges(EDocSalesHeader, SalesHeader) or not TempAddedLine.IsEmpty() or (UnorderedLines.Count() > 0))
                then begin
                    ResponseType := "E-Doc. Response Type"::"Conditionally Accepted";
                    PEPPOLOrderRespBuilder.SetNote(GetUnorderedLinesNote(UnorderedLines));
                    PEPPOLOrderRespBuilder.SetPromisedDeliveryDate(GetSellerDeliveryDate(SalesHeader));
                    AddLineResponses(EDocSalesHeader, SalesHeader, TempAddedLine, PEPPOLOrderRespBuilder);
                end;
            end;
        end;
        ResponseCode := ResponseTypeToCode(ResponseType);

        // cbc:DocumentCurrencyCode is mandatory; a blank currency in BC is the local currency
        GLSetup.GetRecordOnce();
        PEPPOLOrderRespBuilder.SetHeader(ResponseId, SalesOrderId, OrderReferenceId, ResponseCode, GLSetup.GetCurrencyCode(CurrencyCode), 0D);
        SetSellerParty(EDocSalesHeader, PEPPOLOrderRespBuilder);
        SetBuyerParty(EDocSalesHeader, SalesHeader, HasSalesOrder, PEPPOLOrderRespBuilder);
        PEPPOLOrderRespBuilder.Build(TempBlob);
    end;

    local procedure ResponseTypeToCode(ResponseType: Enum "E-Doc. Response Type"): Code[10]
    begin
        // UNCL4343 OrderResponseCode values allowed in PEPPOL BIS 28 (T76).
        case ResponseType of
            "E-Doc. Response Type"::Acknowledged:
                exit(AcknowledgedTok);
            "E-Doc. Response Type"::Accepted:
                exit(AcceptedTok);
            "E-Doc. Response Type"::"Conditionally Accepted":
                exit(ConditionallyAcceptedTok);
            "E-Doc. Response Type"::Rejected:
                exit(RejectedTok);
        end;
    end;

    local procedure GetSalesOrder(EDocument: Record "E-Document"; var SalesHeader: Record "Sales Header"): Boolean
    begin
        if EDocument."Document Record ID".TableNo() <> Database::"Sales Header" then
            exit(false);
        exit(SalesHeader.Get(EDocument."Document Record ID"));
    end;

    local procedure SetSellerParty(EDocSalesHeader: Record "E-Document Sales Header"; var PEPPOLOrderRespBuilder: Codeunit "PEPPOL Order Resp. Builder")
    var
        CompanyInformation: Record "Company Information";
        PEPPOLMgt: Codeunit "PEPPOL30";
        CompanyPartyName: Text;
        EndpointId: Text;
        EndpointSchemeId: Text;
        SellerName: Text;
    begin
        // Reply from the endpoint the buyer addressed the order to
        EndpointId := EDocSalesHeader."Seller Endpoint Id";
        EndpointSchemeId := EDocSalesHeader."Seller Endpoint Scheme Id";
        // cbc:EndpointID and its schemeID are mandatory (PEPPOL-T76-B01501, B01601): otherwise use the company's
        // Peppol identification (GLN or VAT registration no.) as for Peppol invoices, and stop when there is none
        CompanyInformation.Get();
        if (EndpointId = '') or (EndpointSchemeId = '') then begin
            PEPPOLMgt.GetAccountingSupplierPartyInfoBIS(EndpointId, EndpointSchemeId, CompanyPartyName);
            PEPPOLMgt.CheckCompanyPartyIdentification(EndpointId);
            CheckEndpointScheme(EndpointId, EndpointSchemeId, CompanyInformation.Name, CompanyInformation."Country/Region Code");
        end;

        SellerName := CompanyInformation.Name;
        if SellerName = '' then
            SellerName := EDocSalesHeader."Seller Company Name";
        PEPPOLOrderRespBuilder.SetSellerParty(EndpointId, EndpointSchemeId, SellerName);
    end;

    local procedure SetBuyerParty(EDocSalesHeader: Record "E-Document Sales Header"; SalesHeader: Record "Sales Header"; HasSalesOrder: Boolean; var PEPPOLOrderRespBuilder: Codeunit "PEPPOL Order Resp. Builder")
    var
        Customer: Record Customer;
        PEPPOLMgt: Codeunit "PEPPOL30";
        BuyerName: Text;
        CustomerPartyIdentificationID: Text;
        CustomerPartyIDSchemeID: Text;
        CustomerPartyName: Text;
        EndpointId: Text;
        EndpointSchemeId: Text;
    begin
        if not Customer.Get(EDocSalesHeader."[BC] Customer No.") then
            Clear(Customer);
        EndpointId := EDocSalesHeader."Buyer Endpoint Id";
        EndpointSchemeId := EDocSalesHeader."Buyer Endpoint Scheme Id";
        // cbc:EndpointID and its schemeID are mandatory (PEPPOL-T76-B02401): otherwise use the customer's
        // Peppol identification (GLN or VAT registration no.) as for Peppol invoices, and stop when there is none
        if (EndpointId = '') or (EndpointSchemeId = '') then begin
            EndpointId := '';
            if Customer."No." <> '' then begin
                if not HasSalesOrder then begin
                    Clear(SalesHeader);
                    SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
                end;
                PEPPOLMgt.GetAccountingCustomerPartyInfoBIS(SalesHeader, EndpointId, EndpointSchemeId, CustomerPartyIdentificationID, CustomerPartyIDSchemeID, CustomerPartyName);
            end;
            PEPPOLMgt.CheckCustomerPartyIdentification(EndpointId, Customer."No.");
            CheckEndpointScheme(EndpointId, EndpointSchemeId, Customer.Name, SalesHeader."Bill-to Country/Region Code");
        end;

        // PEPPOL-T76-R001: the buyer needs an official name or identifier
        BuyerName := EDocSalesHeader."Buyer Company Name";
        if BuyerName = '' then
            BuyerName := Customer.Name;
        PEPPOLOrderRespBuilder.SetBuyerParty(EndpointId, EndpointSchemeId, BuyerName);
    end;

    local procedure CheckEndpointScheme(EndpointId: Text; EndpointSchemeId: Text; PartyName: Text; CountryRegionCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        // A VAT registration no. gets its scheme from the country's VAT Scheme, which may not be set up;
        // an endpoint without schemeID breaks PEPPOL-T76-B01601/B02402 just like a missing endpoint
        if EndpointSchemeId <> '' then
            exit;
        if CountryRegionCode = '' then begin
            CompanyInformation.Get();
            CountryRegionCode := CompanyInformation."Country/Region Code";
        end;
        Error(MissingEndpointSchemeErr, EndpointId, PartyName, CountryRegion.FieldCaption("VAT Scheme"), CountryRegion.TableCaption(), CountryRegionCode, CompanyInformation.FieldCaption("Use GLN in Electronic Document"));
    end;

    #region Sales order snapshot

    local procedure LoadSalesOrder(EDocumentEntryNo: Integer; SalesHeader: Record "Sales Header")
    var
        Currency: Record Currency;
        EDocRecordLink: Record "E-Doc. Record Link";
        SalesLine: Record "Sales Line";
        SalesLineNoBySystemId: Dictionary of [Guid, Integer];
        SalesLineNo: Integer;
    begin
        // Read the sales order lines and the draft-to-sales-line links once, so the line comparison runs in memory
        TempOrderSalesLine.Reset();
        TempOrderSalesLine.DeleteAll();
        Clear(SalesLineNoByDraftLine);
        Clear(CreatedSalesLineNos);
        HasDraftLinks := false;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                TempOrderSalesLine := SalesLine;
                TempOrderSalesLine.Insert();
                SalesLineNoBySystemId.Add(SalesLine.SystemId, SalesLine."Line No.");
            until SalesLine.Next() = 0;

        EDocRecordLink.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocRecordLink.SetRange("Source Table No.", Database::"E-Document Sales Line");
        EDocRecordLink.SetRange("Target Table No.", Database::"Sales Line");
        EDocRecordLink.SetLoadFields("Source SystemId", "Target SystemId");
        if EDocRecordLink.FindSet() then
            repeat
                HasDraftLinks := true;
                // A link to a sales line that no longer exists means the seller removed the line
                if SalesLineNoBySystemId.Get(EDocRecordLink."Target SystemId", SalesLineNo) then begin
                    SalesLineNoByDraftLine.Set(EDocRecordLink."Source SystemId", SalesLineNo);
                    if not CreatedSalesLineNos.Contains(SalesLineNo) then
                        CreatedSalesLineNos.Add(SalesLineNo);
                end;
            until EDocRecordLink.Next() = 0;

        Currency.Initialize(SalesHeader."Currency Code");
        UnitAmountPrecision := Currency."Unit-Amount Rounding Precision";
    end;

    local procedure FindLinkedSalesLine(EDocSalesLine: Record "E-Document Sales Line"; var SalesLine: Record "Sales Line"): Boolean
    var
        SalesLineNo: Integer;
    begin
        Clear(SalesLine);
        if not SalesLineNoByDraftLine.Get(EDocSalesLine.SystemId, SalesLineNo) then
            exit(false);
        exit(GetOrderSalesLine(SalesLineNo, SalesLine));
    end;

    local procedure GetOrderSalesLine(SalesLineNo: Integer; var SalesLine: Record "Sales Line"): Boolean
    var
        TempLookupSalesLine: Record "Sales Line" temporary;
    begin
        // Look up through a separate view of the snapshot, so a loop over TempOrderSalesLine keeps its filters and position
        TempLookupSalesLine.Copy(TempOrderSalesLine, true);
        TempLookupSalesLine.Reset();
        TempLookupSalesLine.SetRange("Line No.", SalesLineNo);
        if not TempLookupSalesLine.FindFirst() then
            exit(false);
        SalesLine := TempLookupSalesLine;
        exit(true);
    end;

    local procedure FindOrderLines(EDocSalesHeader: Record "E-Document Sales Header"; var EDocSalesLine: Record "E-Document Sales Line"): Boolean
    begin
        EDocSalesLine.SetRange("E-Document Entry No.", EDocSalesHeader."E-Document Entry No.");
        // Only lines received as cac:OrderLine can be referenced; document level charges have no line id
        EDocSalesLine.SetFilter("External Line Id", '<>%1', '');
        exit(EDocSalesLine.FindSet());
    end;

    local procedure HasOrderLines(EDocSalesHeader: Record "E-Document Sales Header"): Boolean
    var
        EDocSalesLine: Record "E-Document Sales Line";
    begin
        EDocSalesLine.SetRange("E-Document Entry No.", EDocSalesHeader."E-Document Entry No.");
        EDocSalesLine.SetFilter("External Line Id", '<>%1', '');
        exit(not EDocSalesLine.IsEmpty());
    end;

    #endregion Sales order snapshot

    #region Seller decision

    local procedure HasSellerChanges(EDocSalesHeader: Record "E-Document Sales Header"; SalesHeader: Record "Sales Header"): Boolean
    var
        EDocSalesLine: Record "E-Document Sales Line";
        SalesLine: Record "Sales Line";
        PriceChanged: Boolean;
        BackorderQuantity: Decimal;
        ConfirmedQuantity: Decimal;
        NetPrice: Decimal;
        UnitCode: Text;
    begin
        if IsDeliveryDateChanged(EDocSalesHeader."Requested Delivery Date", GetSellerDeliveryDate(SalesHeader)) then
            exit(true);

        if not FindOrderLines(EDocSalesHeader, EDocSalesLine) then
            exit(false);
        repeat
            if AnalyzeOrderLine(EDocSalesHeader, EDocSalesLine, SalesHeader, SalesLine, ConfirmedQuantity, BackorderQuantity, UnitCode, NetPrice, PriceChanged) <> LineAcceptedTok then
                exit(true);
        until EDocSalesLine.Next() = 0;
        exit(false);
    end;

    local procedure AnalyzeOrderLine(EDocSalesHeader: Record "E-Document Sales Header"; EDocSalesLine: Record "E-Document Sales Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ConfirmedQuantity: Decimal; var BackorderQuantity: Decimal; var UnitCode: Text; var NetPrice: Decimal; var PriceChanged: Boolean): Code[10]
    var
        UnitChanged: Boolean;
        QtyToShip: Decimal;
        TotalQuantity: Decimal;
    begin
        // UNCL1229 line status codes allowed in PEPPOL BIS 28 (T76); quantities and price are in the ordered unit
        Clear(SalesLine);
        ConfirmedQuantity := 0;
        BackorderQuantity := 0;
        NetPrice := 0;
        PriceChanged := false;
        UnitCode := GetUnitCode(EDocSalesLine."Unit of Measure", '');

        // Without the links written when the sales order was created from the draft (e.g. a custom sales order creation)
        // the seller's decision per line is unknown: answer the line as ordered, so a header change still has lines (R007)
        if not HasDraftLinks then begin
            ConfirmedQuantity := EDocSalesLine.Quantity;
            exit(LineAcceptedTok);
        end;

        if not FindLinkedSalesLine(EDocSalesLine, SalesLine) then
            exit(LineNotAcceptedTok);
        if SalesLine.Quantity = 0 then
            exit(LineNotAcceptedTok);

        GetQuantitiesInOrderedUnit(EDocSalesLine, SalesLine, TotalQuantity, QtyToShip, UnitCode, UnitChanged);
        ConfirmedQuantity := TotalQuantity;
        if IsBackorder(SalesHeader, SalesLine) then begin
            ConfirmedQuantity := QtyToShip;
            BackorderQuantity := TotalQuantity - QtyToShip;
        end;
        PriceChanged := IsNetPriceChanged(EDocSalesLine, SalesHeader, SalesLine, TotalQuantity, NetPrice);

        if UnitChanged or (TotalQuantity <> EDocSalesLine.Quantity) or (BackorderQuantity <> 0) or PriceChanged then
            exit(LineChangedTok);
        if IsLineDeliveryDateChanged(EDocSalesHeader, EDocSalesLine, SalesLine) then
            exit(LineChangedTok);
        exit(LineAcceptedTok);
    end;

    local procedure GetQuantitiesInOrderedUnit(EDocSalesLine: Record "E-Document Sales Line"; SalesLine: Record "Sales Line"; var TotalQuantity: Decimal; var QtyToShip: Decimal; var UnitCode: Text; var UnitChanged: Boolean)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        UnitChanged := false;
        // The unit the sales line was created with: quantities are already in the ordered unit
        if (EDocSalesLine."[BC] Unit of Measure" = '') or (SalesLine."Unit of Measure Code" = EDocSalesLine."[BC] Unit of Measure") then begin
            TotalQuantity := SalesLine.Quantity;
            QtyToShip := SalesLine."Qty. to Ship";
            UnitCode := GetUnitCode(EDocSalesLine."Unit of Measure", SalesLine."Unit of Measure Code");
            exit;
        end;

        // The seller changed the unit: convert through the base quantity, so the quantity is stated in the buyer's unit
        if (SalesLine.Type = SalesLine.Type::Item) and ItemUnitOfMeasure.Get(SalesLine."No.", EDocSalesLine."[BC] Unit of Measure") then
            if ItemUnitOfMeasure."Qty. per Unit of Measure" <> 0 then begin
                TotalQuantity := Round(SalesLine."Quantity (Base)" / ItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001);
                QtyToShip := Round(SalesLine."Qty. to Ship (Base)" / ItemUnitOfMeasure."Qty. per Unit of Measure", 0.00001);
                UnitCode := GetUnitCode(EDocSalesLine."Unit of Measure", EDocSalesLine."[BC] Unit of Measure");
                exit;
            end;

        // Not convertible: state the current quantity in the current unit, never under the ordered unit code
        UnitChanged := true;
        TotalQuantity := SalesLine.Quantity;
        QtyToShip := SalesLine."Qty. to Ship";
        UnitCode := GetUnitCode('', SalesLine."Unit of Measure Code");
    end;

    local procedure IsBackorder(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"): Boolean
    begin
        // A seller keeping the ordered quantity but shipping only part of it now backorders the rest.
        // Qty. to Ship of 0 is left out, as it is also what warehouse handling and blank default quantities produce.
        exit((SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Partial) and
             (SalesLine."Quantity Shipped" = 0) and
             (SalesLine."Qty. to Ship" > 0) and (SalesLine."Qty. to Ship" < SalesLine.Quantity));
    end;

    local procedure IsNetPriceChanged(EDocSalesLine: Record "E-Document Sales Line"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Quantity: Decimal; var NetPrice: Decimal): Boolean
    var
        OrderedNetPrice: Decimal;
    begin
        // Compare the net price (after line discount) so a changed or removed discount is a change as well
        NetPrice := GetNetUnitPrice(SalesHeader, SalesLine, Quantity);
        OrderedNetPrice := GetOrderedNetUnitPrice(EDocSalesLine);
        // An order without a price leaves the price to the seller, which is not a change
        if OrderedNetPrice = 0 then
            exit(false);
        exit(Round(NetPrice, UnitAmountPrecision) <> Round(OrderedNetPrice, UnitAmountPrecision));
    end;

    local procedure GetOrderedNetUnitPrice(EDocSalesLine: Record "E-Document Sales Line"): Decimal
    begin
        if EDocSalesLine.Quantity = 0 then
            exit(0);
        if EDocSalesLine."Line Extension Amount" <> 0 then
            exit(EDocSalesLine."Line Extension Amount" / EDocSalesLine.Quantity);
        exit(EDocSalesLine."Unit Price" - EDocSalesLine."Line Discount Amount" / EDocSalesLine.Quantity);
    end;

    local procedure GetNetUnitPrice(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Quantity: Decimal): Decimal
    var
        LineAmount: Decimal;
    begin
        if Quantity = 0 then
            exit(0);
        // Order amounts are excluding VAT
        LineAmount := SalesLine."Line Amount";
        if SalesHeader."Prices Including VAT" then
            LineAmount := LineAmount / (1 + SalesLine."VAT %" / 100);
        exit(LineAmount / Quantity);
    end;

    local procedure IsLineDeliveryDateChanged(EDocSalesHeader: Record "E-Document Sales Header"; EDocSalesLine: Record "E-Document Sales Line"; SalesLine: Record "Sales Line"): Boolean
    var
        RequestedDeliveryDate: Date;
    begin
        RequestedDeliveryDate := EDocSalesLine."Requested Delivery Date";
        if RequestedDeliveryDate = 0D then
            RequestedDeliveryDate := EDocSalesHeader."Requested Delivery Date";

        if SalesLine."Promised Delivery Date" <> 0D then
            exit(IsDeliveryDateChanged(RequestedDeliveryDate, SalesLine."Promised Delivery Date"));
        if IsDeliveryDateChanged(RequestedDeliveryDate, SalesLine."Requested Delivery Date") then
            exit(true);

        // Dates BC calculated when the line was created moved, so the seller rescheduled the shipment
        if (EDocSalesLine."Created Shipment Date" <> 0D) and (SalesLine."Shipment Date" <> EDocSalesLine."Created Shipment Date") then
            exit(true);
        exit((EDocSalesLine."Created Planned Delivery Date" <> 0D) and (SalesLine."Planned Delivery Date" <> EDocSalesLine."Created Planned Delivery Date"));
    end;

    local procedure IsDeliveryDateChanged(RequestedDeliveryDate: Date; SellerDeliveryDate: Date): Boolean
    begin
        // A date the buyer did not ask for is not a change to the order
        if (RequestedDeliveryDate = 0D) or (SellerDeliveryDate = 0D) then
            exit(false);
        exit(RequestedDeliveryDate <> SellerDeliveryDate);
    end;

    local procedure GetSellerDeliveryDate(SalesHeader: Record "Sales Header"): Date
    begin
        if SalesHeader."Promised Delivery Date" <> 0D then
            exit(SalesHeader."Promised Delivery Date");
        exit(SalesHeader."Requested Delivery Date");
    end;

    local procedure GetSellerDeliveryDate(SalesLine: Record "Sales Line"): Date
    begin
        if SalesLine."Promised Delivery Date" <> 0D then
            exit(SalesLine."Promised Delivery Date");
        if SalesLine."Planned Delivery Date" <> 0D then
            exit(SalesLine."Planned Delivery Date");
        exit(SalesLine."Requested Delivery Date");
    end;

    #endregion Seller decision

    #region Response lines

    local procedure AddLineResponses(EDocSalesHeader: Record "E-Document Sales Header"; SalesHeader: Record "Sales Header"; var TempAddedLine: Record "Name/Value Buffer" temporary; var PEPPOLOrderRespBuilder: Codeunit "PEPPOL Order Resp. Builder")
    var
        EDocSalesLine: Record "E-Document Sales Line";
        SalesLine: Record "Sales Line";
        PriceChanged: Boolean;
        LineStatusCode: Code[10];
        BackorderQuantity: Decimal;
        ConfirmedQuantity: Decimal;
        NetPrice: Decimal;
        UsedLineIds: List of [Text];
        UnitCode: Text;
    begin
        if not FindOrderLines(EDocSalesHeader, EDocSalesLine) then
            exit;
        // Response line ids must be unique (PEPPOL-T76-R003); order lines keep their own id, added lines get a free one
        repeat
            UsedLineIds.Add(EDocSalesLine."External Line Id");
        until EDocSalesLine.Next() = 0;

        EDocSalesLine.FindSet();
        repeat
            LineStatusCode := AnalyzeOrderLine(EDocSalesHeader, EDocSalesLine, SalesHeader, SalesLine, ConfirmedQuantity, BackorderQuantity, UnitCode, NetPrice, PriceChanged);
            PEPPOLOrderRespBuilder.AddLine(EDocSalesLine."External Line Id", LineStatusCode, GetItemName(EDocSalesLine, SalesLine));
            PEPPOLOrderRespBuilder.SetLineItemIdentification(EDocSalesLine."Buyer Item Id", GetSellersItemId(EDocSalesLine, SalesLine));
            if LineStatusCode <> LineNotAcceptedTok then begin
                PEPPOLOrderRespBuilder.SetLineQuantity(ConfirmedQuantity, UnitCode);
                // T76: MaximumBackorderQuantity is 0 when the rest of a reduced line will not be delivered,
                // which is not the case when an added line delivers it
                if BackorderQuantity > 0 then
                    PEPPOLOrderRespBuilder.SetLineMaximumBackorderQuantity(BackorderQuantity)
                else
                    if (ConfirmedQuantity < EDocSalesLine.Quantity) and not HasAddedLines(TempAddedLine, EDocSalesLine."External Line Id") then
                        PEPPOLOrderRespBuilder.SetLineMaximumBackorderQuantity(0);
                if LineStatusCode = LineChangedTok then begin
                    if GetSellerDeliveryDate(SalesLine) <> 0D then
                        PEPPOLOrderRespBuilder.SetLinePromisedDeliveryDate(GetSellerDeliveryDate(SalesLine));
                    if PriceChanged then
                        PEPPOLOrderRespBuilder.SetLinePrice(Round(NetPrice, UnitAmountPrecision));
                end;
            end;
            AddAddedLineResponses(EDocSalesLine, SalesHeader, TempAddedLine, UsedLineIds, PEPPOLOrderRespBuilder);
        until EDocSalesLine.Next() = 0;
    end;

    local procedure CollectAddedLines(EDocSalesHeader: Record "E-Document Sales Header"; var TempAddedLine: Record "Name/Value Buffer" temporary; var UnorderedLines: List of [Integer])
    var
        TempCandidateSalesLine: Record "Sales Line" temporary;
        OrderLineId: Text;
    begin
        // Sales lines not created from an order line were added by the seller. A line of an ordered item is a split of that
        // order line (TempAddedLine: ID = sales line no., Name = order line); any other line is listed in the header note.
        TempAddedLine.Reset();
        TempAddedLine.DeleteAll();
        Clear(UnorderedLines);
        if not HasDraftLinks then
            exit;
        // Iterate a separate view of the snapshot: the order line lookups below must not move this loop
        TempCandidateSalesLine.Copy(TempOrderSalesLine, true);
        TempCandidateSalesLine.Reset();
        // Text lines and lines attached to another line (e.g. extended texts) are not order lines
        TempCandidateSalesLine.SetFilter(Type, '<>%1', TempCandidateSalesLine.Type::" ");
        TempCandidateSalesLine.SetRange("Attached to Line No.", 0);
        TempCandidateSalesLine.SetFilter(Quantity, '<>0');
        if TempCandidateSalesLine.FindSet() then
            repeat
                if not CreatedSalesLineNos.Contains(TempCandidateSalesLine."Line No.") then begin
                    OrderLineId := GetReferencedOrderLineId(EDocSalesHeader, TempCandidateSalesLine);
                    if OrderLineId <> '' then begin
                        TempAddedLine.Init();
                        TempAddedLine.ID := TempCandidateSalesLine."Line No.";
                        TempAddedLine.Name := CopyStr(OrderLineId, 1, MaxStrLen(TempAddedLine.Name));
                        TempAddedLine.Insert();
                    end else
                        UnorderedLines.Add(TempCandidateSalesLine."Line No.");
                end;
            until TempCandidateSalesLine.Next() = 0;
    end;

    local procedure GetReferencedOrderLineId(EDocSalesHeader: Record "E-Document Sales Header"; AddedSalesLine: Record "Sales Line"): Text
    var
        EDocSalesLine: Record "E-Document Sales Line";
        OrderSalesLine: Record "Sales Line";
        PrecedingSameItemLineNo: Integer;
        FirstSameItemOrderLineId: Text;
        PrecedingSameItemOrderLineId: Text;
    begin
        // T76 status 1 extends an ordered line (cac:OrderLineReference is 1..1), e.g. part of it delivered later.
        // Only an added line of an ordered item is such a split; an item that was not ordered has no order line to belong to.
        if not FindOrderLines(EDocSalesHeader, EDocSalesLine) then
            exit('');
        PrecedingSameItemLineNo := 0;
        repeat
            if FindLinkedSalesLine(EDocSalesLine, OrderSalesLine) then
                if IsSameItem(OrderSalesLine, AddedSalesLine) then begin
                    if FirstSameItemOrderLineId = '' then
                        FirstSameItemOrderLineId := EDocSalesLine."External Line Id";
                    if IsNearerPrecedingLine(OrderSalesLine, AddedSalesLine, PrecedingSameItemLineNo) then
                        PrecedingSameItemOrderLineId := EDocSalesLine."External Line Id";
                end;
        until EDocSalesLine.Next() = 0;

        // With several order lines of the item, the split belongs to the nearest one above it
        if PrecedingSameItemOrderLineId <> '' then
            exit(PrecedingSameItemOrderLineId);
        exit(FirstSameItemOrderLineId);
    end;

    local procedure IsNearerPrecedingLine(OrderSalesLine: Record "Sales Line"; AddedSalesLine: Record "Sales Line"; var PrecedingLineNo: Integer): Boolean
    begin
        if (OrderSalesLine."Line No." >= AddedSalesLine."Line No.") or (OrderSalesLine."Line No." <= PrecedingLineNo) then
            exit(false);
        PrecedingLineNo := OrderSalesLine."Line No.";
        exit(true);
    end;

    local procedure AddAddedLineResponses(OrderEDocSalesLine: Record "E-Document Sales Line"; SalesHeader: Record "Sales Header"; var TempAddedLine: Record "Name/Value Buffer" temporary; var UsedLineIds: List of [Text]; var PEPPOLOrderRespBuilder: Codeunit "PEPPOL Order Resp. Builder")
    var
        AddedSalesLine: Record "Sales Line";
        OrderSalesLine: Record "Sales Line";
    begin
        TempAddedLine.SetRange(Name, OrderEDocSalesLine."External Line Id");
        if TempAddedLine.FindSet() then
            repeat
                if GetOrderSalesLine(TempAddedLine.ID, AddedSalesLine) then begin
                    // Added lines are splits of this order line, so they carry the ordered item's identifiers
                    PEPPOLOrderRespBuilder.AddLine(GetUniqueLineId(Format(AddedSalesLine."Line No."), UsedLineIds), OrderEDocSalesLine."External Line Id", LineAddedTok, GetItemName(OrderEDocSalesLine, AddedSalesLine));
                    PEPPOLOrderRespBuilder.SetLineItemIdentification(OrderEDocSalesLine."Buyer Item Id", GetSellersItemId(OrderEDocSalesLine, AddedSalesLine));
                    // The ordered unit only applies when the split uses the same unit of measure as the order line
                    if FindLinkedSalesLine(OrderEDocSalesLine, OrderSalesLine) and (OrderSalesLine."Unit of Measure Code" = AddedSalesLine."Unit of Measure Code") then
                        PEPPOLOrderRespBuilder.SetLineQuantity(AddedSalesLine.Quantity, GetUnitCode(OrderEDocSalesLine."Unit of Measure", AddedSalesLine."Unit of Measure Code"))
                    else
                        PEPPOLOrderRespBuilder.SetLineQuantity(AddedSalesLine.Quantity, GetUnitCode('', AddedSalesLine."Unit of Measure Code"));
                    if GetSellerDeliveryDate(AddedSalesLine) <> 0D then
                        PEPPOLOrderRespBuilder.SetLinePromisedDeliveryDate(GetSellerDeliveryDate(AddedSalesLine));
                    if AddedSalesLine."Line Amount" <> 0 then
                        PEPPOLOrderRespBuilder.SetLinePrice(Round(GetNetUnitPrice(SalesHeader, AddedSalesLine, AddedSalesLine.Quantity), UnitAmountPrecision));
                end;
            until TempAddedLine.Next() = 0;
        TempAddedLine.SetRange(Name);
    end;

    local procedure GetUnorderedLinesNote(UnorderedLines: List of [Integer]) Note: Text
    var
        SalesLine: Record "Sales Line";
        SalesLineNo: Integer;
        LinesText: Text;
    begin
        // T76 has no response line for an item that was not ordered (cac:OrderLineReference is 1..1),
        // so the amendment is stated in the header note that clarifies the seller's decision
        foreach SalesLineNo in UnorderedLines do
            if GetOrderSalesLine(SalesLineNo, SalesLine) then begin
                if LinesText <> '' then
                    LinesText += '; ';
                LinesText += StrSubstNo(UnorderedLineTxt, SalesLine."No.", SalesLine.Description, Format(SalesLine.Quantity, 0, 9), SalesLine."Unit of Measure Code");
            end;
        if LinesText <> '' then
            Note := StrSubstNo(UnorderedLinesNoteTxt, LinesText);
    end;

    local procedure HasAddedLines(var TempAddedLine: Record "Name/Value Buffer" temporary; OrderLineId: Text) Result: Boolean
    begin
        TempAddedLine.SetRange(Name, OrderLineId);
        Result := not TempAddedLine.IsEmpty();
        TempAddedLine.SetRange(Name);
    end;

    local procedure IsSameItem(SalesLine: Record "Sales Line"; OtherSalesLine: Record "Sales Line"): Boolean
    begin
        exit((SalesLine.Type = OtherSalesLine.Type) and (SalesLine."No." = OtherSalesLine."No.") and (SalesLine."Variant Code" = OtherSalesLine."Variant Code"));
    end;

    local procedure GetUniqueLineId(BaseLineId: Text; var UsedLineIds: List of [Text]) LineId: Text
    var
        Suffix: Integer;
    begin
        LineId := BaseLineId;
        while UsedLineIds.Contains(LineId) do begin
            Suffix += 1;
            LineId := BaseLineId + '-' + Format(Suffix);
        end;
        UsedLineIds.Add(LineId);
    end;

    local procedure GetItemName(EDocSalesLine: Record "E-Document Sales Line"; SalesLine: Record "Sales Line"): Text
    begin
        // cac:Item/cbc:Name is mandatory; prefer the name the buyer ordered
        if EDocSalesLine.Description <> '' then
            exit(EDocSalesLine.Description);
        if SalesLine.Description <> '' then
            exit(SalesLine.Description);
        if EDocSalesLine."Seller Item Id" <> '' then
            exit(EDocSalesLine."Seller Item Id");
        exit(EDocSalesLine."Buyer Item Id");
    end;

    local procedure GetSellersItemId(EDocSalesLine: Record "E-Document Sales Line"; SalesLine: Record "Sales Line"): Text
    begin
        if EDocSalesLine."Seller Item Id" <> '' then
            exit(EDocSalesLine."Seller Item Id");
        if SalesLine.Type = SalesLine.Type::Item then
            exit(SalesLine."No.");
    end;

    local procedure GetUnitCode(OrderedUnitCode: Text; UnitOfMeasureCode: Code[10]): Text
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // The UN/ECE Rec 20 code the buyer ordered with, otherwise the international code of the BC unit
        if OrderedUnitCode <> '' then
            exit(OrderedUnitCode);
        if UnitOfMeasureCode = '' then
            exit('');
        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            exit(UnitOfMeasure."International Standard Code");
    end;

    #endregion Response lines
}
