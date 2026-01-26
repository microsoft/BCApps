// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Finance.GeneralLedger.Account;

table 10807 "Sales Tax Setup Wizard"
{
    Caption = 'Sales Tax Setup Wizard';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Tax Account (Sales)"; Code[20])
        {
            Caption = 'Tax Account (Sales)';
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 "Income/Balance" = const("Balance Sheet"),
                                                 Blocked = const(false));

            trigger OnValidate()
            begin
                if ("Tax Account (Sales)" = '') and ("Tax Account (Purchases)" = '') then
                    Error(TaxAccountRequiredErr);
            end;
        }
        field(3; "Tax Account (Purchases)"; Code[20])
        {
            Caption = 'Tax Account (Purchases)';
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));

            trigger OnValidate()
            begin
                Validate("Tax Account (Sales)");
            end;
        }
        field(4; City; Text[30])
        {
            Caption = 'City';

            trigger OnValidate()
            begin
                if ("City Rate" > 0) and (DelChr(City, '<>', ' ') = '') then
                    Error(NotBlankErr, FieldCaption(City), LowerCase(FieldCaption(City)));
                ValidateJurisdiction();
                if City <> xRec.City then
                    "Tax Area Code" := '';
            end;
        }
        field(5; "City Rate"; Decimal)
        {
            Caption = 'City Rate';
            DecimalPlaces = 1 : 3;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("City Rate" > 0) and (DelChr(City, '<>', ' ') = '') then
                    Error(NotBlankErr, FieldCaption(City), LowerCase(FieldCaption(City)));
            end;
        }
        field(6; County; Text[30])
        {
            Caption = 'County';

            trigger OnValidate()
            begin
                if ("County Rate" > 0) and (DelChr(County, '<>', ' ') = '') then
                    Error(NotBlankErr, FieldCaption(County), LowerCase(FieldCaption(County)));
                ValidateJurisdiction();

                if County <> xRec.County then
                    "Tax Area Code" := '';
            end;
        }
        field(7; "County Rate"; Decimal)
        {
            Caption = 'County Rate';
            DecimalPlaces = 1 : 3;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("County Rate" > 0) and (DelChr(County, '<>', ' ') = '') then
                    Error(NotBlankErr, FieldCaption(County), LowerCase(FieldCaption(County)));
            end;
        }
        field(8; State; Code[2])
        {
            Caption = 'State';

            trigger OnValidate()
            begin
                if ("State Rate" > 0) and (DelChr(State, '<>', ' ') = '') then
                    Error(NotBlankErr, FieldCaption(State), LowerCase(FieldCaption(State)));
                ValidateJurisdiction();
                if State <> xRec.State then
                    "Tax Area Code" := '';
            end;
        }
        field(9; "State Rate"; Decimal)
        {
            Caption = 'State Rate';
            DecimalPlaces = 1 : 3;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("State Rate" > 0) and (DelChr(State, '<>', ' ') = '') then
                    Error(NotBlankErr, FieldCaption(State), LowerCase(FieldCaption(State)));
            end;
        }
        field(10; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
        }
        field(10010; "Country/Region"; Option)
        {
            Caption = 'Country/Region';
            OptionCaption = 'US,CA';
            OptionMembers = US,CA;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NotBlankErr: Label '%1 must not be blank when a %2 tax rate is specified.', Comment = '%1 = City, County, or State; %2 = city, county, or state';
        TaxAccountRequiredErr: Label 'You must specify at least one tax account.';
        NotUniqueErr: Label 'The City, County, and State must be unique.';
        TaxableCodeTxt: Label 'TAXABLE', Locked = true;
        TaxableDescriptionTxt: Label 'Taxable';
        CityTxt: Label 'City of %1, %2', Comment = '%1 = Name of city; %2 = State abbreviation';
        StateTxt: Label 'State of %1', Comment = '%1 = State abbreviation';

    local procedure ValidateJurisdiction()
    var
        HasError: Boolean;
    begin
        HasError := (UpperCase(City) = UpperCase(County)) and (City <> '');
        HasError := HasError or ((UpperCase(City) = State) and (City <> ''));
        HasError := HasError or ((UpperCase(County) = State) and (County <> ''));
        if HasError then
            Error(NotUniqueErr);
    end;

    procedure SetTaxGroup(var TaxGroup: Record "Tax Group")
    begin
        if not TaxGroup.Get(TaxableCodeTxt) then begin
            TaxGroup.Init();
            TaxGroup.Validate(Code, TaxableCodeTxt);
            TaxGroup.Validate(Description, TaxableDescriptionTxt);
            TaxGroup.Insert();
        end;
    end;

    procedure SetTaxJurisdiction(Jurisdiction: Text[30]; Description: Text[50]; ReportToCode: Code[10])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        JurisdictionCode: Code[10];
        NewJurisdiction: Boolean;
    begin
        if Jurisdiction = '' then
            exit;

        NewJurisdiction := GetTaxJurisdictionCode(Jurisdiction, JurisdictionCode);

        if JurisdictionCode = '' then
            JurisdictionCode := GenerateTaxJurisdictionCode();

        if NewJurisdiction then begin
            TaxJurisdiction.Init();
            TaxJurisdiction.Validate(Code, JurisdictionCode);
            TaxJurisdiction.Insert();
        end else
            TaxJurisdiction.Get(JurisdictionCode);

        TaxJurisdiction.Validate(Description, Description);
        TaxJurisdiction.Validate(Name, Jurisdiction);
        if ReportToCode <> '' then
            TaxJurisdiction.Validate("Report-to Jurisdiction", ReportToCode);
        TaxJurisdiction.Validate("Tax Account (Sales)", "Tax Account (Sales)");
        TaxJurisdiction.Validate("Tax Account (Purchases)", "Tax Account (Purchases)");
        TaxJurisdiction.Validate("Country/Region", "Country/Region");
        TaxJurisdiction.Modify();
    end;

    procedure SetTaxArea(var TaxArea: Record "Tax Area")
    begin
        if not TaxArea.Get("Tax Area Code") then begin
            TaxArea.Init();
            TaxArea.Validate(Code, "Tax Area Code");
            TaxArea.Validate(Description, "Tax Area Code");
            TaxArea.Validate("Country/Region", "Country/Region");
            TaxArea.Insert();
        end;
    end;

    procedure SetTaxAreaLine(TaxArea: Record "Tax Area"; Jurisdiction: Text)
    var
        TaxAreaLine: Record "Tax Area Line";
        JurisdictionCode: Code[10];
    begin
        GetTaxJurisdictionCode(CopyStr(Jurisdiction, 1, MaxStrLen(City)), JurisdictionCode);

        if JurisdictionCode <> '' then
            if not TaxAreaLine.Get(TaxArea.Code, JurisdictionCode) then begin
                TaxAreaLine.Init();
                TaxAreaLine.Validate("Tax Area", TaxArea.Code);
                TaxAreaLine.Validate("Tax Jurisdiction Code", JurisdictionCode);
                TaxAreaLine.Insert();
            end;
    end;

    procedure SetTaxDetail(Jurisdiction: Text[30]; Group: Code[20]; Tax: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        JurisdictionCode: Code[10];
    begin
        GetTaxJurisdictionCode(Jurisdiction, JurisdictionCode);

        if JurisdictionCode <> '' then begin
            TaxDetail.SetRange("Tax Jurisdiction Code", JurisdictionCode);
            TaxDetail.SetRange("Tax Group Code", Group);
            if not TaxDetail.IsEmpty() then
                TaxDetail.DeleteAll();
            TaxDetail.Init();
            TaxDetail.Validate("Tax Jurisdiction Code", JurisdictionCode);
            TaxDetail.Validate("Tax Group Code", Group);
            TaxDetail.Validate("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
            TaxDetail.Validate("Effective Date", 0D);
            TaxDetail.Validate("Maximum Amount/Qty.", 0);
            TaxDetail.Validate("Tax Below Maximum", Tax);
            TaxDetail.Insert(true);
        end;
    end;

    procedure GetDescription(Description: Text; CityOrCounty: Text[30]) Result: Text[50]
    begin
        Result := CopyStr(StrSubstNo(Description, CityOrCounty, State), 1, 50);
        if State = '' then
            Result := DelChr(Result, '>', ', ');
    end;

    procedure GetDefaultTaxGroupCode(): Code[20]
    begin
        exit(UpperCase(TaxableCodeTxt));
    end;

    procedure GenerateTaxAreaCode(): Code[20]
    var
        TrucatedCity: Text[18];
        CommaSeparator: Text[2];
    begin
        TrucatedCity := CopyStr(City, 1, 16);
        if (StrLen(TrucatedCity) > 0) and (StrLen(State) > 0) then
            CommaSeparator := ', ';
        exit(StrSubstNo('%1%2%3', TrucatedCity, CommaSeparator, State));
    end;

    local procedure GenerateTaxJurisdictionCode() JurisdictionCode: Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        repeat
            JurisdictionCode := CopyStr(LowerCase(Format(CreateGuid(), 0, 4)), 1, MaxStrLen(JurisdictionCode));
        until not TaxJurisdiction.Get(JurisdictionCode);
    end;

    local procedure GetTaxJurisdictionCode(JurisdictionName: Text[30]; var JurisdictionCode: Code[10]) NewJurisdiction: Boolean
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if JurisdictionName = '' then
            exit;

        if StrLen(DelChr(JurisdictionName, '<>', ' ')) < MaxStrLen(JurisdictionCode) then
            JurisdictionCode := CopyStr(DelChr(JurisdictionName, '<>', ' '), 1, MaxStrLen(JurisdictionCode));

        NewJurisdiction := true;
        if JurisdictionCode <> '' then
            if TaxJurisdiction.Get(JurisdictionCode) then
                NewJurisdiction := false;

        if NewJurisdiction then begin
            TaxJurisdiction.SetRange(Name, JurisdictionName);
            if TaxJurisdiction.FindFirst() then begin
                JurisdictionCode := TaxJurisdiction.Code;
                NewJurisdiction := false;
            end;
        end;
    end;

    procedure StoreSalesTaxSetup()
    var
        TaxGroup: Record "Tax Group";
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        if "Tax Area Code" = '' then begin
            "Tax Area Code" := GenerateTaxAreaCode();
            Modify();
        end;
        SetTaxGroup(TaxGroup);
        SetTaxJurisdiction(State, StrSubstNo(StateTxt, State), State);
        if State = '' then
            SetTaxJurisdiction(County, StrSubstNo('%1 County', County), State)
        else
            SetTaxJurisdiction(County, StrSubstNo('%1 County, %2', County, State), State);
        SetTaxJurisdiction(City, GetDescription(CityTxt, City), State);
        SetTaxArea(TaxArea);

        TaxAreaLine.SetRange("Tax Area", "Tax Area Code");
        if not TaxAreaLine.IsEmpty() then
            TaxAreaLine.DeleteAll();
        SetTaxAreaLine(TaxArea, State);
        SetTaxAreaLine(TaxArea, County);
        SetTaxAreaLine(TaxArea, City);
        SetTaxDetail(State, TaxGroup.Code, "State Rate");
        SetTaxDetail(County, TaxGroup.Code, "County Rate");
        SetTaxDetail(City, TaxGroup.Code, "City Rate");
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    var
        TaxSetup: Record "Tax Setup";
        GLAccount: Record "G/L Account";
    begin
        if TaxSetup.Get() then begin
            if ("Tax Account (Sales)" = '') and (TaxSetup."Tax Account (Sales)" <> '') then
                if GLAccount.Get(TaxSetup."Tax Account (Sales)") then
                    Validate("Tax Account (Sales)", GLAccount."No.");
            if ("Tax Account (Purchases)" = '') and (TaxSetup."Tax Account (Purchases)" <> '') then
                if GLAccount.Get(TaxSetup."Tax Account (Purchases)") then
                    Validate("Tax Account (Purchases)", GLAccount."No.");
        end;
    end;
}

