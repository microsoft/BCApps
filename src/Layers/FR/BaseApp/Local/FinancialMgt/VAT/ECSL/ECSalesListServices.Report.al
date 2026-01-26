// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

report 10876 "EC Sales List - Services"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/ECSL/ECSalesListServices.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'EC Sales List - Services';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = sorting("EU Country/Region Code") where("EU Country/Region Code" = filter(<> ''));
            column(DATE2DMY_PeriodStart_3_; Date2DMY(PeriodStart, 3))
            {
            }
            column(FORMAT_DATE2DMY_PeriodStart_2___0____Integer_2__Filler_Character_0___; Format(Date2DMY(PeriodStart, 2), 0, '<Integer,2><Filler Character,0>'))
            {
            }
            column(CompanyInfo_Name; CompanyInfo.Name)
            {
            }
            column(ContactName; ContactName)
            {
            }
            column(CompanyInfo_Address; CompanyInfo.Address)
            {
            }
            column(PhoneNo; PhoneNo)
            {
            }
            column(Fax; Fax)
            {
            }
            column(VATRegNo; VATRegNo)
            {
            }
            column(CompanyInfo_City_________CompanyInfo__Post_Code_; CompanyInfo.City + ' ' + CompanyInfo."Post Code")
            {
            }
            column(Email; Email)
            {
            }
            column(AmountCaption; AmountCaption)
            {
            }
            column(Country_Region_Code; Code)
            {
            }
            column(Reserved_for_the_Authorities_Caption; Reserved_for_the_Authorities_CaptionLbl)
            {
            }
            column(French_Customs_and_ExciseCaption; French_Customs_and_ExciseCaptionLbl)
            {
            }
            column(B_ServiceCaption; B_ServiceCaptionLbl)
            {
            }
            column(EUROPEAN_DECLARATION_OF_SERVICESCaption; EUROPEAN_DECLARATION_OF_SERVICESCaptionLbl)
            {
            }
            column(French_Department_of_the_TreasuryCaption; French_Department_of_the_TreasuryCaptionLbl)
            {
            }
            column(A__Filling_PeriodCaption; A__Filling_PeriodCaptionLbl)
            {
            }
            column(DATE2DMY_PeriodStart_3_Caption; DATE2DMY_PeriodStart_3_CaptionLbl)
            {
            }
            column(FORMAT_DATE2DMY_PeriodStart_2___0____Integer_2__Filler_Character_0___Caption; FORMAT_DATE2DMY_PeriodStart_2___0____Integer_2__Filler_Character_0___CaptionLbl)
            {
            }
            column(Date_name_and_signatureCaption; Date_name_and_signatureCaptionLbl)
            {
            }
            column(VATRegNoCaption; VATRegNoCaptionLbl)
            {
            }
            column(CompanyInfo_NameCaption; CompanyInfo_NameCaptionLbl)
            {
            }
            column(CompanyInfo_AddressCaption; CompanyInfo_AddressCaptionLbl)
            {
            }
            column(City_and_Zip_Caption; City_and_Zip_CaptionLbl)
            {
            }
            column(Contact_Person_Caption; Contact_Person_CaptionLbl)
            {
            }
            column(Phone_Caption; Phone_CaptionLbl)
            {
            }
            column(EmailCaption; EmailCaptionLbl)
            {
            }
            column(Fax_Caption; Fax_CaptionLbl)
            {
            }
            column(C__Filled_By_Caption; C__Filled_By_CaptionLbl)
            {
            }
            column(V3Caption; V3CaptionLbl)
            {
            }
            column(V2Caption; V2CaptionLbl)
            {
            }
            column(V1Caption; V1CaptionLbl)
            {
            }
            column(Customer_VAT_NumberCaption; Customer_VAT_NumberCaptionLbl)
            {
            }
            column(Line_NumberCaption; Line_NumberCaptionLbl)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemLink = "Country/Region Code" = field(Code);
                DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date") where(Type = const(Sale), "Country/Region Code" = filter(<> ''), "EU Service" = filter(true));
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date";
                column(LineNo; LineNo)
                {
                }
                column(VATAmount; VATAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(VAT_Entry__VAT_Registration_No__; "VAT Registration No.")
                {
                }
                column(VAT_Entry_Entry_No_; "Entry No.")
                {
                }
                column(VAT_Entry_Country_Region_Code; "Country/Region Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if StrLen("VAT Registration No.") > 14 then
                        CustVATRegNo := CopyStr("VAT Registration No.", (StrLen("VAT Registration No.") + 1 - 14))
                    else
                        CustVATRegNo := "VAT Registration No.";
                    if UseAmtsInAddCurr then begin
                        VATAmount := "Additional-Currency Base";
                        VATAmountXML := Base;
                    end else
                        VATAmount := Base;

                    VATAmount := Round(VATAmount, 1, '=');
                    Evaluate(VATAmount, Format(-VATAmount, 0, '<Sign><Integer>'));
                    if UseAmtsInAddCurr then
                        Evaluate(VATAmountXML, Format(-VATAmountXML, 0, '<Sign><Integer>'));
                    if "VAT Registration No." <> PrevVATRegNo then begin
                        if CreateXMLFile and (VATAmountRTC <> 0) then
                            CreateXMLLine();
                        if VATAmount <> 0 then
                            LineNo := LineNo + 1
                        else begin
                            VATEntry.Reset();
                            VATEntry.CopyFilters("VAT Entry");
                            VATEntry.SetRange("VAT Registration No.", "VAT Registration No.");
                            VATEntry.SetFilter(Base, '>=%1|<=%2', 0.5, -0.5);
                            if VATEntry.FindFirst() then
                                LineNo := LineNo + 1;
                        end;
                        VATAmountRTC := 0;
                        if not UseAmtsInAddCurr then
                            VATAmountXML := 0;
                        PrevVATRegNo := CustVATRegNo;
                    end;
                    VATAmountRTC := VATAmountRTC + VATAmount;
                    if not UseAmtsInAddCurr then
                        VATAmountXML := VATAmountXML + VATAmount;
                end;

                trigger OnPostDataItem()
                begin
                    if CreateXMLFile and (VATAmountRTC <> 0) then
                        CreateXMLLine();
                end;

                trigger OnPreDataItem()
                begin
                    VATAmountRTC := 0;
                    VATAmountXML := 0;
                    Clear(VATAmount);
                end;
            }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                GLSetup.Get();
                if UseAmtsInAddCurr then begin
                    if GLSetup."Additional Reporting Currency" <> '' then
                        AmountCaption := StrSubstNo(Text10800, GLSetup."Additional Reporting Currency");
                end else
                    AmountCaption := StrSubstNo(Text10800, GLSetup."LCY Code");
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
                    field(ContactName; ContactName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact Person';
                        ToolTip = 'Specifies the name of the contact person.';
                    }
                    field(PhoneNo; PhoneNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone';
                        ToolTip = 'Specifies the telephone number.';
                    }
                    field(Fax; Fax)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fax';
                        ToolTip = 'Specifies the fax number.';
                    }
                    field(Email; Email)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email Address';
                        ToolTip = 'Specifies the email address.';
                    }
                    field(ShowAmountsInAddReportingCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies whether to show amounts in your local currency and in your additional reporting currency.';
                    }
                    field(CreateXML; CreateXMLFile)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create XML';
                        ToolTip = 'Specifies that you want to generate an XML file that you can submit to tax authorities. If you choose this option, the information about the contact person is not needed.';

                        trigger OnValidate()
                        begin
                            PageUpdateRequestForm();
                        end;
                    }
                    field(XMLFile; XMLFile)
                    {
                        ApplicationArea = All;
                        Enabled = XMLFileEnable;
                        ToolTip = 'Specifies the name of the XML file for the report.';
                        Visible = XMLFileVisible;

                        trigger OnAssistEdit()
                        begin
                            XMLFile := '';
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            XMLFileEnable := true;
            XMLFileVisible := true;
        end;

        trigger OnOpenPage()
        begin
            PageUpdateRequestForm();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ToFile: Text[1024];
    begin
        if CreateXMLFile then begin
            if CheckXMLLine then
                XMLDoc.Save(XMLFile)
            else
                Error(Text10801);
            ToFile := Text005;
            if not Download(XMLFile, Text002, '', Text001, ToFile) then
                exit;
            Message(Text003);
        end;
    end;

    trigger OnPreReport()
    var
        Calendar: Record Date;
        FileMgt: Codeunit "File Management";
        PeriodEnd: Date;
    begin
        if CreateXMLFile then
            XMLFile := FileMgt.ServerTempFileName('xml');

        if StrLen(CompanyInfo."VAT Registration No.") = 11 then
            VATRegNo := CompanyInfo."Country/Region Code" + CompanyInfo."VAT Registration No."
        else
            VATRegNo := CompanyInfo."VAT Registration No.";

        PeriodStart := "VAT Entry".GetRangeMin("Posting Date");
        PeriodEnd := "VAT Entry".GetRangeMax("Posting Date");

        Calendar.Reset();
        Calendar.SetRange("Period Type", Calendar."Period Type"::Month);
        Calendar.SetRange("Period Start", PeriodStart);
        Calendar.SetRange("Period End", ClosingDate(PeriodEnd));
        if not Calendar.FindFirst() then
            Error(Text004, "VAT Entry".FieldCaption("Posting Date"), "VAT Entry".GetFilter("Posting Date"));

        if CreateXMLFile then
            CreateXMLDocument();
    end;

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        XMLDOMMgt: Codeunit "XML DOM Management";
        XMLCurrNode: DotNet XmlNode;
        XMLDoc: DotNet XmlDocument;
        NewChildNode: DotNet XmlNode;
        NewChildNode2: DotNet XmlNode;
        XMLFile: Text;
        Email: Text;
        ContactName: Text;
        PhoneNo: Text;
        Fax: Text;
        VATRegNo: Text;
        CustVATRegNo: Text;
        PrevVATRegNo: Text;
        CreateXMLFile: Boolean;
        Text001: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*', Comment = 'Only translate ''XML Files'' and ''All Files'' {Split=r"[\|\(]\*\.[^ |)]*[|) ]?"}';
        Text002: Label 'Export to XML File.';
        UseAmtsInAddCurr: Boolean;
        PeriodStart: Date;
        Text003: Label 'XML file successfully created.';
        Text004: Label '%1 filter %2 must be corrected, to run the report monthly.';
        LineNo: Integer;
        VATAmount: Decimal;
        Text005: Label 'Default.xml';
        VATAmountRTC: Decimal;
        XMLFileVisible: Boolean;
        XMLFileEnable: Boolean;
        AmountCaption: Text;
        VATAmountXML: Decimal;
        Text10800: Label 'Amount( %1)';
        Text10801: Label 'There is no data to export. No XML file is created.';
        CheckXMLLine: Boolean;
        Reserved_for_the_Authorities_CaptionLbl: Label '(Reserved for the Authorities)';
        French_Customs_and_ExciseCaptionLbl: Label 'French Customs and Excise';
        B_ServiceCaptionLbl: Label 'B.Service';
        EUROPEAN_DECLARATION_OF_SERVICESCaptionLbl: Label 'EUROPEAN DECLARATION OF SERVICES';
        French_Department_of_the_TreasuryCaptionLbl: Label 'French Department of the Treasury';
        A__Filling_PeriodCaptionLbl: Label 'A. Filling Period';
        DATE2DMY_PeriodStart_3_CaptionLbl: Label 'Year:';
        FORMAT_DATE2DMY_PeriodStart_2___0____Integer_2__Filler_Character_0___CaptionLbl: Label 'Month:';
        Date_name_and_signatureCaptionLbl: Label 'Date,name and signature';
        VATRegNoCaptionLbl: Label 'VAT Registration Number:';
        CompanyInfo_NameCaptionLbl: Label 'Company Name:';
        CompanyInfo_AddressCaptionLbl: Label 'Address:';
        City_and_Zip_CaptionLbl: Label 'City and Zip:';
        Contact_Person_CaptionLbl: Label 'Contact Person:';
        Phone_CaptionLbl: Label 'Phone:';
        EmailCaptionLbl: Label 'Email Address:';
        Fax_CaptionLbl: Label 'Fax:';
        C__Filled_By_CaptionLbl: Label 'C. Filled By:';
        V3CaptionLbl: Label '3';
        V2CaptionLbl: Label '2';
        V1CaptionLbl: Label '1';
        Customer_VAT_NumberCaptionLbl: Label 'Customer VAT Number';
        Line_NumberCaptionLbl: Label 'Line Number';

    [Scope('OnPrem')]
    procedure CreateXMLDocument()
    var
        XMLCurrNode2: DotNet XmlNode;
        ProcessingInstruction: DotNet XmlProcessingInstruction;
    begin
        XMLDoc := XMLDoc.XmlDocument();
        XMLCurrNode2 := XMLDoc.CreateElement('fichier_des');
        XMLDoc.AppendChild(XMLCurrNode2);
        XMLCurrNode := XMLDoc.CreateElement('declaration_des');
        XMLCurrNode2.AppendChild(XMLCurrNode);

        ProcessingInstruction := XMLDoc.CreateProcessingInstruction('xml', 'version="1.0" encoding="UTF-8"');

        XMLDOMMgt.AddElement(XMLCurrNode, 'num_des', '000001', '', NewChildNode);
        XMLDOMMgt.AddElement(XMLCurrNode, 'num_tvaFr', VATRegNo, '', NewChildNode);
        XMLDOMMgt.AddElement(XMLCurrNode, 'mois_des', Format(Date2DMY(PeriodStart, 2), 0, '<Integer,2><Filler Character,0>'), '', NewChildNode);
        XMLDOMMgt.AddElement(XMLCurrNode, 'an_des', Format(Date2DMY(PeriodStart, 3)), '', NewChildNode);
    end;

    [Scope('OnPrem')]
    procedure CreateXMLLine()
    begin
        CheckXMLLine := true;

        XMLDOMMgt.AddElement(XMLCurrNode, 'ligne_des', '', '', NewChildNode);
        XMLDOMMgt.AddElement(NewChildNode, 'numlin_des', Format(LineNo, 0, '<Integer,6><Filler Character,0>'), '', NewChildNode2);
        XMLDOMMgt.AddElement(NewChildNode, 'valeur', Format(VATAmountXML, 0, '<Sign><Integer>'), '', NewChildNode2);
        XMLDOMMgt.AddElement(NewChildNode, 'partner_des', PrevVATRegNo, '', NewChildNode2);
    end;

    local procedure PageUpdateRequestForm()
    begin
        CompanyInfo.Get();
        PhoneNo := CompanyInfo."Phone No.";
        Fax := CompanyInfo."Fax No.";
        Email := CompanyInfo."E-Mail";
        XMLFileVisible := false;
    end;
}

