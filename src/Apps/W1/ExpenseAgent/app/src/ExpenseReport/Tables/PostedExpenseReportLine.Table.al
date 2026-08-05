// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

table 6916 "Posted Expense Report Line"
{
    Access = Internal;
    Caption = 'Posted Expense Report Line';
    DataClassification = CustomerContent;
    LookupPageId = "Posted Expense Report Lines";
    ReplicateData = false;

    fields
    {
        field(1; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
        }
        field(2; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
            TableRelation = "Posted Expense Report Header"."No.";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; Justification; Text[100])
        {
            Caption = 'Justification';
        }
        field(8; "Additional Information"; Text[100])
        {
            Caption = 'Additional Information';
        }
        field(9; "Expense Date"; Date)
        {
            Caption = 'Expense Date';
        }
        field(10; "Expense Currency Code"; Code[10])
        {
            Caption = 'Expense Currency Code';
            TableRelation = Currency.Code;
            Editable = false;
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(12; "VAT Liable"; Boolean)
        {
            Caption = 'VAT Liable';
        }
        field(13; "Amount without VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount without VAT';
        }
        field(14; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(15; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
            Editable = false;
        }
        field(16; "Merchant Name"; Text[100])
        {
            Caption = 'Merchant Name';
        }
        field(17; "Reimbursement Type"; Enum "Expense Reimbursement Type")
        {
            Caption = 'Reimbursement Type';
        }
        field(18; "Receipt Attached"; Boolean)
        {
            Caption = 'Receipt Attached';
            Editable = false;
        }
        field(19; "Receipt Entry"; Integer)
        {
            Caption = 'Receipt Entry';
            Editable = false;
        }
        field(20; "Account Type"; Enum "Expense Line Type")
        {
            Caption = 'Account Type';
        }
        field(21; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(" ")) "Standard Text"
            else
            if ("Account Type" = const(Resource)) Resource
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("G/L Account")) "G/L Account" where(Blocked = const(false))
            else
            if ("Account Type" = const(Item)) Item
            else
            if ("Account Type" = const("Charge (Item)")) "Item Charge";

            ValidateTableRelation = false;
        }
        field(22; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1), Blocked = const(false));
        }
        field(23; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        field(24; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Expense Payment Method".Code;
        }
        field(25; Refundable; Boolean)
        {
            Caption = 'Refundable';
        }
        field(26; "Purchase Invoice"; Boolean)
        {
            Caption = 'Purchase Invoice';
        }
        field(27; "Posted Purch. Invoice No."; Code[20])
        {
            Caption = 'Posted Purchase Invoice No.';
            TableRelation = "Purch. Inv. Header"."No.";
        }
        field(28; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";
        }
        field(29; "Posted Date"; Date)
        {
            Caption = 'Posted Date';
        }
        field(30; Billable; Boolean)
        {
            Caption = 'Billable';
        }
        field(31; "Billable to Customer"; Code[20])
        {
            Caption = 'Billable to Customer';
            TableRelation = Customer."No.";
        }
        field(32; "Expense Location"; Code[20])
        {
            Caption = 'Expense Location';
            TableRelation = "Expense Location"."No.";
        }
        field(33; "Starting Date and Time"; DateTime)
        {
            Caption = 'Starting Date and Time';
        }
        field(34; "Ending Date and Time"; DateTime)
        {
            Caption = 'Ending Date and Time';
        }
        field(35; "Non-Refundable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'Non-Refundable Amount';
        }
        field(36; "Starting Point"; Text[50])
        {
            Caption = 'Starting Point';
        }
        field(37; "Ending Point"; Text[50])
        {
            Caption = 'Ending Point';
        }
        field(38; "Non-Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Non-Refundable Amount (LCY)';
        }
        /// <summary>
        /// Calculates the net reimbursable amount after applying reductions and currency conversion.
        /// The conversion date and currency factor used for the reimbursement calculation
        /// depend on the Expense Agent Setup configuration.
        /// Determines whether the employee is paid or must repay an amount.
        /// if the Reimbursement Type is not "Employee Paid" then reimbursement amount will be 0 or -Non-Refundable Amount.
        /// </summary>
        field(39; "Reimbursable Amount"; Decimal)
        {
            AutoFormatExpression = GetReimbursementCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount';
        }
        /// <summary>
        /// Calculates the net reimbursable amount after applying reductions and currency conversion.
        /// The conversion date and currency factor used for the reimbursement calculation
        /// depend on the Expense Agent Setup configuration.
        /// Determines whether the employee is paid or must repay an amount in local currency.
        /// if the Reimbursement Type is not "Employee Paid" then reimbursement amount will be 0 or -Non-Refundable Amount in local currency.
        /// </summary>
        field(40; "Reimbursable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Reimbursable Amount (LCY)';
        }
        field(41; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'VAT Amount (LCY)';
            Editable = false;
        }
        field(42; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(44; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
        field(45; "Expense Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Expense Currency Factor';
        }
        field(46; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category"));
        }
        field(47; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(48; "Expense Time"; Time)
        {
            Caption = 'Expense Time';
        }
        field(49; "Itemized Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Posted Exp. Rep. Line Item"."Amount" where("Expense Report No." = field("Document No."),
                                                                          "Expense Report Line No." = field("Line No.")));
        }
        field(50; "Mileage"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Mileage';
        }
        field(67; "Round Trip"; Boolean)
        {
            Caption = 'Round Trip';
            ToolTip = 'Specifies whether the mileage expense is a round trip. When enabled, the distance is doubled for reimbursement calculation.';
        }
        field(51; "Credit Card Feed No."; Integer)
        {
            Caption = 'Credit Card Feed No.';
        }
        field(52; "Applied Rule Id"; Guid)
        {
            Caption = 'Applied Rule Id';
        }
        field(53; "Amount without VAT (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount without VAT (LCY)';
            Editable = false;
        }
        field(54; "Expense Detail Required"; Enum "Expense Detail Needed")
        {
            Caption = 'Expense Detail Required';
        }
        field(56; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No.";
        }
        field(57; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(58; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(59; "VAT Difference"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Difference';
            Editable = false;
        }
        field(60; "Calculated VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'Calculated VAT Amount';
            Editable = false;
        }
        /// <summary>
        /// Calculates the refundable amount using the exchange rate on the posting date
        /// and the currency from the Expense Report Header, rather than the expense date,
        /// to ensure accurate currency conversion.
        /// Refundable will be always be updated with the value that will be posted to the Refundable Account.
        /// </summary>
        field(65; "Refundable Amount"; Decimal)
        {
            AutoFormatExpression = GetReimbursementCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Refundable Amount';
        }
        /// <summary>
        /// Calculates the refundable amount using the exchange rate on the posting date
        /// and the currency from the Expense Report Header, rather than the expense date,
        /// to ensure accurate currency conversion in local currency.
        /// Refundable will be always be updated with the value that will be posted to the Refundable Account in local currency.
        /// </summary>
        field(66; "Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Refundable Amount (LCY)';
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(81; "Expense Ext. Doc. No."; Code[30])
        {
            Caption = 'Expense External Document No.';
        }
        field(85; "Merchant Registration No."; Text[50])
        {
            Caption = 'Merchant Registration No.';
        }
        field(86; "Merchant VAT Registration No."; Text[20])
        {
            Caption = 'Merchant VAT Registration No.';
        }
        field(90; "Created By Exp. User Id"; Guid)
        {
            Caption = 'Created By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(91; "Modified By Exp. User Id"; Guid)
        {
            Caption = 'Modified By Expense User Id';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(92; Canceled; Boolean)
        {
            Caption = 'Canceled';
            Editable = false;
        }
        field(100; "Spend Request No."; Code[20])
        {
            Caption = 'Spend Request No.';
            ToolTip = 'Specifies the spend request to which the posted expense report line is linked.';
            TableRelation = "Spend Request";
        }
        field(101; "Spend Request Close"; Boolean)
        {
            Caption = 'Spend Request Close';
            ToolTip = 'Specifies that the spend request will be closed when the expense report is posted.';
            DataClassification = CustomerContent;
        }
        field(1000; "Job Ledger Entry No."; Integer)
        {
            Caption = 'Project Ledger Entry No.';
            TableRelation = "Job Ledger Entry"."Entry No.";
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        DimMgt: Codeunit DimensionManagement;

    procedure GetReimbursementCurrencyCode(): Code[10]
    begin
        if PostedExpenseReportHeader.Get("Document No.") then
            exit(PostedExpenseReportHeader."Reimbursement Currency Code");

        exit('');
    end;

    procedure ShowDimensions() IsChanged: Boolean
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', "Document No.", "Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        IsChanged := OldDimSetID <> "Dimension Set ID";
    end;

    procedure ShowLineComments()
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        ExpenseCommentSheet: Page "Expense Report Comment Sheet";
    begin
        TestField("Document No.");
        TestField("Line No.");

        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportCommentLine."Document Type"::"Posted Expense Report".AsInteger());
        ExpenseReportCommentLine.SetRange("No.", "Document No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", "Line No.");
        ExpenseCommentSheet.SetTableView(ExpenseReportCommentLine);
        ExpenseCommentSheet.RunModal();
    end;
}
