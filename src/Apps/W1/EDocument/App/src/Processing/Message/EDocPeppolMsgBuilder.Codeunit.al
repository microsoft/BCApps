// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.EServices.EDocument.Processing;
using Microsoft.EServices.EDocument.Processing.Import.Sales;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
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
/// changed quantities, delivery dates and prices, backorders, removed lines or lines the seller added for an ordered item
/// are reported as a conditional acceptance.
/// </summary>
codeunit 6434 "E-Doc. PEPPOL Msg. Builder" implements IEDocMessageBuilder, IEDocResponseMessageBuilder
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AcceptedTok: Label 'AP', Locked = true;
        AcknowledgedTok: Label 'AB', Locked = true;
        ConditionallyAcceptedTok: Label 'CA', Locked = true;
        LineAcceptedTok: Label '5', Locked = true;
        LineAddedTok: Label '1', Locked = true;
        LineChangedTok: Label '3', Locked = true;
        LineNotAcceptedTok: Label '7', Locked = true;
        RejectedTok: Label 'RE', Locked = true;
        MissingEndpointSchemeErr: Label 'The order response cannot be created because the electronic address %1 of %2 has no Peppol scheme. Specify the %3 on %4 %5, or use a GLN with %6.', Comment = '%1 = electronic address (e.g. a VAT registration no.), %2 = company or customer name, %3 = VAT Scheme field caption, %4 = Country/Region table caption, %5 = country/region code, %6 = Use GLN in Electronic Document field caption';

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
                CollectAddedLines(EDocSalesHeader, SalesHeader, TempAddedLine);
                if HasSellerChanges(EDocSalesHeader, SalesHeader) or not TempAddedLine.IsEmpty() then begin
                    ResponseType := "E-Doc. Response Type"::"Conditionally Accepted";
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

    local procedure HasSellerChanges(EDocSalesHeader: Record "E-Document Sales Header"; SalesHeader: Record "Sales Header"): Boolean
    var
        EDocSalesLine: Record "E-Document Sales Line";
        SalesLine: Record "Sales Line";
    begin
        if IsDeliveryDateChanged(EDocSalesHeader."Requested Delivery Date", GetSellerDeliveryDate(SalesHeader)) then
            exit(true);

        if not FindOrderLines(EDocSalesHeader, EDocSalesLine) then
            exit(false);
        repeat
            if GetLineStatusCode(EDocSalesHeader, EDocSalesLine, SalesHeader, SalesLine) <> LineAcceptedTok then
                exit(true);
        until EDocSalesLine.Next() = 0;
        exit(false);
    end;

    local procedure AddLineResponses(EDocSalesHeader: Record "E-Document Sales Header"; SalesHeader: Record "Sales Header"; var TempAddedLine: Record "Name/Value Buffer" temporary; var PEPPOLOrderRespBuilder: Codeunit "PEPPOL Order Resp. Builder")
    var
        EDocSalesLine: Record "E-Document Sales Line";
        SalesLine: Record "Sales Line";
        LineStatusCode: Code[10];
        BackorderQuantity: Decimal;
        ConfirmedQuantity: Decimal;
        UsedLineIds: List of [Text];
    begin
        if not FindOrderLines(EDocSalesHeader, EDocSalesLine) then
            exit;
        // Response line ids must be unique (PEPPOL-T76-R003); order lines keep their own id, added lines get a free one
        repeat
            UsedLineIds.Add(EDocSalesLine."External Line Id");
        until EDocSalesLine.Next() = 0;

        EDocSalesLine.FindSet();
        repeat
            LineStatusCode := GetLineStatusCode(EDocSalesHeader, EDocSalesLine, SalesHeader, SalesLine);
            PEPPOLOrderRespBuilder.AddLine(EDocSalesLine."External Line Id", LineStatusCode, GetItemName(EDocSalesLine, SalesLine));
            PEPPOLOrderRespBuilder.SetLineItemIdentification(EDocSalesLine."Buyer Item Id", GetSellersItemId(EDocSalesLine, SalesLine));
            if LineStatusCode <> LineNotAcceptedTok then begin
                ConfirmedQuantity := GetConfirmedQuantity(SalesHeader, SalesLine, BackorderQuantity);
                PEPPOLOrderRespBuilder.SetLineQuantity(ConfirmedQuantity, GetUnitCode(EDocSalesLine, SalesLine));
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
                    if IsPriceChanged(EDocSalesLine, SalesLine) then
                        PEPPOLOrderRespBuilder.SetLinePrice(SalesLine."Unit Price");
                end;
            end;
            AddAddedLineResponses(EDocSalesLine, SalesHeader, TempAddedLine, UsedLineIds, PEPPOLOrderRespBuilder);
        until EDocSalesLine.Next() = 0;
    end;

    local procedure CollectAddedLines(EDocSalesHeader: Record "E-Document Sales Header"; SalesHeader: Record "Sales Header"; var TempAddedLine: Record "Name/Value Buffer" temporary)
    var
        SalesLine: Record "Sales Line";
    begin
        // Sales lines not created from an order line were added by the seller; ID = sales line no., Name = order line they split.
        // Added lines of an item that was not ordered get no order line and are not collected.
        TempAddedLine.Reset();
        TempAddedLine.DeleteAll();
        if not HasSalesLineLinks(EDocSalesHeader."E-Document Entry No.") then
            exit;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        // Text lines and lines attached to another line (e.g. extended texts) are not order lines
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetRange("Attached to Line No.", 0);
        SalesLine.SetFilter(Quantity, '<>0');
        if SalesLine.FindSet() then
            repeat
                if not IsCreatedFromDraft(EDocSalesHeader."E-Document Entry No.", SalesLine) then begin
                    TempAddedLine.Init();
                    TempAddedLine.ID := SalesLine."Line No.";
                    TempAddedLine.Name := CopyStr(GetReferencedOrderLineId(EDocSalesHeader, SalesHeader, SalesLine), 1, MaxStrLen(TempAddedLine.Name));
                    if TempAddedLine.Name <> '' then
                        TempAddedLine.Insert();
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure GetReferencedOrderLineId(EDocSalesHeader: Record "E-Document Sales Header"; SalesHeader: Record "Sales Header"; AddedSalesLine: Record "Sales Line"): Text
    var
        EDocSalesLine: Record "E-Document Sales Line";
        OrderSalesLine: Record "Sales Line";
        PrecedingSameItemLineNo: Integer;
        FirstSameItemOrderLineId: Text;
        PrecedingSameItemOrderLineId: Text;
    begin
        // T76 status 1 extends an ordered line (cac:OrderLineReference is 1..1), e.g. part of it delivered later.
        // Only an added line of an ordered item is such a split; an item that was not ordered has no order line
        // to belong to, so it is left out of the response (empty result) rather than attached to an unrelated line.
        if not FindOrderLines(EDocSalesHeader, EDocSalesLine) then
            exit('');
        PrecedingSameItemLineNo := 0;
        repeat
            if FindLinkedSalesLine(EDocSalesLine, SalesHeader, OrderSalesLine) then
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
        NoOrderLine: Record "E-Document Sales Line";
        AddedSalesLine: Record "Sales Line";
        OrderSalesLine: Record "Sales Line";
    begin
        TempAddedLine.SetRange(Name, OrderEDocSalesLine."External Line Id");
        if TempAddedLine.FindSet() then
            repeat
                if AddedSalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", TempAddedLine.ID) then begin
                    // Added lines are splits of this order line, so they carry the ordered item's identifiers
                    PEPPOLOrderRespBuilder.AddLine(GetUniqueLineId(Format(AddedSalesLine."Line No."), UsedLineIds), OrderEDocSalesLine."External Line Id", LineAddedTok, GetItemName(OrderEDocSalesLine, AddedSalesLine));
                    PEPPOLOrderRespBuilder.SetLineItemIdentification(OrderEDocSalesLine."Buyer Item Id", GetSellersItemId(OrderEDocSalesLine, AddedSalesLine));
                    // The ordered unit only applies when the split uses the same unit of measure as the order line
                    if FindLinkedSalesLine(OrderEDocSalesLine, SalesHeader, OrderSalesLine) and (OrderSalesLine."Unit of Measure Code" = AddedSalesLine."Unit of Measure Code") then
                        PEPPOLOrderRespBuilder.SetLineQuantity(AddedSalesLine.Quantity, GetUnitCode(OrderEDocSalesLine, AddedSalesLine))
                    else
                        PEPPOLOrderRespBuilder.SetLineQuantity(AddedSalesLine.Quantity, GetUnitCode(NoOrderLine, AddedSalesLine));
                    if GetSellerDeliveryDate(AddedSalesLine) <> 0D then
                        PEPPOLOrderRespBuilder.SetLinePromisedDeliveryDate(GetSellerDeliveryDate(AddedSalesLine));
                    if AddedSalesLine."Unit Price" <> 0 then
                        PEPPOLOrderRespBuilder.SetLinePrice(AddedSalesLine."Unit Price");
                end;
            until TempAddedLine.Next() = 0;
        TempAddedLine.SetRange(Name);
    end;

    local procedure HasAddedLines(var TempAddedLine: Record "Name/Value Buffer" temporary; OrderLineId: Text) Result: Boolean
    begin
        TempAddedLine.SetRange(Name, OrderLineId);
        Result := not TempAddedLine.IsEmpty();
        TempAddedLine.SetRange(Name);
    end;

    local procedure IsCreatedFromDraft(EDocumentEntryNo: Integer; SalesLine: Record "Sales Line"): Boolean
    var
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        EDocRecordLink.SetRange("Target Table No.", Database::"Sales Line");
        EDocRecordLink.SetRange("Target SystemId", SalesLine.SystemId);
        EDocRecordLink.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocRecordLink.SetRange("Source Table No.", Database::"E-Document Sales Line");
        exit(not EDocRecordLink.IsEmpty());
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

    local procedure IsPriceChanged(EDocSalesLine: Record "E-Document Sales Line"; SalesLine: Record "Sales Line"): Boolean
    begin
        // An order without a price leaves the price to the seller, which is not a change
        if EDocSalesLine."Unit Price" = 0 then
            exit(false);
        exit(SalesLine."Unit Price" <> EDocSalesLine."Unit Price");
    end;

    local procedure FindOrderLines(EDocSalesHeader: Record "E-Document Sales Header"; var EDocSalesLine: Record "E-Document Sales Line"): Boolean
    begin
        // Line comparison relies on the links written when the sales order was created from the draft;
        // without them (e.g. a custom sales order creation) the seller's decision per line is unknown.
        if not HasSalesLineLinks(EDocSalesHeader."E-Document Entry No.") then
            exit(false);
        EDocSalesLine.SetRange("E-Document Entry No.", EDocSalesHeader."E-Document Entry No.");
        // Only lines received as cac:OrderLine can be referenced; document level charges have no line id
        EDocSalesLine.SetFilter("External Line Id", '<>%1', '');
        exit(EDocSalesLine.FindSet());
    end;

    local procedure GetLineStatusCode(EDocSalesHeader: Record "E-Document Sales Header"; EDocSalesLine: Record "E-Document Sales Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Code[10]
    var
        BackorderQuantity: Decimal;
    begin
        // UNCL1229 line status codes allowed in PEPPOL BIS 28 (T76).
        if not FindLinkedSalesLine(EDocSalesLine, SalesHeader, SalesLine) then
            exit(LineNotAcceptedTok);
        if SalesLine.Quantity = 0 then
            exit(LineNotAcceptedTok);
        if SalesLine.Quantity <> EDocSalesLine.Quantity then
            exit(LineChangedTok);
        GetConfirmedQuantity(SalesHeader, SalesLine, BackorderQuantity);
        if BackorderQuantity <> 0 then
            exit(LineChangedTok);
        if IsLineDeliveryDateChanged(EDocSalesHeader, EDocSalesLine, SalesLine) then
            exit(LineChangedTok);
        if IsPriceChanged(EDocSalesLine, SalesLine) then
            exit(LineChangedTok);

        exit(LineAcceptedTok);
    end;

    local procedure GetConfirmedQuantity(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var BackorderQuantity: Decimal): Decimal
    begin
        // A seller keeping the ordered quantity but shipping only part of it now backorders the rest.
        // Qty. to Ship of 0 is left out, as it is also what warehouse handling and blank default quantities produce.
        BackorderQuantity := 0;
        if (SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Partial) and
           (SalesLine."Quantity Shipped" = 0) and
           (SalesLine."Qty. to Ship" > 0) and (SalesLine."Qty. to Ship" < SalesLine.Quantity)
        then begin
            BackorderQuantity := SalesLine.Quantity - SalesLine."Qty. to Ship";
            exit(SalesLine."Qty. to Ship");
        end;
        exit(SalesLine.Quantity);
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

    local procedure HasSalesLineLinks(EDocumentEntryNo: Integer): Boolean
    var
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        EDocRecordLink.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocRecordLink.SetRange("Source Table No.", Database::"E-Document Sales Line");
        EDocRecordLink.SetRange("Target Table No.", Database::"Sales Line");
        exit(not EDocRecordLink.IsEmpty());
    end;

    local procedure FindLinkedSalesLine(EDocSalesLine: Record "E-Document Sales Line"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Boolean
    var
        EDocRecordLink: Record "E-Doc. Record Link";
    begin
        Clear(SalesLine);
        EDocRecordLink.SetRange("Source Table No.", Database::"E-Document Sales Line");
        EDocRecordLink.SetRange("Source SystemId", EDocSalesLine.SystemId);
        EDocRecordLink.SetRange("Target Table No.", Database::"Sales Line");
        if not EDocRecordLink.FindFirst() then
            exit(false);
        if not SalesLine.GetBySystemId(EDocRecordLink."Target SystemId") then
            exit(false);
        exit((SalesLine."Document Type" = SalesHeader."Document Type") and (SalesLine."Document No." = SalesHeader."No."));
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

    local procedure IsDeliveryDateChanged(RequestedDeliveryDate: Date; SellerDeliveryDate: Date): Boolean
    begin
        // A date the buyer did not ask for is not a change to the order
        if (RequestedDeliveryDate = 0D) or (SellerDeliveryDate = 0D) then
            exit(false);
        exit(RequestedDeliveryDate <> SellerDeliveryDate);
    end;

    local procedure GetUnitCode(EDocSalesLine: Record "E-Document Sales Line"; SalesLine: Record "Sales Line"): Text
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if EDocSalesLine."Unit of Measure" <> '' then
            exit(EDocSalesLine."Unit of Measure");
        if UnitOfMeasure.Get(SalesLine."Unit of Measure Code") then
            exit(UnitOfMeasure."International Standard Code");
    end;
}
