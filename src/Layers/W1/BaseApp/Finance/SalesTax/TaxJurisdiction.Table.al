// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Globalization;

/// <summary>
/// Stores tax jurisdiction definitions with account mappings and calculation rules.
/// Represents governmental tax authorities (city, county, state) with specific tax configuration.
/// </summary>
table 320 "Tax Jurisdiction"
{
    Caption = 'Tax Jurisdiction';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Tax Jurisdictions";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the tax jurisdiction.
        /// </summary>
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code you want to assign to this tax jurisdiction. You can enter up to 10 characters, both numbers and letters. It is a good idea to enter a code that is easy to remember.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the tax jurisdiction.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the tax jurisdiction. For example, if the tax jurisdiction code is ATLANTA GA, enter the description as Atlanta, Georgia.';
        }
        /// <summary>
        /// G/L account for posting tax amounts on sales transactions.
        /// </summary>
        field(3; "Tax Account (Sales)"; Code[20])
        {
            Caption = 'Tax Account (Sales)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for posting tax amounts on purchase transactions.
        /// </summary>
        field(4; "Tax Account (Purchases)"; Code[20])
        {
            Caption = 'Tax Account (Purchases)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Parent jurisdiction for consolidated tax reporting.
        /// </summary>
        field(5; "Report-to Jurisdiction"; Code[10])
        {
            Caption = 'Report-to Jurisdiction';
            ToolTip = 'Specifies the tax jurisdiction you want to associate with the jurisdiction you are setting up. For example, if you are setting up a jurisdiction for Atlanta, Georgia, the report-to jurisdiction is Georgia because Georgia is the tax authority to which you report Atlanta sales tax.';
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Date filter for tax calculation queries and reports.
        /// </summary>
        field(6; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Tax group filter for jurisdiction-specific tax calculations.
        /// </summary>
        field(7; "Tax Group Filter"; Code[20])
        {
            Caption = 'Tax Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// G/L account for unrealized tax amounts on sales transactions.
        /// </summary>
        field(8; "Unreal. Tax Acc. (Sales)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Sales)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for unrealized tax amounts on purchase transactions.
        /// </summary>
        field(9; "Unreal. Tax Acc. (Purchases)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Purchases)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for reverse charge amounts on purchase transactions.
        /// </summary>
        field(10; "Reverse Charge (Purchases)"; Code[20])
        {
            Caption = 'Reverse Charge (Purchases)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// G/L account for unrealized reverse charge amounts on purchase transactions.
        /// </summary>
        field(11; "Unreal. Rev. Charge (Purch.)"; Code[20])
        {
            Caption = 'Unreal. Rev. Charge (Purch.)';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// Method for calculating unrealized VAT on partial payments.
        /// </summary>
        field(12; "Unrealized VAT Type"; Option)
        {
            Caption = 'Unrealized VAT Type';
            ToolTip = 'Specifies how to handle unrealized tax, which is tax that is calculated but not due until the invoice is paid.';
            OptionCaption = ' ,Percentage,First,Last,First (Fully Paid),Last (Fully Paid)';
            OptionMembers = " ",Percentage,First,Last,"First (Fully Paid)","Last (Fully Paid)";

            trigger OnValidate()
            begin
                if "Unrealized VAT Type" > 0 then begin
                    GLSetup.Get();
                    GLSetup.TestField("Unrealized VAT", true);
                end;
            end;
        }
        /// <summary>
        /// Indicates whether tax is calculated on previously calculated taxes (compound taxation).
        /// </summary>
        field(13; "Calculate Tax on Tax"; Boolean)
        {
            Caption = 'Calculate Tax on Tax';
            ToolTip = 'Specifies whether to calculate the sales tax amount with the tax on tax principle.';

            trigger OnValidate()
            begin
                TaxDetail.SetRange("Tax Jurisdiction Code", Code);
                TaxDetail.ModifyAll("Calculate Tax on Tax", "Calculate Tax on Tax");
                Modify();
            end;
        }
        /// <summary>
        /// Controls whether tax amounts are adjusted for payment discounts.
        /// </summary>
        field(14; "Adjust for Payment Discount"; Boolean)
        {
            Caption = 'Adjust for Payment Discount';
            ToolTip = 'Specifies whether to recalculate tax amounts when you post payments that trigger payment discounts.';

            trigger OnValidate()
            begin
                if "Adjust for Payment Discount" then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
        /// <summary>
        /// Short name for the tax jurisdiction used in reports and displays.
        /// </summary>
        field(15; Name; Text[30])
        {
            Caption = 'Name';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Report-to Jurisdiction")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteDetailLines();
    end;

    trigger OnInsert()
    begin
        SetDefaults();
        InsertDetailLines();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TaxDetail: Record "Tax Detail";

    /// <summary>
    /// Returns the appropriate sales tax G/L account based on realization status.
    /// </summary>
    /// <param name="Unrealized">Whether to return the unrealized tax account</param>
    /// <returns>G/L account code for sales tax posting</returns>
    procedure GetSalesAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            TestField("Unreal. Tax Acc. (Sales)");
            exit("Unreal. Tax Acc. (Sales)");
        end;
        TestField("Tax Account (Sales)");
        exit("Tax Account (Sales)");
    end;

    /// <summary>
    /// Returns the appropriate purchase tax G/L account based on realization status.
    /// </summary>
    /// <param name="Unrealized">Whether to return the unrealized tax account</param>
    /// <returns>G/L account code for purchase tax posting</returns>
    procedure GetPurchAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            TestField("Unreal. Tax Acc. (Purchases)");
            exit("Unreal. Tax Acc. (Purchases)");
        end;
        TestField("Tax Account (Purchases)");
        exit("Tax Account (Purchases)");
    end;

    /// <summary>
    /// Returns the appropriate reverse charge G/L account based on realization status.
    /// </summary>
    /// <param name="Unrealized">Whether to return the unrealized reverse charge account</param>
    /// <returns>G/L account code for reverse charge posting</returns>
    procedure GetRevChargeAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            TestField("Unreal. Rev. Charge (Purch.)");
            exit("Unreal. Rev. Charge (Purch.)");
        end;
        TestField("Reverse Charge (Purchases)");
        exit("Reverse Charge (Purchases)");
    end;

    /// <summary>
    /// Creates a new tax jurisdiction with the specified code and default account setup.
    /// </summary>
    /// <param name="NewJurisdictionCode">Code for the new tax jurisdiction</param>
    procedure CreateTaxJurisdiction(NewJurisdictionCode: Code[10])
    begin
        Init();
        Code := NewJurisdictionCode;
        Description := NewJurisdictionCode;
        SetDefaults();
        if Insert(true) then;
    end;

    local procedure SetDefaults()
    var
        TaxSetup: Record "Tax Setup";
    begin
        TaxSetup.Get();
        "Tax Account (Sales)" := TaxSetup."Tax Account (Sales)";
        "Tax Account (Purchases)" := TaxSetup."Tax Account (Purchases)";
        "Unreal. Tax Acc. (Sales)" := TaxSetup."Unreal. Tax Acc. (Sales)";
        "Unreal. Tax Acc. (Purchases)" := TaxSetup."Unreal. Tax Acc. (Purchases)";
        "Reverse Charge (Purchases)" := TaxSetup."Reverse Charge (Purchases)";
        "Unreal. Rev. Charge (Purch.)" := TaxSetup."Unreal. Rev. Charge (Purch.)";
    end;

    local procedure InsertDetailLines()
    var
        TaxDetail: Record "Tax Detail";
        TaxSetup: Record "Tax Setup";
    begin
        TaxSetup.Get();
        if not TaxSetup."Auto. Create Tax Details" then
            exit;

        TaxDetail.SetRange("Tax Jurisdiction Code", Code);
        if not TaxDetail.IsEmpty() then
            exit;

        TaxDetail.Init();
        TaxDetail."Tax Jurisdiction Code" := Code;
        TaxDetail."Tax Group Code" := '';
        TaxDetail."Tax Type" := TaxDetail."Tax Type"::"Sales Tax";
        TaxDetail."Effective Date" := WorkDate();
        TaxDetail.Insert();

        if TaxSetup."Non-Taxable Tax Group Code" <> '' then begin
            TaxDetail.Init();
            TaxDetail."Tax Jurisdiction Code" := Code;
            TaxDetail."Tax Group Code" := TaxSetup."Non-Taxable Tax Group Code";
            TaxDetail."Tax Type" := TaxDetail."Tax Type"::"Sales Tax";
            TaxDetail."Effective Date" := WorkDate();
            TaxDetail.Insert();
        end;
    end;

    local procedure DeleteDetailLines()
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
    begin
        TaxAreaLine.SetRange("Tax Jurisdiction Code", Code);
        TaxAreaLine.DeleteAll();

        TaxDetail.SetRange("Tax Jurisdiction Code", Code);
        TaxDetail.DeleteAll();
    end;

    /// <summary>
    /// Returns the tax jurisdiction description in the user's current language.
    /// Falls back to the default description if no translation is available.
    /// </summary>
    /// <returns>Localized description text</returns>
    procedure GetDescriptionInCurrentLanguageFullLength(): Text[100]
    var
        TaxJurisdictionTranslation: Record "Tax Jurisdiction Translation";
        Language: Codeunit Language;
    begin
        if TaxJurisdictionTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(TaxJurisdictionTranslation.Description);

        exit(Description);
    end;

    /// <summary>
    /// Returns the jurisdiction name, defaulting to the code if name is empty.
    /// </summary>
    /// <returns>Jurisdiction name or code</returns>
    procedure GetName(): Text[30]
    begin
        if Name = '' then
            Name := Code;

        exit(Name);
    end;
}
