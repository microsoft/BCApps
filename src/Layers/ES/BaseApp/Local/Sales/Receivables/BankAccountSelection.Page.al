// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Currency;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Comment;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;

page 7000018 "Bank Account Selection"
{
    Caption = 'Bank Account Selection';
    DataCaptionExpression = Caption;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SourceTable = "Bank Account";
    SourceTableView = sorting("Currency Code");

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CategoryFilter; CategoryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Category Filter';
                    TableRelation = "Category Code";
                    ToolTip = 'Specifies the categories that the data is included for.';

                    trigger OnValidate()
                    begin
                        CategoryFilterOnAfterValidate();
                    end;
                }
                field("CurrBillGr.""Dealing Type"""; CurrBillGr."Dealing Type")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dealing Type';
                    ToolTip = 'Specifies the type of payment. Collection: The document will be sent to the bank for processing as a receivable. Discount: The document will be sent to the bank for processing as a prepayment discount. When a document is submitted for discount, the bill group bank advances the amount of the document (or a portion of it, in the case of invoices). Later, the bank is responsible for processing the collection of the document on the due date.';

                    trigger OnValidate()
                    begin
                        CurrBillGrDealingTypeOnAfterVa();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bank account number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the name of the account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                    Visible = false;
                }
                field("Credit Limit for Discount"; Rec."Credit Limit for Discount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit limit for the discount of bills available at this particular bank.';
                }
                field("Posted Receiv. Bills Rmg. Amt."; Rec."Posted Receiv. Bills Rmg. Amt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount pending from the receivables registered at this bank.';
                }
                field(RiskIncGr; RiskIncGr)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Risk Including Current Bill Group';
                    Editable = false;
                    ToolTip = 'Specifies that customers'' insolvency risk rating includes the ongoing bill group.';
                }
                field(RiskPercIncGr; RiskPercIncGr)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Risk % Including Current Bill Group';
                    ExtendedDatatype = Ratio;
                    MaxValue = 100;
                    MinValue = 0;
                    ToolTip = 'Specifies that customers'' insolvency risk rating includes the ongoing bill group.';
                }
            }
            group(Control42)
            {
                ShowCaption = false;
                fixed(Control1900668801)
                {
                    ShowCaption = false;
                    group("Curr. Bill Gr. Amount")
                    {
                        Caption = 'Curr. Bill Gr. Amount';
                        field("CurrBillGr.Amount"; CurrBillGr.Amount)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = CurrBillGr."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;

                            trigger OnDrillDown()
                            begin
                                Doc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.", "Category Code");
                                Doc.SetRange(Type, Doc.Type::Receivable);
                                Doc.SetRange("Bill Gr./Pmt. Order No.", CurrBillGr."No.");
                                Doc.SetFilter("Category Code", CategoryFilter);
                                PAGE.RunModal(0, Doc);
                            end;

                            trigger OnValidate()
                            begin
                                CurrBillGrAmountOnAfterValidat();
                            end;
                        }
                    }
                    group("Curr. Bill Gr.Currency Code")
                    {
                        Caption = 'Curr. Bill Gr.Currency Code';
                        field("CurrBillGr.""Currency Code"""; CurrBillGr."Currency Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Curr. Bill Gr.Currency Code';
                            Editable = false;
                            TableRelation = Currency;
                            ToolTip = 'Specifies the currency of the bill groups amount. ';
                        }
                    }
                    group("Curr. Bill Gr. Amt. (LCY)")
                    {
                        Caption = 'Curr. Bill Gr. Amt. (LCY)';
                        field("CurrBillGr.""Amount (LCY)"""; CurrBillGr."Amount (LCY)")
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Curr. Bill Gr. Amt. (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the current amount related to bill groups on the bank account, in LCY.';

                            trigger OnDrillDown()
                            begin
                                Doc.SetCurrentKey(Type, "Bill Gr./Pmt. Order No.", "Category Code");
                                Doc.SetRange(Type, Doc.Type::Receivable);
                                Doc.SetRange("Bill Gr./Pmt. Order No.", CurrBillGr."No.");
                                Doc.SetFilter("Category Code", CategoryFilter);
                                PAGE.RunModal(0, Doc);
                            end;

                            trigger OnValidate()
                            begin
                                CurrBillGrAmountLCYOnAfterVali();
                            end;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Bank Acc.")
            {
                Caption = '&Bank Acc.';
                Image = Bank;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record that is being processed on the document or journal line.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    RunObject = Page "Bank Account Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Bank Account"),
                                  "No." = field("No.");
                    ToolTip = 'View or create a comment.';
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Bank Account Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Balance)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance';
                    Image = Balance;
                    RunObject = Page "Bank Account Balance";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ToolTip = 'View a summary of the bank account balance in different periods.';
                }
                action("St&atements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'St&atements';
                    RunObject = Page "Bank Account Statement List";
                    RunPageLink = "Bank Account No." = field("No.");
                    ToolTip = 'View statements for selected bank accounts. For each bank transaction, the report shows a description, an applied amount, a statement amount, and other information.';
                }
                action("Chec&k Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Chec&k Ledger Entries';
                    Image = CheckLedger;
                    RunObject = Page "Check Ledger Entries";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.", "Entry Status", "Check No.");
                    ToolTip = 'View check ledger entries that result from posting transactions in a payment journal for the relevant bank account.';
                }
                separator(Action51)
                {
                }
                action("&Operation Fees")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Operation Fees';
                    RunObject = Page "Operation Fees";
                    RunPageLink = Code = field("Operation Fees Code"),
                                  "Currency Code" = field("Currency Code");
                    ToolTip = 'View the various operation fees that banks charge to process the documents that are remitted to them. These operations include: collections, discounts, discount interest, rejections, payment orders, unrisked factoring, and risked factoring.';
                }
                action("Customer Ratings")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Ratings';
                    Image = CustomerRating;
                    RunObject = Page "Customer Ratings";
                    RunPageLink = Code = field("Customer Ratings Code"),
                                  "Currency Code" = field("Currency Code");
                    ToolTip = 'View or edit the risk percentages that are assigned to customers according to their insolvency risk.';
                }
                action("Sufi&xes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sufi&xes';
                    Image = NumberSetup;
                    RunObject = Page Suffixes;
                    RunPageLink = "Bank Acc. Code" = field("No.");
                    ToolTip = 'View the bank suffixes that area assigned to manage bill groups. Typically, banks assign the company a different suffix for managing bill groups, depending if they are receivable or discount management type operations.';
                }
                separator(Action10)
                {
                    Caption = '';
                }
                action("Bill &Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill &Groups';
                    Image = VoucherGroup;
                    RunObject = Page "Bill Groups List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'View the related bill groups.';
                }
                action("Posted Bill Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Bill Groups';
                    Image = PostedVoucherGroup;
                    RunObject = Page "Posted Bill Groups List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'View the list of posted bill groups. When a bill group has been posted, the related documents are available for settlement, rejection, or recirculation.';
                }
                separator(Action27)
                {
                    Caption = '';
                }
                action("Payment O&rders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment O&rders';
                    RunObject = Page "Payment Orders List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'View or edit related payment orders.';
                }
                action("Posted P&ayment Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted P&ayment Orders';
                    Image = PostedPayment;
                    RunObject = Page "Posted Payment Orders List";
                    RunPageLink = "Bank Account No." = field("No.");
                    RunPageView = sorting("Bank Account No.");
                    ToolTip = 'View posted payment orders that represent payables to submit to the bank as a file for electronic payment.';
                }
                separator(Action60)
                {
                }
                action("Posted Recei&vable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Recei&vable Bills';
                    Image = PostedReceivableVoucher;
                    RunObject = Page "Bank Cat. Posted Receiv. Bills";
                    ToolTip = 'View the list of posted bill groups pertaining to receivables.';
                }
                action("Posted Pa&yable Bills")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Pa&yable Bills';
                    Image = PostedPayableVoucher;
                    RunObject = Page "Bank Cat. Posted Payable Bills";
                    ToolTip = 'View the list of posted bill groups pertaining to payables.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RiskIncGr := Rec."Posted Receiv. Bills Rmg. Amt.";
        if (CurrBillGr."Dealing Type" = CurrBillGr."Dealing Type"::Discount) and
           (CurrBillGr.Factoring = CurrBillGr.Factoring::" ")
        then
            RiskIncGr := RiskIncGr + CurrBillGr.Amount;
        if Rec."Credit Limit for Discount" <> 0 then
            RiskPercIncGr := RiskIncGr / Rec."Credit Limit for Discount" * 100
        else
            if RiskIncGr = 0 then
                RiskPercIncGr := 0
            else
                RiskPercIncGr := 100;
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnOpenPage()
    begin
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount, "Amount (LCY)");
        if Rec.Get(CurrBillGr."Bank Account No.") then;
    end;

    var
        Doc: Record "Cartera Doc.";
        CurrBillGr: Record "Bill Group";
        CurrPmtOrd: Record "Payment Order";
        RiskIncGr: Decimal;
        RiskPercIncGr: Decimal;
        CategoryFilter: Code[250];
        Caption: Text[250];

    [Scope('OnPrem')]
    procedure SetCurrBillGr(var CurrBillGr2: Record "Bill Group")
    begin
        Rec.Reset();
        CurrBillGr.Copy(CurrBillGr2);
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount, "Amount (LCY)", "Bank Account Name");
        Caption := StrSubstNo('%1 %2 %3', CurrBillGr2."No.", CurrBillGr2."Bank Account Name", CurrBillGr2.TableCaption());
        if (CurrBillGr."Currency Code" <> '') or
           (CurrBillGr."Bank Account No." <> '')
        then
            Rec.SetRange("Currency Code", CurrBillGr."Currency Code");
    end;

    [Scope('OnPrem')]
    procedure SetCurrPmtOrd(var CurrPmtOrd2: Record "Payment Order")
    begin
        Rec.Reset();
        CurrPmtOrd.Copy(CurrPmtOrd2);
        CurrPmtOrd.SetFilter("Category Filter", CategoryFilter);
        CurrPmtOrd.CalcFields(Amount, "Amount (LCY)", "Bank Account Name");
        Caption := StrSubstNo('%1 %2 %3', CurrPmtOrd2."No.", CurrPmtOrd2."Bank Account Name", CurrPmtOrd2.TableCaption());
        if (CurrPmtOrd."Currency Code" <> '') or
           (CurrPmtOrd."Bank Account No." <> '')
        then
            Rec.SetRange("Currency Code", CurrPmtOrd."Currency Code");
    end;

    [Scope('OnPrem')]
    procedure IsForDiscount(): Integer
    begin
        if CurrBillGr."Dealing Type" = CurrBillGr."Dealing Type"::Collection then
            exit(0); // Collection

        exit(1); // Discount
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount, "Amount (LCY)");
        CurrPage.Update(false);
    end;

    local procedure CurrBillGrDealingTypeOnAfterVa()
    begin
        CurrPage.Update();
    end;

    local procedure CurrBillGrAmountLCYOnAfterVali()
    begin
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount);
        CurrPage.Update(false);
    end;

    local procedure CurrBillGrAmountOnAfterValidat()
    begin
        CurrBillGr.SetFilter("Category Filter", CategoryFilter);
        CurrBillGr.CalcFields(Amount);
        CurrPage.Update(false);
    end;
}

