// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Worksheet;

using Microsoft.Bank.BankAccount;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Service.Document;

codeunit 7000034 "Serv. SuggestWorksheetLines ES"
{
    var
        ServiceOrderBillTxt: Label 'Service Order Bill of %1 %2', Comment = '%1 - date, %2 - name';
        CannotCreateCarteraDocErr: Label 'You do not have permissions to create Documents in Cartera.\Please, change the Payment Method.';
        CannotSelectBillBasedErr: Label 'You cannot select a bill-based %1 for a Credit memo.', Comment = '%1 - field name';
        MustBeOneErr: Label '%1 must be 1 if %2 is True in %3.', Comment = '%1 - field name, %2 - field name, %3 - table name';
        SumCannotBeGreaterErr: Label 'The sum of %1 cannot be greater than 100 in the installments for %2 %3.', Comment = '%1 - field name, %2 - table name, %3 - code';

    [EventSubscriber(ObjectType::Report, Report::"Suggest Worksheet Lines", 'OnInsertCFLineForServiceLineOnBeforeInsertTempCFWorksheetLine', '', true, true)]
    local procedure OnInsertCFLineForServiceLineOnBeforeInsertTempCFWorksheetLine(var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; CashFlowForecast: Record "Cash Flow Forecast"; ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; var SkipInsert: Boolean; sender: Report "Suggest Worksheet Lines")
    var
        CarteraSetup: Record "Cartera Setup";
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.Get(ServiceHeader."Payment Method Code") then
            if (PaymentMethod."Create Bills" or PaymentMethod."Invoices to Cartera") and
                (not CarteraSetup.ReadPermission)
            then
                Error(CannotCreateCarteraDocErr);

        if (ServiceLine."Document Type" <> ServiceLine."Document Type"::"Credit Memo") and
            CarteraSetup.ReadPermission and PaymentMethod."Create Bills"
        then
            SplitServInv(
                ServiceHeader, CashFlowWorksheetLine, CashFlowWorksheetLine."Amount (LCY)", CashFlowWorksheetLine."Amount (LCY)" - ServiceLine."Line Amount", sender);

        SkipInsert := (CashFlowWorksheetLine."Amount (LCY)" = 0) or PaymentMethod."Create Bills";
    end;

    local procedure SplitServInv(var ServHeader: Record "Service Header"; var CashFlowWorksheetLine: Record "Cash Flow Worksheet Line"; TotalAmount: Decimal; VATAmount: Decimal; var SuggestWorksheetLines: Report "Suggest Worksheet Lines")
    var
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
        TotalAmount := SuggestWorksheetLines.RoundAmt(TotalAmount);

        if PaymentTerms."No. of Installments" > 0 then begin
            Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
            if Installment.Find('-') then;
        end;

        NextDueDate := ServHeader."Due Date";

        for CurrDocNo := 1 to PaymentTerms."No. of Installments" do begin
            CashFlowWorksheetLine."Cash Flow Date" := NextDueDate;
            CashFlowWorksheetLine.Description :=
              CopyStr(StrSubstNo(ServiceOrderBillTxt, Format(CashFlowWorksheetLine."Cash Flow Date"),
                  ServHeader.Name), 1, MaxStrLen(CashFlowWorksheetLine.Description));
            DueDateAdjust.SalesAdjustDueDate(
              CashFlowWorksheetLine."Cash Flow Date", ServHeader."Document Date", PaymentTerms.CalculateMaxDueDate(ServHeader."Document Date"), ServHeader."Bill-to Customer No.");
            if CurrDocNo < PaymentTerms."No. of Installments" then begin
                Installment.TestField("% of Total");
                if CurrDocNo = 1 then begin
                    TotalPerc := Installment."% of Total";
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment":
                            CashFlowWorksheetLine."Amount (LCY)" := Round(
                                (TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount);
                        PaymentTerms."VAT distribution"::"Last Installment":
                            CashFlowWorksheetLine."Amount (LCY)" := Round(
                                (TotalAmount - VATAmount) * Installment."% of Total" / 100);
                        PaymentTerms."VAT distribution"::Proportional:
                            CashFlowWorksheetLine."Amount (LCY)" := Round(
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
                            CashFlowWorksheetLine."Amount (LCY)" := Round(
                                (TotalAmount - VATAmount) * Installment."% of Total" / 100);
                        PaymentTerms."VAT distribution"::Proportional:
                            CashFlowWorksheetLine."Amount (LCY)" := Round(
                                TotalAmount * Installment."% of Total" / 100);
                    end;
                end;
                RemainingAmount := RemainingAmount - CashFlowWorksheetLine."Amount (LCY)";
                Installment.TestField("Gap between Installments");
                NextDueDate := CalcDate(Installment."Gap between Installments", NextDueDate);
                Installment.Next();
            end else
                CashFlowWorksheetLine."Amount (LCY)" := RemainingAmount;

            if PaymentMethod."Create Bills" and (CashFlowWorksheetLine."Amount (LCY)" <> 0) then
                SuggestWorksheetLines.InsertTempCFWorksheetLine(CashFlowWorksheetLine, 0);
        end;
    end;
}