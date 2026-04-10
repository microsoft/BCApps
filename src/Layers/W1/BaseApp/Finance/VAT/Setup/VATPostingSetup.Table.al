// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Enums;

/// <summary>
/// Defines VAT calculation rules and G/L account mappings for specific combinations of VAT business and product posting groups.
/// Core table controlling VAT processing, account assignments, and calculation methods for all VAT transactions.
/// </summary>
/// <remarks>
/// Key functionality: VAT percentage calculation, G/L account mapping, unrealized VAT handling, reverse charge processing.
/// Integration points: General Ledger, VAT Ledger Entries, Sales/Purchase documents, VAT reporting.
/// Extensibility: VAT posting setup validation events and custom calculation method hooks.
/// </remarks>
table 325 "VAT Posting Setup"
{
    Caption = 'VAT Posting Setup';
    DrillDownPageID = "VAT Posting Setup";
    LookupPageID = "VAT Posting Setup";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// VAT business posting group code identifying the customer/vendor VAT category.
        /// </summary>
        field(1; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group code identifying the item/service VAT category.
        /// </summary>
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// VAT calculation method determining how VAT amounts are computed for this posting group combination.
        /// </summary>
        field(3; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            ToolTip = 'Specifies how VAT will be calculated for purchases or sales of items with this particular combination of VAT business posting group and VAT product posting group.';

            trigger OnValidate()
            begin
                FailIfVATPostingSetupHasVATEntries();
            end;
        }
        /// <summary>
        /// VAT percentage rate used for standard VAT calculations when VAT Calculation Type is Normal VAT.
        /// </summary>
        field(4; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            ToolTip = 'Specifies the relevant VAT rate for the particular combination of VAT business posting group and VAT product posting group. Do not enter the percent sign, only the number. For example, if the VAT rate is 25 %, enter 25 in this field.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("VAT %"));
                CheckVATIdentifier();
            end;
        }
        /// <summary>
        /// Unrealized VAT handling method controlling when VAT is realized for accounting purposes.
        /// </summary>
        field(5; "Unrealized VAT Type"; Option)
        {
            Caption = 'Unrealized VAT Type';
            ToolTip = 'Specifies how to handle unrealized VAT, which is VAT that is calculated but not due until the invoice is paid.';
            OptionCaption = ' ,Percentage,First,Last,First (Fully Paid),Last (Fully Paid)';
            OptionMembers = " ",Percentage,First,Last,"First (Fully Paid)","Last (Fully Paid)";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Unrealized VAT Type"));

                if "Unrealized VAT Type" > 0 then begin
                    GLSetup.Get();
                    if not GLSetup."Unrealized VAT" and not GLSetup."Prepayment Unrealized VAT" then
                        GLSetup.TestField("Unrealized VAT", true);
                    NonDeductibleVAT.CheckUnrealizedVATWithNonDeductibleVATInVATPostingSetup(Rec);
                end;
            end;
        }
        /// <summary>
        /// Controls whether VAT amounts are adjusted when payment discounts are applied to invoices.
        /// </summary>
        field(6; "Adjust for Payment Discount"; Boolean)
        {
            Caption = 'Adjust for Payment Discount';
            ToolTip = 'Specifies whether to recalculate VAT amounts when you post payments that trigger payment discounts.';

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Adjust for Payment Discount"));

                if "Adjust for Payment Discount" then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        /// <summary>
        /// G/L account for posting sales VAT amounts when VAT is realized.
        /// </summary>
        field(7; "Sales VAT Account"; Code[20])
        {
            Caption = 'Sales VAT Account';
            ToolTip = 'Specifies the general ledger account number to which to post sales VAT for the particular combination of VAT business posting group and VAT product posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Sales VAT Account"));

                CheckGLAcc("Sales VAT Account");
            end;
        }
        /// <summary>
        /// G/L account for posting unrealized sales VAT amounts before payment is received.
        /// </summary>
        field(8; "Sales VAT Unreal. Account"; Code[20])
        {
            Caption = 'Sales VAT Unreal. Account';
            ToolTip = 'Specifies the general ledger account number to which to post unrealized sales VAT (as calculated when you post sales invoices) using this particular combination of VAT business posting group and VAT product posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Sales VAT Unreal. Account"));

                CheckGLAcc("Sales VAT Unreal. Account");
            end;
        }
        /// <summary>
        /// G/L account for posting purchase VAT amounts when VAT is realized.
        /// </summary>
        field(9; "Purchase VAT Account"; Code[20])
        {
            Caption = 'Purchase VAT Account';
            ToolTip = 'Specifies the general ledger account number to which to post purchase VAT for the particular combination of business group and product group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Purchase VAT Account"));

                CheckGLAcc("Purchase VAT Account");
            end;
        }
        /// <summary>
        /// G/L account for posting unrealized purchase VAT amounts before payment is made.
        /// </summary>
        field(10; "Purch. VAT Unreal. Account"; Code[20])
        {
            Caption = 'Purch. VAT Unreal. Account';
            ToolTip = 'Specifies the general ledger account number to which to post unrealized purchase VAT (as calculated when you post purchase invoices) using this particular combination of VAT business posting group and VAT product posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Purch. VAT Unreal. Account"));

                CheckGLAcc("Purch. VAT Unreal. Account");
            end;
        }
        /// <summary>
        /// G/L account for posting reverse charge VAT amounts for EU and domestic transactions.
        /// </summary>
        field(11; "Reverse Chrg. VAT Acc."; Code[20])
        {
            Caption = 'Reverse Chrg. VAT Acc.';
            ToolTip = 'Specifies the general ledger account number to which you want to post reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Reverse Chrg. VAT Acc."));

                CheckGLAcc("Reverse Chrg. VAT Acc.");
            end;
        }
        /// <summary>
        /// G/L account for posting unrealized reverse charge VAT amounts before payment is made.
        /// </summary>
        field(12; "Reverse Chrg. VAT Unreal. Acc."; Code[20])
        {
            Caption = 'Reverse Chrg. VAT Unreal. Acc.';
            ToolTip = 'Specifies the number of the general ledger account to post amounts for unrealized reverse charge VAT to.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(FieldCaption("Reverse Chrg. VAT Unreal. Acc."));

                CheckGLAcc("Reverse Chrg. VAT Unreal. Acc.");
            end;
        }
        /// <summary>
        /// Unique identifier used for VAT reporting and grouping VAT posting setups with identical VAT characteristics.
        /// </summary>
        field(13; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            ToolTip = 'Specifies a code to group various VAT posting setups with similar attributes, for example VAT percentage.';

            trigger OnValidate()
            begin
                "VAT %" := GetVATPtc();
                NonDeductibleVAT.CheckVATPostingSetupChangeIsAllowed(Rec);
            end;
        }
        /// <summary>
        /// Indicates whether this setup applies to EU services requiring special VAT handling.
        /// </summary>
        field(14; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            ToolTip = 'Specifies if this combination of VAT business posting group and VAT product posting group are to be reported as services in the periodic VAT reports.';
        }
        /// <summary>
        /// VAT clause code for additional VAT terms and conditions displayed on documents.
        /// </summary>
        field(15; "VAT Clause Code"; Code[20])
        {
            Caption = 'VAT Clause Code';
            ToolTip = 'Specifies the VAT Clause Code that is associated with the VAT Posting Setup.';
            TableRelation = "VAT Clause";
        }
        /// <summary>
        /// Indicates whether a Certificate of Supply is required for this VAT posting setup combination.
        /// </summary>
        field(16; "Certificate of Supply Required"; Boolean)
        {
            Caption = 'Certificate of Supply Required';
            ToolTip = 'Specifies if documents that use this combination of VAT business posting group and VAT product posting group require a certificate of supply.';
        }
        /// <summary>
        /// Tax category code used for electronic document transmission and VAT reporting purposes.
        /// </summary>
        field(17; "Tax Category"; Code[10])
        {
            Caption = 'Tax Category';
            ToolTip = 'Specifies the VAT category in connection with electronic document sending. For example, when you send sales documents through the PEPPOL service, the value in this field is used to populate the TaxApplied element in the Supplier group. The number is based on the UNCL5305 standard.';
        }
        /// <summary>
        /// Descriptive text explaining the purpose and usage of this VAT posting setup combination.
        /// </summary>
        field(20; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the VAT posting setup';
        }
        /// <summary>
        /// Prevents the use of this VAT posting setup in new transactions when enabled.
        /// </summary>
        field(21; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies if this particular combination of VAT business posting group and VAT product posting group is blocked.';
        }
        /// <summary>
        /// VAT reporting code used for sales VAT return and statistical reporting purposes.
        /// </summary>
        field(25; "Sale VAT Reporting Code"; Code[20])
        {
            Caption = 'Sale VAT Reporting Code';
            TableRelation = "VAT Reporting Code";
        }
        /// <summary>
        /// VAT reporting code used for purchase VAT return and statistical reporting purposes.
        /// </summary>
        field(26; "Purch. VAT Reporting Code"; Code[20])
        {
            Caption = 'Purchase VAT Reporting Code';
            TableRelation = "VAT Reporting Code";
        }
        /// <summary>
        /// Percentage of VAT amount that cannot be deducted and must be added to the cost of goods or services.
        /// </summary>
        field(6200; "Non-Deductible VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Non-Deductible VAT %';
            ToolTip = 'Specifies the percentage of the transaction amount to which VAT is not applied.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestNotSalesTax(CopyStr(FieldCaption("VAT %"), 1, 100));
                TestField("Allow Non-Deductible VAT", "Allow Non-Deductible VAT"::Allow);
                NonDeductibleVAT.CheckVATPostingSetupChangeIsAllowed(Rec);
            end;
        }
        /// <summary>
        /// G/L account for posting non-deductible purchase VAT amounts that are added to asset or expense costs.
        /// </summary>
        field(6202; "Non-Ded. Purchase VAT Account"; Code[20])
        {
            Caption = 'Non-Deductible Purchase VAT Account';
            ToolTip = 'Specifies the account associated with the VAT amount that is not deducted due to the type of goods or services purchased.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                TestNotSalesTax(CopyStr(FieldCaption("Non-Ded. Purchase VAT Account"), 1, 100));
                CheckGLAcc("Non-Ded. Purchase VAT Account");
            end;
        }
        /// <summary>
        /// Controls whether non-deductible VAT functionality is allowed for this VAT posting setup combination.
        /// </summary>
        field(6203; "Allow Non-Deductible VAT"; Enum "Allow Non-Deductible VAT Type")
        {
            Caption = 'Allow Non-Deductible VAT';
            ToolTip = 'Specifies whether the Non-Deductible VAT is considered for this particular combination of VAT business posting group and VAT product posting group.';

            trigger OnValidate()
            begin
                NonDeductibleVAT.CheckVATPostingSetupChangeIsAllowed(Rec);
            end;
        }
    }

    keys
    {
        key(Key1; "VAT Bus. Posting Group", "VAT Prod. Posting Group")
        {
            Clustered = true;
        }
        key(Key2; "VAT Prod. Posting Group", "VAT Bus. Posting Group")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckSetupUsage("VAT Bus. Posting Group", "VAT Prod. Posting Group");
    end;

    trigger OnRename()
    begin
        CheckSetupUsage(xRec."VAT Bus. Posting Group", xRec."VAT Prod. Posting Group");
    end;

    trigger OnInsert()
    begin
        if "VAT %" = 0 then
            "VAT %" := GetVATPtc();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PostingSetupMgt: Codeunit PostingSetupManagement;
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        AccountSuggested: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must be entered on the tax jurisdiction line when %2 is %3.';
        Text001: Label '%1 = %2 has already been used for %3 = %4 in %5 for %6 = %7 and %8 = %9.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        YouCannotDeleteOrModifyErr: Label 'You cannot modify or delete VAT posting setup %1 %2 as it has been used to generate GL entries. Changing the setup now can cause inconsistencies in your financial data.', Comment = '%1 = "VAT Bus. Posting Group"; %2 = "VAT Prod. Posting Group"';
        VATPostingSetupHasVATEntriesErr: Label 'You cannot change the VAT posting setup because it has been used to generate VAT entries. Changing the setup now can cause inconsistencies in your financial data.';
        NoAccountSuggestedMsg: Label 'Cannot suggest G/L accounts as there is nothing to base suggestion on.';

    local procedure FailIfVATPostingSetupHasVATEntries()
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Bus. Posting Group", Rec."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", Rec."VAT Prod. Posting Group");

        if not VATEntry.IsEmpty() then
            Error(VATPostingSetupHasVATEntriesErr);
    end;

    /// <summary>
    /// Validates that the specified G/L account exists and is properly configured for VAT posting.
    /// </summary>
    /// <param name="AccNo">G/L Account number to validate</param>
    procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;

    local procedure CheckSetupUsage(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSetupUsage(Rec, IsHandled, VATBusPostingGroup, VATProdPostingGroup);
        if IsHandled then
            exit;

        GLEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        GLEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        if not GLEntry.IsEmpty() then
            Error(YouCannotDeleteOrModifyErr, VATBusPostingGroup, VATProdPostingGroup);
    end;

    /// <summary>
    /// Validates that the specified field is not used when VAT Calculation Type is Sales Tax.
    /// Prevents configuration of VAT fields that are incompatible with Sales Tax calculation method.
    /// </summary>
    /// <param name="FromFieldName">Name of the field being validated for Sales Tax compatibility</param>
    procedure TestNotSalesTax(FromFieldName: Text[100])
    begin
        if "VAT Calculation Type" = "VAT Calculation Type"::"Sales Tax" then
            Error(
              Text000,
              FromFieldName, FieldCaption("VAT Calculation Type"),
              "VAT Calculation Type");
    end;

    local procedure CheckVATIdentifier()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', "VAT Prod. Posting Group");
        VATPostingSetup.SetFilter("VAT %", '<>%1', "VAT %");
        VATPostingSetup.SetRange("VAT Identifier", "VAT Identifier");
        if VATPostingSetup.FindFirst() then
            Error(
              Text001,
              FieldCaption("VAT Identifier"), VATPostingSetup."VAT Identifier",
              FieldCaption("VAT %"), VATPostingSetup."VAT %", TableCaption(),
              FieldCaption("VAT Bus. Posting Group"), VATPostingSetup."VAT Bus. Posting Group",
              FieldCaption("VAT Prod. Posting Group"), VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure GetVATPtc(): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', "VAT Prod. Posting Group");
        VATPostingSetup.SetRange("VAT Identifier", "VAT Identifier");
        if not VATPostingSetup.FindFirst() then
            VATPostingSetup."VAT %" := "VAT %";
        exit(VATPostingSetup."VAT %");
    end;

    /// <summary>
    /// Returns the appropriate sales VAT G/L account based on whether unrealized VAT is being processed.
    /// Retrieves either realized or unrealized sales VAT account with validation for required account setup.
    /// </summary>
    /// <param name="Unrealized">Whether to return unrealized VAT account instead of standard VAT account</param>
    /// <returns>G/L Account number for sales VAT posting</returns>
    procedure GetSalesAccount(Unrealized: Boolean): Code[20]
    var
        SalesVATAccountNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetSalesAccount(Rec, Unrealized, SalesVATAccountNo, IsHandled);
        if IsHandled then
            exit(SalesVATAccountNo);

        if Unrealized then begin
            if "Sales VAT Unreal. Account" = '' then
                PostingSetupMgt.LogVATPostingSetupFieldError(Rec, FieldNo("Sales VAT Unreal. Account"));

            exit("Sales VAT Unreal. Account");
        end;
        if "Sales VAT Account" = '' then
            PostingSetupMgt.LogVATPostingSetupFieldError(Rec, FieldNo("Sales VAT Account"));

        exit("Sales VAT Account");
    end;

    /// <summary>
    /// Returns the appropriate purchase VAT G/L account based on whether unrealized VAT is being processed.
    /// Retrieves either realized or unrealized purchase VAT account with validation for required account setup.
    /// </summary>
    /// <param name="Unrealized">Whether to return unrealized VAT account instead of standard VAT account</param>
    /// <returns>G/L Account number for purchase VAT posting</returns>
    procedure GetPurchAccount(Unrealized: Boolean): Code[20]
    var
        PurchVATAccountNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeGetPurchAccount(Rec, Unrealized, PurchVATAccountNo, IsHandled);
        if IsHandled then
            exit(PurchVATAccountNo);

        if Unrealized then begin
            if "Purch. VAT Unreal. Account" = '' then
                PostingSetupMgt.LogVATPostingSetupFieldError(Rec, FieldNo("Purch. VAT Unreal. Account"));

            exit("Purch. VAT Unreal. Account");
        end;
        if "Purchase VAT Account" = '' then
            PostingSetupMgt.LogVATPostingSetupFieldError(Rec, FieldNo("Purchase VAT Account"));

        exit("Purchase VAT Account");
    end;

    /// <summary>
    /// Returns the appropriate reverse charge VAT G/L account based on whether unrealized VAT is being processed.
    /// Retrieves either realized or unrealized reverse charge VAT account for EU and domestic reverse charge transactions.
    /// </summary>
    /// <param name="Unrealized">Whether to return unrealized VAT account instead of standard VAT account</param>
    /// <returns>G/L Account number for reverse charge VAT posting</returns>
    procedure GetRevChargeAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            if "Reverse Chrg. VAT Unreal. Acc." = '' then
                PostingSetupMgt.LogVATPostingSetupFieldError(Rec, FieldNo("Reverse Chrg. VAT Unreal. Acc."));

            exit("Reverse Chrg. VAT Unreal. Acc.");
        end;
        if "Reverse Chrg. VAT Acc." = '' then
            PostingSetupMgt.LogVATPostingSetupFieldError(Rec, FieldNo("Reverse Chrg. VAT Acc."));

        exit("Reverse Chrg. VAT Acc.");
    end;

    /// <summary>
    /// Sets visibility flags for unrealized VAT and payment discount adjustment based on General Ledger Setup configuration.
    /// Controls UI field visibility for VAT posting setup pages based on system-wide VAT settings.
    /// </summary>
    /// <param name="UnrealizedVATVisible">Returns true if unrealized VAT fields should be visible</param>
    /// <param name="AdjustForPmtDiscVisible">Returns true if payment discount adjustment fields should be visible</param>
    procedure SetAccountsVisibility(var UnrealizedVATVisible: Boolean; var AdjustForPmtDiscVisible: Boolean)
    begin
        GLSetup.Get();
        UnrealizedVATVisible := GLSetup."Unrealized VAT" or GLSetup."Prepayment Unrealized VAT";
        AdjustForPmtDiscVisible := GLSetup."Adjust for Payment Disc.";
    end;

    /// <summary>
    /// Suggests G/L account assignments for VAT posting setup based on existing similar setups and account patterns.
    /// Provides automated account suggestion functionality to streamline VAT posting setup configuration.
    /// </summary>
    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        AccountSuggested := false;
        RecRef.GetTable(Rec);
        SuggestVATAccounts(RecRef);
        if AccountSuggested then
            RecRef.Modify()
        else
            Message(NoAccountSuggestedMsg);
    end;

    local procedure SuggestVATAccounts(var RecRef: RecordRef)
    begin
        if "Sales VAT Account" = '' then
            SuggestAccount(RecRef, FieldNo("Sales VAT Account"));
        if "Purchase VAT Account" = '' then
            SuggestAccount(RecRef, FieldNo("Purchase VAT Account"));

        if "Unrealized VAT Type" > 0 then begin
            if "Sales VAT Unreal. Account" = '' then
                SuggestAccount(RecRef, FieldNo("Sales VAT Unreal. Account"));
            if "Purch. VAT Unreal. Account" = '' then
                SuggestAccount(RecRef, FieldNo("Purch. VAT Unreal. Account"));
        end;

        if "VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT" then begin
            if "Reverse Chrg. VAT Acc." = '' then
                SuggestAccount(RecRef, FieldNo("Reverse Chrg. VAT Acc."));
            if ("Unrealized VAT Type" > 0) and ("Reverse Chrg. VAT Unreal. Acc." = '') then
                SuggestAccount(RecRef, FieldNo("Reverse Chrg. VAT Unreal. Acc."));
        end;
    end;

    local procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        VATPostingSetupRecRef: RecordRef;
        VATPostingSetupFieldRef: FieldRef;
    begin
        VATPostingSetupRecRef.Open(DATABASE::"VAT Posting Setup");

        VATPostingSetupRecRef.Reset();
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Bus. Posting Group"));
        VATPostingSetupFieldRef.SetRange("VAT Bus. Posting Group");
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Prod. Posting Group"));
        VATPostingSetupFieldRef.SetFilter('<>%1', "VAT Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(VATPostingSetupRecRef, AccountFieldNo);

        VATPostingSetupRecRef.Reset();
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Bus. Posting Group"));
        VATPostingSetupFieldRef.SetFilter('<>%1', "VAT Bus. Posting Group");
        VATPostingSetupFieldRef := VATPostingSetupRecRef.Field(FieldNo("VAT Prod. Posting Group"));
        VATPostingSetupFieldRef.SetRange("VAT Prod. Posting Group");
        TempAccountUseBuffer.UpdateBuffer(VATPostingSetupRecRef, AccountFieldNo);

        VATPostingSetupRecRef.Close();

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast() then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
            AccountSuggested := true;
        end;
    end;

    /// <summary>
    /// Integration event raised before retrieving purchase VAT account to allow custom account selection logic.
    /// Enables extensions to override standard purchase VAT account determination based on custom business rules.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record for account determination</param>
    /// <param name="Unrealized">Whether unrealized VAT account is being requested</param>
    /// <param name="PurchVATAccountNo">Custom purchase VAT account number to use</param>
    /// <param name="IsHandled">Set to true to skip standard account determination</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchAccount(var VATPostingSetup: Record "VAT Posting Setup"; Unrealized: Boolean; var PurchVATAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before retrieving sales VAT account to allow custom account selection logic.
    /// Enables extensions to override standard sales VAT account determination based on custom business rules.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record for account determination</param>
    /// <param name="Unrealized">Whether unrealized VAT account is being requested</param>
    /// <param name="SalesVATAccountNo">Custom sales VAT account number to use</param>
    /// <param name="IsHandled">Set to true to skip standard account determination</param>
    /// <summary>
    /// Integration event raised before retrieving sales VAT account to allow custom account selection logic.
    /// Enables extensions to override standard sales VAT account determination based on custom business rules.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record for account determination</param>
    /// <param name="Unrealized">Whether unrealized VAT account is being requested</param>
    /// <param name="SalesVATAccountNo">Custom sales VAT account number to use</param>
    /// <param name="IsHandled">Set to true to skip standard account determination</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesAccount(var VATPostingSetup: Record "VAT Posting Setup"; Unrealized: Boolean; var SalesVATAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking VAT posting setup usage to allow custom validation logic.
    /// Enables extensions to perform additional validation or override standard setup usage checks.
    /// </summary>
    /// <param name="VATPostingSetup">VAT posting setup record being validated</param>
    /// <param name="IsHandled">Set to true to skip standard setup usage validation</param>
    /// <param name="VATBusPostingGroup">VAT business posting group being validated</param>
    /// <param name="VATProdPostingGroup">VAT product posting group being validated</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSetupUsage(var VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
    end;
}
