// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Utilities;

codeunit 87 "Blanket Sales Order to Order"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        Cust: Record Customer;
        BlanketOrderSalesLine: Record "Sales Line";
        SalesLineOrder: Record "Sales Line";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        Reservation: Page Reservation;
        NextLineNo: Integer;
        ShouldRedistributeInvoiceAmount: Boolean;
        CreditLimitExceeded: Boolean;
        SuppressCommit: Boolean;
    begin
        OnBeforeRun(Rec, HideValidationDialog, SuppressCommit);

        Rec.TestField("Document Type", Rec."Document Type"::"Blanket Order");
        ShouldRedistributeInvoiceAmount := SalesCalcDiscountByType.ShouldRedistributeInvoiceDiscountAmount(Rec);

        Cust.Get(Rec."Sell-to Customer No.");
        CheckBlockedCustomer(Rec, Cust);

        Rec.ValidateSalesPersonOnSalesHeader(Rec, true, false);

        Rec.CheckForBlockedLines();

        if Rec.QtyToShipIsZero() then
            Error(Text002);

        SalesSetup.Get();

        CheckAvailability(Rec, SalesLine);

        OnRunOnAfterCheckAvailability(SalesLine, BlanketOrderSalesLine);

        CreditLimitExceeded := CreateSalesHeader(Rec, Cust."Prepayment %");

        BlanketOrderSalesLine.Reset();
        BlanketOrderSalesLine.SetRange("Document Type", Rec."Document Type");
        BlanketOrderSalesLine.SetRange("Document No.", Rec."No.");
        OnRunOnAfterBlanketOrderSalesLineSetFilters(BlanketOrderSalesLine);
        NextLineNo := 0;
        CreateSalesOrderLines(Rec, BlanketOrderSalesLine, SalesOrderHeader, SalesLineOrder, NextLineNo);

        ReserveSalesOrderLines(SalesOrderHeader, SalesLineOrder, TempSalesLine);

        OnAfterInsertAllSalesOrderLines(Rec, SalesOrderHeader);

        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then begin
            SalesOrderHeader."Posting Date" := 0D;
            SalesOrderHeader.Modify();
        end;
        SalesLineOrder.CalcSalesTaxLines(SalesOrderHeader, SalesLineOrder);

        if SalesSetup."Copy Comments Blanket to Order" then begin
            SalesCommentLine.CopyComments(
              SalesCommentLine."Document Type"::"Blanket Order".AsInteger(), SalesOrderHeader."Document Type".AsInteger(), Rec."No.", SalesOrderHeader."No.");
            RecordLinkManagement.CopyLinks(Rec, SalesOrderHeader);
        end;

        if not (ShouldRedistributeInvoiceAmount or SalesSetup."Calc. Inv. Discount") then
            SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(SalesOrderHeader);

        if (not HideValidationDialog) and (not CreditLimitExceeded) then
            CustCheckCreditLimit.BlanketSalesOrderToOrderCheck(SalesOrderHeader);

        OnBeforeReserveItemsManuallyLoop(Rec, SalesOrderHeader, TempSalesLine, SuppressCommit);
        if not SuppressCommit then
            Commit();

        if GuiAllowed then
            if TempSalesLine.Find('-') then
                if Confirm(Text003, true) then
                    repeat
                        Clear(Reservation);
                        Reservation.SetReservSource(TempSalesLine);
                        Reservation.RunModal();
                        Rec.Find();
                    until TempSalesLine.Next() = 0;

        OnAfterRun(Rec, SalesOrderHeader);
    end;

    var
        SalesOrderHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        HideValidationDialog: Boolean;

        QuantityCheckErr: Label '%1 of %2 %3 in %4 %5 cannot be more than %6.\%7\%8 - %9 = %6.', Comment = '%1: FIELDCAPTION("Qty. to Ship (Base)"); %2: Field(Type); %3: Field(No.); %4: FIELDCAPTION("Line No."); %5: Field(Line No.); %6: Decimal Qty Difference; %7: Text001; %8: Field(Outstanding Qty. (Base)); %9: Decimal Quantity On Orders';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 - Unposted %1 = Possible %2';
#pragma warning restore AA0470
        Text002: Label 'There is nothing to create.';
        Text003: Label 'Full automatic reservation was not possible.\Reserve items manually?';
#pragma warning restore AA0074

    procedure CreateSalesOrderLines(var SalesHeaderBlanketOrder: Record "Sales Header"; var SalesLineBlanketOrder: Record "Sales Line";
                                    var SalesHeaderOrder: Record "Sales Header"; var SalesLineOrder: Record "Sales Line"; var NextLineNo: Integer)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ATOLink: Record "Assemble-to-Order Link";
        PrepmtMgt: Codeunit "Prepayment Mgt.";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        QuantityOnOrders: Decimal;
        IsHandled: Boolean;
        ProcessLine: Boolean;
    begin
        if not SalesLineBlanketOrder.FindSet() then
            exit;

        repeat
            OnBeforeHandlingBlanketOrderSalesLine(SalesLineBlanketOrder);
            ProcessLine := (SalesLineBlanketOrder.Type = SalesLineBlanketOrder.Type::" ") or (SalesLineBlanketOrder."Qty. to Ship" <> 0);
            OnBeforeProcessBlanketOrderSalesLine(SalesLineBlanketOrder, ProcessLine);
            if ProcessLine then begin
                SalesLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
                SalesLine.SetRange("Blanket Order No.", SalesLineBlanketOrder."Document No.");
                SalesLine.SetRange("Blanket Order Line No.", SalesLineBlanketOrder."Line No.");
                OnRunOnAfterSalesLineSetFilters(SalesLine);
                QuantityOnOrders := 0;
                if SalesLine.FindSet() then
                    repeat
                        if (SalesLine."Document Type" = SalesLine."Document Type"::"Return Order") or
                           ((SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo") and
                            (SalesLine."Return Receipt No." = ''))
                        then
                            QuantityOnOrders := QuantityOnOrders - SalesLine."Outstanding Qty. (Base)"
                        else
                            if (SalesLine."Document Type" = SalesLine."Document Type"::Order) or
                               ((SalesLine."Document Type" = SalesLine."Document Type"::Invoice) and
                                (SalesLine."Shipment No." = ''))
                            then
                                QuantityOnOrders := QuantityOnOrders + SalesLine."Outstanding Qty. (Base)";
                    until SalesLine.Next() = 0;

                CheckBlanketOrderLineQuantity(SalesLineBlanketOrder, QuantityOnOrders);

                SalesLineOrder := SalesLineBlanketOrder;
                OnRunOnBeforeResetQuantityFields(SalesLineBlanketOrder, SalesLineOrder);
                ResetQuantityFields(SalesLineOrder);
                SalesLineOrder."Document Type" := SalesHeaderOrder."Document Type";
                SalesLineOrder."Document No." := SalesHeaderOrder."No.";
                SalesLineOrder."Blanket Order No." := SalesHeaderBlanketOrder."No.";
                SalesLineOrder."Blanket Order Line No." := SalesLineBlanketOrder."Line No.";
                if (SalesLineOrder."No." <> '') and (SalesLineOrder.Type <> SalesLineOrder.Type::" ") then begin
                    SalesLineOrder.Amount := 0;
                    SalesLineOrder."Amount Including VAT" := 0;
                    SalesOrderLineValidateQuantity(SalesLineOrder, SalesLineBlanketOrder);
                    SalesLineOrder.Validate("Shipment Date", SalesLineBlanketOrder."Shipment Date");
                    OnRunOnAfterSalesOrderLineValidateShipmentDate(SalesLineBlanketOrder, SalesLineOrder);
                    SalesLineOrder.Validate("Unit Price", SalesLineBlanketOrder."Unit Price");
                    SalesLineOrder."Allow Invoice Disc." := SalesLineBlanketOrder."Allow Invoice Disc.";
                    SalesLineOrder."Allow Line Disc." := SalesLineBlanketOrder."Allow Line Disc.";
                    SalesLineOrder.Validate("Line Discount %", SalesLineBlanketOrder."Line Discount %");
                    if (SalesLineOrder.Quantity <> 0) and (SalesLineBlanketOrder."Inv. Discount Amount" <> 0) then
                        SalesLineOrder.Validate(
                            "Inv. Discount Amount",
                            round(SalesLineBlanketOrder."Inv. Discount Amount" * (SalesLineBlanketOrder."Qty. to Ship" / SalesLineBlanketOrder.Quantity)));
                    OnRunOnBeforeSalesLineReserveTransferSaleLineToSalesLine(SalesLineBlanketOrder, SalesLineOrder);
                    SalesLineReserve.TransferSaleLineToSalesLine(
                      SalesLineBlanketOrder, SalesLineOrder, SalesLineBlanketOrder."Qty. to Ship (Base)");
                end;

                Customer.Get(SalesHeaderBlanketOrder."Sell-to Customer No.");
                if Customer."Prepayment %" <> 0 then
                    SalesLineOrder."Prepayment %" := Customer."Prepayment %";
                PrepmtMgt.SetSalesPrepaymentPct(SalesLineOrder, SalesHeaderOrder."Posting Date");
                SalesLineOrder.Validate("Prepayment %");

                SalesLineOrder."Shortcut Dimension 1 Code" := SalesLineBlanketOrder."Shortcut Dimension 1 Code";
                SalesLineOrder."Shortcut Dimension 2 Code" := SalesLineBlanketOrder."Shortcut Dimension 2 Code";
                SalesLineOrder."Dimension Set ID" := SalesLineBlanketOrder."Dimension Set ID";
                if ATOLink.AsmExistsForSalesLine(SalesLineBlanketOrder) then begin
                    SalesLineOrder."Qty. to Assemble to Order" := SalesLineOrder.Quantity;
                    SalesLineOrder."Qty. to Asm. to Order (Base)" := SalesLineOrder."Quantity (Base)";
                end;
                SalesLineOrder.DefaultDeferralCode();
                if IsSalesOrderLineToBeInserted(SalesLineOrder) then begin
                    OnBeforeInsertSalesOrderLine(SalesLineOrder, SalesHeaderOrder, SalesLineBlanketOrder, SalesHeaderBlanketOrder);
                    SalesLineOrder.Insert();
                    OnAfterInsertSalesOrderLine(SalesLineOrder, SalesHeaderOrder, SalesLineBlanketOrder, SalesHeaderBlanketOrder);
                end;

                if ATOLink.AsmExistsForSalesLine(SalesLineBlanketOrder) then
                    ATOLink.MakeAsmOrderLinkedToSalesOrderLine(SalesLineBlanketOrder, SalesLineOrder);

                IsHandled := false;
                OnRunOnBeforeValidateBlanketOrderSalesLineQtytoShip(SalesLineBlanketOrder, SalesLineOrder, SalesHeaderOrder, SalesHeaderBlanketOrder, IsHandled);
                if not IsHandled then
                    if SalesLineBlanketOrder."Qty. to Ship" <> 0 then begin
                        SalesLineBlanketOrder.Validate("Qty. to Ship", 0);
                        SalesLineBlanketOrder.Modify();
                    end;
            end;
        until SalesLineBlanketOrder.Next() = 0;
    end;

    procedure ReserveSalesOrderLines(SalesHeaderOrder: Record "Sales Header"; var SalesLineOrder: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
        TempSalesLine.DeleteAll();
        SalesLineOrder.SetRange("Document Type", SalesHeaderOrder."Document Type");
        SalesLineOrder.SetRange("Document No.", SalesHeaderOrder."No.");
        if SalesLineOrder.FindSet() then
            repeat
                AutoReserve(SalesLineOrder, TempSalesLine);
            until SalesLineOrder.Next() = 0;
    end;

    local procedure SalesOrderLineValidateQuantity(var SalesOrderLine: Record "Sales Line"; var BlanketOrderSalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesOrderLineValidateQuantity(SalesOrderLine, BlanketOrderSalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesOrderLine.Validate(Quantity, BlanketOrderSalesLine."Qty. to Ship");
    end;

    local procedure CheckBlockedCustomer(var SalesHeader: Record "Sales Header"; var Customer: Record Customer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlockedCustomer(SalesHeader, Customer, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        Customer.CheckBlockedCustOnDocs(Customer, SalesHeader."Document Type"::Order, true, false);
    end;

    local procedure CheckBlanketOrderLineQuantity(SalesLineBlanketOrder: Record "Sales Line"; QuantityOnOrders: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlanketOrderLineQuantity(SalesLineBlanketOrder, QuantityOnOrders, IsHandled);
        if IsHandled then
            exit;

        if (Abs(SalesLineBlanketOrder."Qty. to Ship (Base)" + QuantityOnOrders +
              SalesLineBlanketOrder."Qty. Shipped (Base)") >
            Abs(SalesLineBlanketOrder."Quantity (Base)")) or
           (SalesLineBlanketOrder."Quantity (Base)" * SalesLineBlanketOrder."Outstanding Qty. (Base)" < 0)
        then
            Error(
              QuantityCheckErr,
              SalesLineBlanketOrder.FieldCaption("Qty. to Ship (Base)"),
              SalesLineBlanketOrder.Type, SalesLineBlanketOrder."No.",
              SalesLineBlanketOrder.FieldCaption("Line No."), SalesLineBlanketOrder."Line No.",
              SalesLineBlanketOrder."Outstanding Qty. (Base)" - QuantityOnOrders,
              StrSubstNo(
                Text001,
                SalesLineBlanketOrder.FieldCaption("Outstanding Qty. (Base)"),
                SalesLineBlanketOrder.FieldCaption("Qty. to Ship (Base)")),
              SalesLineBlanketOrder."Outstanding Qty. (Base)", QuantityOnOrders);
    end;

    local procedure CreateSalesHeader(SalesHeader: Record "Sales Header"; PrepmtPercent: Decimal) CreditLimitExceeded: Boolean
    var
        StandardCodesMgt: Codeunit "Standard Codes Mgt.";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSalesHeader(SalesHeader, PrepmtPercent, CreditLimitExceeded, IsHandled, SalesOrderHeader);
        if IsHandled then
            exit(CreditLimitExceeded);

        if SalesSetup."Copy Comments Blanket to Order" then
            SalesHeader.CalcFields("Work Description");
        SalesOrderHeader := SalesHeader;
        SalesOrderHeader."Document Type" := SalesOrderHeader."Document Type"::Order;
        if not HideValidationDialog then
            CreditLimitExceeded := CustCheckCreditLimit.SalesHeaderCheck(SalesOrderHeader);

        SalesOrderHeader."No. Printed" := 0;
        SalesOrderHeader.Status := SalesOrderHeader.Status::Open;
        SalesOrderHeader."No." := '';

        OnBeforeInsertSalesOrderHeader(SalesOrderHeader, SalesHeader);
        StandardCodesMgt.SetSkipRecurringLines(true);
        SalesOrderHeader.SetStandardCodesMgt(StandardCodesMgt);
        SalesOrderHeader.Insert(true);
        OnCreateSalesHeaderOnAfterSalesOrderHeaderInsert(SalesHeader, SalesOrderHeader);

        if SalesHeader."Order Date" = 0D then
            SalesOrderHeader."Order Date" := WorkDate()
        else
            SalesOrderHeader."Order Date" := SalesHeader."Order Date";
        if SalesHeader."Posting Date" <> 0D then
            SalesOrderHeader."Posting Date" := SalesHeader."Posting Date";
        if SalesOrderHeader."Posting Date" = 0D then
            SalesOrderHeader."Posting Date" := WorkDate();

        SalesOrderHeader.InitFromSalesHeader(SalesHeader);
        OnCreateSalesHeaderOnAfterSalesOrderHeaderInitFromSalesHeader(SalesHeader, HideValidationDialog, SalesOrderHeader);
        SalesOrderHeader.Validate("Posting Date");
        SalesOrderHeader."Outbound Whse. Handling Time" := SalesHeader."Outbound Whse. Handling Time";
        SalesOrderHeader.Reserve := SalesHeader.Reserve;

        SalesOrderHeader."Prepayment %" := PrepmtPercent;

        OnBeforeSalesOrderHeaderModify(SalesOrderHeader, SalesHeader);
        SalesOrderHeader.Modify();
    end;

    local procedure ResetQuantityFields(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Quantity := 0;
        SalesLine."Quantity (Base)" := 0;
        SalesLine."Qty. Shipped Not Invoiced" := 0;
        SalesLine."Quantity Shipped" := 0;
        SalesLine."Quantity Invoiced" := 0;
        SalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        SalesLine."Qty. Shipped (Base)" := 0;
        SalesLine."Qty. Invoiced (Base)" := 0;
        SalesLine."Outstanding Quantity" := 0;
        SalesLine."Outstanding Qty. (Base)" := 0;

        OnAfterResetQuantityFields(SalesLine);
    end;

    procedure GetSalesOrderHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader := SalesOrderHeader;
    end;

    procedure SetSalesOrderHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesOrderHeader := SalesHeader;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure AutoReserve(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserve(SalesLine, TempSalesLine, IsHandled);
        if IsHandled then
            exit;

        if (SalesLine.Type = SalesLine.Type::Item) and
            (SalesLine.Reserve = SalesLine.Reserve::Always) and
            (SalesLine."No." <> '')
        then begin
            SalesLine.TestField("Shipment Date");
            ReservMgt.SetReservSource(SalesLine);
            ReservMgt.AutoReserve(FullAutoReservation, '', SalesLine."Shipment Date", SalesLine."Qty. to Ship", SalesLine."Qty. to Ship (Base)");
            SalesLine.Find();
            if not FullAutoReservation then begin
                TempSalesLine.TransferFields(SalesLine);
                TempSalesLine.Insert();
            end;
        end;
    end;

    local procedure CheckAvailability(BlanketOrderSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
        BlanketOrderSalesLine: Record "Sales Line";
        IsHandled: Boolean;
        ShouldCheckSalesLineItemAvailability: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAvailability(BlanketOrderSalesHeader, IsHandled);
        if IsHandled then
            exit;

        BlanketOrderSalesLine.SetRange("Document Type", BlanketOrderSalesHeader."Document Type");
        BlanketOrderSalesLine.SetRange("Document No.", BlanketOrderSalesHeader."No.");
        BlanketOrderSalesLine.SetRange(Type, BlanketOrderSalesLine.Type::Item);
        BlanketOrderSalesLine.SetFilter("No.", '<>%1', '');
        if BlanketOrderSalesLine.FindSet() then
            repeat
                if BlanketOrderSalesLine."Qty. to Ship" > 0 then begin
                    SalesLine := BlanketOrderSalesLine;
                    ResetQuantityFields(SalesLine);
                    SalesLine.Quantity := BlanketOrderSalesLine."Qty. to Ship";
                    SalesLine."Quantity (Base)" := Round(SalesLine.Quantity * SalesLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                    SalesLine."Qty. to Ship" := SalesLine.Quantity;
                    SalesLine."Qty. to Ship (Base)" := SalesLine."Quantity (Base)";
                    OnCheckAvailabilityOnBeforeSalesLineInitOutstanding(SalesLine, BlanketOrderSalesLine);
                    SalesLine.InitOutstanding();
                    if ATOLink.AsmExistsForSalesLine(BlanketOrderSalesLine) then begin
                        SalesLine."Qty. to Assemble to Order" := SalesLine.Quantity;
                        SalesLine."Qty. to Asm. to Order (Base)" := SalesLine."Quantity (Base)";
                        SalesLine."Outstanding Quantity" -= SalesLine."Qty. to Assemble to Order";
                        SalesLine."Outstanding Qty. (Base)" -= SalesLine."Qty. to Asm. to Order (Base)";
                    end;

                    ShouldCheckSalesLineItemAvailability := not HideValidationDialog;
                    OnCheckAvailabilityOnAfterCalcShouldCheckSalesLineItemAvailability(BlanketOrderSalesHeader, SalesLine, ShouldCheckSalesLineItemAvailability);
                    if ShouldCheckSalesLineItemAvailability then
                        CheckSalesLineItemAvailability(BlanketOrderSalesHeader, SalesLine);
                end;
            until BlanketOrderSalesLine.Next() = 0;
    end;

    local procedure CheckSalesLineItemAvailability(BlanketOrderSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLineItemAvailability(SalesLine, IsHandled, BlanketOrderSalesHeader);
        if IsHandled then
            exit;

        if ItemCheckAvail.SalesLineCheck(SalesLine) then
            ItemCheckAvail.RaiseUpdateInterruptedError();
    end;

    local procedure IsSalesOrderLineToBeInserted(SalesOrderLine: Record "Sales Line"): Boolean
    var
        AttachedToSalesLine: Record "Sales Line";
    begin
        if not SalesOrderLine.IsExtendedText() then
            exit(true);

        exit(
          AttachedToSalesLine.Get(
            SalesOrderLine."Document Type", SalesOrderLine."Document No.", SalesOrderLine."Attached to Line No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedCustomer(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var SalesHeader: Record "Sales Header"; var HideValidationDialog: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderHeader(var SalesOrderHeader: Record "Sales Header"; var BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesLine: Record "Sales Line"; BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesOrderLine(var SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesLine: Record "Sales Line"; BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllSalesOrderLines(var BlanketOrderSalesHeader: Record "Sales Header"; var OrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetQuantityFields(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlanketOrderLineQuantity(var BlanketOrderSalesLine: Record "Sales Line"; QuantityOnOrders: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLineItemAvailability(var SalesLine: Record "Sales Line"; var IsHandled: Boolean; BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailability(BlanketOrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesHeader(var SalesHeader: Record "Sales Header"; PrepmtPercent: Decimal; var CreditLimitExceeded: Boolean; var IsHandled: Boolean; var OrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandlingBlanketOrderSalesLine(var BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesOrderLineValidateQuantity(var SalesOrderLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesOrderHeaderModify(var SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReserveItemsManuallyLoop(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAvailabilityOnAfterCalcShouldCheckSalesLineItemAvailability(BlanketOrderSalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ShouldCheckSalesLineItemAvailability: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckAvailabilityOnBeforeSalesLineInitOutstanding(var SalesLine: Record "Sales Line"; BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesHeaderOnAfterSalesOrderHeaderInitFromSalesHeader(var SalesHeader: Record "Sales Header"; HideValidationDialog: Boolean; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterBlanketOrderSalesLineSetFilters(var BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesOrderLineValidateShipmentDate(BlanketOrderSalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSalesLineReserveTransferSaleLineToSalesLine(var BlanketOrderSalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeResetQuantityFields(var BlanketOrderSalesLine: Record "Sales Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeValidateBlanketOrderSalesLineQtytoShip(var BlanketOrderSalesLine: Record "Sales Line"; SalesOrderLine: Record "Sales Line"; SalesOrderHeader: Record "Sales Header"; BlanketOrderSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesHeaderOnAfterSalesOrderHeaderInsert(SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterCheckAvailability(var SalesLine: Record "Sales Line"; var BlanketOrderSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessBlanketOrderSalesLine(var BlanketOrderSalesLine: Record "Sales Line"; var ProcessLine: Boolean);
    begin
    end;
}

