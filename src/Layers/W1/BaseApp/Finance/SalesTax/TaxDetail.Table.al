// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

/// <summary>
/// Stores detailed tax rate configurations for specific jurisdictions and tax groups.
/// Defines percentage rates, maximum thresholds, and effective dates for precise tax calculations.
/// </summary>
table 322 "Tax Detail"
{
    Caption = 'Tax Detail';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Tax jurisdiction code this detail applies to.
        /// </summary>
        field(1; "Tax Jurisdiction Code"; Code[10])
        {
            Caption = 'Tax Jurisdiction Code';
            ToolTip = 'Specifies the tax jurisdiction code for the tax-detail entry.';
            NotBlank = true;
            TableRelation = "Tax Jurisdiction";
        }
        /// <summary>
        /// Tax group code for item categorization and rate determination.
        /// </summary>
        field(2; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            ToolTip = 'Specifies the tax group code for the tax-detail entry.';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// Type of tax calculation applied (Sales Tax or Excise Tax).
        /// </summary>
        field(3; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            ToolTip = 'Specifies the type of tax (Sales Tax or Excise Tax) that applies to the tax-detail entry.';
            NotBlank = false;
            OptionCaption = 'Sales Tax,Excise Tax';
            OptionMembers = "Sales Tax","Excise Tax";
        }
        /// <summary>
        /// Maximum amount or quantity threshold for tax rate application.
        /// </summary>
        field(4; "Maximum Amount/Qty."; Decimal)
        {
            Caption = 'Maximum Amount/Qty.';
            ToolTip = 'Specifies a maximum amount or quantity. The program finds the appropriate tax percentage in either the Tax Below Maximum or the Tax Above Maximum field.';
            DecimalPlaces = 2 : 2;
            MinValue = 0;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        /// <summary>
        /// Tax percentage applied below the maximum threshold.
        /// </summary>
        field(5; "Tax Below Maximum"; Decimal)
        {
            Caption = 'Tax Below Maximum';
            ToolTip = 'Specifies the percentage that will be used to calculate tax for all amounts or quantities below the maximum amount quantity in the Maximum Amount/Qty. field.';
            DecimalPlaces = 1 : 3;
            MinValue = 0;
            AutoFormatType = 0;
        }
        /// <summary>
        /// Tax percentage applied above the maximum threshold.
        /// </summary>
        field(6; "Tax Above Maximum"; Decimal)
        {
            Caption = 'Tax Above Maximum';
            ToolTip = 'Specifies the percentage that will be used to calculate tax for all amounts or quantities above the maximum amount quantity in the Maximum Amount/Qty. field.';
            DecimalPlaces = 1 : 3;
            MinValue = 0;
            AutoFormatType = 0;
        }
        /// <summary>
        /// Date when this tax rate configuration becomes effective.
        /// </summary>
        field(7; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
            ToolTip = 'Specifies a date on which the tax-detail entry will go into effect. This allows you to set up tax details in advance.';
        }
        /// <summary>
        /// Indicates whether tax is calculated on previously calculated taxes (compound taxation).
        /// </summary>
        field(8; "Calculate Tax on Tax"; Boolean)
        {
            Caption = 'Calculate Tax on Tax';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Tax Jurisdiction Code", "Tax Group Code", "Tax Type", "Effective Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get("Tax Jurisdiction Code");
        "Calculate Tax on Tax" := TaxJurisdiction."Calculate Tax on Tax";
    end;

    trigger OnRename()
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get("Tax Jurisdiction Code");
        "Calculate Tax on Tax" := TaxJurisdiction."Calculate Tax on Tax";
    end;

    var
        SpecifyTaxMsg: Label 'Please specify a %1 first.', Comment = '%1=Tax Area Code or Tax Group Code';
        CannotChangeNonTaxableGroupCodeErr: Label 'You cannot change the rate for the non-taxable group.';

    local procedure ApplyCommonFilters(TaxJurisdictionCode: Code[20]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date)
    begin
        Reset();
        SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        SetRange("Tax Group Code", TaxGroupCode);
        SetRange("Tax Type", TaxType);
        if EffectiveDate <> 0D then
            SetFilter("Effective Date", '<=%1', EffectiveDate);
    end;

    /// <summary>
    /// Validates and creates missing tax details for a specific tax area and group combination.
    /// Ensures all required tax detail records exist for proper tax calculation.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code to validate</param>
    /// <param name="TaxGroupCode">Tax group code to validate</param>
    /// <param name="EffectiveDate">Effective date for tax detail lookup</param>
    procedure ValidateTaxSetup(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; EffectiveDate: Date)
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        TaxSetup: Record "Tax Setup";
    begin
        TaxArea.Get(TaxAreaCode);
        TaxGroup.Get(TaxGroupCode);
        TaxSetup.Get();
        TaxAreaLine.SetRange("Tax Area", TaxArea.Code);
        if TaxAreaLine.FindSet() then
            repeat
                if TaxGroupCode <> TaxSetup."Non-Taxable Tax Group Code" then begin
                    ApplyCommonFilters(TaxAreaLine."Tax Jurisdiction Code", '', "Tax Type"::"Sales Tax", EffectiveDate);
                    if not FindFirst() then
                        ApplyCommonFilters(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate);
                end else
                    ApplyCommonFilters(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate);
                if not FindFirst() then
                    SetNewTaxRate(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, 0);
            until TaxAreaLine.Next() = 0;
    end;

    /// <summary>
    /// Calculates the total sales tax rate for a tax area and group combination.
    /// Sums tax rates across all jurisdictions within the specified tax area.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code for rate calculation</param>
    /// <param name="TaxGroupCode">Tax group code for rate determination</param>
    /// <param name="EffectiveDate">Date for tax rate lookup</param>
    /// <param name="TaxLiable">Whether the transaction is tax liable</param>
    /// <returns>Combined tax rate as decimal percentage</returns>
    procedure GetSalesTaxRate(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; EffectiveDate: Date; TaxLiable: Boolean): Decimal
    var
        TaxAreaLine: Record "Tax Area Line";
        TotalTaxRate: Decimal;
    begin
        if not TaxLiable then
            exit(0);
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.FindSet() then
            repeat
                TotalTaxRate += GetTaxRate(TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate);
            until TaxAreaLine.Next() = 0;
        exit(TotalTaxRate);
    end;

    /// <summary>
    /// Updates the sales tax rate for a specific tax area and group combination.
    /// Automatically distributes rate changes across appropriate jurisdictions.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code to update</param>
    /// <param name="TaxGroupCode">Tax group code to update</param>
    /// <param name="NewTaxRate">New tax rate as decimal percentage</param>
    /// <param name="EffectiveDate">Effective date for the new rate</param>
    procedure SetSalesTaxRate(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; NewTaxRate: Decimal; EffectiveDate: Date)
    var
        TaxSetup: Record "Tax Setup";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxJurisdiction2: Record "Tax Jurisdiction";
        TotalTaxRate: Decimal;
    begin
        if TaxGroupCode = '' then
            exit;
        if TaxSetup.Get() then
            if TaxSetup."Non-Taxable Tax Group Code" = TaxGroupCode then
                Error(CannotChangeNonTaxableGroupCodeErr);
        if NewTaxRate = GetSalesTaxRate(TaxAreaCode, TaxGroupCode, EffectiveDate, true) then
            exit;
        if TaxAreaCode = '' then begin
            Message(SpecifyTaxMsg, TaxAreaLine.FieldCaption("Tax Area"));
            exit;
        end;
        TotalTaxRate := 0;
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        TaxAreaLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
        if TaxAreaLine.FindSet() then
            repeat
                if TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code") then begin
                    TotalTaxRate += GetTaxRate(TaxJurisdiction.Code, TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate);
                    if TaxJurisdiction2.Code = '' then // the first
                        TaxJurisdiction2 := TaxJurisdiction
                    else
                        if TaxJurisdiction.Code <> TaxJurisdiction."Report-to Jurisdiction" then
                            TaxJurisdiction2 := TaxJurisdiction;
                end;
            until TaxAreaLine.Next() = 0;
        if TaxJurisdiction2.Code = '' then
            exit; // missing setup
        TotalTaxRate -= GetTaxRate(TaxJurisdiction2.Code, TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate);
        SetNewTaxRate(TaxJurisdiction2.Code, TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, NewTaxRate - TotalTaxRate);
    end;

    /// <summary>
    /// Sets detailed sales tax rates for city, county, and state jurisdictions separately.
    /// Allows precise control over multi-level jurisdiction tax rates.
    /// </summary>
    /// <param name="TaxAreaCode">Tax area code to update</param>
    /// <param name="TaxGroupCode">Tax group code to update</param>
    /// <param name="NewCityRate">City-level tax rate</param>
    /// <param name="NewCountyRate">County-level tax rate</param>
    /// <param name="NewStateRate">State-level tax rate</param>
    /// <param name="EffectiveDate">Effective date for the new rates</param>
    procedure SetSalesTaxRateDetailed(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; NewCityRate: Decimal; NewCountyRate: Decimal; NewStateRate: Decimal; EffectiveDate: Date)
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxJurisDictionCodes: array[3] of Code[10];
        i: Integer;
    begin
        if TaxAreaCode = '' then begin
            Message(SpecifyTaxMsg, TaxAreaLine.FieldCaption("Tax Area"));
            exit;
        end;
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        TaxAreaLine.SetFilter("Tax Jurisdiction Code", '<>%1', '');
        if TaxAreaLine.FindSet() then
            repeat
                if TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code") then begin
                    i += 1;
                    if i <= 3 then
                        TaxJurisDictionCodes[i] := TaxJurisdiction.Code;
                end;
            until (TaxAreaLine.Next() = 0) or (i = 3);
        if i = 0 then
            exit;
        if i < 3 then begin
            NewStateRate += NewCountyRate;
            NewCountyRate := 0;
        end;
        if i < 2 then begin
            NewStateRate += NewCityRate;
            NewCityRate := 0;
        end;
        case i of
            1:
                SetNewTaxRate(TaxJurisDictionCodes[1], TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, NewStateRate);
            2:
                begin
                    SetNewTaxRate(TaxJurisDictionCodes[1], TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, NewCityRate);
                    SetNewTaxRate(TaxJurisDictionCodes[2], TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, NewStateRate);
                end;
            3:
                begin
                    SetNewTaxRate(TaxJurisDictionCodes[1], TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, NewCityRate);
                    SetNewTaxRate(TaxJurisDictionCodes[2], TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, NewCountyRate);
                    SetNewTaxRate(TaxJurisDictionCodes[3], TaxGroupCode, "Tax Type"::"Sales Tax", EffectiveDate, NewStateRate);
                end;
        end;
    end;

    local procedure GetTaxRate(TaxJurisdictionCode: Code[20]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date): Decimal
    begin
        ApplyCommonFilters(TaxJurisdictionCode, TaxGroupCode, TaxType, EffectiveDate);
        if FindLast() then
            exit("Tax Below Maximum");
        exit(0);
    end;

    local procedure SetNewTaxRate(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date; NewTaxRate: Decimal)
    begin
        ApplyCommonFilters(TaxJurisdictionCode, TaxGroupCode, TaxType, EffectiveDate);
        SetRange("Effective Date", EffectiveDate);
        LockTable();
        if not FindLast() then begin
            Init();
            "Tax Jurisdiction Code" := TaxJurisdictionCode;
            "Tax Group Code" := TaxGroupCode;
            "Tax Type" := TaxType;
            "Effective Date" := EffectiveDate;
            Insert();
        end;
        "Tax Below Maximum" := NewTaxRate;
        Modify();
    end;
}
