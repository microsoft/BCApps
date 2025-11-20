// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;

/// <summary>
/// Page 981 "Payment Registration" provides a worksheet interface for registering customer payments.
/// This page allows users to quickly record received payments against outstanding customer documents,
/// with features for automatic posting and balance account setup.
/// </summary>
/// <remarks>
/// Source table: Payment Registration Buffer (temporary). Used for rapid payment entry and posting
/// with integrated customer lookup and payment validation.
/// </remarks>
page 981 "Payment Registration"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Register Customer Payments';
    DataCaptionExpression = BalAccCaption;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    AboutTitle = 'About Register Customer Payments';
    AboutText = 'Register and post customer payments against sales documents, track received amounts and dates, and update customer, general ledger, and bank ledger entries for full or partial payments.';
    SourceTable = "Payment Registration Buffer";
    SourceTableTemporary = true;
    UsageCategory = Tasks;
    AdditionalSearchTerms = 'Payment Registration, Receive Customer Payments';

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer or vendor that the payment relates to.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                    begin
                        Customer.Get(Rec."Source No.");
                        PAGE.Run(PAGE::"Customer Card", Customer);
                    end;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that the payment relates to.';
                    Visible = false;

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
                    Visible = false;
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
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = PmtDiscStyle;
                    ToolTip = 'Specifies the amount that remains to be paid on the document.';
                }
                field("Payment Made"; Rec."Payment Made")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you have received or made payment for the document.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions();
                    end;
                }
                field("Date Received"; Rec."Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DueDateStyle;
                    ToolTip = 'Specifies the date when the payment was made.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions();
                    end;
                }
                field("Amount Received"; Rec."Amount Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that is paid in the bank account.';

                    trigger OnValidate()
                    begin
                        SetUserInteractions();
                    end;
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    StyleExpr = PmtDiscStyle;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        SetUserInteractions();
                    end;
                }
                field("Rem. Amt. after Discount"; Rec."Rem. Amt. after Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Rem Amount Incl. Discount';
                    Editable = false;
                    ToolTip = 'Specifies the remaining amount after the payment discount is deducted.';
                    Visible = false;
                }
                field(ExternalDocumentNo; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Document No.';
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
            }
            grid("Bal. Account Details")
            {
                Caption = 'Bal. Account Details';
                field(PostedBalance; PostedBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Balance';
                    Editable = false;
                    ToolTip = 'Specifies the balance of payments posted to the balancing account that is being used in the Payment Registration window.';
                }
                field(UnpostedBalance; UnpostedBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unposted Balance';
                    Editable = false;
                    ToolTip = 'Specifies the amount that exists on unposted journal lines with the same balancing account as the one used in the Payment Registration window.';
                }
                field(TotalBalance; TotalBalance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Balance';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the sum of posted amounts and unposted journal line amounts for the balancing account that is being used on the Payment Registration page. The value in this field is the sum of values in the Posted Balance and the Unposted Balance fields.';
                }
            }
            group(Control27)
            {
                ShowCaption = false;
                Visible = Warning <> '';
                fixed(Control26)
                {
                    ShowCaption = false;
                    group(Control24)
                    {
                        ShowCaption = false;
                        field(Warning; Warning)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
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
            group("Related Information")
            {
                Caption = 'Related Information';
                Image = Navigate;
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    Scope = Repeater;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                    trigger OnAction()
                    begin
                        Rec.Navigate();
                    end;
                }
                action(Details)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Details';
                    Image = ViewDetails;
                    Scope = Repeater;
                    ToolTip = 'View additional information about the document on the selected line and link to the related customer card.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Payment Registration Details", Rec);
                    end;
                }
            }
            group(Search)
            {
                Caption = 'Search';
                action(SearchCustomer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Search Customers';
                    Image = Navigate;
                    RunObject = Page "Customer List";
                    ToolTip = 'Open the list of customers, for example, to check for missing payments from a specific customer.';
                }
                action(SearchDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Search Documents';
                    Image = Navigate;
                    RunObject = Page "Document Search";
                    ToolTip = 'Find documents that are not fully invoiced, for example, to post an invoice so that the received payment can be processed.';
                }
            }
        }
        area(processing)
        {
            group(Post)
            {
                Caption = 'Post';
                Image = Post;
                action(PostPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Payments';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post payment of amounts on the lines where the Payment Made check box is selected.';

                    trigger OnAction()
                    begin
                        PaymentRegistrationMgt.ConfirmPost(Rec);
                    end;
                }
                action(PostAsLump)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post as Lump Payment';
                    Image = PostBatch;
                    ToolTip = 'Post payment as a lump sum of amounts on lines where the Payment Made check box is selected.';

                    trigger OnAction()
                    begin
                        PaymentRegistrationMgt.ConfirmPostLumpPayment(Rec);
                    end;
                }
                action(PreviewPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting Payments';
                    Image = ViewPostedOrder;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal. When you perform the actual posting, you may be asked how to post payment tolerance entries. The posting preview assumes the default option: that each payment tolerance is posted as one entry.';

                    trigger OnAction()
                    var
                        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
                    begin
                        PaymentRegistrationMgt.Preview(Rec, false);
                    end;
                }
                action(PreviewLump)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting Payments as Lump';
                    Image = ViewPostedOrder;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal as a lump sum of amounts. When you perform the actual posting, you may be asked how to post payment tolerance entries. The posting preview assumes the default option: that each payment tolerance is posted as one entry.';

                    trigger OnAction()
                    var
                        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
                    begin
                        PaymentRegistrationMgt.Preview(Rec, true);
                    end;
                }
            }
            group("New Documents")
            {
                Caption = 'New Documents';
                action(OpenGenJnl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal';
                    Image = GLRegisters;
                    ToolTip = 'Open the general journal, for example, to record or post a payment that has no related document.';

                    trigger OnAction()
                    begin
                        PaymentRegistrationMgt.OpenGenJnl();
                    end;
                }
                action(FinanceChargeMemo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Finance Charge Memo';
                    Image = FinChargeMemo;
                    RunObject = Page "Finance Charge Memo";
                    RunPageLink = "Customer No." = field("Source No.");
                    RunPageMode = Create;
                    Scope = Repeater;
                    ToolTip = 'Create a finance charge memo for the customer on the selected line, for example, to issue a finance charge for late payment.';
                }
            }
            group(Action36)
            {
                Caption = 'Setup';
                Image = Setup;
                action(Setup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Setup';
                    Image = Setup;
                    ToolTip = 'Adjust how payments are posted and which balancing account to use.';

                    trigger OnAction()
                    begin
                        if PAGE.RunModal(PAGE::"Payment Registration Setup") = ACTION::LookupOK then
                            FormatPageCaption();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_New)
                {
                    Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                    actionref(FinanceChargeMemo_Promoted; FinanceChargeMemo)
                    {
                    }
                }
                group(Category_Category4)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref(PostPayments_Promoted; PostPayments)
                    {
                    }
                    actionref(PostAsLump_Promoted; PostAsLump)
                    {
                    }
                    actionref(PreviewPayments_Promoted; PreviewPayments)
                    {
                    }
                    actionref(PreviewLump_Promoted; PreviewLump)
                    {
                    }
                }
                actionref(Setup_Promoted; Setup)
                {
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref(Details_Promoted; Details)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Search', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(SearchCustomer_Promoted; SearchCustomer)
                {
                }
                actionref(SearchDocument_Promoted; SearchDocument)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Setup', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Category8)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 7.';

            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetUserInteractions();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Rec.Reload();
        PaymentRegistrationMgt.CalculateBalance(PostedBalance, UnpostedBalance);
        TotalBalance := PostedBalance + UnpostedBalance;
        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        PaymentRegistrationMgt.RunSetup();
        FormatPageCaption();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(PaymentRegistrationMgt.ConfirmClose(Rec));
    end;

    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        BalAccCaption: Text;
        PmtDiscStyle: Text;
        DueDateStyle: Text;
        Warning: Text;
        PostedBalance: Decimal;
        UnpostedBalance: Decimal;
        TotalBalance: Decimal;

    local procedure FormatPageCaption()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get(UserId);
        BalAccCaption := Format(PaymentRegistrationSetup."Bal. Account Type") + ' - ' + PaymentRegistrationSetup."Bal. Account No.";
    end;

    local procedure SetUserInteractions()
    begin
        PmtDiscStyle := Rec.GetPmtDiscStyle();
        DueDateStyle := Rec.GetDueDateStyle();
        Warning := Rec.GetWarning();
    end;
}

