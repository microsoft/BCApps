// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;

/// <summary>
/// Creates default <see cref="Expense Country VAT Rate"/> rows for EU countries.
/// Covers the most common reclaimable expense categories (Hotels, Meals, Air travel,
/// Ground transport, Car rental, Fuel, Events/Conferences, Entertainment) with the
/// applicable standard or reduced VAT rate for each country as of 2026.
/// </summary>
codeunit 6975 "Create Expense VAT Rates"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "VAT Product Posting Group" = rimd;

    trigger OnRun()
    begin
        InsertDefaultRates();
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";

    /// <summary>
    /// Inserts all default EU VAT rate rows. Skips rows whose
    /// (Country/Region Code + Expense Category + Expense Subcategory) combination already exists.
    /// </summary>
    procedure InsertDefaultRates()
    var
        CompanyInfo: Record "Company Information";
        GLAccount: Record "G/L Account";
    begin
        ExpenseAgentSetup.GetRecordOnce();
        if ExpenseAgentSetup."Default VAT Bus. Posting Group" = '' then begin
            ExpenseAgentSetup."Default VAT Bus. Posting Group" := XDOMESTICTxt;
            ExpenseAgentSetup.Modify();
        end;

        if not GLAccount.Get(XEXPENSEVATTok) then begin
            GLAccount.Init();
            GLAccount."No." := XEXPENSEVATTok;
            GLAccount."Name" := 'Expense VAT';
            GLAccount.Insert();
        end;

        CompanyInfo.Get();
        case CompanyInfo."Country/Region Code" of
            'AT':
                CreateVATRatesAT();
            'BE':
                CreateVATRatesBE();
            'DE':
                CreateVATRatesDE();
            'DK':
                CreateVATRatesDK();
            'ES':
                CreateVATRatesES();
            'FI':
                CreateVATRatesFI();
            'FR':
                CreateVATRatesFR();
            'HU':
                CreateVATRatesHU();
            'IE':
                CreateVATRatesIE();
            'IT':
                CreateVATRatesIT();
            'LU':
                CreateVATRatesLU();
            'NL':
                CreateVATRatesNL();
            'PL':
                CreateVATRatesPL();
            'PT':
                CreateVATRatesPT();
            'SE':
                CreateVATRatesSE();
            'CH':
                CreateVATRatesCH();
            'GB':
                CreateVATRatesGB();
            'NO':
                CreateVATRatesNO();
            'BG':
                CreateVATRatesBG();
            'CY':
                CreateVATRatesCY();
            'CZ':
                CreateVATRatesCZ();
            'EE':
                CreateVATRatesEE();
            'GR':
                CreateVATRatesGR();
            'HR':
                CreateVATRatesHR();
            'LT':
                CreateVATRatesLT();
            'LV':
                CreateVATRatesLV();
            'MT':
                CreateVATRatesMT();
            'RO':
                CreateVATRatesRO();
            'SI':
                CreateVATRatesSI();
            'SK':
                CreateVATRatesSK();
            'AU':
                CreateVATRatesAU();
            'NZ':
                CreateVATRatesNZ();
            'MX':
                CreateVATRatesMX();
            'IS':
                CreateVATRatesIS();
            'UA':
                CreateVATRatesUA();
        end;
    end;

    local procedure InsertRate(CategoryCode: Code[20]; SubcategoryCode: Code[20]; VATProdPostingGroup: Code[20]; VATPercent: Decimal; NewDescription: Text[100])
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATProductPostingGroup.Get(VATProdPostingGroup) then begin
            VATProductPostingGroup.Init();
            VATProductPostingGroup."Code" := VATProdPostingGroup;
            VATProductPostingGroup."Description" := NewDescription;
            VATProductPostingGroup.Insert();
        end;

        if not VATPostingSetup.Get(ExpenseAgentSetup."Default VAT Bus. Posting Group", VATProdPostingGroup) then begin
            VATPostingSetup.Init();
            VATPostingSetup.Validate("VAT Bus. Posting Group", ExpenseAgentSetup."Default VAT Bus. Posting Group");
            VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            VATPostingSetup.Validate("Purchase VAT Account", XEXPENSEVATTok);
            VATPostingSetup."VAT %" := VATPercent;
            VATPostingSetup.Insert();
        end;

        if SubcategoryCode = '' then begin
            ExpenseCategory.Get(CategoryCode);
            ExpenseCategory.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            ExpenseCategory.Validate("Default VAT %", VATPostingSetup."VAT %");
            if ExpenseCategory."Default VAT %" <> 0 then
                ExpenseCategory.Validate("Default VAT Reclaim %", 100);
            ExpenseCategory.Modify();
        end else begin
            ExpenseSubcategory.Get(CategoryCode, SubcategoryCode);
            ExpenseSubcategory.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            ExpenseSubcategory.Validate("Default VAT %", VATPostingSetup."VAT %");
            if ExpenseSubcategory."Default VAT %" <> 0 then
                ExpenseSubcategory.Validate("Default VAT Reclaim %", 100);
            ExpenseSubcategory.Modify();
        end;
    end;

    var
        CreateExpenseCategories: Codeunit "Create Expense Categories";

        XEXPENSEVATTok: Label 'EXPENSE VAT', Locked = true; // Virtual G/L account used for VAT on expenses
        XDOMESTICTxt: Label 'DOMESTIC'; // DOMESTIC VAT Business Posting Group used as default for all rates created by this codeunit

    local procedure CreateVATRatesAT()
    begin
        // ── Austria (AT) ──────────────────────────────────────────────────────────────
        // Standard 20 %, reduced 10 % (accommodation, food), 13 % (culture/events)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-10', 10, 'Hotel room - accommodation rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-10', 10, 'Hotel deposit - accommodation rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-10', 10, 'Hotel breakfast - food rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-10', 10, 'Hotel room service - food rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-10', 10, 'Hotel transport - reduced rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-20', 20, 'Hotel fees - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-20', 20, 'Hotel phone - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-20', 20, 'Hotel internet - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-20', 20, 'Hotel incidents - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-20', 20, 'Hotel laundry - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-20', 20, 'Hotel parking - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-20', 20, 'Hotel other - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (AT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (AT)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-10', 10, 'Restaurant / meals - reduced rate (AT)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (AT)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-10', 10, 'Ground transport - reduced rate (AT)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-20', 20, 'Car rental - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-20', 20, 'Fuel / car expenses - standard rate (AT)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-RED-13', 13, 'Conferences / events - reduced rate (AT)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-20', 20, 'Entertainment - standard rate (AT)');
    end;

    local procedure CreateVATRatesBE()
    begin
        // ── Belgium (BE) ──────────────────────────────────────────────────────────────
        // Standard 21 %, reduced 12 % (restaurants), 6 % (some services)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-06', 6, 'Hotel room - accommodation rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-06', 6, 'Hotel deposit - accommodation rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-12', 12, 'Hotel breakfast - restaurant rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-12', 12, 'Hotel room service - restaurant rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-06', 6, 'Hotel transport - reduced rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-21', 21, 'Hotel fees - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-21', 21, 'Hotel phone - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-21', 21, 'Hotel internet - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-21', 21, 'Hotel incidents - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-21', 21, 'Hotel laundry - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-21', 21, 'Hotel parking - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-21', 21, 'Hotel other - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (BE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (BE)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-12', 12, 'Restaurant / meals - reduced rate (BE)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (BE)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-06', 6, 'Ground transport - reduced rate (BE)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-21', 21, 'Car rental - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-21', 21, 'Fuel / car expenses - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-21', 21, 'Conferences / events - standard rate (BE)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-21', 21, 'Entertainment - standard rate (BE)');
    end;

    local procedure CreateVATRatesDK()
    begin
        // ── Denmark (DK) ──────────────────────────────────────────────────────────────
        // Standard 25 %, no reduced rates
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-STD-25', 25, 'Hotel room - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-STD-25', 25, 'Hotel deposit - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-STD-25', 25, 'Hotel breakfast - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-STD-25', 25, 'Hotel room service - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-25', 25, 'Hotel transport - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-25', 25, 'Hotel fees - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-25', 25, 'Hotel phone - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-25', 25, 'Hotel internet - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-25', 25, 'Hotel incidents - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-25', 25, 'Hotel laundry - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-25', 25, 'Hotel parking - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-25', 25, 'Hotel other - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (DK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (DK)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-STD-25', 25, 'Restaurant / meals - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (DK)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-25', 25, 'Ground transport - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-25', 25, 'Car rental - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-25', 25, 'Fuel / car expenses - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-25', 25, 'Conferences / events - standard rate (DK)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-25', 25, 'Entertainment - standard rate (DK)');
    end;

    local procedure CreateVATRatesFI()
    begin
        // ── Finland (FI) ──────────────────────────────────────────────────────────────
        // Standard 25.5 %, reduced 13.5 % (accommodation), 10 % (transport/culture)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-14', 13.5, 'Hotel room - accommodation rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-14', 13.5, 'Hotel deposit - accommodation rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-14', 13.5, 'Hotel breakfast - food rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-14', 13.5, 'Hotel room service - food rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-10', 10, 'Hotel transport - reduced rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-255', 25.5, 'Hotel fees - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-255', 25.5, 'Hotel phone - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-255', 25.5, 'Hotel internet - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-255', 25.5, 'Hotel incidents - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-255', 25.5, 'Hotel laundry - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-255', 25.5, 'Hotel parking - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-255', 25.5, 'Hotel other - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (FI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (FI)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-14', 13.5, 'Restaurant / meals - reduced rate (FI)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (FI)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-10', 10, 'Ground transport - reduced rate (FI)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-255', 25.5, 'Car rental - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-255', 25.5, 'Fuel / car expenses - standard rate (FI)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-RED-10', 10, 'Conferences / events - reduced rate (FI)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-255', 25.5, 'Entertainment - standard rate (FI)');
    end;

    local procedure CreateVATRatesFR()
    begin
        // ── France (FR) ──────────────────────────────────────────────────────────────
        // Standard 20 %, reduced 10 % (accommodation, restaurants), 5.5 % (food)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-10', 10, 'Hotel room - accommodation rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-10', 10, 'Hotel deposit - accommodation rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-10', 10, 'Hotel breakfast - food rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-10', 10, 'Hotel room service - food rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-10', 10, 'Hotel transport - reduced rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-20', 20, 'Hotel fees - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-20', 20, 'Hotel phone - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-20', 20, 'Hotel internet - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-20', 20, 'Hotel incidents - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-20', 20, 'Hotel laundry - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-20', 20, 'Hotel parking - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-20', 20, 'Hotel other - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (FR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (FR)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-10', 10, 'Restaurant / meals - reduced rate (FR)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (FR)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-10', 10, 'Ground transport - reduced rate (FR)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-20', 20, 'Car rental - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-20', 20, 'Fuel / car expenses - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-20', 20, 'Conferences / events - standard rate (FR)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-20', 20, 'Entertainment - standard rate (FR)');
    end;

    local procedure CreateVATRatesDE()
    begin
        // ── Germany (DE) ──────────────────────────────────────────────────────────────
        // Standard 19 %, reduced 7 % (food, accommodation since 2020, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-07', 7, 'Hotel room - accommodation rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-07', 7, 'Hotel deposit - accommodation rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-07', 7, 'Hotel breakfast - food rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-07', 7, 'Hotel room service - food rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-07', 7, 'Hotel transport - reduced rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-19', 19, 'Hotel fees - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-19', 19, 'Hotel phone - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-19', 19, 'Hotel internet - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-19', 19, 'Hotel incidents - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-19', 19, 'Hotel laundry - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-19', 19, 'Hotel parking - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-19', 19, 'Hotel other - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (DE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (DE)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), CreateExpenseCategories.GetFOODTxt(), 'VAT-RED-07', 7, 'Food - reduced rate (DE)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), CreateExpenseCategories.GetALCOHOLTxt(), 'VAT-STD-19', 19, 'Alcohol / drinks - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (DE)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-07', 7, 'Ground transport - reduced rate (DE)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-19', 19, 'Car rental - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-19', 19, 'Fuel / car expenses - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-19', 19, 'Conferences / events - standard rate (DE)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-19', 19, 'Entertainment - standard rate (DE)');
    end;

    local procedure CreateVATRatesHU()
    begin
        // ── Hungary (HU) ──────────────────────────────────────────────────────────────
        // Standard 27 %, reduced 18 % (accommodation, food), 5 % (certain goods)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-18', 18, 'Hotel room - accommodation rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-18', 18, 'Hotel deposit - accommodation rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-18', 18, 'Hotel breakfast - food rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-18', 18, 'Hotel room service - food rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-27', 27, 'Hotel transport - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-27', 27, 'Hotel fees - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-27', 27, 'Hotel phone - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-27', 27, 'Hotel internet - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-27', 27, 'Hotel incidents - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-27', 27, 'Hotel laundry - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-27', 27, 'Hotel parking - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-27', 27, 'Hotel other - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (HU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (HU)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-18', 18, 'Restaurant / meals - reduced rate (HU)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (HU)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-27', 27, 'Ground transport - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-27', 27, 'Car rental - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-27', 27, 'Fuel / car expenses - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-27', 27, 'Conferences / events - standard rate (HU)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-27', 27, 'Entertainment - standard rate (HU)');
    end;

    local procedure CreateVATRatesIE()
    begin
        // ── Ireland (IE) ──────────────────────────────────────────────────────────────
        // Standard 23 %, reduced 13.5 % (accommodation), 9 % (restaurants/tourism)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-135', 13.5, 'Hotel room - accommodation rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-135', 13.5, 'Hotel deposit - accommodation rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-09', 9, 'Hotel breakfast - restaurant rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-09', 9, 'Hotel room service - restaurant rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-09', 9, 'Hotel transport - reduced rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-23', 23, 'Hotel fees - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-23', 23, 'Hotel phone - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-23', 23, 'Hotel internet - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-23', 23, 'Hotel incidents - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-23', 23, 'Hotel laundry - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-23', 23, 'Hotel parking - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-23', 23, 'Hotel other - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (IE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (IE)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-09', 9, 'Restaurant / meals - reduced rate (IE)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (IE)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-09', 9, 'Ground transport - reduced rate (IE)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-23', 23, 'Car rental - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-23', 23, 'Fuel / car expenses - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-23', 23, 'Conferences / events - standard rate (IE)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-23', 23, 'Entertainment - standard rate (IE)');
    end;

    local procedure CreateVATRatesIT()
    begin
        // ── Italy (IT) ────────────────────────────────────────────────────────────────
        // Standard 22 %, reduced 10 % (accommodation, restaurants), 5 %, 4 %
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-10', 10, 'Hotel room - accommodation rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-10', 10, 'Hotel deposit - accommodation rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-10', 10, 'Hotel breakfast - food rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-10', 10, 'Hotel room service - food rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-10', 10, 'Hotel transport - reduced rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-22', 22, 'Hotel fees - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-22', 22, 'Hotel phone - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-22', 22, 'Hotel internet - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-22', 22, 'Hotel incidents - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-22', 22, 'Hotel laundry - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-22', 22, 'Hotel parking - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-22', 22, 'Hotel other - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (IT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (IT)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-10', 10, 'Restaurant / meals - reduced rate (IT)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (IT)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-10', 10, 'Ground transport - reduced rate (IT)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-22', 22, 'Car rental - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-22', 22, 'Fuel / car expenses - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-22', 22, 'Conferences / events - standard rate (IT)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-22', 22, 'Entertainment - standard rate (IT)');
    end;

    local procedure CreateVATRatesLU()
    begin
        // ── Luxembourg (LU) ───────────────────────────────────────────────────────────
        // Standard 17 %, reduced 14 % (some services), 8 %, 3 %
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-08', 8, 'Hotel room - accommodation rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-08', 8, 'Hotel deposit - accommodation rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-08', 8, 'Hotel breakfast - food rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-08', 8, 'Hotel room service - food rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-08', 8, 'Hotel transport - reduced rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-17', 17, 'Hotel fees - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-17', 17, 'Hotel phone - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-17', 17, 'Hotel internet - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-17', 17, 'Hotel incidents - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-17', 17, 'Hotel laundry - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-17', 17, 'Hotel parking - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-17', 17, 'Hotel other - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (LU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (LU)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-08', 8, 'Restaurant / meals - reduced rate (LU)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (LU)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-08', 8, 'Ground transport - reduced rate (LU)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-17', 17, 'Car rental - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-17', 17, 'Fuel / car expenses - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-17', 17, 'Conferences / events - standard rate (LU)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-17', 17, 'Entertainment - standard rate (LU)');
    end;

    local procedure CreateVATRatesNL()
    begin
        // ── Netherlands (NL) ──────────────────────────────────────────────────────────
        // Standard 21 %, reduced 9 % (food, accommodation, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-09', 9, 'Hotel room - accommodation rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-09', 9, 'Hotel deposit - accommodation rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-09', 9, 'Hotel breakfast - food rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-09', 9, 'Hotel room service - food rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-09', 9, 'Hotel transport - reduced rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-21', 21, 'Hotel fees - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-21', 21, 'Hotel phone - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-21', 21, 'Hotel internet - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-21', 21, 'Hotel incidents - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-21', 21, 'Hotel laundry - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-21', 21, 'Hotel parking - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-21', 21, 'Hotel other - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (NL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (NL)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-09', 9, 'Restaurant / meals - reduced rate (NL)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (NL)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-09', 9, 'Ground transport - reduced rate (NL)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-21', 21, 'Car rental - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-21', 21, 'Fuel / car expenses - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-21', 21, 'Conferences / events - standard rate (NL)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-21', 21, 'Entertainment - standard rate (NL)');
    end;

    local procedure CreateVATRatesPL()
    begin
        // ── Poland (PL) ───────────────────────────────────────────────────────────────
        // Standard 23 %, reduced 8 % (accommodation, restaurants), 5 % (food)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-08', 8, 'Hotel room - accommodation rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-08', 8, 'Hotel deposit - accommodation rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-08', 8, 'Hotel breakfast - food rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-08', 8, 'Hotel room service - food rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-08', 8, 'Hotel transport - reduced rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-23', 23, 'Hotel fees - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-23', 23, 'Hotel phone - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-23', 23, 'Hotel internet - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-23', 23, 'Hotel incidents - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-23', 23, 'Hotel laundry - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-23', 23, 'Hotel parking - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-23', 23, 'Hotel other - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (PL)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (PL)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-08', 8, 'Restaurant / meals - reduced rate (PL)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (PL)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-08', 8, 'Ground transport - reduced rate (PL)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-23', 23, 'Car rental - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-23', 23, 'Fuel / car expenses - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-23', 23, 'Conferences / events - standard rate (PL)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-23', 23, 'Entertainment - standard rate (PL)');
    end;

    local procedure CreateVATRatesPT()
    begin
        // ── Portugal (PT) ─────────────────────────────────────────────────────────────
        // Standard 23 %, reduced 13 % (accommodation), 6 % (food)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-13', 13, 'Hotel room - accommodation rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-13', 13, 'Hotel deposit - accommodation rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-13', 13, 'Hotel breakfast - food rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-13', 13, 'Hotel room service - food rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-06', 6, 'Hotel transport - reduced rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-23', 23, 'Hotel fees - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-23', 23, 'Hotel phone - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-23', 23, 'Hotel internet - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-23', 23, 'Hotel incidents - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-23', 23, 'Hotel laundry - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-23', 23, 'Hotel parking - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-23', 23, 'Hotel other - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (PT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (PT)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-13', 13, 'Restaurant / meals - reduced rate (PT)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (PT)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-06', 6, 'Ground transport - reduced rate (PT)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-23', 23, 'Car rental - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-23', 23, 'Fuel / car expenses - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-23', 23, 'Conferences / events - standard rate (PT)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-23', 23, 'Entertainment - standard rate (PT)');
    end;

    local procedure CreateVATRatesES()
    begin
        // ── Spain (ES) ────────────────────────────────────────────────────────────────
        // Standard 21 %, reduced 10 % (accommodation, restaurants, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-10', 10, 'Hotel room - accommodation rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-10', 10, 'Hotel deposit - accommodation rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-10', 10, 'Hotel breakfast - food rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-10', 10, 'Hotel room service - food rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-10', 10, 'Hotel transport - reduced rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-21', 21, 'Hotel fees - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-21', 21, 'Hotel phone - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-21', 21, 'Hotel internet - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-21', 21, 'Hotel incidents - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-21', 21, 'Hotel laundry - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-21', 21, 'Hotel parking - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-21', 21, 'Hotel other - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (ES)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (ES)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-10', 10, 'Restaurant / meals - reduced rate (ES)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (ES)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-10', 10, 'Ground transport - reduced rate (ES)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-21', 21, 'Car rental - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-21', 21, 'Fuel / car expenses - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-21', 21, 'Conferences / events - standard rate (ES)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-21', 21, 'Entertainment - standard rate (ES)');
    end;

    local procedure CreateVATRatesSE()
    begin
        // ── Sweden (SE) ───────────────────────────────────────────────────────────────
        // Standard 25 %, reduced 12 % (accommodation, food), 6 % (transport, culture)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-12', 12, 'Hotel room - accommodation rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-12', 12, 'Hotel deposit - accommodation rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-12', 12, 'Hotel breakfast - food rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-12', 12, 'Hotel room service - food rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-06', 6, 'Hotel transport - reduced rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-25', 25, 'Hotel fees - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-25', 25, 'Hotel phone - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-25', 25, 'Hotel internet - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-25', 25, 'Hotel incidents - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-25', 25, 'Hotel laundry - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-25', 25, 'Hotel parking - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-25', 25, 'Hotel other - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (SE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (SE)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-12', 12, 'Restaurant / meals - reduced rate (SE)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (SE)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-06', 6, 'Ground transport - reduced rate (SE)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-25', 25, 'Car rental - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-25', 25, 'Fuel / car expenses - standard rate (SE)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-RED-06', 6, 'Conferences / events - reduced rate (SE)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-25', 25, 'Entertainment - standard rate (SE)');
    end;

    local procedure CreateVATRatesCH()
    begin
        // ── Switzerland (CH) ──────────────────────────────────────────────────────────
        // Standard 8.1 %, special accommodation rate 3.8 %, reduced 2.6 % (food, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-38', 3.8, 'Hotel room - accommodation rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-38', 3.8, 'Hotel deposit - accommodation rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-26', 2.6, 'Hotel breakfast - food rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-26', 2.6, 'Hotel room service - food rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-26', 2.6, 'Hotel transport - reduced rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-81', 8.1, 'Hotel fees - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-81', 8.1, 'Hotel phone - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-81', 8.1, 'Hotel internet - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-81', 8.1, 'Hotel incidents - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-81', 8.1, 'Hotel laundry - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-81', 8.1, 'Hotel parking - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-81', 8.1, 'Hotel other - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (CH)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (CH)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-STD-81', 8.1, 'Restaurant / meals - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (CH)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-26', 2.6, 'Ground transport - reduced rate (CH)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-81', 8.1, 'Car rental - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-81', 8.1, 'Fuel / car expenses - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-81', 8.1, 'Conferences / events - standard rate (CH)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-81', 8.1, 'Entertainment - standard rate (CH)');
    end;

    local procedure CreateVATRatesGB()
    begin
        // ── United Kingdom (GB) ───────────────────────────────────────────────────────
        // Standard 20 %, zero rate (public transport, international flights)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-STD-20', 20, 'Hotel room - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-STD-20', 20, 'Hotel deposit - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-STD-20', 20, 'Hotel breakfast - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-STD-20', 20, 'Hotel room service - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-20', 20, 'Hotel transport - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-20', 20, 'Hotel fees - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-20', 20, 'Hotel phone - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-20', 20, 'Hotel internet - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-20', 20, 'Hotel incidents - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-20', 20, 'Hotel laundry - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-20', 20, 'Hotel parking - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-20', 20, 'Hotel other - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (GB)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (GB)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-STD-20', 20, 'Restaurant / meals - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - zero-rated (GB)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-ZERO', 0, 'Ground transport - zero-rated public transport (GB)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-20', 20, 'Car rental - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-20', 20, 'Fuel / car expenses - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-20', 20, 'Conferences / events - standard rate (GB)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-20', 20, 'Entertainment - standard rate (GB)');
    end;

    local procedure CreateVATRatesNO()
    begin
        // ── Norway (NO) ───────────────────────────────────────────────────────────────
        // Standard 25 %, reduced 15 % (food), low 12 % (accommodation, transport, culture)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-12', 12, 'Hotel room - accommodation rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-12', 12, 'Hotel deposit - accommodation rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-15', 15, 'Hotel breakfast - food rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-15', 15, 'Hotel room service - food rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-12', 12, 'Hotel transport - reduced rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-25', 25, 'Hotel fees - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-25', 25, 'Hotel phone - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-25', 25, 'Hotel internet - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-25', 25, 'Hotel incidents - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-25', 25, 'Hotel laundry - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-25', 25, 'Hotel parking - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-25', 25, 'Hotel other - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (NO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (NO)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-15', 15, 'Restaurant / meals - food rate (NO)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (NO)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-12', 12, 'Ground transport - reduced rate (NO)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-25', 25, 'Car rental - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-25', 25, 'Fuel / car expenses - standard rate (NO)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-RED-12', 12, 'Conferences / events - reduced rate (NO)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-25', 25, 'Entertainment - standard rate (NO)');
    end;

    local procedure CreateVATRatesBG()
    begin
        // ── Bulgaria (BG) ─────────────────────────────────────────────────────────────
        // Standard 20 %, reduced 9 % (accommodation, restaurants, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-09', 9, 'Hotel room - accommodation rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-09', 9, 'Hotel deposit - accommodation rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-09', 9, 'Hotel breakfast - food rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-09', 9, 'Hotel room service - food rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-09', 9, 'Hotel transport - reduced rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-20', 20, 'Hotel fees - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-20', 20, 'Hotel phone - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-20', 20, 'Hotel internet - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-20', 20, 'Hotel incidents - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-20', 20, 'Hotel laundry - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-20', 20, 'Hotel parking - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-20', 20, 'Hotel other - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (BG)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (BG)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-09', 9, 'Restaurant / meals - reduced rate (BG)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (BG)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-09', 9, 'Ground transport - reduced rate (BG)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-20', 20, 'Car rental - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-20', 20, 'Fuel / car expenses - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-20', 20, 'Conferences / events - standard rate (BG)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-20', 20, 'Entertainment - standard rate (BG)');
    end;

    local procedure CreateVATRatesCY()
    begin
        // ── Cyprus (CY) ──────────────────────────────────────────────────────────────
        // Standard 19 %, reduced 9 % (accommodation, restaurants, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-09', 9, 'Hotel room - accommodation rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-09', 9, 'Hotel deposit - accommodation rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-09', 9, 'Hotel breakfast - food rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-09', 9, 'Hotel room service - food rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-09', 9, 'Hotel transport - reduced rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-19', 19, 'Hotel fees - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-19', 19, 'Hotel phone - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-19', 19, 'Hotel internet - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-19', 19, 'Hotel incidents - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-19', 19, 'Hotel laundry - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-19', 19, 'Hotel parking - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-19', 19, 'Hotel other - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (CY)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (CY)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-09', 9, 'Restaurant / meals - reduced rate (CY)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (CY)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-09', 9, 'Ground transport - reduced rate (CY)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-19', 19, 'Car rental - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-19', 19, 'Fuel / car expenses - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-19', 19, 'Conferences / events - standard rate (CY)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-19', 19, 'Entertainment - standard rate (CY)');
    end;

    local procedure CreateVATRatesCZ()
    begin
        // ── Czech Republic (CZ) ────────────────────────────────────────────────────
        // Standard 21 %, reduced 12 % (accommodation, food, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-12', 12, 'Hotel room - accommodation rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-12', 12, 'Hotel deposit - accommodation rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-12', 12, 'Hotel breakfast - food rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-12', 12, 'Hotel room service - food rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-12', 12, 'Hotel transport - reduced rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-21', 21, 'Hotel fees - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-21', 21, 'Hotel phone - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-21', 21, 'Hotel internet - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-21', 21, 'Hotel incidents - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-21', 21, 'Hotel laundry - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-21', 21, 'Hotel parking - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-21', 21, 'Hotel other - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (CZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (CZ)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-12', 12, 'Restaurant / meals - reduced rate (CZ)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (CZ)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-12', 12, 'Ground transport - reduced rate (CZ)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-21', 21, 'Car rental - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-21', 21, 'Fuel / car expenses - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-21', 21, 'Conferences / events - standard rate (CZ)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-21', 21, 'Entertainment - standard rate (CZ)');
    end;

    local procedure CreateVATRatesEE()
    begin
        // ── Estonia (EE) ──────────────────────────────────────────────────────────────
        // Standard 22 %, reduced 9 % (accommodation, books, medicines)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-09', 9, 'Hotel room - accommodation rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-09', 9, 'Hotel deposit - accommodation rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-STD-22', 22, 'Hotel breakfast - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-STD-22', 22, 'Hotel room service - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-22', 22, 'Hotel transport - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-22', 22, 'Hotel fees - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-22', 22, 'Hotel phone - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-22', 22, 'Hotel internet - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-22', 22, 'Hotel incidents - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-22', 22, 'Hotel laundry - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-22', 22, 'Hotel parking - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-22', 22, 'Hotel other - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (EE)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (EE)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-STD-22', 22, 'Restaurant / meals - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (EE)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-22', 22, 'Ground transport - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-22', 22, 'Car rental - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-22', 22, 'Fuel / car expenses - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-22', 22, 'Conferences / events - standard rate (EE)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-22', 22, 'Entertainment - standard rate (EE)');
    end;

    local procedure CreateVATRatesGR()
    begin
        // ── Greece (GR) ──────────────────────────────────────────────────────────────
        // Standard 24 %, reduced 13 % (food, accommodation, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-13', 13, 'Hotel room - accommodation rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-13', 13, 'Hotel deposit - accommodation rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-13', 13, 'Hotel breakfast - food rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-13', 13, 'Hotel room service - food rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-13', 13, 'Hotel transport - reduced rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-24', 24, 'Hotel fees - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-24', 24, 'Hotel phone - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-24', 24, 'Hotel internet - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-24', 24, 'Hotel incidents - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-24', 24, 'Hotel laundry - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-24', 24, 'Hotel parking - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-24', 24, 'Hotel other - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (GR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (GR)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-13', 13, 'Restaurant / meals - reduced rate (GR)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (GR)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-13', 13, 'Ground transport - reduced rate (GR)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-24', 24, 'Car rental - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-24', 24, 'Fuel / car expenses - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-24', 24, 'Conferences / events - standard rate (GR)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-24', 24, 'Entertainment - standard rate (GR)');
    end;

    local procedure CreateVATRatesHR()
    begin
        // ── Croatia (HR) ──────────────────────────────────────────────────────────────
        // Standard 25 %, reduced 13 % (accommodation, food/restaurants), 5 % (basic foodstuffs)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-13', 13, 'Hotel room - accommodation rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-13', 13, 'Hotel deposit - accommodation rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-13', 13, 'Hotel breakfast - food rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-13', 13, 'Hotel room service - food rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-25', 25, 'Hotel transport - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-25', 25, 'Hotel fees - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-25', 25, 'Hotel phone - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-25', 25, 'Hotel internet - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-25', 25, 'Hotel incidents - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-25', 25, 'Hotel laundry - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-25', 25, 'Hotel parking - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-25', 25, 'Hotel other - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (HR)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (HR)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-13', 13, 'Restaurant / meals - reduced rate (HR)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (HR)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-25', 25, 'Ground transport - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-25', 25, 'Car rental - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-25', 25, 'Fuel / car expenses - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-25', 25, 'Conferences / events - standard rate (HR)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-25', 25, 'Entertainment - standard rate (HR)');
    end;

    local procedure CreateVATRatesLT()
    begin
        // ── Lithuania (LT) ────────────────────────────────────────────────────────────
        // Standard 21 %, reduced 9 % (accommodation, some food services)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-09', 9, 'Hotel room - accommodation rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-09', 9, 'Hotel deposit - accommodation rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-09', 9, 'Hotel breakfast - food rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-09', 9, 'Hotel room service - food rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-21', 21, 'Hotel transport - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-21', 21, 'Hotel fees - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-21', 21, 'Hotel phone - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-21', 21, 'Hotel internet - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-21', 21, 'Hotel incidents - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-21', 21, 'Hotel laundry - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-21', 21, 'Hotel parking - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-21', 21, 'Hotel other - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (LT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (LT)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-09', 9, 'Restaurant / meals - reduced rate (LT)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (LT)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-21', 21, 'Ground transport - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-21', 21, 'Car rental - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-21', 21, 'Fuel / car expenses - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-21', 21, 'Conferences / events - standard rate (LT)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-21', 21, 'Entertainment - standard rate (LT)');
    end;

    local procedure CreateVATRatesLV()
    begin
        // ── Latvia (LV) ──────────────────────────────────────────────────────────────
        // Standard 21 %, reduced 12 % (accommodation)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-12', 12, 'Hotel room - accommodation rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-12', 12, 'Hotel deposit - accommodation rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-STD-21', 21, 'Hotel breakfast - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-STD-21', 21, 'Hotel room service - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-21', 21, 'Hotel transport - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-21', 21, 'Hotel fees - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-21', 21, 'Hotel phone - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-21', 21, 'Hotel internet - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-21', 21, 'Hotel incidents - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-21', 21, 'Hotel laundry - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-21', 21, 'Hotel parking - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-21', 21, 'Hotel other - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (LV)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (LV)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-STD-21', 21, 'Restaurant / meals - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (LV)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-21', 21, 'Ground transport - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-21', 21, 'Car rental - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-21', 21, 'Fuel / car expenses - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-21', 21, 'Conferences / events - standard rate (LV)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-21', 21, 'Entertainment - standard rate (LV)');
    end;

    local procedure CreateVATRatesMT()
    begin
        // ── Malta (MT) ──────────────────────────────────────────────────────────────
        // Standard 18 %, reduced 7 % (accommodation), 5 % (food, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-07', 7, 'Hotel room - accommodation rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-07', 7, 'Hotel deposit - accommodation rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-05', 5, 'Hotel breakfast - food rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-05', 5, 'Hotel room service - food rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-05', 5, 'Hotel transport - reduced rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-18', 18, 'Hotel fees - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-18', 18, 'Hotel phone - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-18', 18, 'Hotel internet - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-18', 18, 'Hotel incidents - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-18', 18, 'Hotel laundry - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-18', 18, 'Hotel parking - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-18', 18, 'Hotel other - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (MT)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (MT)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-05', 5, 'Restaurant / meals - reduced rate (MT)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (MT)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-05', 5, 'Ground transport - reduced rate (MT)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-18', 18, 'Car rental - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-18', 18, 'Fuel / car expenses - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-18', 18, 'Conferences / events - standard rate (MT)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-18', 18, 'Entertainment - standard rate (MT)');
    end;

    local procedure CreateVATRatesRO()
    begin
        // ── Romania (RO) ──────────────────────────────────────────────────────────────
        // Standard 19 %, reduced 9 % (accommodation, food/restaurants), 5 % (some categories)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-09', 9, 'Hotel room - accommodation rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-09', 9, 'Hotel deposit - accommodation rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-09', 9, 'Hotel breakfast - food rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-09', 9, 'Hotel room service - food rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-19', 19, 'Hotel transport - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-19', 19, 'Hotel fees - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-19', 19, 'Hotel phone - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-19', 19, 'Hotel internet - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-19', 19, 'Hotel incidents - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-19', 19, 'Hotel laundry - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-19', 19, 'Hotel parking - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-19', 19, 'Hotel other - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (RO)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (RO)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-09', 9, 'Restaurant / meals - reduced rate (RO)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (RO)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-19', 19, 'Ground transport - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-19', 19, 'Car rental - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-19', 19, 'Fuel / car expenses - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-19', 19, 'Conferences / events - standard rate (RO)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-19', 19, 'Entertainment - standard rate (RO)');
    end;

    local procedure CreateVATRatesSI()
    begin
        // ── Slovenia (SI) ─────────────────────────────────────────────────────────────
        // Standard 22 %, reduced 9.5 % (accommodation, food, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-95', 9.5, 'Hotel room - accommodation rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-95', 9.5, 'Hotel deposit - accommodation rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-95', 9.5, 'Hotel breakfast - food rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-95', 9.5, 'Hotel room service - food rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-95', 9.5, 'Hotel transport - reduced rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-22', 22, 'Hotel fees - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-22', 22, 'Hotel phone - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-22', 22, 'Hotel internet - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-22', 22, 'Hotel incidents - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-22', 22, 'Hotel laundry - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-22', 22, 'Hotel parking - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-22', 22, 'Hotel other - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (SI)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (SI)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-95', 9.5, 'Restaurant / meals - reduced rate (SI)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (SI)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-95', 9.5, 'Ground transport - reduced rate (SI)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-22', 22, 'Car rental - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-22', 22, 'Fuel / car expenses - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-22', 22, 'Conferences / events - standard rate (SI)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-22', 22, 'Entertainment - standard rate (SI)');
    end;

    local procedure CreateVATRatesSK()
    begin
        // ── Slovakia (SK) ─────────────────────────────────────────────────────────────
        // Standard 23 %, reduced 10 % (food, accommodation, transport)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-10', 10, 'Hotel room - accommodation rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-10', 10, 'Hotel deposit - accommodation rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-10', 10, 'Hotel breakfast - food rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-10', 10, 'Hotel room service - food rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-10', 10, 'Hotel transport - reduced rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-23', 23, 'Hotel fees - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-23', 23, 'Hotel phone - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-23', 23, 'Hotel internet - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-23', 23, 'Hotel incidents - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-23', 23, 'Hotel laundry - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-23', 23, 'Hotel parking - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-23', 23, 'Hotel other - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (SK)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (SK)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-10', 10, 'Restaurant / meals - reduced rate (SK)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (SK)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-10', 10, 'Ground transport - reduced rate (SK)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-23', 23, 'Car rental - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-23', 23, 'Fuel / car expenses - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-23', 23, 'Conferences / events - standard rate (SK)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-23', 23, 'Entertainment - standard rate (SK)');
    end;

    local procedure CreateVATRatesAU()
    begin
        // ── Australia (AU) ──────────────────────────────────────────────────────────
        // GST flat 10 % on all taxable supplies; international flights GST-free
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'GST-10', 10, 'Hotel room - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'GST-10', 10, 'Hotel deposit - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'GST-10', 10, 'Hotel breakfast - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'GST-10', 10, 'Hotel room service - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'GST-10', 10, 'Hotel transport - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'GST-10', 10, 'Hotel fees - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'GST-10', 10, 'Hotel phone - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'GST-10', 10, 'Hotel internet - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'GST-10', 10, 'Hotel incidents - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'GST-10', 10, 'Hotel laundry - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'GST-10', 10, 'Hotel parking - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'GST-10', 10, 'Hotel other - GST (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (AU)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (AU)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'GST-10', 10, 'Restaurant / meals - GST (AU)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'International flights - GST-free (AU)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'GST-10', 10, 'Ground transport - GST (AU)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'GST-10', 10, 'Car rental - GST (AU)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'GST-10', 10, 'Fuel / car expenses - GST (AU)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'GST-10', 10, 'Conferences / events - GST (AU)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'GST-10', 10, 'Entertainment - GST (AU)');
    end;

    local procedure CreateVATRatesNZ()
    begin
        // ── New Zealand (NZ) ───────────────────────────────────────────────────────
        // GST flat 15 % on all taxable supplies; international flights zero-rated
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'GST-15', 15, 'Hotel room - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'GST-15', 15, 'Hotel deposit - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'GST-15', 15, 'Hotel breakfast - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'GST-15', 15, 'Hotel room service - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'GST-15', 15, 'Hotel transport - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'GST-15', 15, 'Hotel fees - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'GST-15', 15, 'Hotel phone - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'GST-15', 15, 'Hotel internet - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'GST-15', 15, 'Hotel incidents - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'GST-15', 15, 'Hotel laundry - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'GST-15', 15, 'Hotel parking - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'GST-15', 15, 'Hotel other - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (NZ)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (NZ)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'GST-15', 15, 'Restaurant / meals - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'International flights - zero-rated (NZ)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'GST-15', 15, 'Ground transport - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'GST-15', 15, 'Car rental - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'GST-15', 15, 'Fuel / car expenses - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'GST-15', 15, 'Conferences / events - GST (NZ)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'GST-15', 15, 'Entertainment - GST (NZ)');
    end;

    local procedure CreateVATRatesMX()
    begin
        // ── Mexico (MX) ─────────────────────────────────────────────────────────────
        // IVA standard 16 %; international flights and basic food 0 %
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'IVA-STD-16', 16, 'Hotel room - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'IVA-STD-16', 16, 'Hotel deposit - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'IVA-STD-16', 16, 'Hotel breakfast - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'IVA-STD-16', 16, 'Hotel room service - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'IVA-STD-16', 16, 'Hotel transport - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'IVA-STD-16', 16, 'Hotel fees - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'IVA-STD-16', 16, 'Hotel phone - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'IVA-STD-16', 16, 'Hotel internet - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'IVA-STD-16', 16, 'Hotel incidents - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'IVA-STD-16', 16, 'Hotel laundry - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'IVA-STD-16', 16, 'Hotel parking - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'IVA-STD-16', 16, 'Hotel other - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (MX)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (MX)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'IVA-STD-16', 16, 'Restaurant / meals - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'International flights - zero-rated (MX)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'IVA-STD-16', 16, 'Ground transport - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'IVA-STD-16', 16, 'Car rental - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'IVA-STD-16', 16, 'Fuel / car expenses - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'IVA-STD-16', 16, 'Conferences / events - IVA standard rate (MX)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'IVA-STD-16', 16, 'Entertainment - IVA standard rate (MX)');
    end;

    local procedure CreateVATRatesIS()
    begin
        // ── Iceland (IS) ──────────────────────────────────────────────────────────────
        // Standard 24 %, reduced 11 % (accommodation, food, transport, culture)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-RED-11', 11, 'Hotel room - accommodation rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-RED-11', 11, 'Hotel deposit - accommodation rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-RED-11', 11, 'Hotel breakfast - food rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-RED-11', 11, 'Hotel room service - food rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-RED-11', 11, 'Hotel transport - reduced rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-24', 24, 'Hotel fees - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-24', 24, 'Hotel phone - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-24', 24, 'Hotel internet - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-24', 24, 'Hotel incidents - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-24', 24, 'Hotel laundry - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-24', 24, 'Hotel parking - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-24', 24, 'Hotel other - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (IS)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (IS)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-RED-11', 11, 'Restaurant / meals - reduced rate (IS)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (IS)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-RED-11', 11, 'Ground transport - reduced rate (IS)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-24', 24, 'Car rental - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-24', 24, 'Fuel / car expenses - standard rate (IS)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-RED-11', 11, 'Conferences / events - reduced rate (IS)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-24', 24, 'Entertainment - standard rate (IS)');
    end;

    local procedure CreateVATRatesUA()
    begin
        // -- Ukraine (UA) --------------------------------------------------------------
        // Standard 20 %, reduced 14 % (certain food), 7 % (medicines/medical); 0 % (exports/flights)
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMTxt(), 'VAT-STD-20', 20, 'Hotel room - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetDEPOSITTxt(), 'VAT-STD-20', 20, 'Hotel deposit - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetBREAKFASTTxt(), 'VAT-STD-20', 20, 'Hotel breakfast - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetROOMSERVICETxt(), 'VAT-STD-20', 20, 'Hotel room service - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTRANSPORTTxt(), 'VAT-STD-20', 20, 'Hotel transport - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetFEETxt(), 'VAT-STD-20', 20, 'Hotel fees - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPHONETxt(), 'VAT-STD-20', 20, 'Hotel phone - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINTERNETTxt(), 'VAT-STD-20', 20, 'Hotel internet - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetINCIDENTSTxt(), 'VAT-STD-20', 20, 'Hotel incidents - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetLAUNDRYTxt(), 'VAT-STD-20', 20, 'Hotel laundry - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetPARKINGTxt(), 'VAT-STD-20', 20, 'Hotel parking - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetOTHERTxt(), 'VAT-STD-20', 20, 'Hotel other - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTAXTxt(), 'VAT-ZERO', 0, 'City/tourist tax - levy, zero rate (UA)');
        InsertRate(CreateExpenseCategories.GetHOTELSTxt(), CreateExpenseCategories.GetTIPSTxt(), 'VAT-ZERO', 0, 'Hotel tips - zero rate (UA)');
        InsertRate(CreateExpenseCategories.GetMEALSTxt(), '', 'VAT-STD-20', 20, 'Restaurant / meals - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetAIRLINETxt(), '', 'VAT-ZERO', 0, 'Flights - exempt/zero rate (UA)');
        InsertRate(CreateExpenseCategories.GetGROUNDTRANSTxt(), '', 'VAT-STD-20', 20, 'Ground transport - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetRENTALCARSTxt(), '', 'VAT-STD-20', 20, 'Car rental - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetCARTxt(), '', 'VAT-STD-20', 20, 'Fuel / car expenses - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetEVENTSTxt(), '', 'VAT-STD-20', 20, 'Conferences / events - standard rate (UA)');
        InsertRate(CreateExpenseCategories.GetENTERTAINTxt(), '', 'VAT-STD-20', 20, 'Entertainment - standard rate (UA)');
    end;
}
