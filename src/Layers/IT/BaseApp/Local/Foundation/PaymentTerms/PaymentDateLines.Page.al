// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

page 12171 "Payment Date Lines"
{
    AutoSplitKey = true;
    Caption = 'Payment Date Lines';
    DataCaptionFields = "Sales/Purchase", Type, "Code", "Journal Line No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Payment Lines";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Payment %"; Rec."Payment %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the transaction amount that is issued as an installment payment.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made for a purchase or sales invoice.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment is due.';
                }
                field("Discount Date Calculation"; Rec."Discount Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made in order to obtain a discount.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when early payment of an invoice is due in order to get a discount on the amount.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that is applied for early payment of an invoice amount.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    Editable = false;
                    ToolTip = 'Specifies the amount due.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RecalcAmount)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recalc. Amount';
                ToolTip = 'Recalculate amounts based on the current information.';

                trigger OnAction()
                begin
                    UpdateAmount();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RecalcAmount_Promoted; RecalcAmount)
                {
                }
            }
        }
    }

    var
        GenJnlLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PaymentLines2: Record "Payment Lines";
        DocumentAmount: Decimal;
        ResidualTotal: Decimal;
        CurrencyCode: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order";
        LastRec: Boolean;

    [Scope('OnPrem')]
    procedure UpdateAmount()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAmount(Rec, IsHandled);
        if IsHandled then
            exit;

        ClearAll();
        if Rec.Find('-') then
            repeat
                if Rec.Type <> Rec.Type::"Blanket Order" then
                    DocType := Rec.Type.AsInteger()
                else
                    DocType := DocType::"Blanket Order";

                case Rec."Sales/Purchase" of
                    Rec."Sales/Purchase"::" ":
                        if GenJnlLine.Get(Rec."Journal Template Name", Rec.Code, Rec."Journal Line No.") then begin
                            if GenJnlLine."Currency Code" = '' then
                                Currency.InitRoundingPrecision()
                            else
                                Currency.Get(GenJnlLine."Currency Code");
                            CurrencyCode := Currency.Code;
                            DocumentAmount := GenJnlLine.Amount;
                        end;
                    Rec."Sales/Purchase"::Sales:
                        if SalesHeader.Get(DocType, Rec.Code) then begin
                            SalesHeader.CalcFields("Amount Including VAT");
                            if SalesHeader."Currency Code" = '' then
                                Currency.InitRoundingPrecision()
                            else
                                Currency.Get(SalesHeader."Currency Code");
                            CurrencyCode := Currency.Code;
                            DocumentAmount := SalesHeader."Amount Including VAT";
                        end;
                    Rec."Sales/Purchase"::Purchase:
                        if PurchaseHeader.Get(DocType, Rec.Code) then begin
                            PurchaseHeader.CalcFields("Amount Including VAT");
                            if PurchaseHeader."Currency Code" = '' then
                                Currency.InitRoundingPrecision()
                            else
                                Currency.Get(PurchaseHeader."Currency Code");
                            CurrencyCode := Currency.Code;
                            DocumentAmount := PurchaseHeader."Amount Including VAT";
                        end;
                    else
                        OnUpdateAmount(Rec, CurrencyCode, DocumentAmount, DocType);
                end;

                CalcUpdateAmount();
                Rec.Modify();
            until Rec.Next() = 0;
    end;

    local procedure CalcUpdateAmount()
    begin
        OnBeforeCalcUpdateAmount(Rec, DocumentAmount);

        PaymentLines2.Copy(Rec);
        LastRec := PaymentLines2.Next() = 0;
        if LastRec then
            Rec.Amount := DocumentAmount - ResidualTotal
        else begin
            Rec.Amount := Round(Rec."Payment %" * DocumentAmount / 100, Currency."Amount Rounding Precision");
            ResidualTotal := ResidualTotal + Rec.Amount;
        end;

        OnAfterCalcUpdateAmount(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmount(var PaymentLines: Record "Payment Lines"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcUpdateAmount(var PaymentLines: Record "Payment Lines"; var DocumentAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUpdateAmount(var PaymentLines: Record "Payment Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAmount(var PaymentLines: Record "Payment Lines"; var CurrencyCode: Code[10]; var DocumentAmount: Decimal; DocType: Option)
    begin
    end;
}

