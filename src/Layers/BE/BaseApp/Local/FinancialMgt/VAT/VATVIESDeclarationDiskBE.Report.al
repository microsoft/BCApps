// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

report 11315 "VAT-VIES Declaration Disk BE"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT-VIES Declaration Disk';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    AllowScheduling = false;

    dataset
    {
        dataitem(Cust; Customer)
        {
            DataItemTableView = sorting("VAT Registration No.") order(ascending);
            dataitem(VATloop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemTableView = sorting("Entry No.");
                    RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";

                    trigger OnAfterGetRecord()
                    begin
                        if (Base <> 0) and ("Bill-to/Pay-to No." <> '') then begin
                            TestField("Country/Region Code");
                            Country.Get("Country/Region Code");
                            if not Country.DetermineCountry("Country/Region Code") then
                                VATCustomer.TestField("VAT Registration No.");
                            Country.TestField("EU Country/Region Code");
                            No := No + 1;

                            VatAmount := Base * -1;

                            VatRepAmount := VatRepAmount + VatAmount;

                            Buffer2.Init();
                            Buffer2."Entry No." := No;
                            Buffer2."Country/Region Code" := Country."EU Country/Region Code";
                            Buffer2."VAT Registration No." :=
                              FormatBufferVATNo(Country."EU Country/Region Code", VATCustomer."VAT Registration No.");
                            Buffer2."EU 3-Party Trade" := "EU 3-Party Trade";
                            Buffer2.Year := '';
                            Buffer2."Month/Quarter" := '';
                            Buffer2.Amount := VatAmount;
                            Buffer2."EU Service" := "EU Service";
                            UpdateBuffer(Buffer2);
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey(Type, "Bill-to/Pay-to No.", "Country/Region Code", "EU 3-Party Trade", "VAT Reporting Date");
                        SetRange(Type, Type::Sale);
                        SetRange("Bill-to/Pay-to No.", VATCustomer."No.");
                        SetFilter("Country/Region Code", '<>%1', '');
                        SetRange("VAT Reporting Date", Vdatefrom, Vdateto);
                    end;
                }
                dataitem("VAT VIES Correction"; "VAT VIES Correction")
                {
                    DataItemTableView = sorting("Customer No.", "Period Type", "Declaration Period No.", "Declaration Period Year", "VAT Registration No.", "EU 3-Party Trade", "Correction Period Year", "Correction Period No.");

                    trigger OnAfterGetRecord()
                    begin
                        TestField("VAT Registration No.");
                        Country.Get("Country/Region Code");
                        Country.TestField("EU Country/Region Code");
                        No := No + 1;

                        VatAmount := Amount;
                        VatRepAmount := VatRepAmount + VatAmount;

                        Buffer2.Init();
                        Buffer2."Entry No." := No;
                        Country.Get("Country/Region Code");
                        Buffer2."Country/Region Code" := Country."EU Country/Region Code";
                        Buffer2."VAT Registration No." :=
                          FormatBufferVATNo(Country."EU Country/Region Code", VATCustomer."VAT Registration No.");
                        Buffer2."EU 3-Party Trade" := "EU 3-Party Trade";
                        if "Correction Period Year" = 0 then
                            Buffer2.Year := ''
                        else
                            Buffer2.Year := Format("Correction Period Year");
                        if "Correction Period No." = 0 then
                            Buffer2."Month/Quarter" := ''
                        else
                            Buffer2."Month/Quarter" := Format("Correction Period No.");
                        Buffer2.Amount := VatAmount;
                        Buffer2."EU Service" := "EU Service";
                        UpdateBuffer(Buffer2);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Customer No.", VATCustomer."No.");
                        if Choice = Choice::Month then
                            SetRange("Period Type", "VAT VIES Correction"."Period Type"::Month)
                        else
                            SetRange("Period Type", "VAT VIES Correction"."Period Type"::Quarter);
                        SetRange("Declaration Period No.", Vquarter);
                        SetRange("Declaration Period Year", Vyear);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if VATCustomer.Next() = 0 then
                        CurrReport.Break();
                    if VATCustomer.Mark() then
                        CurrReport.Skip();
                    VATCustomer.Mark(true);
                end;

                trigger OnPostDataItem()
                begin
                    RefreshBufferOnZeroBalance(Cust."Country/Region Code", Cust."VAT Registration No.");
                end;

                trigger OnPreDataItem()
                begin
                    VATCustomer."VAT Registration No." := '';
                    VATCustomer.SetCurrentKey("VAT Registration No.");
                    VATCustomer.SetRange("VAT Registration No.", Cust."VAT Registration No.");
                end;
            }

            trigger OnPreDataItem()
            begin
                if AddRepresentative then begin
                    Representative.Get(Identifier);
                    Representative.CheckCompletion();
                end;
            end;
        }
        dataitem("Create Intervat XML File"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                Result: Boolean;
            begin
                Result := CreateIntervatXML();
                if SilenceRun then
                    exit;

                if not Result then
                    Message(Text007);
            end;

            trigger OnPreDataItem()
            begin
                if Buffer.IsEmpty() then begin
                    Message(Text007);
                    CurrReport.Quit();
                end;
                InitializeXMLFile();
            end;
        }
    }

    requestpage
    {
        DeleteAllowed = false;
        InsertAllowed = false;
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Control1010000)
                    {
                        ShowCaption = false;
                        field(Choice; Choice)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Declaration type';
                            OptionCaption = 'Month,Quarter';
                            ToolTip = 'Specifies the type of declaration that you want to print. Options include Month and Quarter.';

                            trigger OnValidate()
                            begin
                                if Choice = Choice::Quarter then
                                    QuarterChoiceOnValidate();
                                if Choice = Choice::Month then
                                    MonthChoiceOnValidate();
                            end;
                        }
                        field(Vquarter; Vquarter)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Month or Quarter';
                            ToolTip = 'Specifies the month or quarter of the VAT declaration. If you select Month in the Declaration Type field, you must enter a value between 1 and 12 (1 = January, 2 = February, 3 = March, and so on). If you select Quarter, you must enter a value between 1 and 4 (1 = first quarter, 2 = second quarter, 3= third quarter, 4 = fourth quarter).';

                            trigger OnValidate()
                            begin
                                ValidateMonthQuarter();
                            end;
                        }
                        field(Vyear; Vyear)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Year';
                            ToolTip = 'Specifies the year of the period for which you want to print the report. You should enter the year as a 4 digit code. For example, to print a declaration for 2013, you should enter "2013" (instead of "13").';

                            trigger OnValidate()
                            begin
                                ValidateYear();
                            end;
                        }
                        field(TestDeclaration; TestDeclaration)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Test Declaration';
                            ToolTip = 'Specifies if you want to create a test declaration. If selected, an attribute test is written to the file that uses value 1, which indicates that this is a test file. If you want to test the XML file before sending it, you can upload this file to the Intervat site. The file is then validated without being stored on the server and you receive a notification if the file is valid. Also the unique sequence number in the XML file is not increased when a test declaration is created, which means that you can create as many internal test declarations as you want.';
                        }
                    }
                    group("&Representative")
                    {
                        Caption = '&Representative';
                        field(AddRepresentative; AddRepresentative)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Add Representative';
                            ToolTip = 'Specifies if you want to add a VAT declaration representative. A representative is a person or an agency that has license to make a VAT declaration.';

                            trigger OnValidate()
                            begin
                                SetRepresentativeEnabled();
                            end;
                        }
                        field(ID; Identifier)
                        {
                            ApplicationArea = Basic, Suite;
                            Enabled = IDEnable;
                            TableRelation = Representative;
                            ToolTip = 'Specifies the ID of the representative who is responsible for making the VAT declaration.';
                        }
                    }
                    label(Control1010025)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19039936;
                        ShowCaption = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            IDEnable := true;
        end;

        trigger OnOpenPage()
        begin
            SetRepresentativeEnabled();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        CompanyInformation.Get();
        if not CheckVatNo.MOD97Check(CompanyInformation."Enterprise No.") then
            Error(Text000);
        CompanyInformation.TestField("Country/Region Code");
    end;

    trigger OnPostReport()
    begin
        Vfile.Close();

        if FileName = '' then
            FileManagement.DownloadHandler(ServerFileName, '', '', FileManagement.GetToFilterText('', ServerFileName), ClientFileNameTxt)
        else
            FileManagement.CopyServerFile(ServerFileName, FileName, true);
        FileManagement.DeleteServerFile(ServerFileName);
    end;

    trigger OnPreReport()
    begin
        if "VAT Entry".GetFilter("VAT Reporting Date") <> '' then
            Error(Text013, "VAT Entry".FieldCaption("VAT Reporting Date"));

        ValidateMonthQuarter();
        ValidateYear();

        if not AddRepresentative then
            INTERVATHelper.VerifyCpyInfoEmailExists();

        if Choice = Choice::Quarter then begin
            Vdatefrom := DMY2Date(1, (Vquarter * 3) - 2, Vyear);
            Vdateto := CalcDate('<+CQ>', Vdatefrom);
        end else begin
            Vdatefrom := DMY2Date(1, Vquarter, Vyear);
            Vdateto := CalcDate('<+CM>', Vdatefrom);
        end;

        Clear(Vfile);
        Vfile.TextMode := true;
        Vfile.WriteMode := true;
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        Vfile.Create(ServerFileName);

        Vfile.CreateOutStream(OutS);
    end;

    var
        Text000: Label 'Enterprise number in the Company Information table is not valid.';
        Text002: Label 'Quarter must be between 1 and 4.';
        Text003: Label 'Year must be between 1997 and 2050.';
        Text007: Label 'Problem when creating Intervat XML File.';
        CompanyInformation: Record "Company Information";
        Country: Record "Country/Region";
        VATCustomer: Record Customer;
        Buffer: Record "VAT Entry" temporary;
        Buffer2: Record "VAT Entry";
        Representative: Record Representative;
        CheckVatNo: Codeunit VATLogicalTests;
        FileManagement: Codeunit "File Management";
        INTERVATHelper: Codeunit "INTERVAT Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        Vfile: File;
        OutS: OutStream;
        No: Integer;
        Vquarter: Integer;
        Vyear: Integer;
        VatAmount: Decimal;
        VatRepAmount: Decimal;
        FileName: Text;
        DocNameSpace: Text[50];
        ServerFileName: Text;
        Choice: Option Month,Quarter;
        TestDeclaration: Boolean;
        RefreshSequenceNumber: Boolean;
        SilenceRun: Boolean;
        AddRepresentative: Boolean;
        Vdatefrom: Date;
        Vdateto: Date;
        Text011: Label 'Month must be between 1 and 12.';
        Text012: Label 'The VAT Vies corrections for %1 %2 %3 already exists. Are you sure that you want to continue?', Comment = 'Parameter 1 - period type (month or quarter), 2 - period number, 3 - year.';
        Text013: Label '%1 filter can only be specified in the Options tab.';
        IDEnable: Boolean;
        Text19039936: Label 'The report generates a XML file according to the INTERVAT 8.0 schema defined by the Belgium tax authority.';
        Identifier: Text[20];
        ClientFileNameTxt: Label 'Intervat.xml', Locked = true;

    local procedure FormatVATNo(CountryCode: Code[10]; Vatno: Text[30]) FormattedVATNo: Text[50]
    begin
        if StrPos(Vatno, CountryCode) = 1 then
            Vatno := CopyStr(Vatno, StrLen(CountryCode) + 1);

        FormattedVATNo := DelChr(Vatno, '=', ' .-');
    end;

    local procedure FormatBufferVATNo(CountryCode: Code[10]; VatNo: Text[30]): Text[20]
    begin
        exit(DelChr(FormatVATNo(CountryCode, VatNo), '=', '.,/- '));
    end;

    local procedure UpdateBuffer(Buffer2: Record "VAT Entry")
    begin
        Buffer.SetCurrentKey("Country/Region Code",
          "VAT Registration No.",
          "EU 3-Party Trade",
          Year,
          "Month/Quarter");
        Buffer.SetRange("Country/Region Code", Buffer2."Country/Region Code");
        Buffer.SetRange("VAT Registration No.", Buffer2."VAT Registration No.");
        Buffer.SetRange("EU Service", Buffer2."EU Service");
        if not Buffer2."EU Service" then
            Buffer.SetRange("EU 3-Party Trade", Buffer2."EU 3-Party Trade");
        Buffer.SetRange(Year, Buffer2.Year);
        Buffer.SetRange("Month/Quarter", Buffer2."Month/Quarter");

        if Buffer.FindFirst() then begin
            Buffer.Amount := Buffer.Amount + Buffer2.Amount;
            if Buffer.Amount = 0 then
                Buffer.Delete()
            else
                Buffer.Modify();
        end else begin
            Buffer.Init();
            Buffer."Entry No." := Buffer2."Entry No.";
            Buffer."Country/Region Code" := Buffer2."Country/Region Code";
            Buffer."VAT Registration No." := Buffer2."VAT Registration No.";
            if not Buffer2."EU Service" then
                Buffer."EU 3-Party Trade" := Buffer2."EU 3-Party Trade";
            Buffer.Year := Buffer2.Year;
            Buffer."Month/Quarter" := Buffer2."Month/Quarter";
            Buffer.Amount := Buffer2.Amount;
            Buffer."EU Service" := Buffer2."EU Service";
            Buffer.Insert();
        end;

        Buffer.Reset();
    end;

    local procedure InitializeXMLFile()
    begin
    end;

    local procedure CreateIntervatXML(): Boolean
    var
        XMLDocOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLFirstNode: DotNet XmlNode;
    begin
        RefreshSequenceNumber := true;
        Country.Get(CompanyInformation."Country/Region Code");

        XMLDOMMgt.LoadXMLDocumentFromText('<IntraConsignment/>', XMLDocOut);
        XMLCurrNode := XMLDocOut.DocumentElement;
        XMLFirstNode := XMLCurrNode;

        INTERVATHelper.AddProcessingInstruction(XMLDocOut, XMLFirstNode);

        AddHeader(XMLCurrNode);

        if AddRepresentative then begin
            Representative.AddRepresentativeElement(XMLCurrNode, DocNameSpace, GetSequenceNumber());
            XMLCurrNode := XMLCurrNode.ParentNode;
        end;

        AddIntraListing(XMLCurrNode);

        XMLDocOut.Save(OutS);

        exit(true);
    end;

    local procedure ValidateMonthQuarter()
    begin
        if Choice = Choice::Quarter then begin
            if not (Vquarter in [1 .. 4]) then
                Error(Text002);
        end else
            if not (Vquarter in [1 .. 12]) then
                Error(Text011);
    end;

    local procedure ValidateYear()
    begin
        if not (Vyear in [1997 .. 2050]) then
            Error(Text003);
    end;

    local procedure SetRepresentativeEnabled()
    begin
        PageSetRepresentativeEnabled();
    end;

    local procedure GetSequenceNumber(): Integer
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if RefreshSequenceNumber or TestDeclaration then begin
            CompanyInformation."XML Seq. No. EU Sales List" := CompanyInformation."XML Seq. No. EU Sales List" + 1;
            if CompanyInformation."XML Seq. No. EU Sales List" > 9999 then
                CompanyInformation."XML Seq. No. EU Sales List" := 1;
            if not TestDeclaration then
                CompanyInformation.Modify();
            RefreshSequenceNumber := false;
        end;

        exit(CompanyInformation."XML Seq. No. EU Sales List");
    end;

    local procedure AddHeader(XMLCurrNode: DotNet XmlNode)
    begin
        DocNameSpace := 'http://www.minfin.fgov.be/IntraConsignment';
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'IntraListingsNbr', '1');
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns', DocNameSpace);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:common', 'http://www.minfin.fgov.be/InputCommon');
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');

        XMLDOMMgt.AddNameSpacePrefixedAttribute(
          XMLCurrNode.OwnerDocument, XMLCurrNode,
          'http://www.w3.org/2001/XMLSchema-instance',
          'schemaLocation',
          DocNameSpace + ' NewICO-in_v0_7.xsd');
    end;

    local procedure AddIntraListing(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
        CustSequenceNum: Integer;
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'IntraListing', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'SequenceNumber', '1');
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'ClientsNbr', Format(Buffer.Count));
        INTERVATHelper.AddElementDeclarant(XMLCurrNode, GetSequenceNumber());
        XMLCurrNode := XMLCurrNode.ParentNode;

        Buffer.CalcSums(Amount);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'AmountSum', INTERVATHelper.GetXMLAmountRepresentation(Buffer.Amount));

        INTERVATHelper.AddElementPeriod(XMLCurrNode, Choice, Vquarter, Vyear, '');
        XMLCurrNode := XMLCurrNode.ParentNode;

        if Buffer.FindSet(true, false) then
            repeat
                CustSequenceNum := CustSequenceNum + 1;
                AddCustomersList(XMLCurrNode, CustSequenceNum);
                XMLCurrNode := XMLCurrNode.ParentNode;
            until Buffer.Next() = 0;
    end;

    local procedure AddCustomersList(XMLCurrNode: DotNet XmlNode; CustSequenceNum: Integer)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'IntraClient', '', DocNameSpace, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'SequenceNumber', Format(CustSequenceNum));

        XMLDOMMgt.AddElement(XMLCurrNode, 'CompanyVATNumber', Buffer."VAT Registration No.", DocNameSpace, XMLNewChild);
        XMLDOMMgt.AddAttribute(XMLNewChild, 'issuedBy', Buffer."Country/Region Code");

        XMLDOMMgt.AddElement(XMLCurrNode, 'Code', GetLetterForCodeElement(Buffer), DocNameSpace, XMLNewChild);

        XMLDOMMgt.AddElement(
          XMLCurrNode, 'Amount', INTERVATHelper.GetXMLAmountRepresentation(Buffer.Amount), DocNameSpace, XMLNewChild);

        if Buffer.Year <> '' then
            INTERVATHelper.AddElementPeriod(XMLCurrNode, Choice, Vquarter, Vyear, 'CorrectingPeriod');
    end;

    local procedure GetLetterForCodeElement(TempVATEntryBuffer: Record "VAT Entry" temporary): Text[1]
    begin
        case true of
            TempVATEntryBuffer."EU Service":
                exit('S');
            TempVATEntryBuffer."EU 3-Party Trade":
                exit('T');
            else
                exit('L');
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewChoicePeriodType: Integer; NewVPeriod: Integer; NewVyear: Integer; NewFileName: Text[1024])
    begin
        Choice := NewChoicePeriodType;
        Vquarter := NewVPeriod;
        Vyear := NewVyear;
        FileName := NewFileName;
        SilenceRun := true;
    end;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure InitializeRepresentative(NewAddRepresentative: Boolean)
    begin
        AddRepresentative := NewAddRepresentative;
    end;

    local procedure ValidateVATViesCorrection(ChoiceForValidation: Option Month,Quarter)
    var
        VATVIESCorrection: Record "VAT VIES Correction";
    begin
        if ChoiceForValidation = Choice::Month then
            VATVIESCorrection.SetRange("Period Type", VATVIESCorrection."Period Type"::Month)
        else
            VATVIESCorrection.SetRange("Period Type", VATVIESCorrection."Period Type"::Quarter);

        if VATVIESCorrection.FindFirst() then
            if not Confirm(Text012, true, ChoiceForValidation, Vquarter, Vyear) then
                Error('');
    end;

    local procedure PageSetRepresentativeEnabled()
    begin
        IDEnable := AddRepresentative;
    end;

    local procedure MonthChoiceOnValidate()
    begin
        ValidateVATViesCorrection(Choice::Quarter);
    end;

    local procedure QuarterChoiceOnValidate()
    begin
        ValidateVATViesCorrection(Choice::Month);
    end;

    local procedure RefreshBufferOnZeroBalance(CountryRegionCode: Code[10]; VATRegistrationNo: Code[20])
    begin
        Buffer.SetRange("VAT Registration No.", FormatBufferVATNo(GetEUCountryRegionCode(CountryRegionCode), VATRegistrationNo));
        Buffer.CalcSums(Amount);
        if Buffer.Amount = 0 then
            Buffer.DeleteAll();
        Buffer.SetRange("VAT Registration No.");
    end;

    local procedure GetEUCountryRegionCode(CountryRegionCode: Code[10]): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegionCode = '' then begin
            CompanyInformation.Get();
            CountryRegionCode := CompanyInformation."Country/Region Code";
        end;

        CountryRegion.Get(CountryRegionCode);
        exit(CountryRegion."EU Country/Region Code");
    end;
}

