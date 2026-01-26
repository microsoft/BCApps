// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;

/// <summary>
/// Defines G/L account assignments for automatic posting based on combinations of general business and product posting groups.
/// Controls G/L account selection for sales, purchase, inventory, payment discount, and payment tolerance transactions.
/// </summary>
/// <remarks>
/// Creates posting matrix where each combination of business and product posting group determines specific G/L account assignments.
/// Integrates with sales documents, purchase documents, inventory transactions, and payment processing for automatic account determination.
/// Extensibility: Multiple validation events and account retrieval procedures for custom posting logic.
/// </remarks>
table 252 "General Posting Setup"
{
    Caption = 'General Posting Setup';
    DrillDownPageID = "General Posting Setup";
    LookupPageID = "General Posting Setup";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// General business posting group code that identifies the business nature of customers, vendors, or transactions.
        /// </summary>
        field(1; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group code that identifies the nature of items or services being sold or purchased.
        /// </summary>
        field(2; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            NotBlank = true;
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// G/L account used for posting sales revenue transactions for this posting group combination.
        /// </summary>
        field(10; "Sales Account"; Code[20])
        {
            Caption = 'Sales Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Sales Account")
                else
                    LookupGLAccount(
                      "Sales Account", GLAccountCategory."Account Category"::Income,
                      StrSubstNo(TwoSubCategoriesTxt, GLAccountCategoryMgt.GetIncomeProdSales(), GLAccountCategoryMgt.GetIncomeService()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting sales line discounts granted to customers for this posting group combination.
        /// </summary>
        field(11; "Sales Line Disc. Account"; Code[20])
        {
            Caption = 'Sales Line Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Sales Line Disc. Account")
                else
                    LookupGLAccount(
                      "Sales Line Disc. Account", GLAccountCategory."Account Category"::Income,
                      GLAccountCategoryMgt.GetIncomeSalesDiscounts());
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Line Disc. Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting sales invoice discounts granted to customers for this posting group combination.
        /// </summary>
        field(12; "Sales Inv. Disc. Account"; Code[20])
        {
            Caption = 'Sales Inv. Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Sales Inv. Disc. Account")
                else
                    LookupGLAccount(
                      "Sales Inv. Disc. Account", GLAccountCategory."Account Category"::Income,
                      GLAccountCategoryMgt.GetIncomeSalesDiscounts());
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Inv. Disc. Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting sales payment discount debit entries when payment discounts are adjusted.
        /// </summary>
        field(13; "Sales Pmt. Disc. Debit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Disc. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Disc. Debit Acc.");
                if "Sales Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase transactions and expense recognition for this posting group combination.
        /// </summary>
        field(14; "Purch. Account"; Code[20])
        {
            Caption = 'Purch. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Purch. Account")
                else
                    LookupGLAccount(
                      "Purch. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo(AccountSubcategoryFilterTxt, GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase line discounts received from vendors for this posting group combination.
        /// </summary>
        field(15; "Purch. Line Disc. Account"; Code[20])
        {
            Caption = 'Purch. Line Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Purch. Line Disc. Account")
                else
                    LookupGLAccount(
                      "Purch. Line Disc. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      GLAccountCategoryMgt.GetCOGSDiscountsGranted());
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Line Disc. Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase invoice discounts received from vendors for this posting group combination.
        /// </summary>
        field(16; "Purch. Inv. Disc. Account"; Code[20])
        {
            Caption = 'Purch. Inv. Disc. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Purch. Inv. Disc. Account")
                else
                    LookupGLAccount(
                      "Purch. Inv. Disc. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      GLAccountCategoryMgt.GetCOGSDiscountsGranted());
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Inv. Disc. Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase payment discount credit entries when payment discounts are adjusted.
        /// </summary>
        field(17; "Purch. Pmt. Disc. Credit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Disc. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Disc. Credit Acc.");
                if "Purch. Pmt. Disc. Credit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting cost of goods sold for inventory items sold for this posting group combination.
        /// </summary>
        field(18; "COGS Account"; Code[20])
        {
            Caption = 'COGS Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("COGS Account")
                else
                    LookupGLAccount(
                      "COGS Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo(TwoSubCategoriesTxt, GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("COGS Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting inventory value adjustments for this posting group combination.
        /// </summary>
        field(19; "Inventory Adjmt. Account"; Code[20])
        {
            Caption = 'Inventory Adjmt. Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Inventory Adjmt. Account")
                else
                    LookupGLAccount(
                      "Inventory Adjmt. Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo(AccountSubcategoryFilterTxt, GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Inventory Adjmt. Account");
            end;
        }
        field(24; "Job Sales Adjmt. Account"; Code[20])
        {
            Caption = 'Job Sales Adjmt. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Job Sales Adjmt. Account");
            end;
        }
        field(25; "Job Cost Adjmt. Account"; Code[20])
        {
            Caption = 'Job Cost Adjmt. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Job Cost Adjmt. Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting sales credit memo transactions.
        /// Applied when reversing sales transactions or issuing customer refunds.
        /// </summary>
        field(27; "Sales Credit Memo Account"; Code[20])
        {
            Caption = 'Sales Credit Memo Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Sales Credit Memo Account")
                else
                    LookupGLAccount(
                        "Sales Credit Memo Account", GLAccountCategory."Account Category"::Income,
                        StrSubstNo(AccountSubcategoryFilterTxt, GLAccountCategoryMgt.GetIncomeProdSales(), GLAccountCategoryMgt.GetIncomeService()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Credit Memo Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase credit memo transactions.
        /// Applied when reversing purchase transactions or processing vendor refunds.
        /// </summary>
        field(28; "Purch. Credit Memo Account"; Code[20])
        {
            Caption = 'Purch. Credit Memo Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Purch. Credit Memo Account")
                else
                    LookupGLAccount(
                        "Purch. Credit Memo Account", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                        StrSubstNo(AccountSubcategoryFilterTxt, GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Credit Memo Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting sales payment discount credit entries.
        /// Applied when customers take early payment discounts on sales invoices.
        /// </summary>
        field(30; "Sales Pmt. Disc. Credit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Disc. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Disc. Credit Acc.");
                if "Sales Pmt. Disc. Credit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase payment discount debit entries.
        /// Applied when taking early payment discounts on vendor payments.
        /// </summary>
        field(31; "Purch. Pmt. Disc. Debit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Disc. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Disc. Debit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting sales payment tolerance debit entries.
        /// Applied when accepting underpayments within configured tolerance limits.
        /// </summary>
        field(32; "Sales Pmt. Tol. Debit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Tol. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Tol. Debit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting sales payment tolerance credit entries.
        /// Applied when accepting overpayments within configured tolerance limits.
        /// </summary>
        field(33; "Sales Pmt. Tol. Credit Acc."; Code[20])
        {
            Caption = 'Sales Pmt. Tol. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Pmt. Tol. Credit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase payment tolerance debit entries.
        /// Applied when accepting underpayments within configured tolerance limits on vendor payments.
        /// </summary>
        field(34; "Purch. Pmt. Tol. Debit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Tol. Debit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Tol. Debit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase payment tolerance credit entries.
        /// Applied when accepting overpayments within configured tolerance limits on vendor payments.
        /// </summary>
        field(35; "Purch. Pmt. Tol. Credit Acc."; Code[20])
        {
            Caption = 'Purch. Pmt. Tol. Credit Acc.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Pmt. Tol. Credit Acc.");
                if "Purch. Pmt. Disc. Debit Acc." <> '' then begin
                    GLSetup.Get();
                    GLSetup.TestField("Payment Discount Type", GLSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines");
                end;
            end;
        }
        /// <summary>
        /// G/L account used for posting sales prepayment transactions.
        /// Applied when handling advance payments from customers before final invoicing.
        /// </summary>
        field(36; "Sales Prepayments Account"; Code[20])
        {
            Caption = 'Sales Prepayments Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Prepayments Account");
                CheckPrepmtSalesLinesToDeduct(
                    StrSubstNo(CannotChangePrepmtAccErr, '%1', FieldCaption("Sales Prepayments Account")));
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase prepayment transactions.
        /// Applied when making advance payments to vendors before final invoicing.
        /// </summary>
        field(37; "Purch. Prepayments Account"; Code[20])
        {
            Caption = 'Purch. Prepayments Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. Prepayments Account");
                CheckPrepmtPurchLinesToDeduct(
                    StrSubstNo(CannotChangePrepmtAccErr, '%1', FieldCaption("Purch. Prepayments Account")));
            end;
        }
        /// <summary>
        /// Descriptive text explaining the purpose or nature of this general posting setup combination.
        /// </summary>
        field(50; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Controls whether all G/L accounts are shown during account lookup or only relevant account categories are filtered.
        /// </summary>
        field(51; "View All Accounts on Lookup"; Boolean)
        {
            Caption = 'View All Accounts on Lookup';
        }
        /// <summary>
        /// Prevents this general posting setup combination from being used in new transactions when enabled.
        /// </summary>
        field(52; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// G/L account used for posting purchase fixed asset discount transactions.
        /// Applied when processing discount amounts on fixed asset purchases.
        /// </summary>
        field(5600; "Purch. FA Disc. Account"; Code[20])
        {
            Caption = 'Purch. FA Disc. Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purch. FA Disc. Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting inventory accrual amounts during interim inventory processing.
        /// Applied when handling inventory transactions with delayed costing updates.
        /// </summary>
        field(5801; "Invt. Accrual Acc. (Interim)"; Code[20])
        {
            Caption = 'Invt. Accrual Acc. (Interim)';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Invt. Accrual Acc. (Interim)")
                else
                    LookupGLAccount(
                      "Invt. Accrual Acc. (Interim)", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo(TwoSubCategoriesTxt, GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Invt. Accrual Acc. (Interim)");
            end;
        }
        /// <summary>
        /// G/L account used for posting cost of goods sold during interim inventory processing.
        /// Applied when handling COGS transactions with delayed cost calculation and adjustment.
        /// </summary>
        field(5803; "COGS Account (Interim)"; Code[20])
        {
            Caption = 'COGS Account (Interim)';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("COGS Account (Interim)")
                else
                    LookupGLAccount(
                      "COGS Account (Interim)", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo(TwoSubCategoriesTxt, GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("COGS Account (Interim)");
            end;
        }
        /// <summary>
        /// G/L account used for posting direct cost amounts for non-inventory items.
        /// Applied during manufacturing processes for direct costs not applied to inventory.
        /// </summary>
        field(6000; "Direct Cost Non-Inv. App. Acc."; Code[20])
        {
            Caption = 'Direct Cost Non-Inventory Applied Account';
            ToolTip = 'Specifies the general ledger account number to post the direct cost non-inventory applied with this particular combination of business posting group and product posting group.';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Direct Cost Non-Inv. App. Acc.")
                else
                    LookupGLAccount(
                      "Direct Cost Non-Inv. App. Acc.", GLAccountCategory."Account Category"::"Cost of Goods Sold",
                      StrSubstNo(TwoSubCategoriesTxt, GLAccountCategoryMgt.GetCOGSMaterials(), GLAccountCategoryMgt.GetCOGSLabor()));
            end;

            trigger OnValidate()
            begin
                CheckGLAcc("Direct Cost Non-Inv. App. Acc.");
            end;
        }
        /// <summary>
        /// G/L account used for posting applied direct cost amounts during manufacturing processes.
        /// Applied when allocating direct manufacturing costs to work-in-process inventory.
        /// </summary>
        field(99000752; "Direct Cost Applied Account"; Code[20])
        {
            Caption = 'Direct Cost Applied Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Direct Cost Applied Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting applied overhead cost amounts during manufacturing processes.
        /// Applied when allocating indirect manufacturing costs to work-in-process inventory.
        /// </summary>
        field(99000753; "Overhead Applied Account"; Code[20])
        {
            Caption = 'Overhead Applied Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Overhead Applied Account");
            end;
        }
        /// <summary>
        /// G/L account used for posting purchase price variance amounts during manufacturing processes.
        /// Applied when actual purchase costs differ from standard costs in manufacturing scenarios.
        /// </summary>
        field(99000754; "Purchase Variance Account"; Code[20])
        {
            Caption = 'Purchase Variance Account';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Purchase Variance Account");
            end;
        }
    }

    keys
    {
        key(Key1; "Gen. Bus. Posting Group", "Gen. Prod. Posting Group")
        {
            Clustered = true;
        }
        key(Key2; "Gen. Prod. Posting Group", "Gen. Bus. Posting Group")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckSetupUsage();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        AccountSuggested: Boolean;

        YouCannotDeleteErr: Label 'You cannot delete %1 %2.', Comment = '%1 = Location Code; %2 = Posting Group';
        AccountSubcategoryFilterTxt: Label '%1|%2', Comment = '%1 = Account Subcategory; %2 = Account Subcategory2', Locked = true;
        CannotChangePrepmtAccErr: Label 'You cannot change %2 while %1 is pending prepayment.', Comment = '%2- field caption, %1 -recordId - "Sales Header: Order, 1001".';
        TwoSubCategoriesTxt: Label '%1|%2', Locked = true;
        NoAccountSuggestedMsg: Label 'Cannot suggest G/L accounts as there is nothing to base suggestion on.';

    /// <summary>
    /// Validates that the specified G/L account exists and is available for posting.
    /// </summary>
    /// <param name="AccNo">G/L account number to validate</param>
    procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;

    local procedure CheckSetupUsage()
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        if not GLEntry.IsEmpty() then
            Error(YouCannotDeleteErr, "Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
    end;

    internal procedure CheckOrdersPrepmtToDeduct(ErrorMsg: Text)
    begin
        CheckPrepmtPurchLinesToDeduct(ErrorMsg);
        CheckPrepmtSalesLinesToDeduct(ErrorMsg);
    end;

    internal procedure CheckPrepmtSalesLinesToDeduct(ErrorMsg: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetLoadFields("Document No.");
        SalesLine.SetRange("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
        SalesLine.SetRange("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        SalesLine.SetFilter("Prepmt Amt to Deduct", '>0');
        if SalesLine.FindFirst() then
            Error(ErrorMsg, SalesLine.GetSalesHeader().RecordId);
    end;

    internal procedure CheckPrepmtPurchLinesToDeduct(ErrorMsg: Text)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetLoadFields("Document No.");
        PurchaseLine.SetRange("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
        PurchaseLine.SetRange("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        PurchaseLine.SetFilter("Prepmt Amt to Deduct", '>0');
        if PurchaseLine.FindFirst() then
            Error(ErrorMsg, PurchaseLine.GetPurchHeader().RecordId);
    end;

    local procedure FilterBlankSalesDiscountAccounts(DiscountPosting: Option; var FieldNumber: Integer) Found: Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if DiscountPosting = SalesSetup."Discount Posting"::"All Discounts" then
            FilterGroup(-1);
        if DiscountPosting <> SalesSetup."Discount Posting"::"Line Discounts" then begin
            SetRange("Sales Inv. Disc. Account", '');
            FieldNumber := FieldNo("Sales Inv. Disc. Account");
        end;
        if DiscountPosting <> SalesSetup."Discount Posting"::"Invoice Discounts" then begin
            SetRange("Sales Line Disc. Account", '');
            FieldNumber := FieldNo("Sales Line Disc. Account");
        end;
        Found := FindSet();
        if (DiscountPosting = SalesSetup."Discount Posting"::"All Discounts") and ("Sales Line Disc. Account" <> '') then
            FieldNumber := FieldNo("Sales Inv. Disc. Account");
    end;

    local procedure FilterBlankPurchDiscountAccounts(DiscountPosting: Option; var FieldNumber: Integer) Found: Boolean
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        if DiscountPosting = PurchSetup."Discount Posting"::"All Discounts" then
            FilterGroup(-1);
        if DiscountPosting <> PurchSetup."Discount Posting"::"Line Discounts" then begin
            SetRange("Purch. Inv. Disc. Account", '');
            FieldNumber := FieldNo("Purch. Inv. Disc. Account");
        end;
        if DiscountPosting <> PurchSetup."Discount Posting"::"Invoice Discounts" then begin
            SetRange("Purch. Line Disc. Account", '');
            FieldNumber := FieldNo("Purch. Line Disc. Account");
        end;
        Found := FindSet();
        if (DiscountPosting = PurchSetup."Discount Posting"::"All Discounts") and ("Purch. Line Disc. Account" <> '') then
            FieldNumber := FieldNo("Purch. Inv. Disc. Account");
    end;

    /// <summary>
    /// Identifies general posting setup records missing sales discount account configuration for the specified discount posting method.
    /// </summary>
    /// <param name="DiscountPosting">Discount posting method to validate account setup for</param>
    /// <param name="FieldNumber">Returns field number of missing account configuration</param>
    /// <returns>True if records with missing sales discount accounts are found</returns>
    procedure FindSetupMissingSalesDiscountAccount(DiscountPosting: Option; var FieldNumber: Integer): Boolean
    begin
        if FilterBlankSalesDiscountAccounts(DiscountPosting, FieldNumber) then begin
            MarkRecords();
            exit(FindSet());
        end;
    end;

    /// <summary>
    /// Identifies general posting setup records missing purchase discount account configuration for the specified discount posting method.
    /// </summary>
    /// <param name="DiscountPosting">Discount posting method to validate account setup for</param>
    /// <param name="FieldNumber">Returns field number of missing account configuration</param>
    /// <returns>True if records with missing purchase discount accounts are found</returns>
    procedure FindSetupMissingPurchDiscountAccount(DiscountPosting: Option; var FieldNumber: Integer): Boolean
    begin
        if FilterBlankPurchDiscountAccounts(DiscountPosting, FieldNumber) then begin
            MarkRecords();
            exit(FindSet());
        end;
    end;

    local procedure MarkRecords()
    begin
        if FindSet() then
            repeat
                Mark(true);
            until Next() = 0;
        FilterGroup(0);
        MarkedOnly(true);
    end;

    /// <summary>
    /// Retrieves the cost of goods sold account for this posting group combination with error handling for missing configuration.
    /// </summary>
    /// <returns>COGS account number or empty if not configured</returns>
    procedure GetCOGSAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCOGSAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "COGS Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("COGS Account"));

        exit("COGS Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for interim cost of goods sold postings.
    /// </summary>
    /// <returns>Account number for interim COGS transactions, validates account exists before returning</returns>
    procedure GetCOGSInterimAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCOGSInterimAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "COGS Account (Interim)" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("COGS Account (Interim)"));

        exit("COGS Account (Interim)");
    end;

    /// <summary>
    /// Retrieves the G/L account number for inventory adjustment postings.
    /// </summary>
    /// <returns>Account number for inventory adjustment transactions, validates account exists before returning</returns>
    procedure GetInventoryAdjmtAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetInventoryAdjmtAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Inventory Adjmt. Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Inventory Adjmt. Account"));

        exit("Inventory Adjmt. Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for inventory accrual postings.
    /// </summary>
    /// <returns>Account number for inventory accrual transactions, validates account exists before returning</returns>
    procedure GetInventoryAccrualAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetInventoryAccrualAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Invt. Accrual Acc. (Interim)" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Invt. Accrual Acc. (Interim)"));

        exit("Invt. Accrual Acc. (Interim)");
    end;

    /// <summary>
    /// Retrieves the sales account for this posting group combination with error handling for missing configuration.
    /// </summary>
    /// <returns>Sales account number or logs error if not configured</returns>
    procedure GetSalesAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Sales Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Account"));

        exit("Sales Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for sales credit memo postings.
    /// </summary>
    /// <returns>Account number for sales credit memo transactions, validates account exists before returning</returns>
    procedure GetSalesCrMemoAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesCrMemoAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Sales Credit Memo Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Credit Memo Account"));

        exit("Sales Credit Memo Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for sales invoice discount postings.
    /// </summary>
    /// <returns>Account number for sales invoice discount transactions, validates account exists before returning</returns>
    procedure GetSalesInvDiscAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesInvDiscAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Sales Inv. Disc. Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Inv. Disc. Account"));

        exit("Sales Inv. Disc. Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for sales line discount postings.
    /// </summary>
    /// <returns>Account number for sales line discount transactions, validates account exists before returning</returns>
    procedure GetSalesLineDiscAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesLineDiscAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Sales Line Disc. Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Line Disc. Account"));

        exit("Sales Line Disc. Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for sales payment discount postings.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <returns>Account number for sales payment discount transactions, validates account exists before returning</returns>
    procedure GetSalesPmtDiscountAccount(Debit: Boolean) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesPmtDiscountAccount(Debit, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if Debit then begin
            if "Sales Pmt. Disc. Debit Acc." = '' then
                PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Pmt. Disc. Debit Acc."));

            exit("Sales Pmt. Disc. Debit Acc.");
        end;
        if "Sales Pmt. Disc. Credit Acc." = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Pmt. Disc. Credit Acc."));

        exit("Sales Pmt. Disc. Credit Acc.");
    end;

    /// <summary>
    /// Retrieves the G/L account number for sales payment tolerance postings.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <returns>Account number for sales payment tolerance transactions, validates account exists before returning</returns>
    procedure GetSalesPmtToleranceAccount(Debit: Boolean) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesPmtToleranceAccount(Debit, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if Debit then begin
            if "Sales Pmt. Tol. Debit Acc." = '' then
                PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Pmt. Tol. Debit Acc."));

            exit("Sales Pmt. Tol. Debit Acc.");
        end;
        if "Sales Pmt. Tol. Credit Acc." = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Pmt. Tol. Credit Acc."));

        exit("Sales Pmt. Tol. Credit Acc.");
    end;

    /// <summary>
    /// Retrieves the G/L account number for sales prepayment postings.
    /// </summary>
    /// <returns>Account number for sales prepayment transactions, validates account exists before returning</returns>
    procedure GetSalesPrepmtAccount() AccountNo: Code[20]
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesPrepmtAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Sales Prepayments Account" <> '' then begin
            GLAccount.Get("Sales Prepayments Account");
            GLAccount.CheckGenProdPostingGroup();
        end else
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Sales Prepayments Account"));

        exit("Sales Prepayments Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase postings.
    /// </summary>
    /// <returns>Account number for purchase transactions, validates account exists before returning</returns>
    procedure GetPurchAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Purch. Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Account"));

        exit("Purch. Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase credit memo postings.
    /// </summary>
    /// <returns>Account number for purchase credit memo transactions, validates account exists before returning</returns>
    procedure GetPurchCrMemoAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchCrMemoAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Purch. Credit Memo Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Credit Memo Account"));

        exit("Purch. Credit Memo Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase invoice discount postings.
    /// </summary>
    /// <returns>Account number for purchase invoice discount transactions, validates account exists before returning</returns>
    procedure GetPurchInvDiscAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchInvDiscAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Purch. Inv. Disc. Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Inv. Disc. Account"));

        exit("Purch. Inv. Disc. Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase line discount postings.
    /// </summary>
    /// <returns>Account number for purchase line discount transactions, validates account exists before returning</returns>
    procedure GetPurchLineDiscAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchLineDiscAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Purch. Line Disc. Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Line Disc. Account"));

        exit("Purch. Line Disc. Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase payment discount postings.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <returns>Account number for purchase payment discount transactions, validates account exists before returning</returns>
    procedure GetPurchPmtDiscountAccount(Debit: Boolean) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchPmtDiscountAccount(Debit, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if Debit then begin
            if "Purch. Pmt. Disc. Debit Acc." = '' then
                PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Pmt. Disc. Debit Acc."));

            exit("Purch. Pmt. Disc. Debit Acc.");
        end;
        if "Purch. Pmt. Disc. Credit Acc." = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Pmt. Disc. Credit Acc."));

        exit("Purch. Pmt. Disc. Credit Acc.");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase payment tolerance postings.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <returns>Account number for purchase payment tolerance transactions, validates account exists before returning</returns>
    procedure GetPurchPmtToleranceAccount(Debit: Boolean) AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchPmtToleranceAccount(Debit, AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if Debit then begin
            if "Purch. Pmt. Tol. Debit Acc." = '' then
                PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Pmt. Tol. Debit Acc."));

            exit("Purch. Pmt. Tol. Debit Acc.");
        end;
        if "Purch. Pmt. Tol. Credit Acc." = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Pmt. Tol. Credit Acc."));

        exit("Purch. Pmt. Tol. Credit Acc.");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase prepayment postings.
    /// </summary>
    /// <returns>Account number for purchase prepayment transactions, validates account exists before returning</returns>
    procedure GetPurchPrepmtAccount() AccountNo: Code[20]
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchPrepmtAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Purch. Prepayments Account" <> '' then begin
            GLAccount.Get("Purch. Prepayments Account");
            GLAccount.CheckGenProdPostingGroup();
        end else
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. Prepayments Account"));

        exit("Purch. Prepayments Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase fixed asset discount postings.
    /// </summary>
    /// <returns>Account number for purchase FA discount transactions, validates account exists before returning</returns>
    procedure GetPurchFADiscAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchFADiscAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Purch. FA Disc. Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purch. FA Disc. Account"));

        exit("Purch. FA Disc. Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for direct cost applied postings in manufacturing.
    /// </summary>
    /// <returns>Account number for direct cost applied transactions, validates account exists before returning</returns>
    procedure GetDirectCostAppliedAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDirectCostAppliedAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Direct Cost Applied Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Direct Cost Applied Account"));

        exit("Direct Cost Applied Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for direct cost non-inventory applied postings in manufacturing.
    /// </summary>
    /// <returns>Account number for non-inventory direct cost applied transactions, validates account exists before returning</returns>
    procedure GetDirectCostNonInvtAppliedAccount() AccountNo: Code[20]
    begin
        if "Direct Cost Non-Inv. App. Acc." = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Direct Cost Non-Inv. App. Acc."));

        exit("Direct Cost Non-Inv. App. Acc.");
    end;

    /// <summary>
    /// Retrieves the G/L account number for overhead applied postings in manufacturing.
    /// </summary>
    /// <returns>Account number for overhead applied transactions, validates account exists before returning</returns>
    procedure GetOverheadAppliedAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOverheadAppliedAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Overhead Applied Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Overhead Applied Account"));

        exit("Overhead Applied Account");
    end;

    /// <summary>
    /// Retrieves the G/L account number for purchase variance postings in manufacturing.
    /// </summary>
    /// <returns>Account number for purchase variance transactions, validates account exists before returning</returns>
    procedure GetPurchaseVarianceAccount() AccountNo: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchaseVarianceAccount(AccountNo, IsHandled);
        if IsHandled then
            exit(AccountNo);

        if "Purchase Variance Account" = '' then
            PostingSetupMgt.LogGenPostingSetupFieldError(Rec, FieldNo("Purchase Variance Account"));

        exit("Purchase Variance Account");
    end;

    /// <summary>
    /// Configures account field visibility on posting setup pages based on system configuration.
    /// Sets visibility flags for payment tolerance, payment discount, and various discount account fields.
    /// </summary>
    /// <param name="PmtToleranceVisible">Returns true if payment tolerance accounts should be visible</param>
    /// <param name="PmtDiscountVisible">Returns true if payment discount accounts should be visible</param>
    /// <param name="SalesInvDiscVisible">Returns true if sales invoice discount accounts should be visible</param>
    /// <param name="SalesLineDiscVisible">Returns true if sales line discount accounts should be visible</param>
    /// <param name="PurchInvDiscVisible">Returns true if purchase invoice discount accounts should be visible</param>
    /// <param name="PurchLineDiscVisible">Returns true if purchase line discount accounts should be visible</param>
    procedure SetAccountsVisibility(var PmtToleranceVisible: Boolean; var PmtDiscountVisible: Boolean; var SalesInvDiscVisible: Boolean; var SalesLineDiscVisible: Boolean; var PurchInvDiscVisible: Boolean; var PurchLineDiscVisible: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        PaymentTerms: Record "Payment Terms";
    begin
        GLSetup.Get();
        PmtToleranceVisible := (GLSetup."Payment Tolerance %" > 0) or (GLSetup."Max. Payment Tolerance Amount" <> 0);

        PmtDiscountVisible := PaymentTerms.UsePaymentDiscount();

        SalesSetup.Get();
        SalesLineDiscVisible :=
          SalesSetup."Discount Posting" in [SalesSetup."Discount Posting"::"All Discounts",
                                            SalesSetup."Discount Posting"::"Line Discounts"];
        SalesInvDiscVisible :=
          SalesSetup."Discount Posting" in [SalesSetup."Discount Posting"::"All Discounts",
                                            SalesSetup."Discount Posting"::"Invoice Discounts"];

        PurchSetup.Get();
        PurchLineDiscVisible :=
          PurchSetup."Discount Posting" in [PurchSetup."Discount Posting"::"All Discounts",
                                            PurchSetup."Discount Posting"::"Line Discounts"];
        PurchInvDiscVisible :=
          PurchSetup."Discount Posting" in [PurchSetup."Discount Posting"::"All Discounts",
                                            PurchSetup."Discount Posting"::"Invoice Discounts"];
    end;

    /// <summary>
    /// Suggests default G/L account assignments for posting setup configuration.
    /// Analyzes existing accounts and recommends appropriate accounts for sales, purchase, and inventory postings.
    /// </summary>
    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        AccountSuggested := false;
        RecRef.GetTable(Rec);
        SuggestSalesAccounts(RecRef);
        SuggestPurchAccounts(RecRef);
        SuggestInvtAccounts(RecRef);
        if AccountSuggested then
            RecRef.Modify()
        else
            Message(NoAccountSuggestedMsg);
    end;

    local procedure SuggestSalesAccounts(var RecRef: RecordRef)
    begin
        if "Sales Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Account"));
        if "Sales Credit Memo Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Credit Memo Account"));
        if "Sales Inv. Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Inv. Disc. Account"));
        if "Sales Line Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Line Disc. Account"));
        if "Sales Pmt. Disc. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Disc. Credit Acc."));
        if "Sales Pmt. Disc. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Disc. Debit Acc."));
        if "Sales Pmt. Tol. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Tol. Credit Acc."));
        if "Sales Pmt. Tol. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Sales Pmt. Tol. Debit Acc."));
        if "Sales Prepayments Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales Prepayments Account"));

        OnAfterSuggestSalesAccounts(Rec, RecRef);
    end;

    local procedure SuggestPurchAccounts(var RecRef: RecordRef)
    begin
        if "Purch. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Account"));
        if "Purch. Credit Memo Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Credit Memo Account"));
        if "Purch. Inv. Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Inv. Disc. Account"));
        if "Purch. Line Disc. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Line Disc. Account"));
        if "Purch. Pmt. Disc. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Disc. Credit Acc."));
        if "Purch. Pmt. Disc. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Disc. Debit Acc."));
        if "Purch. Pmt. Tol. Credit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Tol. Credit Acc."));
        if "Purch. Pmt. Tol. Debit Acc." = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Pmt. Tol. Debit Acc."));
        if "Purch. Prepayments Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purch. Prepayments Account"));

        OnAfterSuggestPurchAccounts(Rec, RecRef);
    end;

    local procedure SuggestInvtAccounts(var RecRef: RecordRef)
    begin
        if "COGS Account" = '' then
            SuggestAccount(RecRef, FieldNo("COGS Account"));
        if "COGS Account (Interim)" = '' then
            SuggestAccount(RecRef, FieldNo("COGS Account (Interim)"));
        if "Inventory Adjmt. Account" = '' then
            SuggestAccount(RecRef, FieldNo("Inventory Adjmt. Account"));
        if "Invt. Accrual Acc. (Interim)" = '' then
            SuggestAccount(RecRef, FieldNo("Invt. Accrual Acc. (Interim)"));
        if "Direct Cost Applied Account" = '' then
            SuggestAccount(RecRef, FieldNo("Direct Cost Applied Account"));
        if "Overhead Applied Account" = '' then
            SuggestAccount(RecRef, FieldNo("Overhead Applied Account"));
        if "Purchase Variance Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purchase Variance Account"));

        OnAfterSuggestInvtAccounts(Rec, RecRef);
    end;

    protected procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        GenPostingSetupRecRef: RecordRef;
        GenPostingSetupFieldRef: FieldRef;
    begin
        GenPostingSetupRecRef.Open(DATABASE::"General Posting Setup");

        GenPostingSetupRecRef.Reset();
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Bus. Posting Group"));
        GenPostingSetupFieldRef.SetRange("Gen. Bus. Posting Group");
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Prod. Posting Group"));
        GenPostingSetupFieldRef.SetFilter('<>%1', "Gen. Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(GenPostingSetupRecRef, AccountFieldNo);

        GenPostingSetupRecRef.Reset();
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Bus. Posting Group"));
        GenPostingSetupFieldRef.SetFilter('<>%1', "Gen. Bus. Posting Group");
        GenPostingSetupFieldRef := GenPostingSetupRecRef.Field(FieldNo("Gen. Prod. Posting Group"));
        GenPostingSetupFieldRef.SetRange("Gen. Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(GenPostingSetupRecRef, AccountFieldNo);

        GenPostingSetupRecRef.Close();

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast() then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
            AccountSuggested := true;
        end;
    end;

    protected procedure LookupGLAccount(var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    begin
        GLAccountCategoryMgt.LookupGLAccount(Database::"General Posting Setup", CurrFieldNo, AccountNo, AccountCategory, AccountSubcategoryFilter);
    end;

    /// <summary>
    /// Integration event raised after suggesting inventory-related G/L account assignments during posting setup account suggestion.
    /// Enables custom logic for modifying suggested inventory accounts based on business requirements.
    /// </summary>
    /// <param name="GeneralPostingSetup">General posting setup record being updated with suggested accounts</param>
    /// <param name="RecRef">Record reference for accessing field values and metadata</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestInvtAccounts(var GeneralPostingSetup: Record "General Posting Setup"; var RecRef: RecordRef);
    begin
    end;

    /// <summary>
    /// Integration event raised after suggesting sales-related G/L account assignments during posting setup account suggestion.
    /// Enables custom logic for modifying suggested sales accounts based on business requirements.
    /// </summary>
    /// <param name="GeneralPostingSetup">General posting setup record being updated with suggested accounts</param>
    /// <param name="RecRef">Record reference for accessing field values and metadata</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestSalesAccounts(var GeneralPostingSetup: Record "General Posting Setup"; var RecRef: RecordRef);
    begin
    end;

    /// <summary>
    /// Integration event raised after suggesting purchase-related G/L account assignments during posting setup account suggestion.
    /// Enables custom logic for modifying suggested purchase accounts based on business requirements.
    /// </summary>
    /// <param name="GeneralPostingSetup">General posting setup record being updated with suggested accounts</param>
    /// <param name="RecRef">Record reference for accessing field values and metadata</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestPurchAccounts(var GeneralPostingSetup: Record "General Posting Setup"; var RecRef: RecordRef);
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales prepayment account number.
    /// Enables custom account retrieval logic for sales prepayment transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for sales prepayment, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetSalesPrepmtAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase prepayment account number.
    /// Enables custom account retrieval logic for purchase prepayment transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for purchase prepayment, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetPurchPrepmtAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving cost of goods sold account number.
    /// Enables custom account retrieval logic for COGS transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for COGS, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCOGSAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving interim cost of goods sold account number.
    /// Enables custom account retrieval logic for interim COGS transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for interim COGS, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCOGSInterimAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving inventory adjustment account number.
    /// Enables custom account retrieval logic for inventory adjustment transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for inventory adjustments, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInventoryAdjmtAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving inventory accrual account number.
    /// Enables custom account retrieval logic for inventory accrual transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for inventory accrual, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetInventoryAccrualAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales account number.
    /// Enables custom account retrieval logic for sales transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for sales, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales credit memo account number.
    /// Enables custom account retrieval logic for sales credit memo transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for sales credit memo, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesCrMemoAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales invoice discount account number.
    /// Enables custom account retrieval logic for sales invoice discount transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for sales invoice discount, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesInvDiscAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales line discount account number.
    /// Enables custom account retrieval logic for sales line discount transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for sales line discount, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesLineDiscAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales payment discount account number.
    /// Enables custom account retrieval logic for sales payment discount transactions.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <param name="AccountNo">Account number to use for sales payment discount, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesPmtDiscountAccount(Debit: Boolean; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales payment tolerance account number.
    /// Enables custom account retrieval logic for sales payment tolerance transactions.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <param name="AccountNo">Account number to use for sales payment tolerance, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesPmtToleranceAccount(Debit: Boolean; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase account number.
    /// Enables custom account retrieval logic for purchase transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for purchase, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase credit memo account number.
    /// Enables custom account retrieval logic for purchase credit memo transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for purchase credit memo, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchCrMemoAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase invoice discount account number.
    /// Enables custom account retrieval logic for purchase invoice discount transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for purchase invoice discount, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchInvDiscAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase line discount account number.
    /// Enables custom account retrieval logic for purchase line discount transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for purchase line discount, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchLineDiscAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase payment discount account number.
    /// Enables custom account retrieval logic for purchase payment discount transactions.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <param name="AccountNo">Account number to use for purchase payment discount, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchPmtDiscountAccount(Debit: Boolean; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase payment tolerance account number.
    /// Enables custom account retrieval logic for purchase payment tolerance transactions.
    /// </summary>
    /// <param name="Debit">True to get debit account, false to get credit account</param>
    /// <param name="AccountNo">Account number to use for purchase payment tolerance, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchPmtToleranceAccount(Debit: Boolean; var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase fixed asset discount account number.
    /// Enables custom account retrieval logic for purchase fixed asset discount transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for purchase FA discount, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchFADiscAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving direct cost applied account number.
    /// Enables custom account retrieval logic for manufacturing direct cost applied transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for direct cost applied, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDirectCostAppliedAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving overhead applied account number.
    /// Enables custom account retrieval logic for manufacturing overhead applied transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for overhead applied, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOverheadAppliedAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase variance account number.
    /// Enables custom account retrieval logic for manufacturing purchase variance transactions.
    /// </summary>
    /// <param name="AccountNo">Account number to use for purchase variance, can be modified by subscribers</param>
    /// <param name="IsHandled">Set to true to bypass standard account retrieval logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchaseVarianceAccount(var AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

}
