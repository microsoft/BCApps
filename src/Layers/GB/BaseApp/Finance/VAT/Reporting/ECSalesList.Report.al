// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
#if not CLEAN27
using System;
using System.IO;
using System.Utilities;
#endif

/// <summary>
/// Generates European Community Sales List report for EU trade reporting requirements.
/// Provides detailed listing of sales to EU customers with VAT registration numbers and transaction values.
/// </summary>
report 130 "EC Sales List"
{
    DefaultLayout = RDLC;
#if not CLEAN27
    RDLCLayout = './Finance/VAT/Reporting/ECSalesListGB.rdlc';
#else
    RDLCLayout = './Finance/VAT/Reporting/ECSalesList.rdlc';
#endif
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
#if not CLEAN27
            column(Indicator_Code_Caption; Indicator_Code_CaptionLbl)
            {
            }
#endif
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
#if not CLEAN27
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date", "EU Service";
#else
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date";
#endif
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
#if not CLEAN27
                column(IndicatorCode; IndicatorCode)
                {
                }
#endif
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
#if not CLEAN27
                        NewGroupStarted := false;
#endif
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
#if not CLEAN27
                        if NotEUTrdPartyAmt <> 0 then begin
                            Grouping := Grouping::NotEUTrdPartyAmt;
                            IndicatorCode := GetIndicatorCode(false, false)
                        end;
                        if NotEUTrdPartyAmtService <> 0 then begin
                            Grouping := Grouping::NotEUTrdPartyAmtService;
                            IndicatorCode := GetIndicatorCode(false, true)
                        end;
                        if EUTrdPartyAmt <> 0 then begin
                            Grouping := Grouping::EUTrdPartyAmt;
                            IndicatorCode := GetIndicatorCode(true, false)
                        end;
                        if EUTrdPartyAmtService <> 0 then begin
                            Grouping := Grouping::EUTrdPartyAmtService;
                            IndicatorCode := GetIndicatorCode(false, true)
                        end;
#else
                        if NotEUTrdPartyAmt <> 0 then
                            Grouping := Grouping::NotEUTrdPartyAmt;
                        if NotEUTrdPartyAmtService <> 0 then
                            Grouping := Grouping::NotEUTrdPartyAmtService;
                        if EUTrdPartyAmt <> 0 then
                            Grouping := Grouping::EUTrdPartyAmt;
                        if EUTrdPartyAmtService <> 0 then
                            Grouping := Grouping::EUTrdPartyAmtService
#endif
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
#if not CLEAN27
                        NewGroupStarted := true;
                        PrevVATRegNo := "VAT Registration No.";
                        UpdateXMLFileRTC();
#endif
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

#if not CLEAN27
                trigger OnPostDataItem()
                begin
                    UpdateXMLFileRTC();
                end;
#endif

                trigger OnPreDataItem()
                begin
                    ResetVATEntry := true;
                    VATEntry.SetCurrentKey(
                      Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date");
                    VATEntry.CopyFilters("VAT Entry");
#if not CLEAN27
                    if not VATEntry.FindSet() then;
#else
                    if VATEntry.FindSet() then;
#endif
#if not CLEAN27      
                    EUTrdPartyAmtService := 0;
                    NotEUTrdPartyAmtService := 0;
                    EUTrdPartyAmt := 0;
                    NotEUTrdPartyAmt := 0
#endif
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
#if not CLEAN27
                    field("Create XML File"; "Create XML File")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create XML File';
                        ToolTip = 'Specifies the calculated tax and base amounts, and creates the sales VAT advance notification XML document that will be sent to the tax authority.';

                        trigger OnValidate()
                        begin
                            CreateXMLFileOnAfterValidate();
                        end;
                    }
#endif
                }
            }
        }

        actions
        {
        }

#if not CLEAN27
        trigger OnInit()
        begin
            XMLFileEnable := true;
        end;
#endif

#if not CLEAN27
        trigger OnOpenPage()
        begin
            XMLFileEnable := "Create XML File";
        end;
#endif
    }

    labels
    {
    }

#if not CLEAN27
    trigger OnPostReport()
    begin
        if "Create XML File" then
            SaveXMLFile();
    end;
#endif

    trigger OnPreReport()
#if not CLEAN27
    var
        PeriodEnd: Date;
        IsHandled: Boolean;
#endif
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        VATEntryFilter := "VAT Entry".GetFilters();
#if not CLEAN27
        PeriodStart := "VAT Entry".GetRangeMin("Posting Date");
        PeriodEnd := "VAT Entry".GetRangeMax("Posting Date");

        Calendar.Reset();
        Calendar.SetFilter("Period Type", '%1|%2', Calendar."Period Type"::Month, Calendar."Period Type"::Quarter);
        Calendar.SetRange("Period Start", PeriodStart);
        Calendar.SetRange("Period End", ClosingDate(PeriodEnd));
        IsHandled := false;
        OnBeforePostingDateError(IsHandled);
        if not IsHandled then
            if not Calendar.FindFirst() then
                Error(Text10500, "VAT Entry".FieldCaption("Posting Date"), "VAT Entry".GetFilter("Posting Date"));
#endif
        GLSetup.Get();
#if not CLEAN27
        if "Create XML File" then
            CreateXMLDocument();
#endif
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
#if not CLEAN27
        Calendar: Record Date;
        XMLOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        Attribute: DotNet XmlAttribute;
        NewChildNode: DotNet XmlNode;
        NewChildNode2: DotNet XmlNode;
        NewChildNode3: DotNet XmlNode;
        "XML File": Text[1024];
        "Create XML File": Boolean;
        Text1041000: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        Text1041001: Label 'Export to XML File';
        PeriodStart: Date;
        Text1041002: Label 'XML file successfully created';
        Text1040003: Label 'Default';
        ToFile: Text[1024];
        PrevVATRegNo: Text[30];
        NewGroupStarted: Boolean;
        XMLFileEnable: Boolean;
        Text10500: Label '%1 filter %2 must be corrected, to run the report monthly or quarterly. ';
        IndicatorCode: Integer;
#endif
        ECSalesListCaptionLbl: Label 'EC Sales List';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoHomePageCaptionLbl: Label 'Home Page';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Registration No.';
        TotalValueofItemSuppliesCaptionLbl: Label 'Total Value of Item Supplies';
        EU3PartyTradeCaptionLbl: Label 'EU 3-Party Trade';
        TotalValueofServiceSuppliesCaptionLbl: Label 'Total Value of Service Supplies';
#if not CLEAN27
        Indicator_Code_CaptionLbl: Label 'Indicator Code';
#endif
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

    /// <summary>
    /// Initializes report layout option for EU sales list generation.
    /// Configures report format and display preferences.
    /// </summary>
    /// <param name="NewReportLayout">Report layout option to apply</param>
    procedure InitializeRequest(NewReportLayout: Option)
    begin
        ReportLayout := NewReportLayout;
    end;

#if not CLEAN27
    [Obsolete('Moved to GovTalk app', '27.0')]
    [Scope('OnPrem')]
    procedure CreateXMLDocument()
    var
        RBMgt: Codeunit "File Management";
        IsHandled: Boolean;
    begin
        IsHandled := true;
        OnBeforeCreateXMLDocument(IsHandled);
        if IsHandled then
            exit;
        "XML File" := RBMgt.ServerTempFileName('xml');
        XMLOut := XMLOut.XmlDocument();


        XMLCurrNode := XMLOut.CreateElement('Submission');
        Attribute := XMLOut.CreateAttribute('type');
        Attribute.Value := 'HMCE_VAT_ESL_BULK_SUBMISSION_FILE';
        XMLCurrNode.Attributes.SetNamedItem(Attribute);
        XMLOut.AppendChild(XMLCurrNode);

        XMLOut.CreateProcessingInstruction('xml', 'version="1.0" encoding="utf-8"');

        NewChildNode := XMLOut.CreateElement('TraderVRN');
        NewChildNode.InnerText(CompanyInfo."VAT Registration No.");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Branch');
        NewChildNode.InnerText(CompanyInfo."Branch Number");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Year');
        NewChildNode.InnerText(Format(Date2DMY(PeriodStart, 3)));
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Period');
        NewChildNode.InnerText(FormatPeriod(Calendar."Period No." * CalcPeriodValue()));
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('CurrencyA3');
        NewChildNode.InnerText(GLSetup."LCY Code");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('ContactName');
        NewChildNode.InnerText(CompanyInfo."Contact Person");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Online');
        NewChildNode.InnerText('0');
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('SubmissionLines');
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    [Scope('OnPrem')]
    procedure CreateXMLSubmissionLine(Amount: Decimal; IndicatorCode: Integer)
    begin
        NewChildNode2 := XMLOut.CreateElement('SubmissionLine');

        NewChildNode3 := XMLOut.CreateElement('CountryA2');
        NewChildNode3.InnerText("Country/Region"."EU Country/Region Code");

        NewChildNode.AppendChild(NewChildNode2);
        NewChildNode2.AppendChild(NewChildNode3);

        NewChildNode3 := XMLOut.CreateElement('CustomerVRN');
        if NewGroupStarted then
            NewChildNode3.InnerText(PrevVATRegNo)
        else
            NewChildNode3.InnerText("VAT Entry"."VAT Registration No.");
        NewChildNode2.AppendChild(NewChildNode3);

        NewChildNode3 := XMLOut.CreateElement('Value');
        NewChildNode3.InnerText(FormatAmtXML(Amount));
        NewChildNode2.AppendChild(NewChildNode3);
        NewChildNode3 := XMLOut.CreateElement('Indicator');
        NewChildNode3.InnerText(Format(IndicatorCode));
        NewChildNode2.AppendChild(NewChildNode3);
        XMLCurrNode.AppendChild(NewChildNode);
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    [Scope('OnPrem')]
    procedure SaveXMLFile()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveXMLFile(IsHandled);
        if IsHandled then
            exit;
        XMLOut.Save("XML File");
        ToFile := Text1040003 + '.xml';
        if not Download("XML File", Text1041001, '', Text1041000, ToFile) then
            exit;
        Message(Text1041002);
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    local procedure FormatAmtXML(AmountToPrint: Decimal): Text[30]
    begin
        exit(Format(Round(-AmountToPrint, 1), 0, 1));
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    [Scope('OnPrem')]
    procedure UpdateXMLFileRTC()
    var
        IndicatorCode2: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateXMLFileRTC(IsHandled);
        if IsHandled then
            exit;
        if "Create XML File" and
           (NotEUTrdPartyAmt <> 0)
        then begin
            IndicatorCode2 := GetIndicatorCode(false, false);
            CreateXMLSubmissionLine(NotEUTrdPartyAmt, IndicatorCode2);
        end;

        if "Create XML File" and (NotEUTrdPartyAmtService <> 0) then begin
            IndicatorCode2 := GetIndicatorCode(false, true);
            CreateXMLSubmissionLine(NotEUTrdPartyAmtService, IndicatorCode2);
        end;
        if "Create XML File" and
           (EUTrdPartyAmt <> 0)
        then begin
            IndicatorCode2 := GetIndicatorCode(true, false);
            CreateXMLSubmissionLine(EUTrdPartyAmt, IndicatorCode2);
        end;
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    local procedure CreateXMLFileOnAfterValidate()
    begin
        XMLFileEnable := "Create XML File";
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    [Scope('OnPrem')]
    procedure CalcPeriodValue(): Integer
    begin
        if Calendar."Period Type" = Calendar."Period Type"::Month then
            exit(1)
        else
            exit(3)
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    [Scope('OnPrem')]
    procedure FormatPeriod(PeriodNo: Integer): Text[30]
    begin
        exit(Format(PeriodNo, 2, '<Integer,2><Filler Character,0>'));
    end;

    [Obsolete('Moved to GovTalk app', '27.0')]
    [Scope('OnPrem')]
    procedure GetIndicatorCode(EU3rdPartyTrade: Boolean; EUService: Boolean): Integer
    begin
        if EUService then
            exit(3)
        else
            if EU3rdPartyTrade then
                exit(2)
            else
                exit(0)
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetGrouping(ReportLayout: Option "Separate &Lines","Column with &Amount"; NotEUTrdPartyAmt: Decimal; Grouping: Option NotEUTrdPartyAmt,NotEUTrdPartyAmtService,EUTrdPartyAmt,EUTrdPartyAmtService; NotEUTrdPartyAmtService: Decimal; EUTrdPartyAmt: Decimal; EUTrdPartyAmtService: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterVATEntryNext(ResetVATEntry: Boolean; "VAT Entry": Record "VAT Entry")
    begin
    end;

#if not CLEAN27
    [Obsolete('Event will be removed in a future release.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateXMLFileRTC(var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Event will be removed in a future release.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveXMLFile(var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Event will be removed in a future release.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostingDateError(var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Event will be removed in a future release.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateXMLDocument(var IsHandled: Boolean)
    begin
    end;
#endif
}

