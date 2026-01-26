// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

table 12170 "Payment Lines"
{
    Caption = 'Payment Lines';
    DrillDownPageID = "Payment Terms Lines";
    LookupPageID = "Payment Terms Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Payment Lines Document Type")
        {
            Caption = 'Type';
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = if (Type = const("Payment Terms")) "Payment Terms";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Payment %"; Decimal)
        {
            Caption = 'Payment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; "Due Date Calculation"; DateFormula)
        {
            Caption = 'Due Date Calculation';
        }
        field(6; "Discount Date Calculation"; DateFormula)
        {
            Caption = 'Discount Date Calculation';
        }
        field(7; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(8; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            begin
                FindDocument();

                if "Due Date" < DocumentDate then
                    Error(InvalidDueDateErr);
            end;
        }
        field(9; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';

            trigger OnValidate()
            begin
                FindDocument();

                if "Pmt. Discount Date" < DocumentDate then
                    Error(InvalidPmtDiscountDateErr);
            end;
        }
        field(10; "Sales/Purchase"; Option)
        {
            Caption = 'Sales/Purchase';
            OptionCaption = ' ,Sales,Purchase,Service';
            OptionMembers = " ",Sales,Purchase,Service;
        }
        field(11; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(12; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(14; "Prepmt. Due Date Calculation"; DateFormula)
        {
            Caption = 'Prepmt. Due Date Calculation';
        }
        field(15; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(16; "Prepmt. Due Date"; Date)
        {
            Caption = 'Prepmt. Due Date';

            trigger OnValidate()
            begin
                FindDocument();

                if "Due Date" < DocumentDate then
                    Error(InvalidDueDateErr);
            end;
        }
    }

    keys
    {
        key(Key1; "Sales/Purchase", Type, "Code", "Journal Template Name", "Journal Line No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = "Payment %";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckPrepPaymentTermsLinked();
    end;

    trigger OnInsert()
    begin
        CheckTotalPaymentsPerc("Payment %");
        CheckPrepPaymentTermsLinked();
    end;

    trigger OnModify()
    begin
        CheckTotalPaymentsPerc("Payment %" - xRec."Payment %");
    end;

    var
        InvalidDueDateErr: Label 'The Due Date must be greater than or equal to the Document Date';
        GenJnlLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DocumentDate: Date;
        InvalidPmtDiscountDateErr: Label 'The Pmt. Discount Date must be greater than or equal to Document Date.';
        OnlyOnePaymLineAllowedVendorErr: Label 'Only one payment line is allowed for payment terms %1 if it is defined as Prepmt. Payment Terms Code at least for one vendor.';
        OnlyOnePaymLineAllowedPurchDocErr: Label 'Only one payment line is allowed for payment terms %1 if it is defined as Prepmt. Payment Terms Code at least for one purchase document.';
        PaymentPctErr: Label 'The total of Payment % cannot be greater than 100.';

    [Scope('OnPrem')]
    procedure FindDocument()
    begin
        OnBeforeFindDocument(Rec, DocumentDate);
        if DocumentDate <> 0D then
            exit;

        case "Sales/Purchase" of
            "Sales/Purchase"::" ":
                begin
                    GenJnlLine.Get("Journal Template Name", Code, "Journal Line No.");
                    DocumentDate := GenJnlLine."Document Date";
                end;
            "Sales/Purchase"::Sales:
                begin
                    SalesHeader.Get(Type, Code);
                    DocumentDate := SalesHeader."Document Date";
                    SalesHeader.CalcFields("Amount Including VAT");
                end;
            "Sales/Purchase"::Purchase:
                begin
                    PurchaseHeader.Get(Type, Code);
                    DocumentDate := PurchaseHeader."Document Date";
                    PurchaseHeader.CalcFields("Amount Including VAT");
                end;
            else
                DocumentDate := "Due Date";
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckTotalPaymentsPerc(NewValue: Decimal)
    var
        TempPaymentLines: Record "Payment Lines";
        TotalPaymentPerc: Decimal;
    begin
        TempPaymentLines.CopyFilters(Rec);

        if TempPaymentLines.GetFilter(Code) = '' then begin
            TempPaymentLines.SetRange("Sales/Purchase", Rec."Sales/Purchase");
            TempPaymentLines.SetRange(Type, Rec.Type);
            TempPaymentLines.SetRange(Code, Rec.Code);
        end;

        OnCheckTotalPaymentsPercOnAfterSetFilters(TempPaymentLines, Rec);

        if TempPaymentLines.CalcSums("Payment %") then
            TotalPaymentPerc := TempPaymentLines."Payment %" + NewValue;

        if TotalPaymentPerc > 100 then
            Error(PaymentPctErr);
    end;

    local procedure CheckPrepPaymentTermsLinked()
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        if Type <> Type::"Payment Terms" then
            exit;

        PaymentTerms.Get(Code);
        PaymentTerms.CalcFields("Payment Nos.");
        if PaymentTerms."Payment Nos." = 1 then begin
            Vendor.SetRange("Prepmt. Payment Terms Code", Code);
            if not Vendor.IsEmpty() then
                Error(OnlyOnePaymLineAllowedVendorErr, Code);
            PurchaseHeader.SetRange("Prepmt. Payment Terms Code", Code);
            if not PurchaseHeader.IsEmpty() then
                Error(OnlyOnePaymLineAllowedPurchDocErr, Code);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentLinesSales(SalesHeader: Record "Sales Header")
    var
        PaymentLines: Record "Payment Lines";
        PaymentLinesTerms: Record "Payment Lines";
        DeferringDueDates: Record "Deferring Due Dates";
        FixedDueDates: Record "Fixed Due Dates";
        OldDate: Date;
        PaymentCounter: Integer;
        Day: Integer;
        MaximumDay: Integer;
        Month: Integer;
        Year: Integer;
    begin
        if SalesHeader."No." = '' then
            exit;

        DeletePaymentLines(SalesHeader);

        if (SalesHeader."Payment Terms Code" = '') or (SalesHeader."Document Date" = 0D) then
            exit;

        PaymentLinesTerms.Reset();
        PaymentLinesTerms.SetRange("Sales/Purchase", PaymentLines."Sales/Purchase"::" ");
        PaymentLinesTerms.SetRange(Type, PaymentLinesTerms.Type::"Payment Terms");
        PaymentLinesTerms.SetRange(Code, SalesHeader."Payment Terms Code");

        if PaymentLinesTerms.FindSet() then begin
            PaymentCounter := 0;
            DeferringDueDates.SetCurrentKey("No.", "To-Date");
            DeferringDueDates.SetRange("No.", SalesHeader."Bill-to Customer No.");

            FixedDueDates.Reset();
            FixedDueDates.SetRange(Type, FixedDueDates.Type::Customer);
            FixedDueDates.SetRange(Code, SalesHeader."Bill-to Customer No.");

            repeat
                PaymentLines.Init();
                PaymentLines."Sales/Purchase" := PaymentLines."Sales/Purchase"::Sales;
                if SalesHeader."Document Type" <> SalesHeader."Document Type"::"Blanket Order" then
                    PaymentLines.Type := SalesHeader."Document Type"
                else
                    PaymentLines.Type := PaymentLines.Type::"Blanket Order";
                PaymentLines.Code := SalesHeader."No.";
                PaymentCounter := PaymentCounter + 10000;
                PaymentLines."Line No." := PaymentCounter;
                PaymentLines."Payment %" := PaymentLinesTerms."Payment %";
                PaymentLines."Due Date Calculation" := PaymentLinesTerms."Due Date Calculation";
                PaymentLines."Discount Date Calculation" := PaymentLinesTerms."Discount Date Calculation";
                PaymentLines."Discount %" := PaymentLinesTerms."Discount %";
                PaymentLines."Due Date" := CalcDate(PaymentLinesTerms."Due Date Calculation", SalesHeader."Document Date");
                OnCreatePaymentLinesSalesOnAfterPopulatePaymentLines(PaymentLines, PaymentLinesTerms, SalesHeader);

                repeat
                    if PaymentLines."Due Date" < SalesHeader."Document Date" then
                        PaymentLines."Due Date" := SalesHeader."Document Date";

                    DeferringDueDates.SetFilter("To-Date", '%1..', PaymentLines."Due Date");

                    if DeferringDueDates.FindFirst() and (PaymentLines."Due Date" >= DeferringDueDates."From-Date") then begin
                        PaymentLines."Due Date Calculation" := DeferringDueDates."Due Date Calculation";
                        if Format(DeferringDueDates."Due Date Calculation") = '' then
                            PaymentLines."Due Date" := DeferringDueDates."To-Date" + 1
                        else
                            PaymentLines."Due Date" := CalcDate(DeferringDueDates."Due Date Calculation", DeferringDueDates."To-Date");

                        if PaymentLines."Due Date" < SalesHeader."Document Date" then
                            PaymentLines."Due Date" := SalesHeader."Document Date";
                    end;
                    OnCreatePaymentLinesSalesOnAfterSetDueDate(PaymentLines, SalesHeader, DeferringDueDates);

                    OldDate := PaymentLines."Due Date";
                    FixedDueDates.SetRange("Payment Days", Date2DMY(PaymentLines."Due Date", 1), 99);

                    if FixedDueDates.FindFirst() then begin
                        Day := FixedDueDates."Payment Days";
                        MaximumDay := Date2DMY(CalcDate('<CM>', PaymentLines."Due Date"), 1);
                        if Day > MaximumDay then
                            Day := MaximumDay;
                        Month := Date2DMY(PaymentLines."Due Date", 2);
                        Year := Date2DMY(PaymentLines."Due Date", 3);
                        PaymentLines."Due Date" := DMY2Date(Day, Month, Year);
                    end else begin
                        FixedDueDates.SetRange("Payment Days");
                        if FixedDueDates.FindFirst() then begin
                            Day := FixedDueDates."Payment Days";
                            MaximumDay := Date2DMY(CalcDate('<CM + 1M>', PaymentLines."Due Date"), 1);
                            if Day > MaximumDay then
                                Day := MaximumDay;
                            Month := Date2DMY(PaymentLines."Due Date", 2) + 1;
                            Year := Date2DMY(PaymentLines."Due Date", 3);
                            if Month = 13 then begin
                                Month := 1;
                                Year := Year + 1;
                            end;
                            PaymentLines."Due Date" := DMY2Date(Day, Month, Year);
                        end;
                    end;

                until OldDate = PaymentLines."Due Date";

                PaymentLines."Pmt. Discount Date" := CalcDate(PaymentLinesTerms."Discount Date Calculation", SalesHeader."Document Date");

                if PaymentLines."Pmt. Discount Date" < SalesHeader."Document Date" then
                    PaymentLines."Pmt. Discount Date" := SalesHeader."Document Date";
                OnCreatePaymentLinesSalesOnBeforePaymentLinesInsert(PaymentLines, SalesHeader, PaymentLinesTerms);
                PaymentLines.Insert();
            until PaymentLinesTerms.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentLiensPurchases(PurchaseHeader: Record "Purchase Header")
    var
        PaymentLines: Record "Payment Lines";
        PaymentLinesTerms: Record "Payment Lines";
        FixedDueDates: Record "Fixed Due Dates";
        Vendor: Record Vendor;
        PaymentCounter: Integer;
        Day: Integer;
        MaximumDay: Integer;
        Month: Integer;
        Year: Integer;
    begin
        if PurchaseHeader."No." = '' then
            exit;

        DeletePaymentLines(PurchaseHeader);

        if (PurchaseHeader."Payment Terms Code" = '') or (PurchaseHeader."Document Date" = 0D) then
            exit;

        PaymentLinesTerms.Reset();
        PaymentLinesTerms.SetRange("Sales/Purchase", PaymentLinesTerms."Sales/Purchase"::" ");
        PaymentLinesTerms.SetRange(Type, PaymentLinesTerms.Type::"Payment Terms");
        PaymentLinesTerms.SetRange(Code, PurchaseHeader."Payment Terms Code");

        if PaymentLinesTerms.FindSet() then begin
            ;
            PaymentCounter := 0;
            FixedDueDates.Reset();
            if (PurchaseHeader."Pay-to Vendor No." <> '') or (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Quote) then
                Vendor.Get(PurchaseHeader."Pay-to Vendor No.");

            if Vendor."Apply Company Payment days" then begin
                FixedDueDates.SetRange(Type, FixedDueDates.Type::Company);
                FixedDueDates.SetRange(Code, '');
            end else begin
                FixedDueDates.SetRange(Type, FixedDueDates.Type::Vendor);
                FixedDueDates.SetRange(Code, Vendor."No.");
            end;
            repeat
                PaymentLines.Init();
                PaymentLines."Sales/Purchase" := PaymentLines."Sales/Purchase"::Purchase;
                if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::"Blanket Order" then
                    PaymentLines.Type := PurchaseHeader."Document Type"
                else
                    PaymentLines.Type := PaymentLines.Type::"Blanket Order";
                PaymentLines.Code := PurchaseHeader."No.";
                PaymentCounter := PaymentCounter + 10000;
                PaymentLines."Line No." := PaymentCounter;
                PaymentLines."Payment %" := PaymentLinesTerms."Payment %";
                PaymentLines."Due Date Calculation" := PaymentLinesTerms."Due Date Calculation";
                PaymentLines."Discount Date Calculation" := PaymentLinesTerms."Discount Date Calculation";
                PaymentLines."Discount %" := PaymentLinesTerms."Discount %";
                PaymentLines."Due Date" := CalcDate(PaymentLinesTerms."Due Date Calculation", PurchaseHeader."Document Date");
                OnCreatePaymentLiensPurchasesOnAfterPopulatePaymentLines(PaymentLines, PaymentLinesTerms, PurchaseHeader);

                if PaymentLines."Due Date" < PurchaseHeader."Document Date" then
                    PaymentLines."Due Date" := PurchaseHeader."Document Date";

                FixedDueDates.SetRange("Payment Days", Date2DMY(PaymentLines."Due Date", 1), 99);
                if FixedDueDates.FindFirst() then begin
                    Day := FixedDueDates."Payment Days";
                    MaximumDay := Date2DMY(CalcDate('<CM>', PaymentLines."Due Date"), 1);
                    if Day > MaximumDay then
                        Day := MaximumDay;
                    Month := Date2DMY(PaymentLines."Due Date", 2);
                    Year := Date2DMY(PaymentLines."Due Date", 3);
                    PaymentLines."Due Date" := DMY2Date(Day, Month, Year);
                end else begin
                    FixedDueDates.SetRange("Payment Days");
                    if FixedDueDates.FindFirst() then begin
                        Day := FixedDueDates."Payment Days";
                        MaximumDay := Date2DMY(CalcDate('<CM+1M>', PaymentLines."Due Date"), 1);
                        if Day > MaximumDay then
                            Day := MaximumDay;
                        Month := Date2DMY(PaymentLines."Due Date", 2) + 1;
                        Year := Date2DMY(PaymentLines."Due Date", 3);
                        if Month = 13 then begin
                            Month := 1;
                            Year := Year + 1;
                        end;
                        PaymentLines."Due Date" := DMY2Date(Day, Month, Year);
                    end;
                end;

                PaymentLines."Pmt. Discount Date" :=
                  CalcDate(PaymentLinesTerms."Discount Date Calculation", PurchaseHeader."Document Date");

                if PaymentLines."Pmt. Discount Date" < PurchaseHeader."Document Date" then
                    PaymentLines."Pmt. Discount Date" := PurchaseHeader."Document Date";

                OnCreatePaymentLiensPurchasesOnBeforePaymentLinesInsert(PaymentLines, PurchaseHeader, PaymentLinesTerms);
                PaymentLines.Insert();
            until PaymentLinesTerms.Next() = 0;
        end;
    end;


    [Scope('OnPrem')]
    procedure DeletePaymentLines(RecVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
        SalesPurchaseType: Option;
        DocumentType: Option;
        DocumentNo: Code[20];
        IsBlanketOrder: Boolean;
    begin
        RecRef.GetTable(RecVar);

        case RecRef.Number of
            DATABASE::"Sales Header":
                begin
                    SalesPurchaseType := "Sales/Purchase"::Sales;
                    SalesHeader := RecVar;
                    DocumentType := SalesHeader."Document Type".AsInteger();
                    DocumentNo := SalesHeader."No.";
                    IsBlanketOrder := SalesHeader."Document Type" = SalesHeader."Document Type"::"Blanket Order";
                end;
            DATABASE::"Purchase Header":
                begin
                    SalesPurchaseType := "Sales/Purchase"::Purchase;
                    PurchaseHeader := RecVar;
                    DocumentType := PurchaseHeader."Document Type".AsInteger();
                    DocumentNo := PurchaseHeader."No.";
                    IsBlanketOrder := PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Blanket Order";
                end;
        end;
        OnDeletePaymentLinesOnAfterGetDocument(RecRef, SalesPurchaseType, DocumentType, DocumentNo, IsBlanketOrder);


        DeletePaymentLinesInternal(SalesPurchaseType, DocumentType, DocumentNo, IsBlanketOrder);
    end;

    local procedure DeletePaymentLinesInternal(SalesPurchaseType: Option; DocumentType: Option; DocumentNo: Code[20]; IsBlanketOrder: Boolean)
    var
        PaymentLines: Record "Payment Lines";
    begin
        PaymentLines.Reset();
        PaymentLines.SetRange("Sales/Purchase", SalesPurchaseType);

        if not IsBlanketOrder then
            PaymentLines.SetRange(Type, DocumentType)
        else
            PaymentLines.SetRange(Type, PaymentLines.Type::"Blanket Order");

        PaymentLines.SetRange(Code, DocumentNo);
        if not PaymentLines.IsEmpty() then
            PaymentLines.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTotalPaymentsPercOnAfterSetFilters(var TempPaymentLines: Record "Payment Lines"; var PaymentLines: Record "Payment Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentLiensPurchasesOnBeforePaymentLinesInsert(var PaymentLines: Record "Payment Lines"; PurchaseHeader: Record "Purchase Header"; PaymentLinesTerms: Record "Payment Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentLinesSalesOnBeforePaymentLinesInsert(var PaymentLines: Record "Payment Lines"; SalesHeader: Record "Sales Header"; PaymentLinesTerms: Record "Payment Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentLinesSalesOnAfterSetDueDate(var PaymentLines: Record "Payment Lines"; var SalesHeader: Record "Sales Header"; DeferringDueDates: Record "Deferring Due Dates")
    begin
    end;



    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentLiensPurchasesOnAfterPopulatePaymentLines(var PaymentLines: Record "Payment Lines"; PaymentLinesTerms: Record "Payment Lines"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentLinesSalesOnAfterPopulatePaymentLines(var PaymentLines: Record "Payment Lines"; PaymentLinesTerms: Record "Payment Lines"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindDocument(var PaymentLines: Record "Payment Lines"; var DocumentDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeletePaymentLinesOnAfterGetDocument(RecRef: RecordRef; var SalesPurchaseType: Option ,Sales,Purchase,Service; var DocumentType: Option; var DocumentNo: Code[20]; IsBlanketOrder: Boolean)
    begin
    end;
}
