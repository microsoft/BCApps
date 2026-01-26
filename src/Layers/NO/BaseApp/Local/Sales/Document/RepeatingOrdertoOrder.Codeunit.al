// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Availability;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;

codeunit 15000300 "Repeating Order to Order"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        OnBeforeOnRun(Rec);

        Rec.TestField("Document Type", Rec."Document Type"::"Blanket Order");

        if Rec."Order Date" > ProcessingDate then
            Error(Text15000300, Rec."No.", Rec."Order Date", ProcessingDate);
        RecurringGroup.Get(Rec."Recurring Group Code");
        RecurringGroup.TestField("Date formula");
        if (RecurringGroup."Starting date" > ProcessingDate) or
           ((RecurringGroup."Closing date" < ProcessingDate) and (RecurringGroup."Closing date" <> 0D))
        then
            Error(Text15000301, Rec."No.", ProcessingDate, RecurringGroup.Code, RecurringGroup."Starting date", RecurringGroup."Closing date");
        Rec.TestField("Deactivate recurrence", false);
        Rec.TestField("Order Date");

        SalesSetup.Get();

        BlanketOrderSalesLine.SetRange("Document Type", Rec."Document Type");
        BlanketOrderSalesLine.SetRange("Document No.", Rec."No.");
        BlanketOrderSalesLine.SetRange(Type, BlanketOrderSalesLine.Type::Item);
        BlanketOrderSalesLine.SetFilter("No.", '<>%1', '');
        if BlanketOrderSalesLine.Find('-') then
            repeat
                if BlanketOrderSalesLine."Qty. to Ship" > 0 then begin
                    SalesLine := BlanketOrderSalesLine;
                    SalesLine."Line No." := 0;
                    ResetQuantityFields(SalesLine);
                    SalesLine.Quantity := BlanketOrderSalesLine."Qty. to Ship";
                    SalesLine."Quantity (Base)" := Round(SalesLine.Quantity * SalesLine."Qty. per Unit of Measure", 0.00001);
                    SalesLine."Qty. to Ship" := SalesLine.Quantity;
                    SalesLine."Qty. to Ship (Base)" := SalesLine."Quantity (Base)";
                    SalesLine.InitOutstanding();
                    if SalesLine.Reserve <> SalesLine.Reserve::Always then
                        if not HideValidationDialog then
                            ItemCheckAvail.SalesLineCheck(SalesLine);
                end;
            until BlanketOrderSalesLine.Next() = 0;

        // To create only the latest orders, order date should be the latest possible
        if CreateLatest or RecurringGroup."Create only the latest" then begin
            NextOrderDate := Rec."Order Date";
            repeat
                Rec.Validate("Order Date", NextOrderDate);
                NextOrderDate := CalcDate(RecurringGroup."Date formula", Rec."Order Date");
            // Stop if the date is overwritten or not moved (Date formula is for inst. 0D):
            until (NextOrderDate > ProcessingDate) or (NextOrderDate = Rec."Order Date");
        end else
            NextOrderDate := CalcDate(RecurringGroup."Date formula", Rec."Order Date");

        SalesOrderHeader := Rec;
        SalesOrderHeader."Document Type" := SalesOrderHeader."Document Type"::Order;
        if not HideValidationDialog then
            CustCheckCreditLimit.SalesHeaderCheck(SalesOrderHeader);

        SalesOrderHeader."No. Printed" := 0;
        SalesOrderHeader.Status := SalesOrderHeader.Status::Open;
        SalesOrderHeader."No." := '';

        SalesOrderLine.LockTable();
        SalesOrderHeader.Insert(true);

        SalesOrderHeader."Dimension Set ID" := Rec."Dimension Set ID";
        SalesOrderHeader."Order Date" := Rec."Order Date";
        // Manage the dates as descrpied in the setup
        // if Rec."Posting Date" <> 0D then
        //   SalesOrderHeader."Posting Date" := "Posting Date";
        SalesOrderHeader."Posting Date" := Rec."Order Date";
        case RecurringGroup."Update Document Date" of
            RecurringGroup."Update Document Date"::"Posting Date":
                SalesOrderHeader.Validate("Document Date", CalcDate(RecurringGroup."Document Date Formula", SalesOrderHeader."Posting Date"));
            RecurringGroup."Update Document Date"::"Processing Date":
                SalesOrderHeader.Validate("Document Date", CalcDate(RecurringGroup."Document Date Formula", ProcessingDate));
        end;
        SalesOrderHeader."VAT Reporting Date" := GLSetup.GetVATDate(SalesOrderHeader."Posting Date", SalesOrderHeader."Document Date");
        SalesOrderHeader.Validate("Shipment Date", CalcDate(RecurringGroup."Delivery Date Formula", SalesOrderHeader."Posting Date"));
        // SalesOrderHeader."Document Date" := "Document Date";
        // SalesOrderHeader."Shipment Date" := "Shipment Date";
        SalesOrderHeader."Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";
        SalesOrderHeader."Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";
        SalesOrderHeader.Modify();

        BlanketOrderSalesLine.Reset();
        BlanketOrderSalesLine.SetRange("Document Type", Rec."Document Type");
        BlanketOrderSalesLine.SetRange("Document No.", Rec."No.");

        LinesCreated := false;
        if BlanketOrderSalesLine.Find('-') then
            repeat
                SalesLine.SetCurrentKey("Document Type", "Blanket Order No.", "Blanket Order Line No.");
                SalesLine.SetRange("Blanket Order No.", BlanketOrderSalesLine."Document No.");
                SalesLine.SetRange("Blanket Order Line No.", BlanketOrderSalesLine."Line No.");
                QuantityOnOrders := 0;
                if SalesLine.Find('-') and (RecurringGroup."Update Number" = RecurringGroup."Update Number"::Reduce) then
                    repeat
                        if SalesLine."Document Type" in
                          [SalesLine."Document Type"::"Return Order",
                           SalesLine."Document Type"::"Credit Memo"]
                        then
                            QuantityOnOrders := QuantityOnOrders - SalesLine."Outstanding Qty. (Base)"
                        else
                            QuantityOnOrders := QuantityOnOrders + SalesLine."Outstanding Qty. (Base)";
                    until SalesLine.Next() = 0;
                if (Abs(BlanketOrderSalesLine."Qty. to Ship (Base)") + Abs(QuantityOnOrders) >
                    Abs(BlanketOrderSalesLine."Quantity (Base)")) or
                   (BlanketOrderSalesLine."Quantity (Base)" * BlanketOrderSalesLine."Outstanding Qty. (Base)" < 0)
                then
                    Error(
                      Text000 + '%6\' + '%7 - %8 = %9',
                      BlanketOrderSalesLine.FieldCaption("Qty. to Ship (Base)"),
                      BlanketOrderSalesLine.Type, BlanketOrderSalesLine."No.",
                      BlanketOrderSalesLine.FieldCaption("Line No."), BlanketOrderSalesLine."Line No.",
                      StrSubstNo(
                        Text001,
                        BlanketOrderSalesLine.FieldCaption("Outstanding Qty. (Base)"),
                        BlanketOrderSalesLine.FieldCaption("Qty. to Ship (Base)")),
                      BlanketOrderSalesLine."Outstanding Qty. (Base)", QuantityOnOrders,
                      BlanketOrderSalesLine."Outstanding Qty. (Base)" - QuantityOnOrders);
                SalesOrderLine := BlanketOrderSalesLine;
                ResetQuantityFields(SalesOrderLine);
                SalesOrderLine."Document Type" := SalesOrderHeader."Document Type";
                SalesOrderLine."Document No." := SalesOrderHeader."No.";
                if (SalesOrderLine."No." <> '') and (SalesOrderLine.Type <> "Sales Line Type"::" ") then begin
                    SalesOrderLine.Amount := 0;
                    SalesOrderLine."Amount Including VAT" := 0;
                    SalesOrderLine.Validate(Quantity, BlanketOrderSalesLine."Qty. to Ship");
                    SalesOrderLine.Validate("Shipment Date", BlanketOrderSalesLine."Shipment Date");
                    SalesOrderLine.Validate("Unit Price", BlanketOrderSalesLine."Unit Price");
                    SalesOrderLine."Allow Invoice Disc." := BlanketOrderSalesLine."Allow Invoice Disc.";
                    SalesOrderLine."Allow Line Disc." := BlanketOrderSalesLine."Allow Line Disc.";
                    SalesOrderLine.Validate("Line Discount %", BlanketOrderSalesLine."Line Discount %");
                    SalesLineReserve.TransferSaleLineToSalesLine(
                      BlanketOrderSalesLine, SalesOrderLine, BlanketOrderSalesLine."Outstanding Qty. (Base)");
                end;
                SalesOrderLine."Shortcut Dimension 1 Code" := BlanketOrderSalesLine."Shortcut Dimension 1 Code";
                SalesOrderLine."Shortcut Dimension 2 Code" := BlanketOrderSalesLine."Shortcut Dimension 2 Code";
                case RecurringGroup."Update Price" of
                    RecurringGroup."Update Price"::Fixed:
                        ; // Price remained unchanged. No action is taken.
                    RecurringGroup."Update Price"::Recalculate:
                        if SalesOrderLine.Type in [SalesOrderLine.Type::Item, SalesOrderLine.Type::Resource] then begin
                            StoreNumber := SalesOrderLine.Quantity;
                            UpdateUnitPrice();
                            SalesOrderLine.Validate(Quantity, StoreNumber);
                        end;
                    RecurringGroup."Update Price"::Reset:
                        SalesOrderLine.Validate("Unit Price", 0);
                end;
                SalesOrderLine."Dimension Set ID" := BlanketOrderSalesLine."Dimension Set ID";
                SalesOrderLine.Insert();

                if BlanketOrderSalesLine."Qty. to Ship" <> 0 then begin
                    LinesCreated := true;
                    // Deleted: BlanketOrderSalesLine.VALIDATE("Qty. to Ship",0);
                    case RecurringGroup."Update Number" of
                        RecurringGroup."Update Number"::Constant:
                            ; // "Deliver (number)" is unchanged - no action is taken.
                        RecurringGroup."Update Number"::Reduce:
                            BlanketOrderSalesLine.Validate("Qty. to Ship", 0); // This is the usual procedure
                    end;
                    BlanketOrderSalesLine.Modify();
                end;
            until BlanketOrderSalesLine.Next() = 0;

        if not LinesCreated then
            Error(Text002);

        if SalesSetup."Copy Comments Blanket to Order" then begin
            SalesCommentLine.SetRange("Document Type", SalesCommentLine."Document Type"::"Blanket Order");
            SalesCommentLine.SetRange("No.", Rec."No.");
            if SalesCommentLine.Find('-') then
                repeat
                    SalesCommentLine2 := SalesCommentLine;
                    SalesCommentLine2."Document Type" := SalesOrderHeader."Document Type";
                    SalesCommentLine2."No." := SalesOrderHeader."No.";
                    SalesCommentLine2.Insert();
                until SalesCommentLine.Next() = 0;
        end;

        Rec.Validate("Order Date", NextOrderDate);
        Rec.Modify();
        CreatePost(Rec, SalesOrderHeader);

        Commit();
        Clear(CustCheckCreditLimit);
        Clear(ItemCheckAvail);
    end;

    var
        Text000: Label '%1 of %2 %3 in %4 %5 cannot be more than %9.\', Comment = 'Parameter 1 - qty to ship (base) field caption, 2 - Line Type, 3 - Line No, 4 - Line No caption, 5 - Line no';
        Text001: Label '%1 - Unposted %1 = Possible %2';
        Text002: Label 'There are no lines to create.';
        BlanketOrderSalesLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
        SalesCommentLine2: Record "Sales Comment Line";
        SalesSetup: Record "Sales & Receivables Setup";
        RecurringGroup: Record "Recurring Group";
        CustCheckCreditLimit: Codeunit "Cust-Check Cr. Limit";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        LinesCreated: Boolean;
        HideValidationDialog: Boolean;
        QuantityOnOrders: Decimal;
        ProcessingDate: Date;
        StoreNumber: Decimal;
        CreateLatest: Boolean;
        NextOrderDate: Date;
        PostDate: Date;
        PostTime: Time;
        Text15000300: Label 'Recurring order %1 could not be created.\Order date %2 is after the processing date %3.';
        Text15000301: Label 'Recurring order %1 could not be created.\Processing date is %2 and the recurring group %3 is only active in the period %4..%5.', Comment = 'Parameter 1 - Sales header No., 2 - posting date, 3 - code, 4 - starting date, 5 - closing date';

    [Scope('OnPrem')]
    procedure ResetQuantityFields(var TempSalesLine: Record "Sales Line")
    begin
        TempSalesLine."Qty. Shipped Not Invoiced" := 0;
        TempSalesLine."Quantity Shipped" := 0;
        TempSalesLine."Quantity Invoiced" := 0;
        TempSalesLine."Qty. Shipped Not Invd. (Base)" := 0;
        TempSalesLine."Qty. Shipped (Base)" := 0;
        TempSalesLine."Qty. Invoiced (Base)" := 0;
    end;

    [Scope('OnPrem')]
    procedure GetSalesOrderHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader := SalesOrderHeader;
    end;

    [Scope('OnPrem')]
    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    [Scope('OnPrem')]
    procedure Initialize(NewProcessingDate: Date; NewCreateLatest: Boolean)
    begin
        ProcessingDate := NewProcessingDate;
        CreateLatest := NewCreateLatest;
        PostDate := Today;
        PostTime := Time;
    end;

    local procedure UpdateUnitPrice()
    var
        SalesHeader: Record "Sales Header";
        PriceCalculation: Interface "Price Calculation";
        CalledByFieldNo: Integer;
    begin
        // Init to be able to use the code from table 37 (see Note).
        SalesHeader := SalesOrderHeader;
        CalledByFieldNo := SalesOrderLine.FieldNo("No.");

        // Note >>: This is a copy of code from function "UpdateUnitPriceByField" on table 37.
        SalesOrderLine.TestField("Qty. per Unit of Measure");

        case SalesOrderLine.Type of
            SalesOrderLine.Type::Item, SalesOrderLine.Type::Resource:
                begin
                    SalesOrderLine.GetPriceCalculationHandler("Price Type"::Sale, SalesHeader, PriceCalculation);
                    if not (SalesOrderLine."Copied From Posted Doc." and SalesOrderLine.IsCreditDocType()) then begin
                        PriceCalculation.ApplyDiscount();
                        SalesOrderLine.ApplyPrice(CalledByFieldNo, PriceCalculation);
                    end;
                end;
            SalesOrderLine.Type::"Charge (Item)":
                SalesOrderLine.UpdateItemChargeAssgnt();
        end;
        SalesOrderLine.Validate("Unit Price");
        // Note <<
    end;

    local procedure CreatePost(BlanketOrder: Record "Sales Header"; SalesOrder: Record "Sales Header")
    var
        RecurringPost: Record "Recurring Post";
    begin
        RecurringPost.Validate("Blanket Order No.", BlanketOrder."No.");
        RecurringPost.Validate(Date, PostDate);
        RecurringPost.Validate(Time, PostTime);
        RecurringPost.Validate("Document Type", SalesOrder."Document Type");
        RecurringPost.Validate("Document No.", SalesOrder."No.");
        RecurringPost.Validate("User ID", UserId);
        RecurringPost.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;
}

