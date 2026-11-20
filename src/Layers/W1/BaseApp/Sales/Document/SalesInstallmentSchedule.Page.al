// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using System.Environment.Configuration;

using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Receivables;

page 8841 "Sales Installment Schedule"
{
    Caption = 'Sales Installment Schedule';
    PageType = List;
    SourceTable = "Sales Installment Plan Line";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InstructionalText = 'Preview calculated from the invoice rule snapshot and current totals. Posting recalculates the schedule using final invoice totals. Only supported standalone sales invoices can post.';

    layout
    {
        area(Content)
        {
            group(Invoice)
            {
                Caption = 'Invoice';
                field(SourceDocumentNo; SourceDocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the sales invoice being previewed.';
                }
                field(DocumentCurrencyCode; DocumentCurrencyCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the document currency. A blank value represents local currency.';
                }
            }
            repeater(Lines)
            {
                field("Installment No."; Rec."Installment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the consecutive installment number.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the installment due date calculated from the document date.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the installment amount including VAT in document currency.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the independently allocated installment amount in local currency.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last payment date for the installment payment discount, before any grace period.';
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the snapshotted payment discount percentage.';
                }
                field("Original Pmt. Disc. Possible"; Rec."Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated eligible payment discount in document currency, using the current posting date and grace period.';
                }
                field("Rounding Adjustment"; Rec."Rounding Adjustment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the final document currency residual assigned to this installment.';
                }
                field("Rounding Adjustment (LCY)"; Rec."Rounding Adjustment (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the independent final local currency residual.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the snapshotted installment description.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureKeyManagement.CheckPaymentInstallmentsEnabled();
    end;

    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
        SourceDocumentNo: Code[20];
        DocumentCurrencyCode: Code[10];

    internal procedure SetSchedule(SalesHeader: Record "Sales Header"; var TempPlanLine: Record "Sales Installment Plan Line" temporary)
    begin
        Rec.Copy(TempPlanLine, true);
        Rec.Reset();
        SourceDocumentNo := SalesHeader."No.";
        DocumentCurrencyCode := SalesHeader."Currency Code";
    end;
}
