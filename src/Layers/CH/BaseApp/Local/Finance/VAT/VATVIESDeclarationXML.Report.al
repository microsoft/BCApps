// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Customer;
using System.IO;
using System.Utilities;

report 11108 "VAT - VIES Declaration XML"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/VATVIESDeclarationXML.rdlc';
    Caption = 'VAT - VIES Declaration XML';
    ProcessingOnly = false;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") where(Type = const(Sale), "Bill-to/Pay-to No." = filter(<> ''), "Document Type" = filter(" " | Invoice | "Credit Memo" | Payment | Refund));
            RequestFilterFields = "VAT Bus. Posting Group";
            column("Filter"; Filter)
            {
            }
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(RepPeriodFrom; Format(RepPeriodFrom))
            {
            }
            column(RepPeriodTo; Format(RepPeriodTo))
            {
            }
            column(PaketNr; PaketNr)
            {
            }
            column(NoOfRecs; NoOfRecs)
            {
            }
            column(VAT_Entry_Entry_No_; "Entry No.")
            {
            }
            column(VAT__VIES_Declaration_DiskCaption; VAT__VIES_Declaration_DiskCaptionLbl)
            {
            }
            column(Reportingperiod_fromCaption; Reportingperiod_fromCaptionLbl)
            {
            }
            column(Reportingperiod_toCaption; Reportingperiod_toCaptionLbl)
            {
            }
            column(FilterCaption; FilterCaptionLbl)
            {
            }
            column(PaketNrCaption; PaketNrCaptionLbl)
            {
            }
            column(SumPrn_EUServiceCaption; SumPrn_EUServiceCaptionLbl)
            {
            }
            column(SumPrn_Control1160019Caption; SumPrn_Control1160019CaptionLbl)
            {
            }
            column(SumPrnCaption; SumPrnCaptionLbl)
            {
            }
            column(Customer_NameCaption; Customer_NameCaptionLbl)
            {
            }
            column(tempVATEntry__Bill_to_Pay_to_No__Caption; tempVATEntry__Bill_to_Pay_to_No__CaptionLbl)
            {
            }
            column(tempVATEntry__VAT_Registration_No__Caption; tempVATEntry__VAT_Registration_No__CaptionLbl)
            {
            }
            column(tempVATEntry__Country_Region_Code_Caption; tempVATEntry__Country_Region_Code_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Clear(VATRegNo);
                if "VAT Registration No." = '' then begin
                    if Customer."No." <> "Bill-to/Pay-to No." then
                        if not Customer.Get("Bill-to/Pay-to No.") then
                            Clear(Customer)
                        else
                            if Customer."VAT Registration No." = '' then
                                Error(Text014, Customer."No.", Customer.Name);
                    VATRegNo := Customer."VAT Registration No."
                end else
                    VATRegNo := "VAT Registration No.";

                tempVATEntry.SetRange(Type, Type::Sale);
                tempVATEntry.SetRange("Country/Region Code", "Country/Region Code");
                tempVATEntry.SetRange("VAT Registration No.", VATRegNo);
                tempVATEntry.SetRange("EU Service", "EU Service");
                if "EU Service" then
                    tempVATEntry.SetRange("EU 3-Party Trade")
                else
                    tempVATEntry.SetRange("EU 3-Party Trade", "EU 3-Party Trade");
                if tempVATEntry.Find('-') then begin
                    tempVATEntry.Base := tempVATEntry.Base + Base;
                    tempVATEntry."Additional-Currency Base" := tempVATEntry."Additional-Currency Base" + "Additional-Currency Base";
                    tempVATEntry.Modify();
                end else begin
                    tempVATEntry := "VAT Entry";
                    tempVATEntry."VAT Registration No." := VATRegNo;
                    tempVATEntry.Insert();
                    NoOfRecs := NoOfRecs + 1;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("VAT Reporting Date", '%1..%2', RepPeriodFrom, RepPeriodTo);
                NoOfRecs := 0;
                Clear(Customer);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(SumPrn; SumPrn)
            {
            }
            column(Customer_Name; Customer.Name)
            {
            }
            column(tempVATEntry__Bill_to_Pay_to_No__; tempVATEntry."Bill-to/Pay-to No.")
            {
            }
            column(tempVATEntry__VAT_Registration_No__; tempVATEntry."VAT Registration No.")
            {
            }
            column(tempVATEntry__Country_Region_Code_; tempVATEntry."Country/Region Code")
            {
            }
            column(tempVATEntry__EU_3_Party_Trade_; tempVATEntry."EU 3-Party Trade")
            {
            }
            column(tempVATEntry__EU_Service_; tempVATEntry."EU Service")
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(IntegerCaption; IntegerCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number > 1 then
                    tempVATEntry.Next();

                if Customer."No." <> tempVATEntry."Bill-to/Pay-to No." then
                    if not Customer.Get(tempVATEntry."Bill-to/Pay-to No.") then
                        Clear(Customer);
                if AmountsInReportCurrency then
                    Sum := tempVATEntry."Additional-Currency Base"
                else
                    Sum := tempVATEntry.Base;
                SumPrn := Round(Sum * -100, 100) / 100;

                ColNo := GetColumnNo(tempVATEntry);
                TotalSum[ColNo] := TotalSum[ColNo] + SumPrn;
            end;

            trigger OnPreDataItem()
            begin
                tempVATEntry.Reset();
                tempVATEntry.SetCurrentKey(Type, "Country/Region Code", "VAT Registration No.");
                if not tempVATEntry.Find('-') then
                    CurrReport.Break();
                SetRange(Number, 1, tempVATEntry.Count);
            end;
        }
        dataitem(Totaling; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(TotalSum; TotalSum[1])
            {
            }
            column(TotalSumEU3PartyTrade; TotalSum[2])
            {
            }
            column(TotalSumEUService; TotalSum[3])
            {
            }
            column(Totaling_Number; Number)
            {
            }
            column(TotalSumCaption; TotalSumCaptionLbl)
            {
            }
        }
        dataitem(XML; "Integer")
        {
            DataItemTableView = sorting(Number);

            trigger OnAfterGetRecord()
            var
                VATRegNo: Text[20];
                Counter: Integer;
            begin
                if AmountsInReportCurrency then
                    Sum := tempVATEntry."Additional-Currency Base"
                else
                    Sum := tempVATEntry.Base;
                VATRegNo := tempVATEntry."VAT Registration No.";
                ColNo := GetColumnNo(tempVATEntry);
                TotalSum[ColNo] += Sum;

                if tempVATEntry.Next() <> 0 then begin
                    if tempVATEntry."VAT Registration No." <> VATRegNo then begin
                        for Counter := 1 to 3 do
                            if TotalSum[Counter] <> 0 then
                                WriteXMLData(VATRegNo, TotalSum[Counter], Counter);
                        Clear(TotalSum);
                        VATRegNo := tempVATEntry."VAT Registration No.";
                    end;
                end else
                    for Counter := 1 to 3 do
                        if TotalSum[Counter] <> 0 then
                            WriteXMLData(VATRegNo, TotalSum[Counter], Counter);
            end;

            trigger OnPostDataItem()
            begin
                if NoOfRecs > 0 then
                    WriteXMLFooter();
            end;

            trigger OnPreDataItem()
            begin
                if not tempVATEntry.Find('-') then
                    CurrReport.Break();
                WriteXMLHeader();
                SetRange(Number, 1, tempVATEntry.Count);
                WriteXMLGeneral();
                Clear(TotalSum);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Statement Period")
                    {
                        Caption = 'Statement Period';
                        field(RepPeriodFrom; RepPeriodFrom)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        }
                        field(RepPeriodTo; RepPeriodTo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the last date that the report includes data for.';
                        }
                    }
                    field(ReportingDate; Reportingdate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reporting Date';
                        ToolTip = 'Specifies the date when the VAT-VIES declaration is created.';
                    }
                    field(ReportingType; Reportingtype)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reporting Type';
                        OptionCaption = 'Normal transmission,Recall of an earlier report';
                        ToolTip = 'Specifies what is exported. Select Normal transmission to export a full VAT-VIES declaration, or select Recall of an earlier report.';
                    }
                    field(NoSeries; NoSeries.Code)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. Series';
                        Lookup = true;
                        TableRelation = "No. Series";
                        ToolTip = 'Specifies the code for the number series that was used to assign numbers.';
                    }
                    field(AmountsInReportCurrency; AmountsInReportCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want report amounts to be shown in the additional reporting currency.';
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

    trigger OnPostReport()
    begin
        if tempVATEntry.Find('-') then
            if FileName = '' then
                FileManagement.DownloadHandler(ServerFileName, '', '',
                  FileManagement.GetToFilterText('', ServerFileName), TextExportFileName)
            else
                FileManagement.CopyServerFile(ServerFileName, FileName, true);

        tempVATEntry.DeleteAll();
    end;

    trigger OnPreReport()
    var
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        if Reportingtype = Reportingtype::"Recall of an earlier report" then
            Filter := Text000
        else
            Filter := "VAT Entry".GetFilters();

        ServerFileName := FileManagement.ServerTempFileName('xml');

        if Reportingtype = Reportingtype::"Normal transmission" then
            if Reportingdate <> 0D then
                Error(Text002);
        if Reportingtype = Reportingtype::"Recall of an earlier report" then
            if Reportingdate = 0D then
                Error(Text003);
        if NoSeries.Code = '' then
            Error(Text1160004);

        PaketNr := NoSeriesCodeunit.GetNextNo(NoSeries.Code, Today());
        if StrLen(PaketNr) <> 9 then
            Error(Text1160006, NoSeries.Code);

        if DelChr(PaketNr, '=', '01234567890 ') <> '' then
            Error(Text1160007);

        CompanyInfo.Get();
        VATReportSetup.Get();

        Clear(TotalSum);
    end;

    var
        Text000: Label 'Recall of an earlier report';
        Text002: Label 'Reportingdate must be empty, if marking is "Normal transmission".';
        Text003: Label 'Reportingdate must not be empty, if marking is "recall of an earlier report".';
        Text014: Label 'Customer %1, %2 doesn''t have an UID.';
        Text1160004: Label 'You didn''t define a No. Series.';
        Text1160006: Label 'The No. Series %1 has not 9 digits.';
        Text1160007: Label 'The No. Series should only contain numbers.';
        TextExportFileName: Label 'ZM_jjjj_Qnn.xml';
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        VATReportSetup: Record "VAT Report Setup";
        tempVATEntry: Record "VAT Entry" temporary;
        NoSeries: Record "No. Series";
        FileManagement: Codeunit "File Management";
        XMLFile: File;
        "Filter": Text;
        VATRegNo: Text[20];
        ServerFileName: Text;
        FileName: Text;
        RepPeriodFrom: Date;
        RepPeriodTo: Date;
        Reportingdate: Date;
        NoOfRecs: Integer;
        TotalSum: array[3] of Decimal;
        "Sum": Decimal;
        SumPrn: Decimal;
        Reportingtype: Option "Normal transmission","Recall of an earlier report";
        PaketNr: Code[9];
        AmountsInReportCurrency: Boolean;
        GesamtrueckDone: Boolean;
        VAT__VIES_Declaration_DiskCaptionLbl: Label 'VAT- VIES Declaration Disk';
        Reportingperiod_fromCaptionLbl: Label 'Reporting period from';
        Reportingperiod_toCaptionLbl: Label 'Reporting period to';
        FilterCaptionLbl: Label 'Filter';
        PaketNrCaptionLbl: Label 'Package No.';
        SumPrn_EUServiceCaptionLbl: Label 'Base amount EU Service';
        SumPrn_Control1160019CaptionLbl: Label 'Base amount EU 3-Party Trade';
        SumPrnCaptionLbl: Label 'Base amount';
        Customer_NameCaptionLbl: Label 'Customer Name';
        tempVATEntry__Bill_to_Pay_to_No__CaptionLbl: Label 'Customer No.';
        tempVATEntry__VAT_Registration_No__CaptionLbl: Label 'UID';
        tempVATEntry__Country_Region_Code_CaptionLbl: Label 'Country Code';
        IntegerCaptionLbl: Label 'Integer';
        TotalSumCaptionLbl: Label 'Total';
        ColNo: Integer;

    [Scope('OnPrem')]
    procedure WriteXMLHeader()
    var
        IdentificationKeyTextL: Text;
    begin
        GesamtrueckDone := false;

        XMLFile.WriteMode(true);
        XMLFile.TextMode(true);
        XMLFile.Create(ServerFileName);

        XMLFile.Write('<?xml version="1.0" encoding="iso-8859-1"?>');
        XMLFile.Write('<ERKLAERUNGS_UEBERMITTLUNG>');
        XMLFile.Write('<INFO_DATEN>');
        XMLFile.Write('<ART_IDENTIFIKATIONSBEGRIFF>FASTNR</ART_IDENTIFIKATIONSBEGRIFF>');
        IdentificationKeyTextL := StrSubstNo('<IDENTIFIKATIONSBEGRIFF>%1%2</IDENTIFIKATIONSBEGRIFF>',
                    CompanyInfo."Tax Office Number", DelChr(CompanyInfo."Registration No.", '=', '-/ '));
        OnWriteXMLHeaderOnBeforeWriteIdentificationKey(CompanyInfo, IdentificationKeyTextL);
        XMLFile.Write(IdentificationKeyTextL);
        XMLFile.Write(StrSubstNo('<PAKET_NR>%1</PAKET_NR>', PaketNr));
        XMLFile.Write(StrSubstNo('<DATUM_ERSTELLUNG type="datum">%1</DATUM_ERSTELLUNG>', Format(Today, 10, '<YEAR4>-<MONTH,2>-<DAY,2>')));
        XMLFile.Write(StrSubstNo('<UHRZEIT_ERSTELLUNG type="uhrzeit">%1</UHRZEIT_ERSTELLUNG>',
            Format(Time, 8, '<HOURS24,2><Filler Character,0>:<Minutes,2>:<seconds,2>')));
        XMLFile.Write(StrSubstNo('<ANZAHL_ERKLAERUNGEN>%1</ANZAHL_ERKLAERUNGEN>', 1));
        XMLFile.Write('</INFO_DATEN>');
        XMLFile.Write('<ERKLAERUNG art="U13">');
    end;

    [Scope('OnPrem')]
    procedure WriteXMLGeneral()
    begin
        XMLFile.Write(StrSubstNo('<SATZNR>%1</SATZNR>', 1));
        XMLFile.Write('<ALLGEMEINE_DATEN>');
        XMLFile.Write('<ANBRINGEN>U13</ANBRINGEN>');
        XMLFile.Write(StrSubstNo('<ZRVON type="jahrmonat">%1</ZRVON>', Format(RepPeriodFrom, 7, '<YEAR4>-<MONTH,2>')));
        XMLFile.Write(StrSubstNo('<ZRBIS type="jahrmonat">%1</ZRBIS>', Format(RepPeriodTo, 7, '<YEAR4>-<MONTH,2>')));
        XMLFile.Write(
          StrSubstNo('<FASTNR>%1%2</FASTNR>', CompanyInfo."Tax Office Number", DelChr(CompanyInfo."Registration No.", '=', '-/ '))
          );
        XMLFile.Write(StrSubstNo('<KUNDENINFO>%1</KUNDENINFO>', DelChr(Format(DelChr(GetCompanyName(), '<>', ' '), 20), '<>', ' ')));
        XMLFile.Write('</ALLGEMEINE_DATEN>');
    end;

    [Scope('OnPrem')]
    procedure WriteXMLData(VATRegNo: Text[20]; Amount: Decimal; ColumnNo: Integer)
    begin
        if Reportingtype = Reportingtype::"Normal transmission" then begin
            XMLFile.Write('<ZM>');
            XMLFile.Write(StrSubstNo('<UID_MS>%1</UID_MS>', DelChr(Format(DelChr(VATRegNo, '<>', ' '), 15), '<>', ' ')));
            XMLFile.Write(StrSubstNo('<SUM_BGL type="kz">%1</SUM_BGL>',
                DelChr(Format(Round(Amount * -100, 100) / 100, 11, '<Sign><integer>'), '<>', ' ')));
            case ColumnNo of
                3:
                    XMLFile.Write(StrSubstNo('<SOLEI>%1</SOLEI>', 'J'));
                2:
                    XMLFile.Write(StrSubstNo('<DREIECK>%1</DREIECK>', 1));
            end;
            XMLFile.Write('</ZM>');
        end else
            if (Reportingtype = Reportingtype::"Recall of an earlier report") and not GesamtrueckDone then begin
                XMLFile.Write('<GESAMTRUECKZIEHUNG>');
                XMLFile.Write('<GESAMTRUECK>J</GESAMTRUECK>');
                XMLFile.Write('</GESAMTRUECKZIEHUNG>');
                GesamtrueckDone := true;
            end;
    end;

    [Scope('OnPrem')]
    procedure WriteXMLFooter()
    begin
        XMLFile.Write('</ERKLAERUNG>');
        XMLFile.Write('</ERKLAERUNGS_UEBERMITTLUNG>');
        XMLFile.Close();
    end;

    [Scope('OnPrem')]
    procedure GetColumnNo(VATEntry: Record "VAT Entry"): Integer
    begin
        if VATEntry."EU Service" then
            exit(3);
        if VATEntry."EU 3-Party Trade" then
            exit(2);
        exit(1);
    end;

    local procedure GetCompanyName(): Text
    begin
        if VATReportSetup."Company Name" <> '' then
            exit(VATReportSetup."Company Name");

        exit(CompanyInfo.Name);
    end;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWriteXMLHeaderOnBeforeWriteIdentificationKey(var CompanyInfo: Record "Company Information"; var IdentificationKeyText: Text)
    begin
    end;
}

