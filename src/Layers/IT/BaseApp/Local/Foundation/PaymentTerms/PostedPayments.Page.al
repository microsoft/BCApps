// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

page 12172 "Posted Payments"
{
    Caption = 'Posted Payments';
    DataCaptionFields = "Sales/Purchase", Type, "Code";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Payment Lines";

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
                    ToolTip = 'Specifies the formula that is used to calculate the date that a payment must be made in order to obtain a discount.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the discount percentage that is applied for early payment of an invoice amount.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when early payment of an invoice is due in order to get a discount on the amount.';
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
        Currency: Record Currency;
        PostedPaymentLines2: Record "Posted Payment Lines";
        DocumentAmount: Decimal;
        CurrencyCode: Code[20];
        LastRec: Boolean;
        ResidualTotal: Decimal;

    procedure UpdateAmount()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        OnBeforeUpdateAmount(Rec);
        ClearAll();
        if Rec.Find('-') then
            repeat
                DocumentAmount := 0;
                case Rec."Sales/Purchase" of
                    Rec."Sales/Purchase"::Sales:
                        case Rec.Type of
                            Rec.Type::Invoice:
                                if SalesInvoiceHeader.Get(Rec.Code) then begin
                                    SalesInvoiceHeader.CalcFields("Amount Including VAT");
                                    DocumentAmount := SalesInvoiceHeader."Amount Including VAT";
                                    CurrencyCode := SalesInvoiceHeader."Currency Code";
                                end;
                            Rec.Type::"Credit Memo":
                                if SalesCrMemoHeader.Get(Rec.Code) then begin
                                    CurrencyCode := SalesCrMemoHeader."Currency Code";
                                    SalesCrMemoHeader.CalcFields("Amount Including VAT");
                                    DocumentAmount := SalesCrMemoHeader."Amount Including VAT";
                                end;
                        end;
                    Rec."Sales/Purchase"::Purchase:
                        case Rec.Type of
                            Rec.Type::Invoice:
                                if PurchInvHeader.Get(Rec.Code) then begin
                                    PurchInvHeader.CalcFields("Amount Including VAT");
                                    DocumentAmount := PurchInvHeader."Amount Including VAT";
                                    CurrencyCode := PurchInvHeader."Currency Code";
                                end;
                            Rec.Type::"Credit Memo":
                                if PurchCrMemoHdr.Get(Rec.Code) then begin
                                    CurrencyCode := PurchCrMemoHdr."Currency Code";
                                    PurchCrMemoHdr.CalcFields("Amount Including VAT");
                                    DocumentAmount := PurchCrMemoHdr."Amount Including VAT";
                                end;
                        end;
                    else
                        OnUpdateAmount(Rec, CurrencyCode, DocumentAmount);
                end;

                if CurrencyCode = '' then
                    Currency.InitRoundingPrecision()
                else begin
                    Currency.Get(CurrencyCode);
                    Currency.TestField("Amount Rounding Precision");
                end;

                CalcUpdateAmount();
                Rec.Modify();
            until Rec.Next() = 0;
    end;

    local procedure CalcUpdateAmount()
    begin
        OnBeforeCalcUpdateAmount(Rec, DocumentAmount);

        Rec.Amount := Rec."Payment %" * DocumentAmount / 100;
        PostedPaymentLines2.Copy(Rec);
        LastRec := PostedPaymentLines2.Next() = 0;
        if LastRec then
            Rec.Amount := DocumentAmount - ResidualTotal
        else begin
            Rec.Amount := Round(Rec."Payment %" * DocumentAmount / 100, Currency."Amount Rounding Precision");
            ResidualTotal := ResidualTotal + Rec.Amount;
        end;

        OnAfterCalcUpdateAmount(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAmount(var PostedPaymentLines: Record "Posted Payment Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcUpdateAmount(var PostedPaymentLines: Record "Posted Payment Lines"; var DocumentAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUpdateAmount(var PostedPaymentLines: Record "Posted Payment Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAmount(var PostedPaymentLines: Record "Posted Payment Lines"; var CurrencyCode: Code[10]; var DocumentAmount: Decimal)
    begin
    end;
}

