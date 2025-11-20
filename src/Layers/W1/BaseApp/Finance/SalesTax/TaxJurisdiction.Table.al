// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Globalization;

table 320 "Tax Jurisdiction"
{
    Caption = 'Tax Jurisdiction';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Tax Jurisdictions";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Tax Account (Sales)"; Code[20])
        {
            Caption = 'Tax Account (Sales)';
            TableRelation = "G/L Account";
        }
        field(4; "Tax Account (Purchases)"; Code[20])
        {
            Caption = 'Tax Account (Purchases)';
            TableRelation = "G/L Account";
        }
        field(5; "Report-to Jurisdiction"; Code[10])
        {
            Caption = 'Report-to Jurisdiction';
            TableRelation = "Tax Jurisdiction";
        }
        field(6; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(7; "Tax Group Filter"; Code[20])
        {
            Caption = 'Tax Group Filter';
            FieldClass = FlowFilter;
            TableRelation = "Tax Group";
        }
        field(8; "Unreal. Tax Acc. (Sales)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Sales)';
            TableRelation = "G/L Account";
        }
        field(9; "Unreal. Tax Acc. (Purchases)"; Code[20])
        {
            Caption = 'Unreal. Tax Acc. (Purchases)';
            TableRelation = "G/L Account";
        }
        field(10; "Reverse Charge (Purchases)"; Code[20])
        {
            Caption = 'Reverse Charge (Purchases)';
            TableRelation = "G/L Account";
        }
        field(11; "Unreal. Rev. Charge (Purch.)"; Code[20])
        {
            Caption = 'Unreal. Rev. Charge (Purch.)';
            TableRelation = "G/L Account";
        }
        field(12; "Unrealized VAT Type"; Option)
        {
            Caption = 'Unrealized VAT Type';
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
        field(13; "Calculate Tax on Tax"; Boolean)
        {
            Caption = 'Calculate Tax on Tax';

            trigger OnValidate()
            begin
                TaxDetail.SetRange("Tax Jurisdiction Code", Code);
                TaxDetail.ModifyAll("Calculate Tax on Tax", "Calculate Tax on Tax");
                Modify();
            end;
        }
        field(14; "Adjust for Payment Discount"; Boolean)
        {
            Caption = 'Adjust for Payment Discount';

            trigger OnValidate()
            begin
                if "Adjust for Payment Discount" then begin
                    GLSetup.Get();
                    GLSetup.TestField("Adjust for Payment Disc.", true);
                end;
            end;
        }
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

    procedure GetSalesAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            TestField("Unreal. Tax Acc. (Sales)");
            exit("Unreal. Tax Acc. (Sales)");
        end;
        TestField("Tax Account (Sales)");
        exit("Tax Account (Sales)");
    end;

    procedure GetPurchAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            TestField("Unreal. Tax Acc. (Purchases)");
            exit("Unreal. Tax Acc. (Purchases)");
        end;
        TestField("Tax Account (Purchases)");
        exit("Tax Account (Purchases)");
    end;

    procedure GetRevChargeAccount(Unrealized: Boolean): Code[20]
    begin
        if Unrealized then begin
            TestField("Unreal. Rev. Charge (Purch.)");
            exit("Unreal. Rev. Charge (Purch.)");
        end;
        TestField("Reverse Charge (Purchases)");
        exit("Reverse Charge (Purchases)");
    end;

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

    procedure GetDescriptionInCurrentLanguageFullLength(): Text[100]
    var
        TaxJurisdictionTranslation: Record "Tax Jurisdiction Translation";
        Language: Codeunit Language;
    begin
        if TaxJurisdictionTranslation.Get(Code, Language.GetUserLanguageCode()) then
            exit(TaxJurisdictionTranslation.Description);

        exit(Description);
    end;

    procedure GetName(): Text[30]
    begin
        if Name = '' then
            Name := Code;

        exit(Name);
    end;
}
