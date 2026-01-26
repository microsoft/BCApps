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
using Microsoft.Sales.Receivables;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

report 11309 "VAT Annual Listing - Disk"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Annual Listing - Disk';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    AllowScheduling = false;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("Country/Region Code") where("VAT Liable" = const(true));
            dataitem(VATloop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem("VAT Entry"; "VAT Entry")
                {
                    DataItemTableView = sorting("Entry No.");

                    trigger OnAfterGetRecord()
                    var
                        CrMemoCustLedgerEntry: Record "Cust. Ledger Entry";
                        TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
                        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
                        IsCreditMemo: Boolean;
                    begin
                        WBase := WBase + Base;
                        WAmount := WAmount + Amount;
                        IsCreditMemo := (Base > 0);

                        if IsCreditMemoWithAppliedInvoice then
                            CurrReport.Skip();

                        if IsCreditMemo then begin
                            CrMemoCustLedgerEntry.SetRange("Document Type", "Document Type");
                            CrMemoCustLedgerEntry.SetRange("Document No.", "Document No.");
                            CrMemoCustLedgerEntry.SetRange("Posting Date", "Posting Date");
                            CrMemoCustLedgerEntry.SetRange("Customer No.", "Bill-to/Pay-to No.");
                            if CrMemoCustLedgerEntry.FindFirst() then begin
                                CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempAppliedCustLedgerEntry, CrMemoCustLedgerEntry."Entry No.");
                                TempAppliedCustLedgerEntry.SetRange("Posting Date", 0D, DMY2Date(31, 12, PreviousYear));
                                if not TempAppliedCustLedgerEntry.IsEmpty() then
                                    IsCreditMemoWithAppliedInvoice := true;
                            end;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetCurrentKey(Type, "Bill-to/Pay-to No.", "Country/Region Code", "EU 3-Party Trade", "VAT Reporting Date");
                        SetRange(Type, Type::Sale);
                        SetRange("Bill-to/Pay-to No.", VATCustomer."No.");
                        SetRange("VAT Reporting Date", DMY2Date(1, 1, VYear), DMY2Date(31, 12, VYear));
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if VATCustomer.Next() = 0 then
                        CurrReport.Break();
                    if VATCustomer.Mark() then
                        CurrReport.Skip();
                    if not CheckVatNo.MOD97Check(VATCustomer."Enterprise No.") then
                        CurrReport.Skip();
                    VATCustomer.Mark(true);
                end;

                trigger OnPreDataItem()
                var
                    i: Integer;
                begin
                    VATCustomer."Enterprise No." := '';
                    VATCustomer.SetCurrentKey("Enterprise No.");

                    VatRegNoFilter := '*';

                    for i := 1 to StrLen(Customer."Enterprise No.") do
                        if Customer."Enterprise No."[i] in ['a' .. 'z', 'A' .. 'Z', '0' .. '9'] then
                            VatRegNoFilter := VatRegNoFilter + CopyStr(Customer."Enterprise No.", i, 1) + '*';
                    VATCustomer.SetFilter("Enterprise No.", VatRegNoFilter);

                    if IncludeCountry = IncludeCountry::Specific then
                        VATCustomer.SetRange("Country/Region Code", Country);
                end;
            }
            dataitem(Vatloop2; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                var
                    Country2: Record "Country/Region";
                    i: Integer;
                    EnterpriseNo: Text[50];
                begin
                    i := Buffer.Count + 1;
                    EnterpriseNo := DelChr(Customer."Enterprise No.", '=', DelChr(Customer."Enterprise No.", '=', '0123456789'));
                    EnterpriseNoExistInBuffer := IsEnterpriseNoExistInBuffer(EnterpriseNo);

                    if ((IsCustBalanceGreaterThanMinimum() and IsCustVATAmountNotZero()) or IsCreditMemoWithAppliedInvoice) and
                       not EnterpriseNoExistInBuffer then begin
                        Buffer.Init();
                        Buffer."Entry No." := i;
                        Buffer."Enterprise No." := EnterpriseNo;
                        Country2.Get(Customer."Country/Region Code");
                        Buffer."Country/Region Code" := Country2."ISO Code";
                        Buffer.Base := -WBase;
                        Buffer.Amount := -WAmount;
                        Buffer.Insert();
                    end;
                    if EnterpriseNoExistInBuffer then
                        AddVatAmountToSimilarEnterpriseNo();

                    Buffer.Reset();
                end;

                trigger OnPostDataItem()
                begin
                    if ((IsCustBalanceGreaterThanMinimum() and IsCustVATAmountNotZero()) or IsCreditMemoWithAppliedInvoice) and
                       not EnterpriseNoExistInBuffer then begin
                        WTotBase2 := WTotBase2 + Buffer.Base;
                        WTotAmount2 := WTotAmount2 + Buffer.Amount;
                    end;
                    if EnterpriseNoExistInBuffer then begin
                        WTotBase2 := WTotBase2 - WBase;
                        WTotAmount2 := WTotAmount2 - WAmount;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not CheckVatNo.MOD97Check("Enterprise No.") then
                    CurrReport.Skip();

                Clear(WBase);
                Clear(WAmount);
                IsCreditMemoWithAppliedInvoice := false;
            end;

            trigger OnPreDataItem()
            begin
                if AddRepresentative then begin
                    Representative.Get(Identifier);
                    Representative.CheckCompletion();
                end;

                if IncludeCountry = IncludeCountry::Specific then
                    SetRange("Country/Region Code", Country);
            end;
        }
        dataitem("Create Intervat XML File"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            var
                RunResults: Boolean;
            begin
                RunResults := CreateIntervatXML();

                if SilenceRun and RunResults then
                    exit;

                if not RunResults then
                    Error(Text004);
            end;

            trigger OnPreDataItem()
            begin
                if Buffer.IsEmpty() then begin
                    Message(Text009);
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
                    group(Control1010020)
                    {
                        ShowCaption = false;
                        field(VYear; VYear)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Year';
                            NotBlank = true;
                            ToolTip = 'Specifies the year of the period for which you want to print the report. You should enter the year as a 4 digit code. For example, to print a declaration for 2013, you should enter "2013" (instead of "13").';

                            trigger OnValidate()
                            begin
                                if not (VYear in [1997 .. 2050]) then
                                    Error(Text002);
                            end;
                        }
                        field(Minimum; Minimum)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Minimum Amount';
                            ToolTip = 'Specifies the minimum customer''s year balance to be included in the report. If the yearly balance of the customer is smaller than the minimum amount (and there are no negative entries), the customer will not be included in the declaration.';
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
                    group("Country/Region")
                    {
                        Caption = 'Country/Region';
                        field(IncludeCountry; IncludeCountry)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Include Customers From';
                            OptionCaption = 'All Countries/Regions,Specific Country/Region';
                            ToolTip = 'Specifies whether to include customers from all countries/regions or from a specific country/region in the report.';
                        }
                        field(Country; Country)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Country/Region';
                            TableRelation = "Country/Region";
                            ToolTip = 'Specifies the country/region to include in the report.';
                        }
                    }
                    label(Control1010019)
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
            if VYear = 0 then
                VYear := Date2DMY(WorkDate(), 3);
            SetRepresentativeEnabled();

            IncludeCountry := IncludeCountry::Specific;
            Country := INTERVATHelper.GetCpyInfoCountryRegionCode();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if not CheckVatNo.MOD97Check(CompanyInformation."Enterprise No.") then
            Error(Text000, CompanyInformation.FieldCaption("Enterprise No."), CompanyInformation.TableCaption());
        CompanyInformation.TestField("Country/Region Code");
    end;

    trigger OnPreReport()
    begin
        if not AddRepresentative then
            INTERVATHelper.VerifyCpyInfoEmailExists();
        PreviousYear := VYear - 1;
    end;

    var
        Text000: Label '%1 in table %2 is not valid.';
        Text002: Label 'Year must be between 1997 and 2050.';
        Text004: Label 'Problem when creating Intervat XML File.';
        VATCustomer: Record Customer;
        Buffer: Record "VAT Entry" temporary;
        Representative: Record Representative;
        CheckVatNo: Codeunit VATLogicalTests;
        INTERVATHelper: Codeunit "INTERVAT Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        WBase: Decimal;
        WAmount: Decimal;
        WTotBase2: Decimal;
        WTotAmount2: Decimal;
        Text009: Label 'No annual sales to export.';
        Minimum: Decimal;
        SilenceRun: Boolean;
        TestDeclaration: Boolean;
        AddRepresentative: Boolean;
        RefreshClientListingsNbr: Boolean;
        FileName: Text;
        VatRegNoFilter: Text[250];
        xmlnsCommon: Text[250];
        xmlnsClientListingConsignment: Text[250];
        VYear: Integer;
        IDEnable: Boolean;
        Text19039936: Label 'The report generates a XML file according to the INTERVAT 8.0 schema defined by the Belgium tax authority.';
        Identifier: Text[20];
        IncludeCountry: Option All,Specific;
        Country: Code[10];
        ClientFileNameTxt: Label 'Intervat.xml', Locked = true;
        IsCreditMemoWithAppliedInvoice: Boolean;
        PreviousYear: Integer;
        EnterpriseNoExistInBuffer: Boolean;

    local procedure InitializeXMLFile()
    begin
    end;

    local procedure CreateIntervatXML() ReturnValue: Boolean
    var
        FileManagement: Codeunit "File Management";
        XMLDocOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        XMLFirstNode: DotNet XmlNode;
        ServerFileName: Text;
    begin
        ReturnValue := false;
        RefreshClientListingsNbr := true;

        XMLDOMMgt.LoadXMLDocumentFromText('<ClientListingConsignment/>', XMLDocOut);
        XMLCurrNode := XMLDocOut.DocumentElement;
        INTERVATHelper.AddProcessingInstruction(XMLDocOut, XMLCurrNode);

        AddHeader(XMLCurrNode);
        XMLFirstNode := XMLCurrNode;

        if AddRepresentative then begin
            Representative.AddRepresentativeElement(XMLCurrNode, xmlnsClientListingConsignment, GetClientListingsNbr());
            XMLCurrNode := XMLFirstNode;
        end;

        AddClientListing(XMLCurrNode);

        ServerFileName := FileManagement.ServerTempFileName('.xml');
        XMLDocOut.Save(ServerFileName);
        if FileName = '' then
            FileManagement.DownloadHandler(ServerFileName, '', '', FileManagement.GetToFilterText('', ServerFileName), ClientFileNameTxt)
        else
            FileManagement.CopyServerFile(ServerFileName, FileName, true);
        FileManagement.DeleteServerFile(ServerFileName);

        ReturnValue := true;
    end;

    local procedure AddClientListing(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
        BaseAmount: Text[100];
        VatAmount: Text[100];
    begin
        XMLDOMMgt.AddElement(XMLCurrNode, 'ClientListing', '', xmlnsClientListingConsignment, XMLNewChild);
        XMLCurrNode := XMLNewChild;

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'SequenceNumber', '1');

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'ClientsNbr', Format(Buffer.Count));
        GetAmounts(BaseAmount, VatAmount);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'TurnOverSum', BaseAmount);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'VATAmountSum', VatAmount);

        INTERVATHelper.AddElementDeclarant(XMLCurrNode, GetClientListingsNbr());
        XMLCurrNode := XMLCurrNode.ParentNode;

        XMLDOMMgt.AddElement(XMLCurrNode, 'Period', Format(VYear), xmlnsClientListingConsignment, XMLNewChild);

        AddClientsList(XMLCurrNode);
    end;

    local procedure AddClientsList(XMLCurrNode: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
        CustSequenceNum: Integer;
    begin
        if Buffer.FindSet(true, false) then
            repeat
                CustSequenceNum := CustSequenceNum + 1;
                XMLDOMMgt.AddElement(XMLCurrNode, 'Client', '', xmlnsClientListingConsignment, XMLNewChild);
                XMLDOMMgt.AddAttribute(XMLNewChild, 'SequenceNumber', Format(CustSequenceNum));
                XMLCurrNode := XMLNewChild;
                XMLDOMMgt.AddElement(XMLCurrNode, 'CompanyVATNumber', Buffer."Enterprise No.", xmlnsClientListingConsignment, XMLNewChild);
                XMLDOMMgt.AddAttribute(XMLNewChild, 'issuedBy', Buffer."Country/Region Code");
                XMLDOMMgt.AddElement(XMLCurrNode, 'TurnOver', INTERVATHelper.GetXMLAmountRepresentation(Buffer.Base),
                  xmlnsClientListingConsignment, XMLNewChild);
                XMLDOMMgt.AddElement(XMLCurrNode, 'VATAmount', INTERVATHelper.GetXMLAmountRepresentation(Buffer.Amount),
                  xmlnsClientListingConsignment, XMLNewChild);
                XMLCurrNode := XMLCurrNode.ParentNode;
            until Buffer.Next() = 0;
    end;

    local procedure AddHeader(var XMLCurrNode: DotNet XmlNode)
    begin
        xmlnsCommon := 'http://www.minfin.fgov.be/InputCommon';
        xmlnsClientListingConsignment := 'http://www.minfin.fgov.be/ClientListingConsignment';

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'ClientListingsNbr', '1');

        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns', 'http://www.minfin.fgov.be/VatList'); // DocNameSpace
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns', xmlnsClientListingConsignment);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:common', xmlnsCommon);
        XMLDOMMgt.AddAttribute(XMLCurrNode, 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');

        XMLDOMMgt.AddNameSpacePrefixedAttribute(
          XMLCurrNode.OwnerDocument, XMLCurrNode,
          'http://www.w3.org/2001/XMLSchema-instance',
          'schemaLocation',
          xmlnsClientListingConsignment + ' NewLK-in_v0_7.xsd');
    end;

    local procedure GetAmounts(var BaseAmount: Text[100]; var VATAmount: Text[100])
    begin
        BaseAmount := INTERVATHelper.GetXMLAmountRepresentation(WTotBase2);
        VATAmount := INTERVATHelper.GetXMLAmountRepresentation(WTotAmount2);
    end;

    [Scope('OnPrem')]
    procedure InitializeRepresentative(NewAddRepresentative: Boolean)
    begin
        AddRepresentative := NewAddRepresentative;
    end;

    local procedure GetClientListingsNbr(): Integer
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if RefreshClientListingsNbr or TestDeclaration then begin
            CompanyInformation."XML Seq. No. Annual Listing" := CompanyInformation."XML Seq. No. Annual Listing" + 1;
            if CompanyInformation."XML Seq. No. Annual Listing" > 9999 then
                CompanyInformation."XML Seq. No. Annual Listing" := 1;

            if not TestDeclaration then
                CompanyInformation.Modify();

            RefreshClientListingsNbr := false;
        end;

        exit(CompanyInformation."XML Seq. No. Annual Listing");
    end;

    [Scope('OnPrem')]
    procedure SetFileName(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure SetRepresentativeEnabled()
    begin
        PageSetRepresentativeEnabled();
    end;

    local procedure IsCustBalanceGreaterThanMinimum(): Boolean
    begin
        exit(-WBase >= Minimum);
    end;

    local procedure PageSetRepresentativeEnabled()
    begin
        IDEnable := AddRepresentative;
    end;

    local procedure IsCustVATAmountNotZero(): Boolean
    begin
        exit(WBase <> 0);
    end;

    local procedure IsEnterpriseNoExistInBuffer(EnterpriseNo: Text[50]): Boolean
    begin
        Buffer.Reset();
        Buffer.SetRange("Enterprise No.", EnterpriseNo);
        if Buffer.IsEmpty then
            exit(false);

        exit(true);
    end;

    local procedure AddVatAmountToSimilarEnterpriseNo()
    begin
        Buffer.FindFirst();
        Buffer.Base := Buffer.Base - WBase;
        Buffer.Amount := Buffer.Amount - WAmount;
        Buffer.Modify();
    end;
}

