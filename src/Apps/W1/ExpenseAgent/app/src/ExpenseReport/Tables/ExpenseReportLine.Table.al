// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SpendRequest;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Utilities;

table 6907 "Expense Report Line"
{
    Access = Internal;
    Caption = 'Expense Report Line';
    DataClassification = CustomerContent;
    DrillDownPageId = "Expense Report Lines";
    LookupPageId = "Expense Report Lines";
    ReplicateData = false;

    fields
    {
        field(1; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
            Editable = false;

            trigger OnValidate()
            begin
                GetExpenseReportHeader();

                Rec.TestField("Expense User No.", ExpenseReportHeader."Expense User No.");
            end;
        }
        field(2; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
            Editable = false;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Expense Report Header"."No.";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code where(Inactive = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();
                GetExpenseReportHeader();

                if Rec."Expense Category" <> xRec."Expense Category" then begin
                    ConfirmAndDeleteAssociatedRecords(Rec.FieldCaption("Expense Category"));

                    ClearRuleId();
                    UpdateFromExpenseCategory();
                    ApplyRule();
                end;
            end;
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(7; Justification; Text[100])
        {
            Caption = 'Justification';

            trigger OnValidate()
            begin
                TestStatusOpen();

                ApplyRule();
            end;
        }
        field(8; "Additional Information"; Text[100])
        {
            Caption = 'Additional Information';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(9; "Expense Date"; Date)
        {
            Caption = 'Expense Date';

            trigger OnValidate()
            begin
                if "Expense Date" <> xRec."Expense Date" then begin
                    TestStatusOpen();
                    ClearRuleId();
                    UpdateAmounts();
                    ApplyRule();
                end;
            end;
        }
        field(10; "Expense Currency Code"; Code[10])
        {
            Caption = 'Expense Currency Code';
            TableRelation = Currency.Code;

            trigger OnValidate()
            begin
                TestStatusOpen();
                GetExpenseReportHeader();
                UpdateAmounts();
                ApplyRule();
            end;
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
                ApplyRule();
            end;
        }
        field(12; "VAT Liable"; Boolean)
        {
            Caption = 'VAT Liable';

            trigger OnValidate()
            var
                ExpenseBillingInformation: Page "Expense Billing Information";
            begin
                TestStatusOpen();

                if Rec."VAT Liable" then begin
                    Rec.TestField("Non-Refundable Amount", 0);
                    Rec.TestField(Refundable, true);

                    if Rec."Vendor No." = '' then begin
                        if GuiAllowed then begin
                            Rec.Modify();
                            Commit();
                            ExpenseBillingInformation.SetRecord(Rec);
                            ExpenseBillingInformation.RunModal();
                            ExpenseBillingInformation.GetRecord(Rec);
                        end;

                        Rec.TestField("Vendor No.");
                    end;
                end;

                UpdateAmounts();
            end;
        }
        field(13; "Amount without VAT"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount without VAT';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(14; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'VAT Amount';

            trigger OnValidate()
            var
                CurrencyToConsider: Record Currency;
                RefundableAmount: Decimal;
                CurrFactor: Decimal;
                ConversionDate: Date;
            begin
                TestStatusOpen();
                Rec.TestField("VAT %");
                Rec.TestField("Amount without VAT");
                if Rec."VAT Amount" / Rec."Amount without VAT" < 0 then
                    Error(CannotBeNegativeErr, FieldCaption("VAT Amount"));
                Rec."VAT Difference" := Rec."VAT Amount" - Rec."Calculated VAT Amount";

                if ExpenseReportHeader."Reimbursement Currency Code" = '' then begin
                    if Rec."Expense Currency Code" = '' then
                        CurrencyToConsider.InitRoundingPrecision()
                    else
                        CurrencyToConsider.Get(Rec."Expense Currency Code");
                end else
                    CurrencyToConsider.Get(ExpenseReportHeader."Reimbursement Currency Code");

                ConversionDate := ExpenseReportHeader."Posting Date";
                CurrFactor := CurrencyExchangeRate.ExchangeRate(ConversionDate, CurrencyToConsider.Code);

                CheckVATDifference(CurrencyToConsider);
                GetExpenseReportHeader();

                RefundableAmount := Rec."Reimbursable Amount";

                Rec."Amount without VAT" := RefundableAmount - Rec."VAT Amount";

                if ExpenseReportHeader."Reimbursement Currency Code" = '' then begin
                    Rec."VAT Amount (LCY)" := Rec."VAT Amount";
                    Rec."Amount without VAT (LCY)" := Rec."Amount without VAT";
                end else begin
                    Rec."Amount without VAT (LCY)" :=
                        Round(
                            CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                                ConversionDate,
                                CurrencyToConsider.Code,
                                Rec."Amount without VAT",
                                CurrFactor),
                                CurrencyToConsider."Amount Rounding Precision");

                    Rec."VAT Amount (LCY)" :=
                       Round(
                           CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                               ConversionDate,
                               CurrencyToConsider.Code,
                               Rec."VAT Amount",
                               CurrFactor),
                               CurrencyToConsider."Amount Rounding Precision");
                end;
            end;
        }
        field(15; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
            end;
        }
        field(16; "Merchant Name"; Text[100])
        {
            Caption = 'Merchant Name';

            trigger OnValidate()
            begin
                if xRec."Merchant Name" <> Rec."Merchant Name" then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
        }
        field(17; "Reimbursement Type"; Enum "Expense Reimbursement Type")
        {
            Caption = 'Reimbursement Type';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();

                ApplyRule();
                UpdateAmounts();
            end;
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

            trigger OnValidate()
            begin
                TestStatusOpen();

                if (Rec."Receipt Entry" <> 0) then
                    Rec.Validate("Receipt Attached", true);
            end;
        }
        field(20; "Account Type"; Enum "Expense Line Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Rec."Account Type" <> xRec."Account Type" then
                    if Rec."Account No." <> '' then
                        Rec.Validate("Account No.", '');
            end;
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

            trigger OnValidate()
            begin
                TestStatusOpen();

                GetExpenseReportHeader();
                InitHeaderDefaults(ExpenseReportHeader);

                case "Account Type" of
                    "Account Type"::" ":
                        CopyFromStandardText();
                    "Account Type"::"G/L Account":
                        CopyFromGLAccount();
                    "Account Type"::Item:
                        CopyFromItem();
                    "Account Type"::Resource:
                        CopyFromResource();
                    "Account Type"::"Fixed Asset":
                        CopyFromFixedAsset();
                    "Account Type"::"Bank Account":
                        CopyFromBankAccount();
                    "Account Type"::"Charge (Item)":
                        CopyFromItemCharge();
                end;

                CreateDimFromDefaultDim(Rec.FieldNo("Account No."));
            end;
        }
        field(22; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1), Blocked = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();

                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(23; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();

                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(24; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Expense Payment Method";

            trigger OnValidate()
            var
                ExpensePaymentMethod: Record "Expense Payment Method";
            begin
                TestStatusOpen();

                if xRec."Payment Method Code" <> Rec."Payment Method Code" then begin
                    Rec.Validate("Reimbursement Type", Rec."Reimbursement Type"::" ");

                    if Rec."Payment Method Code" <> '' then begin
                        ExpensePaymentMethod.Get(Rec."Payment Method Code");

                        Rec.Validate("Reimbursement Type", ExpensePaymentMethod."Reimbursement Type");
                    end;
                end;
            end;
        }
        field(25; Refundable; Boolean)
        {
            Caption = 'Refundable';

            trigger OnValidate()
            begin
                TestStatusOpen();
                GetExpenseReportHeader();

                if not Rec.Refundable then begin
                    Rec.TestField("VAT Liable", false);
                    Rec.TestField("Non-Refundable Amount", 0);
                    Rec.Validate("Spend Request No.", '');
                    Rec."Spend Request Close" := false;
                end;

                if Rec.Refundable and (Rec."Expense User No." <> '') then begin
                    Rec.SetSkipSpendRequestClose(true);
                    Rec.Validate("Spend Request No.", ExpenseReportHeader."Spend Request No.");
                    Rec."Spend Request Close" := ExpenseReportHeader."Spend Request Close";
                    Rec.SetSkipSpendRequestClose(false);
                end;

                UpdateAmounts();
            end;
        }
        field(26; "Purchase Invoice"; Boolean)
        {
            Caption = 'Purchase Invoice';

            trigger OnValidate()
            begin
                if xRec."Purchase Invoice" <> Rec."Purchase Invoice" then begin
                    Rec.Validate("Vendor No.", '');
                    Rec.Validate("Posted Purch. Invoice No.", '');
                end;

                TestStatusOpen();
            end;
        }
        field(27; "Posted Purch. Invoice No."; Code[20])
        {
            Caption = 'Posted Purchase Invoice No.';
            TableRelation = "Purch. Inv. Header"."No.";

            trigger OnValidate()
            begin
                if Rec."Posted Purch. Invoice No." <> '' then begin
                    Rec.TestField("Vendor No.");
                    Rec.TestField("Purchase Invoice", true);
                end;

                TestStatusOpen();
            end;
        }
        field(28; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Rec."Vendor No." = '' then
                    Rec.TestField("VAT Liable", false);
            end;
        }
        field(29; "Posted Date"; Date)
        {
            Caption = 'Posted Date';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(30; Billable; Boolean)
        {
            Caption = 'Billable';

            trigger OnValidate()
            begin
                if xRec.Billable <> Rec.Billable then
                    Rec.Validate("Billable to Customer", '');

                TestStatusOpen();
            end;
        }
        field(31; "Billable to Customer"; Code[20])
        {
            Caption = 'Billable to Customer';
            TableRelation = Customer."No.";

            trigger OnValidate()
            begin
                TestStatusOpen();

                if (Rec."Billable to Customer" <> '') and (Rec."Job No." <> '') then
                    Error(BillableCustomerAndProjectErr, Rec.FieldCaption("Billable to Customer"), Rec.FieldCaption("Job No."));

                CreateDimFromDefaultDim(Rec.FieldNo("Billable to Customer"));
            end;
        }
        field(32; "Expense Location"; Code[20])
        {
            Caption = 'Expense Location';
            TableRelation = "Expense Location"."No.";

            trigger OnValidate()
            begin
                TestStatusOpen();

                if "Expense Location" <> xRec."Expense Location" then begin
                    if ModificationDoneOnPerDiemCategory(xRec."Expense Detail Required") then
                        DeleteExpenseReportLinePerDiem();

                    CheckForAssociatedRecords(Rec."Document No.", Rec."Line No.", Rec.FieldCaption("Expense Location"));
                    if Rec."Expense Location" <> '' then
                        if not (Rec."Expense Detail Required" = Rec."Expense Detail Required"::"Per Diem") then
                            Error(OnlyUseExpenseLocationWithPerDiemErr, Rec."Expense Location", Rec."Expense Category", Rec."Document No.");

                    if Rec."Starting Date and Time" = 0DT then
                        Rec."Starting Date and Time" := CurrentDateTime;

                    if Rec."Ending Date and Time" = 0DT then
                        Rec."Ending Date and Time" := CurrentDateTime;

                    ClearRuleId();
                end;

                ApplyRule();
            end;
        }
        field(33; "Starting Date and Time"; DateTime)
        {
            Caption = 'Starting Date and Time';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Rec."Starting Date and Time" = 0DT then
                    Rec."Ending Date and Time" := 0DT;

                if Rec."Starting Date and Time" > Rec."Ending Date and Time" then
                    Rec."Ending Date and Time" := Rec."Starting Date and Time";

                ApplyRule();
            end;
        }
        field(34; "Ending Date and Time"; DateTime)
        {
            Caption = 'Ending Date and Time';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if (Rec."Ending Date and Time" <> 0DT) and (Rec."Ending Date and Time" < Rec."Starting Date and Time") then
                    Error(InvalidEndingDateErr);

                ApplyRule();
            end;
        }
        field(35; "Non-Refundable Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Non-Refundable Amount';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if Rec."Non-Refundable Amount" < 0 then
                    Error(NonRefundableCannotBeNegativeErr, Rec.FieldCaption("Non-Refundable Amount"), Rec."Document No.", Rec."Line No.");

                if Rec."Non-Refundable Amount" <> 0 then
                    Rec.TestField("VAT Liable", false);

                if Amount < "Non-Refundable Amount" then
                    Error(NonRefundableGreaterThanAmountErr, Rec.FieldCaption("Non-Refundable Amount"));

                UpdateAmounts();
                ApplyRule();
            end;
        }
        field(36; "Starting Point"; Text[50])
        {
            Caption = 'Starting Point';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(37; "Ending Point"; Text[50])
        {
            Caption = 'Ending Point';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(38; "Non-Refundable Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Non-Refundable Amount (LCY)';

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
            end;
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
            BlankZero = true;
            Caption = 'Reimbursable Amount';

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
            end;
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
            BlankZero = true;
            Caption = 'Reimbursable Amount (LCY)';

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
            end;
        }
        field(41; "VAT Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'VAT Amount (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
            end;

        }
        field(42; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(43; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                TestStatusOpen();
                GetExpenseReportHeader();
                Rec.TestField("VAT Bus. Posting Group", ExpenseReportHeader."VAT Bus. Posting Group");
                Rec.Validate("VAT Prod. Posting Group");
            end;
        }
        field(44; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                TestStatusOpen();

                if Rec."VAT Prod. Posting Group" <> xRec."VAT Prod. Posting Group" then
                    ClearVATPostingValues();

                if Rec."VAT Prod. Posting Group" <> '' then begin
                    VATPostingSetup.Get(Rec."VAT Bus. Posting Group", Rec."VAT Prod. Posting Group");
                    CopyFromVATPostingSetup(VATPostingSetup);
                end;

                if Rec."Expense Currency Code" = '' then
                    ExpenseCurrency.InitRoundingPrecision()
                else
                    ExpenseCurrency.Get(Rec."Expense Currency Code");

                if Rec."VAT Liable" then
                    UpdateAmounts();
            end;
        }
        field(45; "Expense Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Expense Currency Factor';
        }
        field(46; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            TableRelation = "Expense SubCategory".Code where("Expense Category Code" = field("Expense Category"), Inactive = const(false));

            trigger OnValidate()
            begin
                TestStatusOpen();

                ApplyRule();
            end;
        }
        field(47; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            begin
                TestStatusOpen();

                ApplyRule();
            end;
        }
        field(48; "Expense Time"; Time)
        {
            Caption = 'Expense Time';

            trigger OnValidate()
            begin
                TestStatusOpen();

                ApplyRule();
            end;
        }
        field(49; "Itemized Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Expense Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Expense Report Line Item"."Amount" where("Expense Report No." = field("Document No."),
                                                                        "Expense Report Line No." = field("Line No.")));
        }
        field(50; "Mileage"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Mileage';

            trigger OnValidate()
            begin
                TestStatusOpen();

                ApplyRule();
            end;
        }
        field(67; "Round Trip"; Boolean)
        {
            Caption = 'Round Trip';
            ToolTip = 'Specifies whether the mileage expense is a round trip. When enabled, the distance is doubled for reimbursement calculation.';

            trigger OnValidate()
            begin
                TestStatusOpen();

                ApplyRule();
            end;
        }
        field(51; "Credit Card Feed No."; Integer)
        {
            Caption = 'Credit Card Feed No.';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(52; "Applied Rule Id"; Guid)
        {
            Caption = 'Applied Rule Id';

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(53; "Amount without VAT (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount without VAT (LCY)';
            Editable = false;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(54; "Expense Detail Required"; Enum "Expense Detail Needed")
        {
            Caption = 'Expense Detail Required';
        }
        field(55; "Rule Violations"; Boolean)
        {
            Caption = 'Rule Violations';
            FieldClass = FlowField;
            CalcFormula = exist("Expense Report Rule Violation" where("Expense Report No." = field("Document No."), "Report Line No." = field("Line No.")));
            Editable = false;
        }
        field(56; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job."No." where(Status = filter(<> Completed));

            trigger OnValidate()
            begin
                TestStatusOpen();
                GetExpenseReportHeader();

                if (Rec."Job No." <> '') and (Rec."Billable to Customer" <> '') then
                    Error(BillableCustomerAndProjectErr, Rec.FieldCaption("Billable to Customer"), Rec.FieldCaption("Job No."));

                if xRec."Job No." <> Rec."Job No." then
                    Rec.Validate("Job Task No.", '');

                CreateDimFromDefaultDim(Rec.FieldNo("Job No."));
            end;
        }
        field(57; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
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
        field(62; "Expense Vendor No."; Code[20])
        {
            Caption = 'Expense Vendor No.';
            ToolTip = 'Specifies the expense vendor record created for accountant review and matching to a Business Central vendor.';
            TableRelation = "Expense Vendor";
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

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
            end;
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

            trigger OnValidate()
            begin
                TestStatusOpen();

                UpdateAmounts();
            end;
        }
        field(77; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(81; "Expense Ext. Doc. No."; Code[30])
        {
            Caption = 'Expense External Document No.';

            trigger OnValidate()
            begin
                if xRec."Expense Ext. Doc. No." <> Rec."Expense Ext. Doc. No." then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
        }
        field(85; "Merchant Registration No."; Text[50])
        {
            Caption = 'Merchant Registration No.';

            trigger OnValidate()
            begin
                if xRec."Merchant Registration No." <> Rec."Merchant Registration No." then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
        }
        field(86; "Merchant VAT Registration No."; Text[20])
        {
            Caption = 'Merchant VAT Registration No.';
            trigger OnValidate()
            begin
                if xRec."Merchant VAT Registration No." <> Rec."Merchant VAT Registration No." then begin
                    TestStatusOpen();
                    ApplyRule(false, true);
                end;
            end;
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
        field(92; "User Confirmed"; Boolean)
        {
            Caption = 'User Confirmed';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestStatusOpen();
            end;
        }
        field(100; "Spend Request No."; Code[20])
        {
            Caption = 'Spend Request No.';
            ToolTip = 'Specifies the spend request number that is associated with this expense report line.The spend request must be approved and released before it can be selected.';
            TableRelation = "Spend Request" where(Status = const(Approved));

            trigger OnValidate()
            var
                SpendRequest: Record "Spend Request";
                DimensionSetIDArr: array[10] of Integer;
            begin
                if Rec."Spend Request No." <> '' then begin
                    Rec.TestField(Refundable, true);
                    CheckTraveler();
                    SpendRequest.SetSkipSpendRequestClose(SkipSpendRequestClose);
                    SpendRequest.ValidateSpendRequest(Rec."Spend Request No.", Rec."Spend Request Close", Rec."Refundable Amount (LCY)");

                    if SpendRequest."Dimension Set ID" <> 0 then begin
                        DimensionSetIDArr[1] := Rec."Dimension Set ID";
                        DimensionSetIDArr[2] := SpendRequest."Dimension Set ID";
                        Rec."Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, Rec."Shortcut Dimension 1 Code", Rec."Shortcut Dimension 2 Code");
                    end;
                end else
                    Rec."Spend Request Close" := false;
            end;
        }
        field(101; "Spend Request Close"; Boolean)
        {
            Caption = 'Spend Request Close';
            ToolTip = 'Specifies that the spend request will be closed when the expense report is posted.';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        GetExpenseReportHeader();
        InitHeaderDefaults(ExpenseReportHeader);
        ValidateDate();
        SetExpenseUserOnCreate();
        ApplyRule();
    end;

    trigger OnModify()
    begin
        UpdateExpenseUserOnModify();
    end;

    trigger OnDelete()
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        DeleteAssociatedRecords();

        RemoveExpenseReportNoInExpense();

        ExpenseReportRuleViolation.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", Rec."Line No.");
        if not ExpenseReportRuleViolation.IsEmpty() then
            ExpenseReportRuleViolation.DeleteAll(true);

        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportCommentLine."Document Type"::"Expense Report".AsInteger());
        ExpenseReportCommentLine.SetRange("No.", "Document No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", "Line No.");
        ExpenseReportCommentLine.DeleteAll();
    end;

    var
        ExpenseReportHeader: Record "Expense Report Header";
        ReimbursementCurrency: Record Currency;
        ExpenseCurrency: Record Currency;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DimMgt: Codeunit DimensionManagement;
        ExpenseAgentAPIValidation: Codeunit "Expense Agent API Validation";
        SkipRuleApplication: Boolean;
        HideValidationDialog: Boolean;
        SkipSpendRequestClose: Boolean;
        EmptyGuid: Guid;
        InvalidEndingDateErr: Label 'Ending Date and Time cannot be earlier than Starting Date and Time.';
        CannotModifyWithParticipantsErr: Label 'You cannot modify %1 field of expense report %2, Line No. %3 because it has associated participants.', Comment = '%1 = Field Name, %2 = Expense No., %3 = Line No.';
        CannotModifyWithItemizationErr: Label 'You cannot modify %1 field of expense report %2, Line No. %3 because it has associated itemizations.', Comment = '%1 = Field Name, %2 = Expense No., %3 = Line No.';
        DeleteAssociatedRecordsQst: Label 'If you change %1, the existing %2 details will be deleted.\\Do you want to continue?', Comment = '%1 = Field Name, %2 = Expense Detail Required';
        OnlyUseExpenseLocationWithPerDiemErr: Label 'The selected Expense Location %1 and Expense Category %2 can only be used with per diem expenses on Expense No. %3.', Comment = '%1 = Expense Location, %2 = Expense Category, %3 = Expense No.';
        NonRefundableGreaterThanAmountErr: Label '%1 cannot be greater than Amount.', Comment = '%1 = Field Caption';
        NonRefundableCannotBeNegativeErr: Label '%1 cannot be in negative on Expense Report No. %2, Line No. %3.', Comment = '%1 = Field Caption, %2 = Expense Report No., %3 = Line No.';
        CannotUseVATCalcTypeErr: Label 'You cannot use VAT Calculation Type %1 in Expense Report Line Expense No. %2, Line No. %3', Comment = '%1 = VAT Calculation Type, %2 = Expense No., %3 = Line No.';
        CannotBeNegativeErr: Label '%1 must not be negative.', Comment = '%1 = Field Name';
        CannotExceedForErr: Label '%1 for %2 must not exceed %3 = %4.', Comment = '%1 = Field Name, %2 = Description, %3 = Limit Field Name, %4 = Limit Value';
        CannotExceedErr: Label '%1 must not exceed %2 = %3.', Comment = '%1 = Field Name, %2 = Limit Field Name, %3 = Limit Value';
        ExpenseReportNotFoundErr: Label 'Expense Report %1 does not exist.', Comment = '%1 = Expense Report No.';
        OnlyRelinkToAnotherReportErr: Label 'You can only relink an expense report line to another expense report.';
        ExpenseUserNotTravelerErr: Label 'Expense User %1 is not a traveler on Spend Request %2.', Comment = '%1 = Expense User No., %2 = Spend Request No.';
        BillableCustomerAndProjectErr: Label 'You cannot use both %1 and %2 at the same time.', Comment = '%1 = Billable to Customer field caption, %2 = Project No. field caption';

    internal procedure CopyFromVATPostingSetup(var VATPostingSetupFrom: Record "VAT Posting Setup")
    begin
        "VAT %" := VATPostingSetupFrom."VAT %";

        if VATPostingSetupFrom."VAT Calculation Type" <> VATPostingSetupFrom."VAT Calculation Type"::"Normal VAT" then
            Error(CannotUseVATCalcTypeErr, VATPostingSetupFrom."VAT Calculation Type", Rec."Document No.", Rec."Line No.");

        "VAT Calculation Type" := VATPostingSetupFrom."VAT Calculation Type";
    end;

    internal procedure ClearVATPostingValues()
    begin
        "VAT %" := 0;
    end;

    procedure DeleteAssociatedRecords()
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        ExpenseReportLineItemization: Record "Expense Report Line Item";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpenseReportLineParticip.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportLineParticip.SetRange("Expense Report Line No.", Rec."Line No.");
        if not ExpenseReportLineParticip.IsEmpty() then
            ExpenseReportLineParticip.DeleteAll();

        ExpenseReportLineItemization.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportLineItemization.SetRange("Expense Report Line No.", Rec."Line No.");
        if not ExpenseReportLineItemization.IsEmpty() then
            ExpenseReportLineItemization.DeleteAll();

        ExpenseReportLinePerDiem.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", Rec."Line No.");
        if not ExpenseReportLinePerDiem.IsEmpty() then
            ExpenseReportLinePerDiem.DeleteAll();
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    local procedure ConfirmAndDeleteAssociatedRecords(FieldCaption: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not HasAssociatedRecords() then
            exit;

        if not HideValidationDialog then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteAssociatedRecordsQst, FieldCaption, Rec."Expense Detail Required"), true) then
                Error('');

        DeleteAssociatedRecords();
    end;

    local procedure HasAssociatedRecords(): Boolean
    var
        ExpenseReportLineParticip: Record "Expense Report Line Particip.";
        ExpenseReportLineItemization: Record "Expense Report Line Item";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        case Rec."Expense Detail Required" of
            Rec."Expense Detail Required"::Itemize:
                begin
                    ExpenseReportLineItemization.SetRange("Expense Report No.", Rec."Document No.");
                    ExpenseReportLineItemization.SetRange("Expense Report Line No.", Rec."Line No.");
                    exit(not ExpenseReportLineItemization.IsEmpty());
                end;
            Rec."Expense Detail Required"::Participants:
                begin
                    ExpenseReportLineParticip.SetRange("Expense Report No.", Rec."Document No.");
                    ExpenseReportLineParticip.SetRange("Expense Report Line No.", Rec."Line No.");
                    exit(not ExpenseReportLineParticip.IsEmpty());
                end;
            Rec."Expense Detail Required"::"Per Diem":
                begin
                    ExpenseReportLinePerDiem.SetRange("Expense Report No.", Rec."Document No.");
                    ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", Rec."Line No.");
                    exit(not ExpenseReportLinePerDiem.IsEmpty());
                end;
        end;
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

        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportCommentLine."Document Type"::"Expense Report".AsInteger());
        ExpenseReportCommentLine.SetRange("No.", "Document No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", "Line No.");
        ExpenseCommentSheet.SetTableView(ExpenseReportCommentLine);
        ExpenseCommentSheet.RunModal();
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, Rec."Dimension Set ID");
    end;

    local procedure ValidateDate()
    begin
        if Rec."Expense Date" = 0D then
            Rec."Expense Date" := WorkDate();
    end;

    local procedure CopyFromStandardText()
    var
        StandardText: Record "Standard Text";
    begin
        "VAT Liable" := false;
        StandardText.Get("Account No.");
        Description := StandardText.Description;
    end;

    local procedure CopyFromGLAccount()
    var
        GLAcc: Record "G/L Account";
    begin
        if "Account No." = '' then
            exit;

        GLAcc.Get("Account No.");
        GLAcc.CheckGLAcc();
        GLAcc.TestField("Direct Posting", true);
        Description := GLAcc.Name;
        "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
        "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
    end;

    local procedure CopyFromItem()
    var
        Item: Record Item;
    begin
        Description := '';
        if not Item.Get("Account No.") then
            exit;

        Item.TestField(Blocked, false);
        Item.TestField("Gen. Prod. Posting Group");
        Description := Item.Description;
        "VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";

        CreateDimFromDefaultDim(Rec.FieldNo("Account No."));
    end;

    local procedure ModificationDoneOnPerDiemCategory(ExpenseDetail: Enum "Expense Detail Needed"): Boolean
    begin
        exit(ExpenseDetail = ExpenseDetail::"Per Diem");
    end;

    local procedure DeleteExpenseReportLinePerDiem()
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", Rec."Line No.");
        if not ExpenseReportLinePerDiem.IsEmpty() then
            ExpenseReportLinePerDiem.DeleteAll();
    end;

    local procedure CopyFromResource()
    var
        Resource: Record Resource;
    begin
        Description := '';
        if not Resource.Get("Account No.") then
            exit;

        Resource.CheckResourcePrivacyBlocked(false);
        Resource.TestField(Blocked, false);
        Resource.TestField("Gen. Prod. Posting Group");
        Description := Resource.Name;
        "VAT Prod. Posting Group" := Resource."VAT Prod. Posting Group";


        CreateDimFromDefaultDim(Rec.FieldNo("Account No."));
    end;

    local procedure CopyFromFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        Description := '';
        if not FixedAsset.Get("Account No.") then
            exit;

        FixedAsset.TestField(Inactive, false);
        FixedAsset.TestField(Blocked, false);
        Description := FixedAsset.Description;

        CreateDimFromDefaultDim(Rec.FieldNo("Account No."));
    end;

    local procedure CopyFromBankAccount()
    var
        BankAcc: Record "Bank Account";
    begin
        Description := '';
        if not BankAcc.Get("Account No.") then
            exit;

        BankAcc.TestField(Blocked, false);
        Description := BankAcc.Name;

        CreateDimFromDefaultDim(Rec.FieldNo("Account No."));
    end;

    local procedure CopyFromItemCharge()
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get("Account No.");
        Description := ItemCharge.Description;
        "VAT Prod. Posting Group" := ItemCharge."VAT Prod. Posting Group";
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        ShouldCreateDim: Boolean;
    begin
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        ShouldCreateDim := DimMgt.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo));
        if ShouldCreateDim then
            CreateDefaultDim(DefaultDimSource);
    end;

    procedure UpdatePostingDescription(): Text[100]
    var
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        if "Expense Subcategory Code" <> '' then begin
            ExpenseSubcategory.Get("Expense Category", "Expense Subcategory Code");
            exit(CopyStr(Description + ' - ' + ExpenseSubcategory."Posting Description", 1, 100));
        end;
        exit(CopyStr(Description, 1, 100));
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        case Rec."Account Type" of
            Rec."Account Type"::"G/L Account":
                DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", Rec."Account No.", FieldNo = Rec.FieldNo("Account No."));
            Rec."Account Type"::Item:
                DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Account No.", FieldNo = Rec.FieldNo("Account No."));
            Rec."Account Type"::Resource:
                DimMgt.AddDimSource(DefaultDimSource, Database::Resource, Rec."Account No.", FieldNo = Rec.FieldNo("Account No."));
            Rec."Account Type"::"Bank Account":
                DimMgt.AddDimSource(DefaultDimSource, Database::"Bank Account", Rec."Account No.", FieldNo = Rec.FieldNo("Account No."));
            Rec."Account Type"::"Fixed Asset":
                DimMgt.AddDimSource(DefaultDimSource, Database::"Fixed Asset", Rec."Account No.", FieldNo = Rec.FieldNo("Account No."));
            Rec."Account Type"::"Charge (Item)":
                DimMgt.AddDimSource(DefaultDimSource, Database::"Item Charge", Rec."Account No.", FieldNo = Rec.FieldNo("Account No."));
        end;

        DimMgt.AddDimSource(DefaultDimSource, Database::Customer, Rec."Billable to Customer", FieldNo = Rec.FieldNo("Billable to Customer"));
        DimMgt.AddDimSource(DefaultDimSource, Database::Vendor, Rec."Vendor No.", FieldNo = Rec.FieldNo("Vendor No."));
        DimMgt.AddDimSource(DefaultDimSource, Database::Job, Rec."Job No.", FieldNo = Rec.FieldNo("Job No."));
    end;

    procedure CreateDefaultDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        GetExpenseReportHeader();
        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';

        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup.Expense,
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ExpenseReportHeader."Dimension Set ID", Database::Employee);

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    begin
        case true of
            FieldNo = Rec.FieldNo("Account No."):
                TableValuePair.Add(ExpenseLineTypeToTableID("Account Type"), Rec."Account No.");
            FieldNo = Rec.FieldNo("Billable to Customer"):
                TableValuePair.Add(Database::Customer, Rec."Billable to Customer");
            FieldNo = Rec.FieldNo("Vendor No."):
                TableValuePair.Add(Database::Vendor, Rec."Vendor No.");
            FieldNo = Rec.FieldNo("Job No."):
                TableValuePair.Add(Database::Job, Rec."Job No.");
        end;
    end;

    local procedure ExpenseLineTypeToTableID(LineType: Enum "Expense Line Type"): Integer
    begin
        case LineType of
            "Expense Line Type"::"G/L Account":
                exit(Database::"G/L Account");
            "Expense Line Type"::Item:
                exit(Database::Item);
            "Expense Line Type"::Resource:
                exit(Database::Resource);
            "Expense Line Type"::"Fixed Asset":
                exit(Database::"Fixed Asset");
            "Expense Line Type"::"Bank Account":
                exit(Database::"Bank Account");
            "Expense Line Type"::"Charge (Item)":
                exit(Database::"Item Charge");
        end;
    end;

    procedure IsDefaultDimDefinedForTable(TableValuePair: Dictionary of [Integer, Code[20]]): Boolean
    var
        DefaultDim: Record "Default Dimension";
    begin
        if TableValuePair.Count = 0 then
            exit(true);

        DefaultDim.SetRange("Table ID", TableValuePair.Keys.Get(1));
        DefaultDim.SetFilter("No.", '%1|%2', TableValuePair.Values.Get(1), '');
        DefaultDim.SetFilter("Dimension Value Code", '<>%1', '');
        if not DefaultDim.IsEmpty() then
            exit(true);
    end;

    procedure InitHeaderDefaults(ExpReportHeader: Record "Expense Report Header")
    begin
        CheckExpenseReportDocument(ExpReportHeader);

        "Expense User No." := ExpReportHeader."Expense User No.";
        "Posted Date" := ExpReportHeader."Posting Date";
        "VAT Bus. Posting Group" := ExpReportHeader."VAT Bus. Posting Group";

        if Rec."Expense No." = '' then begin
            "Expense Date" := ExpReportHeader."Expense Report Date";
            "Expense Currency Code" := ExpReportHeader."Reimbursement Currency Code";
        end;

        if Rec."Expense Date" = 0D then
            Rec."Expense Date" := ExpReportHeader."Expense Report Date";

        if Rec.Refundable then begin
            "Spend Request No." := ExpReportHeader."Spend Request No.";
            "Spend Request Close" := ExpReportHeader."Spend Request Close";
        end;

        "Dimension Set ID" := ExpReportHeader."Dimension Set ID";
    end;

    local procedure CheckExpenseReportDocument(ExpReportHeader: Record "Expense Report Header")
    begin
        ExpReportHeader.TestField("No.");
        ExpReportHeader.TestField("Expense User No.");
    end;

    procedure UpdateAmounts()
    begin
        UpdateVATAmount();

        if Rec."Non-Refundable Amount" <> 0 then
            Rec.TestField(Refundable, true);

        UpdateAmountLCY();
        UpdateAmountByReimbursementType();

        if ("Spend Request No." <> '') and Rec.Refundable then
            CheckSpendRequestAmount();
    end;

    local procedure CheckSpendRequestAmount()
    var
        SpendRequest: Record "Spend Request";
    begin
        SpendRequest.CheckSpendRequestAmount(Rec."Spend Request No.", Rec."Refundable Amount (LCY)");
    end;

    local procedure UpdateVATAmount()
    var
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RefundableAmount: Decimal;
        RefundableAmountLCY: Decimal;
    begin
        GetExpenseReportHeader();

        Rec."VAT Amount" := 0;
        Rec."VAT Amount (LCY)" := 0;
        Rec."Amount without VAT" := 0;
        Rec."Amount without VAT (LCY)" := 0;
        Rec."VAT Difference" := 0;

        RefundableAmount := Rec."Reimbursable Amount";
        RefundableAmountLCY := Rec."Reimbursable Amount (LCY)";

        ExpenseReportPost.UpdateVATAmount(
            RefundableAmount, RefundableAmountLCY,
            Rec."VAT Amount", Rec."VAT Amount (LCY)",
            Rec."Amount without VAT", Rec."Amount without VAT (LCY)",
            ExpenseReportHeader, Rec);

        Rec."Calculated VAT Amount" := Rec."VAT Amount";
    end;

    procedure CheckVATDifference(Currency: Record Currency)
    var
        GLSetup: Record "General Ledger Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.GetRecordOnce();
        if not PurchSetup."Allow VAT Difference" then
            Rec.TestField("VAT Difference", 0);

        if Abs("VAT Difference") > Currency."Max. VAT Difference Allowed" then
            if Currency.Code <> '' then
                Error(
                  CannotExceedForErr, Rec.FieldCaption("VAT Difference"), Currency.Code,
                  Currency.FieldCaption("Max. VAT Difference Allowed"), Currency."Max. VAT Difference Allowed")
            else begin
                if GLSetup.Get() then;
                if Abs(Rec."VAT Difference") > GLSetup."Max. VAT Difference Allowed" then
                    Error(
                      CannotExceedErr, Rec.FieldCaption("VAT Difference"),
                      GLSetup.FieldCaption("Max. VAT Difference Allowed"), GLSetup."Max. VAT Difference Allowed");
            end;
    end;

    local procedure UpdateAmountLCY()
    begin
        UpdateCurrencyFactor();

        ExpenseCurrency.Initialize(Rec."Expense Currency Code");
        if Rec."Expense Currency Code" = '' then begin
            Rec."Amount (LCY)" := Rec.Amount;
            Rec."Non-Refundable Amount (LCY)" := Rec."Non-Refundable Amount";
        end else begin
            Rec."Amount (LCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                        GetExpenseCurrencyDate(), Rec."Expense Currency Code", Rec.Amount, Rec."Expense Currency Factor"),
                    ExpenseCurrency."Amount Rounding Precision");
            Rec."Non-Refundable Amount (LCY)" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                        GetExpenseCurrencyDate(), Rec."Expense Currency Code", Rec."Non-Refundable Amount", Rec."Expense Currency Factor"),
                    ExpenseCurrency."Amount Rounding Precision");
        end;
    end;

    local procedure UpdateAmountByReimbursementType()
    begin
        GetExpenseReportHeader();
        ExpenseAgentSetup.GetRecordOnce();
        ReimbursementCurrency.Initialize(ExpenseReportHeader."Reimbursement Currency Code");

        Rec."Reimbursable Amount (LCY)" := 0;
        Rec."Reimbursable Amount" := 0;
        Rec."Refundable Amount (LCY)" := 0;
        Rec."Refundable Amount" := 0;

        if Rec.Refundable then
            UpdateRefundableAmount();

        if (Rec.Refundable) or (Rec."Reimbursement Type" <> Rec."Reimbursement Type"::"Employee Paid") then
            UpdateReimbursableAmount();
    end;

    local procedure UpdateReimbursableAmount()
    begin
        // The conversion date and currency factor to consider for reimbursement calculation will depend on the setup in Expense Agent Setup. 
        // If the setup is based on posting date, then the conversion date will be the posting date of the expense report. 
        // If the setup is based on expense date, then the conversion date will be the expense date of the line.

        // When the reimbursement type is "Employee Paid" and Refundable is true, the Non-Refundable Amount will reduce from Amount and will be reimbursed to the employee.
        // When the reimbursement type is not "Employee Paid" and Refundable is false, the amount will be paid by the employee that is the reimbursable amount.
        if (Rec."Reimbursement Type" = Rec."Reimbursement Type"::"Employee Paid") or (not Rec.Refundable) then begin
            Rec."Reimbursable Amount (LCY)" :=
                Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    GetReimbursementConversionDate(),
                    ExpenseCurrency.Code,
                    Rec.Amount - Rec."Non-Refundable Amount",
                    CurrencyExchangeRate.ExchangeRate(GetReimbursementConversionDate(), ExpenseCurrency.Code)),
                ExpenseCurrency."Amount Rounding Precision");

            // When the reimbursement type is not "Employee Paid" and Refundable is false, the amount will be paid by the employee that is the reimbursable amount and sign must be negative.
            if not Rec.Refundable then
                Rec."Reimbursable Amount (LCY)" := -1 * Rec."Reimbursable Amount (LCY)";

            if ExpenseCurrency.Code = ReimbursementCurrency.Code then begin
                if Rec.Refundable then
                    Rec."Reimbursable Amount" := Rec.Amount - Rec."Non-Refundable Amount"
                else
                    Rec."Reimbursable Amount" := -1 * (Rec.Amount - Rec."Non-Refundable Amount");
            end else
                Rec."Reimbursable Amount" :=
                    Round(
                        CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                            GetReimbursementConversionDate(),
                            ReimbursementCurrency.Code,
                            Rec."Reimbursable Amount (LCY)",
                            CurrencyExchangeRate.ExchangeRate(GetReimbursementConversionDate(), ReimbursementCurrency.Code)),
                        ReimbursementCurrency."Amount Rounding Precision")
        end else begin
            // The Non-Refundable Amount to consider for reimbursement should also be converted to LCY using the exchange rate on the conversion date, regardless of whether the expense currency and reimbursement currency are the same or not.
            // When the reimbursement type is not "Employee Paid" and Refundable is true, the Non-Refundable Amount will be paid by the employee that is the reimbursable amount.
            Rec."Reimbursable Amount (LCY)" :=
                -Round(
                    CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                        GetReimbursementConversionDate(),
                        ExpenseCurrency.Code,
                        Rec."Non-Refundable Amount",
                        CurrencyExchangeRate.ExchangeRate(GetReimbursementConversionDate(), ExpenseCurrency.Code)),
                    ExpenseCurrency."Amount Rounding Precision");

            if ExpenseCurrency.Code = ReimbursementCurrency.Code then
                Rec."Reimbursable Amount" := -Rec."Non-Refundable Amount"
            else
                Rec."Reimbursable Amount" :=
                    Round(
                        CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                            GetReimbursementConversionDate(),
                            ReimbursementCurrency.Code,
                            Rec."Reimbursable Amount (LCY)",
                            CurrencyExchangeRate.ExchangeRate(GetReimbursementConversionDate(), ReimbursementCurrency.Code)),
                        ReimbursementCurrency."Amount Rounding Precision");
        end;
    end;

    local procedure UpdateRefundableAmount()
    begin
        Rec."Refundable Amount" := Rec.Amount - Rec."Non-Refundable Amount";

        // For refundable amount calculation, we need to consider the exchange rate on posting date, not on the date of expense date.
        // Because We need to post rounding difference on reimbursable amount if the exchange rate on posting date is different from the exchange rate based on expense date in setup.
        // so we need to consider exchange rate on posting date for conversion to calculate the accurate refundable amount in LCY and calculate the rounding difference.
        Rec."Refundable Amount (LCY)" :=
            Round(
                CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    ExpenseReportHeader."Posting Date",
                    ExpenseCurrency.Code,
                    Rec."Refundable Amount",
                    CurrencyExchangeRate.ExchangeRate(ExpenseReportHeader."Posting Date", ExpenseCurrency.Code)),
                ExpenseCurrency."Amount Rounding Precision");

        if ExpenseCurrency.Code <> ReimbursementCurrency.Code then
            Rec."Refundable Amount" :=
                Round(
                    CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                        ExpenseReportHeader."Posting Date",
                        ReimbursementCurrency.Code,
                        Rec."Refundable Amount (LCY)",
                        CurrencyExchangeRate.ExchangeRate(ExpenseReportHeader."Posting Date", ReimbursementCurrency.Code)),
                    ReimbursementCurrency."Amount Rounding Precision");
    end;

    local procedure UpdateCurrencyFactor()
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        CurrencyDate: Date;
    begin
        if Rec."Expense Currency Code" <> '' then begin
            if Rec."Expense Date" <> 0D then
                CurrencyDate := "Expense Date"
            else
                CurrencyDate := WorkDate();

            if UpdateCurrencyExchangeRates.ExchangeRatesForCurrencyExist(CurrencyDate, Rec."Expense Currency Code") then
                Rec."Expense Currency Factor" := CurrencyExchangeRate.ExchangeRate(CurrencyDate, Rec."Expense Currency Code")
            else
                UpdateCurrencyExchangeRates.ShowMissingExchangeRatesNotification("Expense Currency Code");
        end else
            Rec."Expense Currency Factor" := 0;
    end;

    procedure GetReimbursementConversionDate(): Date
    begin
        GetExpenseReportHeader();

        ExpenseAgentSetup.GetRecordOnce();
        case ExpenseAgentSetup."Exchange Rate for Expenses" of
            Enum::"Expense Exchange Rate"::"Posting Date":
                exit(GetReimbursementCurrencyDate());
            Enum::"Expense Exchange Rate"::"Expense Date":
                if ExpenseReportHeader."Reimbursement Currency Code" <> '' then
                    exit(GetReimbursementCurrencyDate())
                else
                    exit(GetExpenseCurrencyDate());
        end;
    end;

    local procedure RemoveExpenseReportNoInExpense()
    var
        Expense: Record Expense;
    begin
        if not Expense.Get(Rec."Expense No.") then
            exit;

        if Expense."Posted Expense Report No." <> '' then
            exit;

        Expense.Validate("Expense Report No.", '');
        Expense.Status := Expense.Status::Released;
        Expense.Modify();
    end;

    local procedure ClearRuleId()
    begin
        Rec."Applied Rule Id" := EmptyGuid;
    end;

    local procedure CheckForAssociatedRecords(ExpenseNo: Code[20]; LineNo: Integer; FieldName: Text)
    var
        ExpenseParticipant: Record "Expense Report Line Particip.";
        ExpenseItemization: Record "Expense Report Line Item";
    begin
        ExpenseParticipant.SetRange("Expense No.", ExpenseNo);
        ExpenseParticipant.SetRange("Expense Report Line No.", LineNo);
        if not ExpenseParticipant.IsEmpty() then
            Error(CannotModifyWithParticipantsErr, FieldName, ExpenseNo, LineNo);

        ExpenseItemization.SetRange("Expense No.", ExpenseNo);
        ExpenseItemization.SetRange("Expense Report Line No.", LineNo);
        if not ExpenseItemization.IsEmpty() then
            Error(CannotModifyWithItemizationErr, FieldName, ExpenseNo, LineNo);
    end;

    procedure ApplyRule(ApplyAndValidateRuleOnExpense: Boolean; ValidateRuleOnly: Boolean)
    var
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if ApplyAndValidateRuleOnExpense then begin
            ApplyRule();
            exit;
        end;

        if ValidateRuleOnly then begin
            TestStatusOpen();
            ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(Rec);
        end;
    end;

    procedure ApplyRule()
    var
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
    begin
        if GuiAllowed then
            if (Rec."Document No." = '') or (Rec."Line No." = 0) then
                exit;

        TestStatusOpen();
        if SkipRuleApplication then
            exit;

        Rec.SetSkipRuleApplication(true);

        ExpenseAutoPopulation.FindRuleAndUpdateExpenseReportLine(Rec);
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(Rec);

        Rec.SetSkipRuleApplication(false);
    end;

    local procedure GetReimbursementCurrencyDate(): Date
    begin
        GetExpenseReportHeader();
        if ExpenseReportHeader."Posting Date" <> 0D then
            exit(ExpenseReportHeader."Posting Date");

        exit(WorkDate());
    end;

    procedure GetReimbursementCurrencyCode(): Code[10]
    begin
        GetExpenseReportHeader();
        exit(ExpenseReportHeader."Reimbursement Currency Code");
    end;

    local procedure GetExpenseCurrencyDate(): Date
    begin
        if Rec."Expense Date" <> 0D then
            exit(Rec."Expense Date");

        exit(WorkDate());
    end;

    procedure SetSkipRuleApplication(NewSkipRuleApplication: Boolean)
    begin
        SkipRuleApplication := NewSkipRuleApplication;
    end;

    procedure TestStatusOpen()
    begin
        GetExpenseReportHeader();
        ExpenseReportHeader.TestField(Status, ExpenseReportHeader.Status::Open);
    end;

    procedure GetExpenseReportHeader()
    begin
        GetExpenseReportHeader(ExpenseReportHeader, ReimbursementCurrency);
    end;

    procedure GetExpenseReportHeader(var OutExpenseReportHeader: Record "Expense Report Header"; var OutCurrency: Record Currency)
    begin
        if ("Document No." <> ExpenseReportHeader."No.") and ("Document No." <> '') then
            if ExpenseReportHeader.Get("Document No.") then
                ReimbursementCurrency.Initialize(ExpenseReportHeader."Reimbursement Currency Code")
            else
                Clear(ExpenseReportHeader);

        OutExpenseReportHeader := ExpenseReportHeader;
        OutCurrency := ReimbursementCurrency;
    end;

    procedure SetExpenseReportHeader(NewExpenseReportHeader: Record "Expense Report Header")
    begin
        TestField("Document No.");
        ExpenseReportHeader := NewExpenseReportHeader;

        if ExpenseReportHeader."Reimbursement Currency Code" = '' then
            ReimbursementCurrency.InitRoundingPrecision()
        else begin
            ReimbursementCurrency.Get(ExpenseReportHeader."Reimbursement Currency Code");

            ReimbursementCurrency.TestField("Amount Rounding Precision");
        end;
    end;

    procedure Initialize(NewExpenseReportHeader: Record "Expense Report Header")
    begin
        Clear(ReimbursementCurrency);
        Clear(ExpenseCurrency);
        SetExpenseReportHeader(NewExpenseReportHeader);
    end;

    local procedure UpdateFromExpenseCategory()
    var
        ExpenseCategory: Record "Expense Category";
    begin
        Rec.Description := '';
        Rec."Expense Detail Required" := Rec."Expense Detail Required"::" ";
        Rec."Spend Request No." := '';
        Rec."Spend Request Close" := false;

        if Rec."Expense Category" = '' then begin
            Rec.Validate("Expense Location", '');
            Rec."Unit of Measure Code" := '';
            Rec.Amount := 0;
            Rec.UpdateAmounts();
            exit;
        end;

        if not ExpenseCategory.Get(Rec."Expense Category") then begin
            Rec.Validate("Expense Location", '');
            exit;
        end;

        if ExpenseCategory."Expense Detail Required" <> ExpenseCategory."Expense Detail Required"::"Per Diem" then
            Rec.Validate("Expense Location", '');

        Rec.Validate(Refundable, ExpenseCategory.Refundable);
        Rec.Validate(Description, ExpenseCategory."Posting Description");
        Rec.Validate("Reimbursement Type", ExpenseCategory."Reimbursement Type");
        if ExpenseCategory."Default Payment Method" <> '' then
            Rec.Validate("Payment Method Code", ExpenseCategory."Default Payment Method");

        Rec.Validate("Expense Detail Required", ExpenseCategory."Expense Detail Required");

        ExpenseAgentSetup.GetRecordOnce();
        if Rec."Expense Detail Required" = Rec."Expense Detail Required"::Mileage then begin
            ExpenseAgentSetup.TestField("Default Mileage UOM");
            Rec.Validate("Unit of Measure Code", ExpenseAgentSetup."Default Mileage UOM");
        end;

        if Rec."Expense No." = '' then
            Rec.Validate("Expense Currency Code", '');

        Rec.Amount := 0;
        Rec.UpdateAmounts();
    end;

    procedure ShowItemization()
    var
        ExpenseReportLineItemization: Record "Expense Report Line Item";
    begin
        ExpenseReportLineItemization.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportLineItemization.SetRange("Expense Report Line No.", Rec."Line No.");
        ExpenseReportLineItemization.SetRange("Expense Category Code", Rec."Expense Category");

        Page.RunModal(Page::"Expense Report Line Items", ExpenseReportLineItemization);
    end;

    procedure ShowParticipants()
    var
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
    begin
        ExpenseReportLineParticipant.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportLineParticipant.SetRange("Expense Report Line No.", Rec."Line No.");

        Page.RunModal(Page::"Expense Report Line Particips", ExpenseReportLineParticipant);
    end;

    procedure ShowPerDiem()
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", Rec."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", Rec."Line No.");

        Page.RunModal(Page::"Expense Report Line Per Diems", ExpenseReportLinePerDiem);
    end;

    /// <summary>
    /// Shows the expense billing information page and validates the expense report line against the rules.
    /// </summary>
    procedure ShowExpenseBillingInformation()
    var
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        ExpenseBillingInformation: Page "Expense Billing Information";
    begin
        Commit();

        ExpenseBillingInformation.SetRecord(Rec);
        ExpenseBillingInformation.RunModal();
        ExpenseBillingInformation.GetRecord(Rec);

        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(Rec);
    end;

    internal procedure MoveToExpenseReport(TargetExpenseReportNo: Code[20])
    var
        SourceExpenseReportHeader: Record "Expense Report Header";
        TargetExpenseReportHeader: Record "Expense Report Header";
        NewLine: Record "Expense Report Line";
        Expense: Record Expense;
        ExpenseReport: Codeunit "Expense Report";
        SourceDocNo: Code[20];
        SourceLineNo: Integer;
    begin
        Rec.TestField("Document No.");
        Rec.TestField("Line No.");

        if TargetExpenseReportNo = Rec."Document No." then
            Error(OnlyRelinkToAnotherReportErr);

        if not SourceExpenseReportHeader.Get(Rec."Document No.") then
            Error(ExpenseReportNotFoundErr, Rec."Document No.");

        if not TargetExpenseReportHeader.Get(TargetExpenseReportNo) then
            Error(ExpenseReportNotFoundErr, TargetExpenseReportNo);

        SourceExpenseReportHeader.TestField(Status, SourceExpenseReportHeader.Status::Open);
        TargetExpenseReportHeader.TestField(Status, TargetExpenseReportHeader.Status::Open);
        SourceExpenseReportHeader.TestField("Expense User No.", TargetExpenseReportHeader."Expense User No.");

        SourceDocNo := Rec."Document No.";
        SourceLineNo := Rec."Line No.";

        NewLine.TransferFields(Rec, false);
        NewLine."Document No." := TargetExpenseReportNo;
        NewLine."Line No." := GetNextExpenseReportLineNo(TargetExpenseReportNo);
        NewLine."Posted Date" := TargetExpenseReportHeader."Posting Date";
        NewLine."VAT Bus. Posting Group" := TargetExpenseReportHeader."VAT Bus. Posting Group";
        NewLine.Insert();

        ExpenseReport.CopyReportLineParticipants(SourceDocNo, SourceLineNo, NewLine."Document No.", NewLine."Line No.");
        ExpenseReport.CopyReportLineItemizations(SourceDocNo, SourceLineNo, NewLine."Document No.", NewLine."Line No.");
        ExpenseReport.CopyReportLinePerDiems(SourceDocNo, SourceLineNo, NewLine."Document No.", NewLine."Line No.");
        ExpenseReport.CopyReportLineComments(SourceDocNo, SourceLineNo, NewLine."Document No.", NewLine."Line No.");
        ExpenseReport.CopyReportLineAttachments(SourceDocNo, SourceLineNo, NewLine."Document No.", NewLine."Line No.");

        NewLine.UpdateAmounts();
        NewLine.ApplyRule(false, true);
        NewLine.Modify();

        Rec.Delete(true);

        if NewLine."Expense No." <> '' then
            if Expense.Get(NewLine."Expense No.") then begin
                Expense.Validate("Expense Report No.", TargetExpenseReportNo);
                Expense.Status := Expense.Status::Submitted;
                Expense.Modify(true);
            end;

        Rec := NewLine;
    end;

    internal procedure GetNextExpenseReportLineNo(ExpenseReportNo: Code[20]): Integer
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        if ExpenseReportLine.FindLast() then
            exit(ExpenseReportLine."Line No." + 10000);

        exit(10000);
    end;

    local procedure SetExpenseUserOnCreate()
    var
        ExpenseUser: Record "Expense User";
    begin
        // Only update the Created By and Modified By Expense User Id when the change is made through Expense Agent, otherwise leave them unchanged as the change is made by other Business Central user.
        if not ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then
            exit;

        if Rec."Expense User No." = '' then
            exit;

        if not ExpenseUser.Get(Rec."Expense User No.") then
            exit;

        Rec."Created By Exp. User Id" := ExpenseUser.SystemId;
        Rec."Modified By Exp. User Id" := ExpenseUser.SystemId;
    end;

    local procedure UpdateExpenseUserOnModify()
    var
        ExpenseUser: Record "Expense User";
    begin
        // Only update Modified By Expense User Id when the change is made through Expense Agent, otherwise change it to Blank as the change is made by other Business Central user.
        if not ExpenseAgentAPIValidation.IsCurrentUserExpenseAgent() then begin
            Rec."Modified By Exp. User Id" := EmptyGuid;
            exit;
        end;

        if Rec."Expense User No." = '' then
            exit;

        if not ExpenseUser.Get(Rec."Expense User No.") then
            exit;

        Rec."Modified By Exp. User Id" := ExpenseUser.SystemId;
    end;

    local procedure CheckTraveler()
    var
        Traveler: Record Traveler;
    begin
        Rec.TestField("Expense User No.");

        Traveler.SetRange("Spend Request No.", Rec."Spend Request No.");
        Traveler.SetRange("Expense User No.", Rec."Expense User No.");
        if Traveler.IsEmpty() then
            Error(ExpenseUserNotTravelerErr, Rec."Expense User No.", Rec."Spend Request No.");
    end;

    /// <summary>
    /// Sets whether the confirmation to close the related spend request should be skipped during validation.
    /// </summary>
    /// <param name="NewSkipSpendRequestClose">True to skip the close confirmation; otherwise false.</param>
    internal procedure SetSkipSpendRequestClose(NewSkipSpendRequestClose: Boolean)
    begin
        SkipSpendRequestClose := NewSkipSpendRequestClose;
    end;
}