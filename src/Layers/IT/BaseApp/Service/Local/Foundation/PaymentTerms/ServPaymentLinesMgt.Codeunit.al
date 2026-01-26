// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.Currency;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 12192 "Serv. Payment Lines Mgt."
{
    var
        Currency: Record Currency;

    [EventSubscriber(ObjectType::Page, Page::"Payment Date Lines", 'OnUpdateAmount', '', false, false)]
    local procedure PaymentDateLinesOnUpdateAmount(var PaymentLines: Record "Payment Lines"; var CurrencyCode: Code[10]; var DocumentAmount: Decimal; DocType: Option)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        case PaymentLines."Sales/Purchase" of
            PaymentLines."Sales/Purchase"::Service:
                if ServiceHeader.Get(DocType, PaymentLines.Code) then begin
                    if ServiceHeader."Currency Code" = '' then
                        Currency.InitRoundingPrecision()
                    else
                        Currency.Get(ServiceHeader."Currency Code");
                    CurrencyCode := Currency.Code;
                    DocumentAmount := 0;
                    ServiceLine.Reset();
                    ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
                    ServiceLine.SetRange("Document No.", ServiceHeader."No.");
                    if ServiceLine.FindSet() then
                        repeat
                            DocumentAmount := DocumentAmount + ServiceLine."Amount Including VAT";
                        until ServiceLine.Next() = 0;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"posted Payments", 'OnUpdateAmount', '', false, false)]
    local procedure OnUpdateAmount(var PostedPaymentLines: Record "Posted Payment Lines"; var CurrencyCode: Code[10]; var DocumentAmount: Decimal)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
    begin
        case PostedPaymentLines."Sales/Purchase" of
            PostedPaymentLines."Sales/Purchase"::Service:
                if ServiceInvoiceHeader.Get(PostedPaymentLines.Code) then begin
                    CurrencyCode := ServiceInvoiceHeader."Currency Code";
                    ServiceInvoiceLine.Reset();
                    ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
                    if ServiceInvoiceLine.FindSet() then
                        repeat
                            DocumentAmount := DocumentAmount + ServiceInvoiceLine."Amount Including VAT";
                        until ServiceInvoiceLine.Next() = 0;
                end else
                    if ServiceCrMemoHeader.Get(PostedPaymentLines.Code) then begin
                        CurrencyCode := ServiceCrMemoHeader."Currency Code";
                        ServiceCrMemoLine.Reset();
                        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
                        if ServiceCrMemoLine.FindSet() then
                            repeat
                                DocumentAmount := DocumentAmount + ServiceCrMemoLine."Amount Including VAT";
                            until ServiceCrMemoLine.Next() = 0;
                    end;
        end;
    end;


    [EventSubscriber(ObjectType::Table, Database::"Payment Lines", 'OnBeforeFindDocument', '', false, false)]
    local procedure OnBeforeFindDocument(var PaymentLines: Record "Payment Lines"; var DocumentDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        case PaymentLines."Sales/Purchase" of
            PaymentLines."Sales/Purchase"::Service:
                begin
                    ServiceHeader.Get(PaymentLines.Type, PaymentLines.Code);
                    DocumentDate := ServiceHeader."Document Date";
                end;
        end;
    end;

    procedure CreatePaymentLinesServices(ServiceHeader: Record "Service Header")
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
        if ServiceHeader."No." = '' then
            exit;

        PaymentLines.DeletePaymentLines(ServiceHeader);

        if (ServiceHeader."Payment Terms Code" = '') or (ServiceHeader."Document Date" = 0D) then
            exit;

        PaymentLinesTerms.Reset();
        PaymentLinesTerms.SetRange("Sales/Purchase", PaymentLines."Sales/Purchase"::" ");
        PaymentLinesTerms.SetRange(Type, PaymentLinesTerms.Type::"Payment Terms");
        PaymentLinesTerms.SetRange(Code, ServiceHeader."Payment Terms Code");

        if PaymentLinesTerms.FindSet() then begin
            PaymentCounter := 0;
            DeferringDueDates.SetCurrentKey("No.", "To-Date");
            DeferringDueDates.SetRange("No.", ServiceHeader."Bill-to Customer No.");

            FixedDueDates.Reset();
            FixedDueDates.SetRange(Type, FixedDueDates.Type::Customer);
            FixedDueDates.SetRange(Code, ServiceHeader."Bill-to Customer No.");

            repeat
                PaymentLines.Init();
                PaymentLines."Sales/Purchase" := PaymentLines."Sales/Purchase"::Service;
                PaymentLines.Type := ServiceHeader."Document Type";
                PaymentLines.Code := ServiceHeader."No.";
                PaymentCounter := PaymentCounter + 10000;
                PaymentLines."Line No." := PaymentCounter;
                PaymentLines."Payment %" := PaymentLinesTerms."Payment %";
                PaymentLines."Due Date Calculation" := PaymentLinesTerms."Due Date Calculation";
                PaymentLines."Discount Date Calculation" := PaymentLinesTerms."Discount Date Calculation";
                PaymentLines."Discount %" := PaymentLinesTerms."Discount %";
                PaymentLines."Due Date" := CalcDate(PaymentLinesTerms."Due Date Calculation", ServiceHeader."Document Date");

                repeat
                    if PaymentLines."Due Date" < ServiceHeader."Document Date" then
                        PaymentLines."Due Date" := ServiceHeader."Document Date";

                    DeferringDueDates.SetFilter("To-Date", '%1..', PaymentLines."Due Date");

                    if DeferringDueDates.FindFirst() and (PaymentLines."Due Date" >= DeferringDueDates."From-Date") then begin
                        PaymentLines."Due Date Calculation" := DeferringDueDates."Due Date Calculation";
                        if Format(DeferringDueDates."Due Date Calculation") = '' then
                            PaymentLines."Due Date" := DeferringDueDates."To-Date" + 1
                        else
                            PaymentLines."Due Date" := CalcDate(DeferringDueDates."Due Date Calculation", DeferringDueDates."To-Date");

                        if PaymentLines."Due Date" < ServiceHeader."Document Date" then
                            PaymentLines."Due Date" := ServiceHeader."Document Date";
                    end;
                    OnCreatePaymentLinesServicesOnAfterSetDueDate(PaymentLines, ServiceHeader, DeferringDueDates);

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

                PaymentLines."Pmt. Discount Date" := CalcDate(PaymentLinesTerms."Discount Date Calculation", ServiceHeader."Document Date");

                if PaymentLines."Pmt. Discount Date" < ServiceHeader."Document Date" then
                    PaymentLines."Pmt. Discount Date" := ServiceHeader."Document Date";
                OnCreatePaymentLinesServicesOnBeforePaymentLinesInsert(PaymentLines, ServiceHeader, PaymentLinesTerms);
                PaymentLines.Insert();
            until PaymentLinesTerms.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentLinesServicesOnAfterSetDueDate(var PaymentLines: Record "Payment Lines"; var ServiceHeader: Record Microsoft.Service.Document."Service Header"; DeferringDueDates: Record "Deferring Due Dates")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePaymentLinesServicesOnBeforePaymentLinesInsert(var PaymentLines: Record "Payment Lines"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; PaymentLinesTerms: Record "Payment Lines")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Payment Lines", 'OnDeletePaymentLinesOnAfterGetDocument', '', false, false)]
    local procedure OnDeletePaymentLinesOnAfterGetDocument(RecRef: RecordRef; var SalesPurchaseType: Option ,Sales,Purchase,Service; var DocumentType: Option; var DocumentNo: Code[20]; IsBlanketOrder: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        case RecRef.Number of
            Database::"Service Header":
                begin
                    SalesPurchaseType := SalesPurchaseType::Service;
                    RecRef.SetTable(ServiceHeader);
                    DocumentType := ServiceHeader."Document Type".AsInteger();
                    DocumentNo := ServiceHeader."No.";
                    IsBlanketOrder := false;
                end;
        end;
    end;
}