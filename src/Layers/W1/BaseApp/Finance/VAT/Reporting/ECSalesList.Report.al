// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

report 130 "EC Sales List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/ECSalesList.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'EC Sales List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = sorting("EU Country/Region Code") where("EU Country/Region Code" = filter(<> ''));
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(CompanyAddr7; CompanyAddr[7])
            {
            }
            column(CompanyAddr8; CompanyAddr[8])
            {
            }
            column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfoHomePage; CompanyInfo."Home Page")
            {
            }
            column(CompanyInfoEMail; CompanyInfo."E-Mail")
            {
            }
            column(CompanyInfoVATRegistrationNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(PageCaption; StrSubstNo(Text001, ''))
            {
            }
            column(GLSetupLCYCode; StrSubstNo(Text000, GLSetup."LCY Code"))
            {
            }
            column(VATEntryTableCaptionFilter; "VAT Entry".TableCaption + ': ' + VATEntryFilter)
            {
            }
            column(VATEntryFilter; VATEntryFilter)
            {
            }
            column(ThirdPartyTrade; ThirdPartyTrade)
            {
            }
            column(NotEUTrdPartyAmtTotal; FormatNotEUTrdPartyAmt)
            {
            }
            column(NotEUTrdPartyAmtServiceTotal; FormatNotEUTrdPartyAmtService)
            {
            }
            column(FORMATTRUE; Format(true))
            {
            }
            column(EUTrdPartyAmtTotal; FormatEUTrdPartyAmt)
            {
            }
            column(EUTrdPartyAmtServiceTotal; FormatEUTrdPartyAmtService)
            {
            }
            column(ECSalesListCaption; ECSalesListCaptionLbl)
            {
            }
            column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyInfoHomePageCaption; CompanyInfoHomePageCaptionLbl)
            {
            }
            column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
            {
            }
            column(TotalValueofItemSuppliesCaption; TotalValueofItemSuppliesCaptionLbl)
            {
            }
            column(EU3PartyTradeCaption; EU3PartyTradeCaptionLbl)
            {
            }
            column(TotalValueofServiceSuppliesCaption; TotalValueofServiceSuppliesCaptionLbl)
            {
            }
            column(EU3PartyItemTradeAmtCaption; EU3PartyItemTradeAmtCaptionLbl)
            {
            }
            column(EUPartySrvcTradeAmtCaption; EUPartySrvcTradeAmtCaptionLbl)
            {
            }
            column(NumberoflinesThispageCaption; NumberoflinesThispageCaptionLbl)
            {
            }
            column(NumberoflinesAllpagesCaption; NumberoflinesAllpagesCaptionLbl)
            {
            }
            column(CompanyInfoEMailCaption; CompanyInfoEMailCaptionLbl)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemLink = "Country/Region Code" = field(Code);
                DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") where(Type = const(Sale), "Country/Region Code" = filter(<> ''));
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date";
                column(VATRegNo_VATEntry; "VAT Registration No.")
                {
                }
                column(VATRegNo_VATEntryCaption; FieldCaption("VAT Registration No."))
                {
                }
                column(CountryRegionEUCountryRegionCode; "Country/Region"."EU Country/Region Code")
                {
                }
                column(CountryRegionEUCountryRegionCodeCaption; "Country/Region".FieldCaption("EU Country/Region Code"))
                {
                }
                column(NotEUTrdPartyAmt; NotEUTrdPartyAmt)
                {
                }
                column(Grouping; Grouping)
                {
                    OptionCaption = 'NotEUTrdPartyAmt,NotEUTrdPartyAmtService,EUTrdPartyAmt,EUTrdPartyAmtService';
                }
                column(NotEUTrdPartyAmtService; NotEUTrdPartyAmtService)
                {
                }
                column(EUTrdPartyAmt; EUTrdPartyAmt)
                {
                }
                column(EUTrdPartyAmtService; EUTrdPartyAmtService)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ResetVATEntry then begin
                        ResetVATEntry := false;
                        EUTrdPartyAmtService := 0;
                        NotEUTrdPartyAmtService := 0;
                        EUTrdPartyAmt := 0;
                        NotEUTrdPartyAmt := 0
                    end;

                    if "EU Service" then
                        if "EU 3-Party Trade" then
                            EUTrdPartyAmtService += Base
                        else
                            NotEUTrdPartyAmtService += Base
                    else
                        if "EU 3-Party Trade" then
                            EUTrdPartyAmt += Base
                        else
                            NotEUTrdPartyAmt += Base;

                    OnBeforeSetGrouping(ReportLayout, NotEUTrdPartyAmt, Grouping, NotEUTrdPartyAmtService, EUTrdPartyAmt, EUTrdPartyAmtService);
                    if ReportLayout = ReportLayout::"Separate &Lines" then begin
                        if NotEUTrdPartyAmt <> 0 then
                            Grouping := Grouping::NotEUTrdPartyAmt;
                        if NotEUTrdPartyAmtService <> 0 then
                            Grouping := Grouping::NotEUTrdPartyAmtService;
                        if EUTrdPartyAmt <> 0 then
                            Grouping := Grouping::EUTrdPartyAmt;
                        if EUTrdPartyAmtService <> 0 then
                            Grouping := Grouping::EUTrdPartyAmtService
                    end;

                    if not (VATEntry.Next() = 0) then begin
                        if VATEntry."VAT Registration No." = "VAT Registration No." then
                            if ReportLayout = ReportLayout::"Separate &Lines" then begin
                                if (VATEntry."EU Service" = "EU Service") and (VATEntry."EU 3-Party Trade" = "EU 3-Party Trade") then
                                    CurrReport.Skip()
                            end else
                                CurrReport.Skip();
                        ResetVATEntry := true;
                        OnAfterVATEntryNext(ResetVATEntry, "VAT Entry");
                    end;

                    TotalEUTrdPartyAmtService += Round(EUTrdPartyAmtService, 1);
                    TotalNotEUTrdPartyAmtService += Round(NotEUTrdPartyAmtService, 1);
                    TotalEUTrdPartyAmt += Round(EUTrdPartyAmt, 1);
                    TotalNotEUTrdPartyAmt += Round(NotEUTrdPartyAmt, 1);
                    FormatEUTrdPartyAmtService := FormatAmt(TotalEUTrdPartyAmtService);
                    FormatNotEUTrdPartyAmtService := FormatAmt(TotalNotEUTrdPartyAmtService);
                    FormatEUTrdPartyAmt := FormatAmt(TotalEUTrdPartyAmt);
                    FormatNotEUTrdPartyAmt := FormatAmt(TotalNotEUTrdPartyAmt);
                end;

                trigger OnPreDataItem()
                begin
                    ResetVATEntry := true;
                    VATEntry.SetCurrentKey(
                      Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date");
                    VATEntry.CopyFilters("VAT Entry");
                    if VATEntry.FindSet() then;
                end;
            }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                ThirdPartyTrade := (ReportLayout = ReportLayout::"Separate &Lines");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About EC Sales List';
        AboutText = 'The **EC Sales List** report summarizes sales of goods and services to VAT-registered customers in other EU countries for tax reporting. Use it for preparing and submitting EC Sales declarations to EU tax authorities, ensuring compliance with intra-EU VAT reporting requirements.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ReportLayout; ReportLayout)
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Print Third Party Trade as';
                        OptionCaption = 'Separate Lines,Column with Amount';
                        ToolTip = 'Specifies if you want the report to show third party trade as a separate line for each customer or as an additional column.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        VATEntryFilter := "VAT Entry".GetFilters();

        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        VATEntry: Record "VAT Entry";
        FormatAddr: Codeunit "Format Address";
        VATEntryFilter: Text;
        CompanyAddr: array[8] of Text[100];
        EUTrdPartyAmt: Decimal;
        NotEUTrdPartyAmt: Decimal;
        EUTrdPartyAmtService: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'All amounts are in whole %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NotEUTrdPartyAmtService: Decimal;
        ReportLayout: Option "Separate &Lines","Column with &Amount";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ThirdPartyTrade: Boolean;
        ResetVATEntry: Boolean;
        Grouping: Option NotEUTrdPartyAmt,NotEUTrdPartyAmtService,EUTrdPartyAmt,EUTrdPartyAmtService;
        TotalNotEUTrdPartyAmt: Decimal;
        TotalEUTrdPartyAmt: Decimal;
        TotalNotEUTrdPartyAmtService: Decimal;
        TotalEUTrdPartyAmtService: Decimal;
        FormatNotEUTrdPartyAmt: Text[30];
        FormatEUTrdPartyAmt: Text[30];
        FormatNotEUTrdPartyAmtService: Text[30];
        FormatEUTrdPartyAmtService: Text[30];
        ECSalesListCaptionLbl: Label 'EC Sales List';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoHomePageCaptionLbl: Label 'Home Page';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Registration No.';
        TotalValueofItemSuppliesCaptionLbl: Label 'Total Value of Item Supplies';
        EU3PartyTradeCaptionLbl: Label 'EU 3-Party Trade';
        TotalValueofServiceSuppliesCaptionLbl: Label 'Total Value of Service Supplies';
        EU3PartyItemTradeAmtCaptionLbl: Label 'EU 3-Party Item Trade Amount';
        EUPartySrvcTradeAmtCaptionLbl: Label 'EU 3-Party Service Trade Amount';
        NumberoflinesThispageCaptionLbl: Label 'Number of lines (this page)';
        NumberoflinesAllpagesCaptionLbl: Label 'Number of lines (all pages)';
        CompanyInfoEMailCaptionLbl: Label 'Email';

    local procedure FormatAmt(AmountToPrint: Decimal): Text[30]
    var
        TextAmt: Text[30];
    begin
        TextAmt := Format(Round(-AmountToPrint, 1), 0, '<Integer Thousand><Decimals>');
        if AmountToPrint > 0 then
            TextAmt := '(' + TextAmt + ')';
        exit(TextAmt);
    end;

    procedure InitializeRequest(NewReportLayout: Option)
    begin
        ReportLayout := NewReportLayout;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetGrouping(ReportLayout: Option "Separate &Lines","Column with &Amount"; NotEUTrdPartyAmt: Decimal; Grouping: Option NotEUTrdPartyAmt,NotEUTrdPartyAmtService,EUTrdPartyAmt,EUTrdPartyAmtService; NotEUTrdPartyAmtService: Decimal; EUTrdPartyAmt: Decimal; EUTrdPartyAmtService: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterVATEntryNext(ResetVATEntry: Boolean; "VAT Entry": Record "VAT Entry")
    begin
    end;
}

