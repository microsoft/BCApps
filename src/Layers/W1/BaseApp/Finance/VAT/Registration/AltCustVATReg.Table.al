// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Foundation.Address;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Customer;
using System.Telemetry;

table 213 "Alt. Cust. VAT Reg."
{
    Caption = 'Alternative Customer VAT Registration';
    LookupPageId = "Alt. Cust. VAT Reg.";
    DrillDownPageId = "Alt. Cust. VAT Reg.";

    fields
    {
        field(1; ID; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Customer;
            NotBlank = true;
            ToolTip = 'Specifies the customer number.';
        }
        field(3; "VAT Country/Region Code"; Code[10])
        {
            DataClassification = CustomerContent;
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country or region code for the VAT';
            NotBlank = true;

            trigger OnLookup()
            var
                Customer: Record Customer;
                CountryRegion: Record "Country/Region";
                CountriesRegionsPage: Page "Countries/Regions";
            begin
                if "Customer No." <> '' then begin
                    Customer.Get("Customer No.");
                    if Customer."Country/Region Code" <> '' then
                        CountryRegion.SetFilter(Code, '<>%1', Customer."Country/Region Code");
                end;
                CountriesRegionsPage.SetTableView(CountryRegion);
                CountriesRegionsPage.LookupMode(true);
                if CountriesRegionsPage.RunModal() = Action::LookupOK then begin
                    CountriesRegionsPage.GetRecord(CountryRegion);
                    Validate("VAT Country/Region Code", CountryRegion.Code);
                end;
            end;

            trigger OnValidate()
            begin
                if "VAT Country/Region Code" <> xRec."VAT Country/Region Code" then
                    VATRegistrationValidation();
            end;
        }
        field(4; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the VAT registration number.';

            trigger OnValidate()
            begin
                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." <> xRec."VAT Registration No." then
                    VATRegistrationValidation();
            end;
        }
        field(5; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Business Posting Group";
            ToolTip = 'Specifies the customer''s trade type to link transactions made for this customer with the appropriate general ledger account according to the general posting setup.';

            trigger OnValidate()
            var
                GenBusPostingGrp: Record "Gen. Business Posting Group";
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(6; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            DataClassification = CustomerContent;
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the customer''s VAT specification to link transactions made for this customer to.';
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
        key(CustomerVATCountryKey; "Customer No.", "VAT Country/Region Code")
        {
        }
    }

    var
        AltCustVATRegFacade: Codeunit "Alt. Cust. VAT. Reg. Facade";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureNameTxt: Label 'Alternative Customer VAT Registration', Locked = true;

    trigger OnInsert()
    begin
        AltCustVATRegFacade.CheckAltCustVATRegConsistent(Rec);
        FeatureTelemetry.LogUptake('0000NFH', FeatureNameTxt, Enum::"Feature Uptake Status"::"Set up");
    end;

    trigger OnModify()
    begin
        AltCustVATRegFacade.CheckAltCustVATRegConsistent(Rec);
    end;

    procedure VATRegistrationValidation()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        Customer: Record Customer;
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ResultRecordRef: RecordRef;
        ApplicableCountryCode: Code[10];
        IsHandled: Boolean;
        LogNotVerified: Boolean;
    begin
        IsHandled := false;
        OnBeforeVATRegistrationValidation(Rec, IsHandled);
        if IsHandled then
            exit;

        if not VATRegistrationNoFormat.Test("VAT Registration No.", "VAT Country/Region Code", "Customer No.", DATABASE::Customer) then
            exit;

        LogNotVerified := true;
        if ("VAT Country/Region Code" <> '') or (VATRegistrationNoFormat."Country/Region Code" <> '') then begin
            ApplicableCountryCode := "VAT Country/Region Code";
            if ApplicableCountryCode = '' then
                ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";
            if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
                LogNotVerified := false;
                VATRegistrationLogMgt.ValidateVATRegNoWithVIES(
                    ResultRecordRef, Rec, "Customer No.", VATRegistrationLog."Account Type"::Customer.AsInteger(), ApplicableCountryCode);
                ResultRecordRef.SetTable(Rec);
            end;
        end;

        if LogNotVerified then begin
            Customer.Get(Rec."Customer No.");
            VATRegistrationLogMgt.LogCustomer(Customer);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATRegistrationValidation(var AltCustVATReg: Record "Alt. Cust. VAT Reg."; var IsHandled: Boolean)
    begin
    end;
}