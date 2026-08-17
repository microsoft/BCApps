// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.IO;

codeunit 10150 "O365 Tax Settings Management"
{

    trigger OnRun()
    begin
    end;

    var
        TaxableCodeTxt: Label 'TAXABLE', Locked = true;
        PercentTxt: Label '%';
        DiscardWithNoNameOptionQst: Label 'Keep editing,Discard';
        DiscardWithNoNameInstructionTxt: Label 'City or state name must be filled in.';
        UpdateOtherAreasOptionQst: Label 'Continue,Undo';
        UpdateOtherAreasInstructionTxt: Label 'Updating a city or state tax rate will affect all customers using the rate.';
        DefaultTxt: Label 'DEFAULT', Comment = 'Please translate all caps with max length 20 chars.';
        TemplateTaxAreaDoesNotExistMsg: Label 'Customer template tax area %1 does not exist.', Locked = true;
        TemplateInvoicingCategoryTxt: Label 'AL Inv template', Locked = true;
        CannotRemoveDefaultTaxAreaErr: Label 'You cannot remove the default tax area.';

    procedure IsDefaultTaxAreaAPI(TaxAreaCode: Code[20]): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then
            exit(CompanyInformation."Tax Area Code" = TaxAreaCode);

        exit(TaxAreaCode = DefaultTxt);
    end;

    procedure UpdateSalesTaxSetupWizard(TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary)
    var
        SalesTaxSetupWizard: Record "Sales Tax Setup Wizard";
    begin
        if SalesTaxSetupWizard.Get() then
            SalesTaxSetupWizard.Delete();

        SalesTaxSetupWizard := TempSalesTaxSetupWizard;
        SalesTaxSetupWizard.Insert(true);
    end;

    procedure InitializeTaxSetupFromTaxAreaLinesForUS(var TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary)
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaLine.SetRange("Tax Area", TempSalesTaxSetupWizard."Tax Area Code");
        if TaxAreaLine.FindSet() then
            repeat
                TaxJurisdiction.SetRange(Code, TaxAreaLine."Tax Jurisdiction Code");
                if TaxJurisdiction.FindFirst() then
                    if TaxJurisdiction."Report-to Jurisdiction" = TaxJurisdiction.Code then begin
                        TempSalesTaxSetupWizard.State := CopyStr(TaxJurisdiction.Code, 1, MaxStrLen(TempSalesTaxSetupWizard.State));
                        TempSalesTaxSetupWizard."State Rate" += GetTaxRate(TaxJurisdiction.Code)
                    end else begin
                        TempSalesTaxSetupWizard.City := TaxJurisdiction.GetName();
                        TempSalesTaxSetupWizard."City Rate" += GetTaxRate(TaxJurisdiction.Code)
                    end;
            until TaxAreaLine.Next() = 0;
    end;

    procedure GetProvinceFullLength(JurisdictionCode: Code[10]): Text[100]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        if not TaxJurisdiction.Get(JurisdictionCode) then
            exit('');

        exit(TaxJurisdiction.GetDescriptionInCurrentLanguageFullLength());
    end;

    procedure GetTaxRate(JurisdictionCode: Code[10]): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        if GetDefaultTaxDetail(TaxDetail, JurisdictionCode) then
            exit(TaxDetail."Tax Below Maximum");
    end;

    procedure GetDefaultTaxDetail(var TaxDetail: Record "Tax Detail"; JurisdictionCode: Code[10]): Boolean
    begin
        TaxDetail.SetRange("Tax Jurisdiction Code", JurisdictionCode);
        TaxDetail.SetRange("Tax Group Code", TaxableCodeTxt);
        TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        if TaxDetail.FindLast() then
            exit(true);

        TaxDetail.Reset();
        exit(false);
    end;

    procedure GetDefaultTaxArea(): Code[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        if CompanyInformation.Get() then
            exit(CompanyInformation."Tax Area Code");
    end;

    [Scope('OnPrem')]
    procedure GenerateTaxAreaDescription(TotalRate: Decimal; City: Text; State: Code[10]): Text[100]
    var
        DummyTaxArea: Record "Tax Area";
        Result: Text;
    begin
        Result := Format(TotalRate) + PercentTxt;

        case true of
            (State <> '') and (City <> ''):
                Result := StrSubstNo('%1, %2, %3', City, State, Result);
            City <> '':
                Result := StrSubstNo('%1, %2', City, Result);
            State <> '':
                Result := StrSubstNo('%1, %2', State, Result);
        end;

        exit(CopyStr(Result, 1, MaxStrLen(DummyTaxArea.Description)));
    end;

    [Scope('OnPrem')]
    procedure UpdateTaxAreaDescriptionsWithSameStateOrCity(SalesTaxSetupWizard: Record "Sales Tax Setup Wizard")
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TempSalesTaxSetupWizard2: Record "Sales Tax Setup Wizard" temporary;
        SalesLine: Record "Sales Line";
    begin
        TaxAreaLine.SetFilter(
          "Tax Jurisdiction Code", '%1|%2', SalesTaxSetupWizard.State, GetCityCodeFromSalesTaxSetup(SalesTaxSetupWizard));

        // For each tax area pair using the modified state or city, regenerate the tax area description
        // Also update the invoice amount for all existing invoices using these tax areas
        if TaxAreaLine.FindSet() then
            repeat
                if TaxArea.Get(TaxAreaLine."Tax Area") then begin
                    TempSalesTaxSetupWizard2.Init();
                    TempSalesTaxSetupWizard2."Tax Area Code" := TaxArea.Code;
                    InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard2);

                    TaxArea.Description := GenerateTaxAreaDescription(
                        TempSalesTaxSetupWizard2."City Rate" + TempSalesTaxSetupWizard2."State Rate",
                        TempSalesTaxSetupWizard2.City, TempSalesTaxSetupWizard2.State);
                    TaxArea.Modify(true);

                    SalesLine.SetRange("Tax Area Code", TaxArea.Code);
                    if SalesLine.FindSet() then
                        repeat
                            SalesLine.UpdateAmounts();
                            SalesLine.Modify(true);
                        until SalesLine.Next() = 0;
                end;
            until TaxAreaLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CountTaxAreaLinesWithJurisdictionCode(JurisdictionCode: Code[10]): Integer
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.SetRange("Tax Jurisdiction Code", JurisdictionCode);
        exit(TaxAreaLine.Count);
    end;

    [Scope('OnPrem')]
    procedure HasBeenModifiedUS(SalesTaxSetupWizard: Record "Sales Tax Setup Wizard"): Boolean
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
    begin
        TempSalesTaxSetupWizard."Tax Area Code" := SalesTaxSetupWizard."Tax Area Code";
        InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard);

        if (TempSalesTaxSetupWizard.City <> SalesTaxSetupWizard.City) or
           (TempSalesTaxSetupWizard."City Rate" <> SalesTaxSetupWizard."City Rate") or
           (TempSalesTaxSetupWizard.State <> SalesTaxSetupWizard.State) or
           (TempSalesTaxSetupWizard."State Rate" <> SalesTaxSetupWizard."State Rate")
        then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure OtherTaxAreasWithSameStateOrCityExist(SalesTaxSetupWizard: Record "Sales Tax Setup Wizard") DoOtherTaxAreasExist: Boolean
    var
        TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary;
        CityCode: Code[10];
        ExistingTaxAreaLines: Integer;
    begin
        TempSalesTaxSetupWizard."Tax Area Code" := SalesTaxSetupWizard."Tax Area Code";
        InitializeTaxSetupFromTaxAreaLinesForUS(TempSalesTaxSetupWizard);

        ExistingTaxAreaLines := CountTaxAreaLinesWithJurisdictionCode(SalesTaxSetupWizard.State);

        // Only if the state name is unchanged, expect to find one tax area line (for the existing record)
        if (SalesTaxSetupWizard.State <> '') and (SalesTaxSetupWizard.State = TempSalesTaxSetupWizard.State) then
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 1)
        else
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 0);

        CityCode := GetCityCodeFromSalesTaxSetup(SalesTaxSetupWizard);
        ExistingTaxAreaLines := CountTaxAreaLinesWithJurisdictionCode(CityCode);

        // Only if the city name is unchanged, expect to find one tax area line (for the existing record)
        if (SalesTaxSetupWizard.City <> '') and (SalesTaxSetupWizard.City = TempSalesTaxSetupWizard.City) then
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 1)
        else
            DoOtherTaxAreasExist := DoOtherTaxAreasExist or (ExistingTaxAreaLines > 0);
    end;

    local procedure AssignTaxAreaToCustomersAndSalesLines(TaxAreaCode: Code[20])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        OldSalesLine: Record "Sales Line";
    begin
        Customer.SetFilter("Tax Area Code", '%1', '');
        if not Customer.IsEmpty() then
            Customer.ModifyAll("Tax Area Code", TaxAreaCode);

        SalesLine.LockTable();
        SalesLine.SetRange("Tax Area Code", TaxAreaCode);
        SalesLine.SetFilter(Quantity, '<>%1', 0);
        SalesLine.SetFilter("Unit Price", '<>%1', 0);
        if SalesLine.FindSet() then
            repeat
                OldSalesLine := SalesLine;
                SalesLine.UpdateAmounts();
                if (OldSalesLine."Amount Including VAT" <> SalesLine."Amount Including VAT") or
                   (OldSalesLine.Amount <> SalesLine.Amount)
                then
                    SalesLine.Modify();
            until SalesLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure StoreTaxSettingsForUS(var TempSalesTaxSetupWizard: Record "Sales Tax Setup Wizard" temporary; TaxRateDescription: Text[100]): Boolean
    var
        TaxArea: Record "Tax Area";
        ResponseOptNoName: Option Cancel,KeepEditing,Discard;
        ResponseOptUpdate: Option Cancel,Continue,Undo;
    begin
        if not HasBeenModifiedUS(TempSalesTaxSetupWizard) then
            exit(true);

        if GuiAllowed then
            if ((TempSalesTaxSetupWizard."City Rate" <> 0) and (TempSalesTaxSetupWizard.City = '')) or ((TempSalesTaxSetupWizard."State Rate" <> 0) and (TempSalesTaxSetupWizard.State = '')) then begin
                ResponseOptNoName := StrMenu(DiscardWithNoNameOptionQst, 0, DiscardWithNoNameInstructionTxt);
                exit(ResponseOptNoName = ResponseOptNoName::Discard);
            end;

        if GuiAllowed then
            if OtherTaxAreasWithSameStateOrCityExist(TempSalesTaxSetupWizard) then begin
                ResponseOptUpdate := StrMenu(UpdateOtherAreasOptionQst, 0, UpdateOtherAreasInstructionTxt);
                if ResponseOptUpdate = ResponseOptUpdate::Cancel then
                    exit(false);
                if ResponseOptUpdate = ResponseOptUpdate::Undo then
                    exit(true);
            end;

        UpdateTaxAreaNameUS(TempSalesTaxSetupWizard);
        if TempSalesTaxSetupWizard."Tax Area Code" <> '' then begin
            TempSalesTaxSetupWizard.StoreSalesTaxSetup();
            if TaxArea.Get(TempSalesTaxSetupWizard."Tax Area Code") then begin
                TaxArea.Validate(Description, TaxRateDescription);
                TaxArea.Modify();
            end;
            AssignTaxAreaToCustomersAndSalesLines(TempSalesTaxSetupWizard."Tax Area Code");
        end;

        UpdateTaxAreaDescriptionsWithSameStateOrCity(TempSalesTaxSetupWizard);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateTaxAreaNameUS(var SalesTaxSetupWizard: Record "Sales Tax Setup Wizard")
    begin
        if SalesTaxSetupWizard."Tax Area Code" = '' then
            SalesTaxSetupWizard."Tax Area Code" := SalesTaxSetupWizard.GenerateTaxAreaCode();
    end;

    [Scope('OnPrem')]
    procedure AssignDefaultTaxArea(NewTaxAreaCode: Code[20])
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        ConfigTemplateManagement.ReplaceDefaultValueForAllTemplates(
          DATABASE::Customer, Customer.FieldNo("Tax Area Code"), NewTaxAreaCode);

        CompanyInformation.LockTable();
        if CompanyInformation.Get() then
            if CompanyInformation."Tax Area Code" <> NewTaxAreaCode then begin
                CompanyInformation.Validate("Tax Area Code", NewTaxAreaCode);
                CompanyInformation.Modify();
            end;
    end;

    procedure GetTotalTaxRate(TaxAreaCode: Code[20]) TaxRate: Decimal
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        if TaxAreaLine.FindSet() then
            repeat
                TaxJurisdiction.SetRange(Code, TaxAreaLine."Tax Jurisdiction Code");
                if TaxJurisdiction.FindFirst() then
                    TaxRate := TaxRate + GetTaxRate(TaxJurisdiction.Code)
            until TaxAreaLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure IsTaxSet(TaxAreaCode: Code[20]): Boolean
    begin
        exit(GetTotalTaxRate(TaxAreaCode) <> 0);
    end;

    local procedure GetCityCodeFromSalesTaxSetup(var SalesTaxSetupWizard: Record "Sales Tax Setup Wizard"): Code[10]
    begin
        exit(CopyStr(DelChr(SalesTaxSetupWizard.City, '<>', ' '), 1, 10));
    end;

    [Scope('OnPrem')]
    procedure CheckCustomerTemplateTaxIntegrity()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
        DummyCustomer: Record Customer;
        TaxArea: Record "Tax Area";
        CompanyInformation: Record "Company Information";
    begin
        ConfigTemplateHeader.SetRange("Table ID", DATABASE::Customer);
        ConfigTemplateHeader.SetRange(Enabled, true);

        if ConfigTemplateHeader.FindSet() then
            repeat
                ConfigTemplateLine.LockTable();
                ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
                ConfigTemplateLine.SetRange("Table ID", DATABASE::Customer);
                ConfigTemplateLine.SetRange("Field ID", DummyCustomer.FieldNo("Tax Area Code"));

                if ConfigTemplateLine.FindFirst() then
                    if not TaxArea.Get(ConfigTemplateLine."Default Value") then begin
                        OnBeforeSanitizeCustomerTemplateTax(ConfigTemplateLine);
                        if CompanyInformation.Get() then
                            if TaxArea.Get(CompanyInformation."Tax Area Code") then begin
                                ConfigTemplateLine.Validate("Default Value", CompanyInformation."Tax Area Code");
                                ConfigTemplateLine.Modify(true);
                            end;
                    end;
            until ConfigTemplateHeader.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSanitizeCustomerTemplateTax(ConfigTemplateLine: Record "Config. Template Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"O365 Tax Settings Management", 'OnBeforeSanitizeCustomerTemplateTax', '', true, true)]
    local procedure LogWarningIfTemplateIncorrect(ConfigTemplateLine: Record "Config. Template Line")
    begin
        Session.LogMessage('00001OQ', StrSubstNo(TemplateTaxAreaDoesNotExistMsg, ConfigTemplateLine."Default Value"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TemplateInvoicingCategoryTxt);
    end;

    [Scope('OnPrem')]
    procedure DeleteTaxArea(var TaxArea: Record "Tax Area"): Boolean
    begin
        if IsDefaultTaxAreaAPI(TaxArea.Code) then
            Error(CannotRemoveDefaultTaxAreaErr);
        exit(TaxArea.Delete(true));
    end;
}
