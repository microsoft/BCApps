// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Worksheet;

using Microsoft.Bank.BankAccount;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Service.Document;

reportextension 6485 "Serv. Suggest Worksheet Lines" extends "Suggest Worksheet Lines"
{
    dataset
    {
        addafter("Sales Line")
        {
            dataitem("Service Line"; "Service Line")
            {
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Document Type" = const(Order));

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, ServiceOrderTxt);
                    Window.Update(3, "Document No.");

                    ServiceHeader.Get("Document Type", "Document No.");
                    if ServiceHeader."Bill-to Customer No." <> '' then
                        Customer.Get(ServiceHeader."Bill-to Customer No.")
                    else
                        Customer.Init();

                    InsertCFLineForServiceLine();
                end;

                trigger OnPreDataItem()
                begin
                    if not ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] then
                        CurrReport.Break();

                    if not ReadPermission then
                        CurrReport.Break();
                end;
            }
        }
    }

    requestpage
    {
        layout
        {
            addafter("ConsiderSource[SourceType::""Sales Order""]")
            {
#pragma warning disable AA0100
                field("ConsiderSource[SourceType::""Service Orders""]"; ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()])
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    ToolTip = 'Specifies if you want to include service orders in the cash flow forecast.';
                }
            }
        }

        trigger OnOpenPage()
        begin
            if ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] then
                ConsiderSource["Cash Flow Source Type"::"Service Orders".AsInteger()] := "Service Line".ReadPermission;
        end;
    }

    var
        ServiceOrderTxt: Label 'Service Orders';
        ServiceOrderBillTxt: Label 'Service Order Bill of %1 %2', Comment = '%1 - date, %2 - name';
        ServiceDocumentDescriptionTxt: Label 'Service %1 - %2 %3', Comment = '%1 = Source Document Type (e.g. Invoice), %2 = Due Date, %3 = Source Name (e.g. Customer Name). Example: Service Invoice - 04-05-18 The Cannon Group PLC';

    protected var
        ServiceHeader: Record "Service Header";

    local procedure InsertCFLineForServiceLine()
    var
        CarteraSetup: Record "Cartera Setup";
        PaymentMethod: Record "Payment Method";
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2 := "Service Line";
        if Summarized and (ServiceLine2.Next() <> 0) and (ServiceLine2."Customer No." <> '') and
           (ServiceLine2."Document No." = "Service Line"."Document No.")
        then begin
            TotalAmt += CalculateLineAmountForServiceLine("Service Line");

            MultiSalesLines := true;
        end else begin
            CFWorksheetLine2.Init();
            CFWorksheetLine2."Source Type" := CFWorksheetLine2."Source Type"::"Service Orders";
            CFWorksheetLine2."Source No." := "Service Line"."Document No.";
            CFWorksheetLine2."Source Line No." := "Service Line"."Line No.";
            CFWorksheetLine2."Document Type" := CFWorksheetLine2."Document Type"::Invoice;
            CFWorksheetLine2."Document Date" := ServiceHeader."Document Date";
            CFWorksheetLine2."Shortcut Dimension 1 Code" := ServiceHeader."Shortcut Dimension 1 Code";
            CFWorksheetLine2."Shortcut Dimension 2 Code" := ServiceHeader."Shortcut Dimension 2 Code";
            CFWorksheetLine2."Dimension Set ID" := ServiceHeader."Dimension Set ID";
            CFWorksheetLine2."Cash Flow Account No." := CFSetup."Service CF Account No.";
            CFWorksheetLine2.Description :=
              CopyStr(
                StrSubstNo(
                  ServiceDocumentDescriptionTxt,
                  ServiceHeader."Document Type",
                  ServiceHeader.Name,
                  Format(ServiceHeader."Order Date")),
                1, MaxStrLen(CFWorksheetLine2.Description));
            SetCashFlowDate(CFWorksheetLine2, ServiceHeader."Due Date");
            CFWorksheetLine2."Document No." := "Service Line"."Document No.";
            CFWorksheetLine2."Amount (LCY)" := CalculateLineAmountForServiceLine("Service Line");

            if Summarized and MultiSalesLines then begin
                CFWorksheetLine2."Amount (LCY)" := CFWorksheetLine2."Amount (LCY)" + TotalAmt;
                MultiSalesLines := false;
                TotalAmt := 0;
            end;

            if PaymentMethod.Get(PurchHeader."Payment Method Code") then
                if (PaymentMethod."Create Bills" or PaymentMethod."Invoices to Cartera") and
                   (not CarteraSetup.ReadPermission)
                then
                    Error(CannotCreateCarteraDocErr);

            if ("Service Line"."Document Type" <> "Service Line"."Document Type"::"Credit Memo") and
               CarteraSetup.ReadPermission and PaymentMethod."Create Bills"
            then
                SplitServInv(
                  ServiceHeader, CFWorksheetLine2, CFWorksheetLine2."Amount (LCY)", CFWorksheetLine2."Amount (LCY)" - "Service Line"."Line Amount");

            if "Cash Flow Forecast"."Consider CF Payment Terms" and (Customer."Cash Flow Payment Terms Code" <> '') then
                CFWorksheetLine2."Payment Terms Code" := Customer."Cash Flow Payment Terms Code"
            else
                CFWorksheetLine2."Payment Terms Code" := ServiceHeader."Payment Terms Code";

            OnInsertCFLineForServiceLineOnBeforeInsertTempCFWorksheetLine(CFWorksheetLine2, "Cash Flow Forecast", "Service Line");
            if (CFWorksheetLine2."Amount (LCY)" <> 0) and not PaymentMethod."Create Bills" then
                InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
        end;
    end;

    local procedure CalculateLineAmountForServiceLine(ServiceLine: Record "Service Line"): Decimal
    begin
        exit(GetServiceAmountForCFLine(ServiceLine));
    end;

    local procedure GetServiceAmountForCFLine(ServiceLine: Record "Service Line"): Decimal
    begin
        exit(ServiceLine."Outstanding Amount (LCY)" + ServiceLine."Shipped Not Invoiced (LCY)");
    end;

    [Scope('OnPrem')]
    procedure SplitServInv(var ServHeader: Record "Service Header"; var CFJournalLine3: Record "Cash Flow Worksheet Line"; TotalAmount: Decimal; VATAmount: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
        Installment: Record Installment;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        DueDateAdjust: Codeunit "Due Date-Adjust";
        CurrDocNo: Integer;
        RemainingAmount: Decimal;
        TotalPerc: Decimal;
        NextDueDate: Date;
    begin
        if not PaymentMethod.Get(ServHeader."Payment Method Code") then
            exit;
        if (not PaymentMethod."Create Bills") and (not PaymentMethod."Invoices to Cartera") then
            exit;
        if PaymentMethod."Create Bills" and (ServHeader."Document Type" = ServHeader."Document Type"::"Credit Memo") then
            Error(CannotSelectBillBasedErr, ServHeader.FieldCaption("Payment Method Code"));

        ServHeader.TestField("Payment Terms Code");
        PaymentTerms.Get(ServHeader."Payment Terms Code");
        PaymentTerms.CalcFields("No. of Installments");
        if PaymentTerms."No. of Installments" = 0 then
            PaymentTerms."No. of Installments" := 1;
        if PaymentMethod."Invoices to Cartera" and (PaymentTerms."No. of Installments" > 1) then
            Error(
              MustBeOneErr,
              PaymentTerms.FieldCaption("No. of Installments"),
              PaymentMethod.FieldCaption("Invoices to Cartera"),
              PaymentMethod.TableCaption());

        RemainingAmount := TotalAmount;
        // create bills
        if ServHeader."Currency Code" = '' then begin
            GLSetup.Get();
            Currency."Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
            Currency."Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";
            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
        end else
            Currency.Get(ServHeader."Currency Code");
        TotalAmount := RoundAmt(TotalAmount);

        if PaymentTerms."No. of Installments" > 0 then begin
            Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
            if Installment.Find('-') then;
        end;

        NextDueDate := ServHeader."Due Date";

        for CurrDocNo := 1 to PaymentTerms."No. of Installments" do begin
            CFJournalLine3."Cash Flow Date" := NextDueDate;
            CFJournalLine3.Description :=
              CopyStr(StrSubstNo(ServiceOrderBillTxt, Format(CFJournalLine3."Cash Flow Date"),
                  ServHeader.Name), 1, MaxStrLen(CFJournalLine3.Description));
            DueDateAdjust.SalesAdjustDueDate(
              CFJournalLine3."Cash Flow Date", ServHeader."Document Date", PaymentTerms.CalculateMaxDueDate(ServHeader."Document Date"), ServHeader."Bill-to Customer No.");
            if CurrDocNo < PaymentTerms."No. of Installments" then begin
                Installment.TestField("% of Total");
                if CurrDocNo = 1 then begin
                    TotalPerc := Installment."% of Total";
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment":
                            CFJournalLine3."Amount (LCY)" := Round(
                                (TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount);
                        PaymentTerms."VAT distribution"::"Last Installment":
                            CFJournalLine3."Amount (LCY)" := Round(
                                (TotalAmount - VATAmount) * Installment."% of Total" / 100);
                        PaymentTerms."VAT distribution"::Proportional:
                            CFJournalLine3."Amount (LCY)" := Round(
                                TotalAmount * Installment."% of Total" / 100);
                    end;
                end else begin
                    TotalPerc := TotalPerc + Installment."% of Total";
                    if TotalPerc >= 100 then
                        Error(
                          SumCannotBeGreaterErr,
                          Installment.FieldCaption("% of Total"),
                          PaymentTerms.TableCaption(),
                          PaymentTerms.Code);
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment",
                      PaymentTerms."VAT distribution"::"Last Installment":
                            CFJournalLine3."Amount (LCY)" := Round(
                                (TotalAmount - VATAmount) * Installment."% of Total" / 100);
                        PaymentTerms."VAT distribution"::Proportional:
                            CFJournalLine3."Amount (LCY)" := Round(
                                TotalAmount * Installment."% of Total" / 100);
                    end;
                end;
                RemainingAmount := RemainingAmount - CFJournalLine3."Amount (LCY)";
                Installment.TestField("Gap between Installments");
                NextDueDate := CalcDate(Installment."Gap between Installments", NextDueDate);
                Installment.Next();
            end else
                CFJournalLine3."Amount (LCY)" := RemainingAmount;

            if PaymentMethod."Create Bills" and (CFJournalLine3."Amount (LCY)" <> 0) then
                InsertTempCFWorksheetLine(CFWorksheetLine2, 0);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCFLineForServiceLineOnBeforeInsertTempCFWorksheetLine(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; CashFlowForecast: Record "Cash Flow Forecast"; ServiceLine: Record "Service Line")
    begin
    end;
}