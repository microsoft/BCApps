// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

tableextension 7000080 "CRT Bank Account" extends "Bank Account"
{
    fields
    {
        field(7000000; "Delay for Notices"; Integer)
        {
            Caption = 'Delay for Notices';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(7000001; "Credit Limit for Discount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Credit Limit for Discount';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
        field(7000002; "Last Bill Gr. No."; Code[20])
        {
            Caption = 'Last Bill Gr. No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7000003; "Date of Last Post. Bill Gr."; Date)
        {
            Caption = 'Date of Last Post. Bill Gr.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7000004; "Operation Fees Code"; Code[20])
        {
            Caption = 'Operation Fees Code';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
            ValidateTableRelation = true;
        }
        field(7000005; "Posted Receiv. Bills Rmg. Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Remaining Amount" where("Bank Account No." = field("No."),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Dealing Type" = field("Dealing Type Filter"),
                                                                              Status = field("Status Filter"),
                                                                              "Category Code" = field("Category Filter"),
                                                                              "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                              "Due Date" = field("Due Date Filter"),
                                                                              Type = const(Receivable),
                                                                              "Document Type" = const(Bill)));
            Caption = 'Posted Receiv. Bills Rmg. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000006; "Posted Receiv. Bills Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = field("Dealing Type Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Category Code" = field("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Receivable),
                                                                                   "Document Type" = const(Bill)));
            Caption = 'Posted Receiv. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000007; "Closed Receiv. Bills Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Closed Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Receivable),
                                                                                   "Document Type" = const(Bill)));
            Caption = 'Closed Receiv. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000008; "Dealing Type Filter"; Enum "Cartera Dealing Type")
        {
            Caption = 'Dealing Type Filter';
            FieldClass = FlowFilter;
        }
        field(7000009; "Status Filter"; Enum "Cartera Document Status")
        {
            Caption = 'Status Filter';
            FieldClass = FlowFilter;
        }
        field(7000010; "Category Filter"; Code[10])
        {
            Caption = 'Category Filter';
            FieldClass = FlowFilter;
            TableRelation = "Category Code";
        }
        field(7000011; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(7000012; "Honored/Rejtd. at Date Filter"; Date)
        {
            Caption = 'Honored/Rejtd. at Date Filter';
            FieldClass = FlowFilter;
        }
        field(7000013; "Posted R.Bills Rmg. Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Posted Cartera Doc."."Remaining Amt. (LCY)" where("Bank Account No." = field("No."),
                                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                  "Dealing Type" = field("Dealing Type Filter"),
                                                                                  Status = field("Status Filter"),
                                                                                  "Category Code" = field("Category Filter"),
                                                                                  "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                  "Due Date" = field("Due Date Filter"),
                                                                                  Type = const(Receivable),
                                                                                  "Document Type" = const(Bill)));
            Caption = 'Posted R.Bills Rmg. Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000014; "Posted Receiv Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Posted Cartera Doc."."Amt. for Collection (LCY)" where("Bank Account No." = field("No."),
                                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                       "Dealing Type" = field("Dealing Type Filter"),
                                                                                       Status = field("Status Filter"),
                                                                                       "Category Code" = field("Category Filter"),
                                                                                       "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = field("Due Date Filter"),
                                                                                       Type = const(Receivable),
                                                                                       "Document Type" = const(Bill)));
            Caption = 'Posted Receiv Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000015; "Closed Receiv Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Closed Cartera Doc."."Amt. for Collection (LCY)" where("Bank Account No." = field("No."),
                                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                       Status = field("Status Filter"),
                                                                                       "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = field("Due Date Filter"),
                                                                                       Type = const(Receivable),
                                                                                       "Document Type" = const(Bill)));
            Caption = 'Closed Receiv Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000016; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            DataClassification = CustomerContent;
        }
        field(7000017; "Customer Ratings Code"; Code[20])
        {
            Caption = 'Customer Ratings Code';
            DataClassification = CustomerContent;
            TableRelation = "Bank Account" where("Currency Code" = field("Currency Code"));
            ValidateTableRelation = true;
        }
        field(7000018; "Posted Pay. Bills Rmg. Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Remaining Amount" where("Bank Account No." = field("No."),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Dealing Type" = field("Dealing Type Filter"),
                                                                              Status = field("Status Filter"),
                                                                              "Category Code" = field("Category Filter"),
                                                                              "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                              "Due Date" = field("Due Date Filter"),
                                                                              Type = const(Payable),
                                                                              "Document Type" = const(Bill)));
            Caption = 'Posted Pay. Bills Rmg. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000019; "Posted Pay. Bills Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = field("Dealing Type Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Category Code" = field("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Payable),
                                                                                   "Document Type" = const(Bill)));
            Caption = 'Posted Pay. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000020; "Closed Pay. Bills Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Closed Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Payable),
                                                                                   "Document Type" = const(Bill)));
            Caption = 'Closed Pay. Bills Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000021; "Posted P.Bills Rmg. Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Posted Cartera Doc."."Remaining Amt. (LCY)" where("Bank Account No." = field("No."),
                                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                  "Dealing Type" = field("Dealing Type Filter"),
                                                                                  Status = field("Status Filter"),
                                                                                  "Category Code" = field("Category Filter"),
                                                                                  "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                  "Due Date" = field("Due Date Filter"),
                                                                                  "Document Type" = const(Bill),
                                                                                  Type = const(Payable)));
            Caption = 'Posted P.Bills Rmg. Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000022; "Posted Pay. Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Posted Cartera Doc."."Amt. for Collection (LCY)" where("Bank Account No." = field("No."),
                                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                       "Dealing Type" = field("Dealing Type Filter"),
                                                                                       Status = field("Status Filter"),
                                                                                       "Category Code" = field("Category Filter"),
                                                                                       "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = field("Due Date Filter"),
                                                                                       Type = const(Payable),
                                                                                       "Document Type" = const(Bill)));
            Caption = 'Posted Pay. Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000023; "Closed Pay. Bills Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Closed Cartera Doc."."Amt. for Collection (LCY)" where("Bank Account No." = field("No."),
                                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                       Status = field("Status Filter"),
                                                                                       "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                       "Due Date" = field("Due Date Filter"),
                                                                                       Type = const(Payable),
                                                                                       "Document Type" = const(Bill)));
            Caption = 'Closed Pay. Bills Amt. (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000024; "Post. Receivable Inv. Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = field("Dealing Type Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Category Code" = field("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Receivable),
                                                                                   "Document Type" = const(Invoice)));
            Caption = 'Post. Receivable Inv. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000025; "Clos. Receivable Inv. Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Closed Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Receivable),
                                                                                   "Document Type" = const(Invoice)));
            Caption = 'Clos. Receivable Inv. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000026; "Posted Pay. Invoices Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = field("Dealing Type Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Category Code" = field("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Payable),
                                                                                   "Document Type" = const(Invoice)));
            Caption = 'Posted Pay. Invoices Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000027; "Closed Pay. Invoices Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Closed Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Payable),
                                                                                   "Document Type" = const(Invoice)));
            Caption = 'Closed Pay. Invoices Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000028; "Posted Pay. Inv. Rmg. Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Remaining Amount" where("Bank Account No." = field("No."),
                                                                              "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                              "Dealing Type" = field("Dealing Type Filter"),
                                                                              Status = field("Status Filter"),
                                                                              "Category Code" = field("Category Filter"),
                                                                              "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                              "Due Date" = field("Due Date Filter"),
                                                                              Type = const(Payable),
                                                                              "Document Type" = const(Invoice)));
            Caption = 'Posted Pay. Inv. Rmg. Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000029; "Posted Pay. Documents Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Posted Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   "Dealing Type" = field("Dealing Type Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Category Code" = field("Category Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Payable)));
            Caption = 'Posted Pay. Documents Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7000030; "Closed Pay. Documents Amt."; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            CalcFormula = sum("Closed Cartera Doc."."Amount for Collection" where("Bank Account No." = field("No."),
                                                                                   "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                                   Status = field("Status Filter"),
                                                                                   "Honored/Rejtd. at Date" = field("Honored/Rejtd. at Date Filter"),
                                                                                   "Due Date" = field("Due Date Filter"),
                                                                                   Type = const(Payable)));
            Caption = 'Closed Pay. Documents Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    var
        CarteraSetup: Record "Cartera Setup";
        PostedBillGr: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        PostedPmtOrd: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";

    [Scope('OnPrem')]
    procedure DiscInterestsTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Discount Interests Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Discount Interests Amt.");
            exit(PostedBillGr."Discount Interests Amt." + ClosedBillGr."Discount Interests Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure ServicesFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Discount Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Discount Expenses Amt.");
            exit(PostedBillGr."Discount Expenses Amt." + ClosedBillGr."Discount Expenses Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure CollectionFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Collection Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Collection Expenses Amt.");
            exit(PostedBillGr."Collection Expenses Amt." + ClosedBillGr."Collection Expenses Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure RejExpensesAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Rejection Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Rejection Expenses Amt.");
            exit(PostedBillGr."Rejection Expenses Amt." + ClosedBillGr."Rejection Expenses Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure RiskFactFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Risked Factoring Exp. Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Risked Factoring Exp. Amt.");
            exit(PostedBillGr."Risked Factoring Exp. Amt." + ClosedBillGr."Risked Factoring Exp. Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure UnriskFactFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Collection Expenses Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Unrisked Factoring Exp. Amt.");
            exit(PostedBillGr."Unrisked Factoring Exp. Amt." + ClosedBillGr."Unrisked Factoring Exp. Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure DiscInterestFactTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            PostedBillGr.SetRange("Bank Account No.", "No.");
            PostedBillGr.SetFilter(Factoring, '<>%1', PostedBillGr.Factoring::" ");
            PostedBillGr.SetFilter("Posting Date", PostDateFilter);
            PostedBillGr.CalcSums("Discount Interests Amt.");
            ClosedBillGr.SetCurrentKey("Bank Account No.", "Posting Date", Factoring);
            ClosedBillGr.SetRange("Bank Account No.", "No.");
            ClosedBillGr.SetFilter(Factoring, '<>%1', ClosedBillGr.Factoring::" ");
            ClosedBillGr.SetFilter("Posting Date", PostDateFilter);
            ClosedBillGr.CalcSums("Discount Interests Amt.");
            PostedBillGr.SetRange(Factoring);
            ClosedBillGr.SetRange(Factoring);
            exit(PostedBillGr."Discount Interests Amt." + ClosedBillGr."Discount Interests Amt.");
        end;
    end;

    [Scope('OnPrem')]
    procedure PaymentOrderFeesTotalAmt(PostDateFilter: Code[250]): Decimal
    begin
        if CarteraSetup.ReadPermission then begin
            PostedPmtOrd.SetCurrentKey("Bank Account No.", "Posting Date");
            PostedPmtOrd.SetRange("Bank Account No.", "No.");
            PostedPmtOrd.SetFilter("Posting Date", PostDateFilter);
            PostedPmtOrd.CalcSums("Payment Order Expenses Amt.");
            ClosedPmtOrd.SetCurrentKey("Bank Account No.", "Posting Date");
            ClosedPmtOrd.SetRange("Bank Account No.", "No.");
            ClosedPmtOrd.SetFilter("Posting Date", PostDateFilter);
            ClosedPmtOrd.CalcSums("Payment Order Expenses Amt.");
            exit(PostedPmtOrd."Payment Order Expenses Amt." + ClosedPmtOrd."Payment Order Expenses Amt.");
        end;
    end;
}