// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;

/// <summary>
/// Page 983 "Payment Registration Details" provides detailed view and editing capabilities for individual payment registration entries.
/// This page displays comprehensive payment information including document details, payment discounts, and warning messages.
/// </summary>
/// <remarks>
/// Source table: Payment Registration Buffer. Used for detailed payment entry management
/// with navigation to related customer records and document exploration.
/// </remarks>
page 983 "Payment Registration Details"
{
    Caption = 'Payment Registration Details';
    DataCaptionExpression = PageCaptionVariable;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    SourceTable = "Payment Registration Buffer";

    layout
    {
        area(content)
        {
            group("Document Name")
            {
                Caption = 'Document Name';
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = true;
                    ToolTip = 'Specifies the name of the customer or vendor that the payment relates to.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        Customer.Get(Rec."Source No.");
                        PAGE.Run(PAGE::"Customer Card", Customer);
                    end;
                }
            }
            group("Document Details")
            {
                Caption = 'Document Details';
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that the payment relates to.';

                    trigger OnDrillDown()
                    begin
                        Rec.Navigate();
                    end;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of document that the payment relates to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the invoice transaction that the payment relates to.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = DueDateStyle;
                    ToolTip = 'Specifies the payment due date on the related document.';
                }
            }
            group("Payment Discount")
            {
                Caption = 'Payment Discount';
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = PmtDiscStyle;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions();
                    end;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = PmtDiscStyle;
                    ToolTip = 'Specifies the amount that remains to be paid on the document.';
                }
                field("Rem. Amt. after Discount"; Rec."Rem. Amt. after Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount after the payment discount is deducted.';
                }
            }
            group(Warning)
            {
                Caption = 'Warning';
                fixed(Control21)
                {
                    ShowCaption = false;
                    group(Control20)
                    {
                        ShowCaption = false;
                        field(WarningField; Warning)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            Style = Unfavorable;
                            StyleExpr = true;
                            ToolTip = 'Specifies a warning about the payment, such as past due date.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("New Document")
            {
                Caption = 'New Document';
                action(FinanceChargeMemo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Memo';
                    Image = FinChargeMemo;
                    RunObject = Page "Finance Charge Memo";
                    RunPageLink = "Customer No." = field("Source No.");
                    RunPageMode = Create;
                    ToolTip = 'Create a finance charge memo for the customer on the selected line, for example, to issue a finance charge for late payment.';
                }
            }
            group(Action19)
            {
                Caption = 'Navigate';
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                    trigger OnAction()
                    begin
                        Rec.Navigate();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(FinanceChargeMemo_Promoted; FinanceChargeMemo)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetUserInteractions();
    end;

    trigger OnOpenPage()
    begin
        PageCaptionVariable := '';
    end;

    var
        PmtDiscStyle: Text;
        DueDateStyle: Text;
        Warning: Text;
        PageCaptionVariable: Text;

    local procedure SetUserInteractions()
    begin
        PmtDiscStyle := Rec.GetPmtDiscStyle();
        DueDateStyle := Rec.GetDueDateStyle();
        Warning := Rec.GetWarning();
    end;
}

