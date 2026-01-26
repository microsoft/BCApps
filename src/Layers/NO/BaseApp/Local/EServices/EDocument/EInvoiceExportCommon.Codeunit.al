// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Peppol;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

codeunit 10628 "E-Invoice Export Common"
{

    trigger OnRun()
    begin
    end;

    var
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
        CBCTxt: Label 'cbc', Locked = true;
        CACTxt: Label 'cac', Locked = true;
        BasicCompSpaceNameTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', Locked = true;
        AggregateCompSpaceNameTxt: Label 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2', Locked = true;
        XMLDOMMgt: Codeunit "XML DOM Management";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        XMLCurrNode: DotNet XmlNode;
        XMLdocOut: DotNet XmlDocument;
        XMLRootNode: DotNet XmlNode;
        UBLVersionID: Code[3];
        EInvoiceDocumentsTxt: Label 'Documents';
        NoCategoryMatchesVATPercentErr: Label 'The VAT percentage %1 does not match the percentage specified for any VAT categories.', Comment = '%1 is the VAT percentage.';
        IbanEmptyAndNoOtherPaymentMeansErr: Label 'No payment means are available for this invoice. You must specify an IBAN.';
        ReverseChargeNotAuthorizedErr: Label 'Reverse Charge tax category (K) is not part of the UNCL 5303 code list BII2 subset (rule CL-T10-R007).';

    [Scope('OnPrem')]
    procedure CreateDocAndRootNode()
    var
        Header: Text[1000];
    begin
        Header := '<?xml version="1.0" encoding="UTF-8"?> ' +
          '<' + TempEInvoiceExportHeader."Schema Name" + ' xsi:schemaLocation="' + TempEInvoiceExportHeader."Schema Location" + '" ' +
          'xmlns="' + TempEInvoiceExportHeader.xmlns + '" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ';
        if TempEInvoiceExportHeader."Uses Common Aggregate Comp." then
            Header += 'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ';
        if TempEInvoiceExportHeader."Uses Common Basic Comp." then
            Header += 'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ';
        if TempEInvoiceExportHeader."Uses Common Extension Comp." then
            Header += 'xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ';
        Header += '/>';

        XMLDOMMgt.LoadXMLDocumentFromText(Header, XMLdocOut);
        XMLCurrNode := XMLdocOut.DocumentElement;
        XMLRootNode := XMLCurrNode;
        UBLVersionID := GetUBLVersionID();
    end;

    [Scope('OnPrem')]
    procedure CreateLineNode(TempEInvExportLine: Record "E-Invoice Export Line" temporary)
    begin
        TempEInvoiceExportLine := TempEInvExportLine;
        XMLCurrNode := XMLRootNode; // Ensure that line nodes are always added to the root.

        // Header->Line
        AddGroupNode(XMLCurrNode, TempEInvoiceExportHeader."Schema Name" + 'Line', AggregateCompSpaceNameTxt, CACTxt);
        AddNotEmptyNode(XMLCurrNode, 'ID', Format(TempEInvoiceExportLine."Line No."), BasicCompSpaceNameTxt, CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure SaveToXML(var TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary; Path: Text[250]; FileName: Text[250])
    var
        FileMgt: Codeunit "File Management";
    begin
        TempEInvoiceTransferFile."Server Temp File Name" := CopyStr(FileMgt.ServerTempFileName('xml'), 1, 250);
        TempEInvoiceTransferFile."Local File Name" := StrSubstNo('%1.xml', FileName);
        TempEInvoiceTransferFile."Local Path" := DelChr(Path, '>', '\');
        XMLdocOut.Save(TempEInvoiceTransferFile."Server Temp File Name");
    end;

    [Scope('OnPrem')]
    procedure DownloadEInvoiceFile(var TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary)
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        ServerTempFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        ToFile: Text;
    begin
        TempEInvoiceTransferFile.FindSet();
        DataCompression.CreateZipArchive();
        repeat
            FileManagement.BLOBImportFromServerFile(TempBlob, TempEInvoiceTransferFile."Server Temp File Name");
            TempBlob.CreateInStream(ServerTempFileInStream);
            DataCompression.AddEntry(ServerTempFileInStream, TempEInvoiceTransferFile."Local File Name");
        until TempEInvoiceTransferFile.Next() = 0;
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        ToFile := StrSubstNo('%1.zip', EInvoiceDocumentsTxt);
        DownloadFromStream(ZipInStream, '', '', '', ToFile);
    end;

    [Scope('OnPrem')]
    procedure SetEInvoiceCommonTables(TempEInvoiceExportHeaderValue: Record "E-Invoice Export Header" temporary; var TempEInvoiceExportLineValue: Record "E-Invoice Export Line" temporary)
    begin
        TempEInvoiceExportHeader := TempEInvoiceExportHeaderValue;
        TempEInvoiceExportLine.Copy(TempEInvoiceExportLineValue, true);
    end;

    [Scope('OnPrem')]
    procedure AddHeaderAccountingCustomerParty()
    var
        Customer: Record Customer;
    begin
        AddGroupNode(XMLCurrNode, 'AccountingCustomerParty', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNode(XMLCurrNode, 'Party', AggregateCompSpaceNameTxt, CACTxt);

        if UBLVersionID <> '2.1' then
            if TempEInvoiceExportHeader."VAT Registration No." <> '' then
                AddGroupNodeIDVAT(
                  XMLCurrNode, 'EndpointID', EInvoiceDocumentEncode.GetVATRegNo(TempEInvoiceExportHeader."VAT Registration No.", false),
                  BasicCompSpaceNameTxt, CBCTxt)
            else
                AddGroupNodeIDGLN(XMLCurrNode, 'EndpointID', '9908:' + TempEInvoiceExportHeader.GLN, BasicCompSpaceNameTxt, CBCTxt)
        else
            if Customer.Get(TempEInvoiceExportHeader."Bill-to Customer No.") and
               (Customer."VAT Registration No." <> '')
            then
                AddGroupNodeIDVAT(
                  XMLCurrNode, 'EndpointID', EInvoiceDocumentEncode.GetVATRegNo(Customer."VAT Registration No.", false),
                  BasicCompSpaceNameTxt, CBCTxt);

        // Header->AccountingCustomerParty->Party->PartyIdentification
        if (UBLVersionID = '2.1') and (TempEInvoiceExportHeader.GLN <> '') then begin
            AddGroupNode(XMLCurrNode, 'PartyIdentification', AggregateCompSpaceNameTxt, CACTxt);
            AddGroupNodeWithData(XMLCurrNode, 'ID', TempEInvoiceExportHeader.GLN, BasicCompSpaceNameTxt, CBCTxt);
            AddAttribute(XMLCurrNode, 'schemeID', 'GLN');
            XMLCurrNode := XMLCurrNode.ParentNode();
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;
        if UBLVersionID = '2.0' then begin
            AddGroupNode(XMLCurrNode, 'PartyIdentification', AggregateCompSpaceNameTxt, CACTxt);
            AddLastNode(XMLCurrNode, 'ID', TempEInvoiceExportHeader."Bill-to Customer No.", BasicCompSpaceNameTxt, CBCTxt);
        end;

        // Header->AccountingCustomerParty->Party->PartyName
        AddGroupNode(XMLCurrNode, 'PartyName', AggregateCompSpaceNameTxt, CACTxt);
        AddLastNode(XMLCurrNode, 'Name', TempEInvoiceExportHeader."Bill-to Name", BasicCompSpaceNameTxt, CBCTxt);

        // Header->AccountingCustomerParty->Party->PostalAddress
        AddGroupNode(XMLCurrNode, 'PostalAddress', AggregateCompSpaceNameTxt, CACTxt);
        AddNotEmptyNode(XMLCurrNode, 'StreetName', TempEInvoiceExportHeader."Bill-to Address", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'AdditionalStreetName', TempEInvoiceExportHeader."Bill-to Address 2", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'CityName', TempEInvoiceExportHeader."Bill-to City", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'PostalZone', TempEInvoiceExportHeader."Bill-to Post Code", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'CountrySubentity', TempEInvoiceExportHeader."Bill-to County", BasicCompSpaceNameTxt, CBCTxt);

        // Header->AccountingCustomerParty->Party->PostalAddress->Country
        AddCountry(EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(TempEInvoiceExportHeader."Bill-to Country/Region Code"));
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->AccountingCustomerParty->Party->PartyTextScheme
        AddGroupNode(XMLCurrNode, 'PartyTaxScheme', AggregateCompSpaceNameTxt, CACTxt);
        AddNotEmptyNode(
          XMLCurrNode, 'CompanyID',
          EInvoiceDocumentEncode.GetVATRegNo(
            TempEInvoiceExportHeader."VAT Registration No.", true),
          BasicCompSpaceNameTxt, CBCTxt);

        AddGroupNode(XMLCurrNode, 'TaxScheme', AggregateCompSpaceNameTxt, CACTxt);
        AddGroupNodeWithData(XMLCurrNode, 'ID', 'VAT', BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'schemeID', 'UN/ECE 5153');
        AddAttribute(XMLCurrNode, 'schemeAgencyID', '6');
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->AccountingCustomerParty->Party->PartyLegalEntity
        AddGroupNode(XMLCurrNode, 'PartyLegalEntity', AggregateCompSpaceNameTxt, CACTxt);

        // Header->AccountingCustomerParty->Party->PartyLegalEntity->RegistrationName
        AddNotEmptyNode(XMLCurrNode, 'RegistrationName', TempEInvoiceExportHeader."Bill-to Name", BasicCompSpaceNameTxt, CBCTxt);

        // Header->AccountingCustomerParty->Party->PartyLegalEntity->CompanyID
        AddGroupNodeWithData(
          XMLCurrNode, 'CompanyID',
          WriteCompanyID(TempEInvoiceExportHeader."VAT Registration No."),
          BasicCompSpaceNameTxt, CBCTxt);

        // UBL 2.1
        if UBLVersionID = '2.1' then begin
            AddAttribute(XMLCurrNode, 'schemeID', 'NO:ORGNR');
            AddAttribute(XMLCurrNode, 'schemeAgencyID', '82');
        end;
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->AccountingCustomerParty->Party->Contact
        AddGroupNode(XMLCurrNode, 'Contact', AggregateCompSpaceNameTxt, CACTxt);
        AddNodeNA(XMLCurrNode, 'ID', TempEInvoiceExportHeader."Your Reference", BasicCompSpaceNameTxt, CBCTxt);
        if TempEInvoiceExportHeader."Your Reference" <> '' then begin
            AddNotEmptyNode(XMLCurrNode, 'Name', TempEInvoiceExportHeader."Bill-to Name", BasicCompSpaceNameTxt, CBCTxt);
            if Customer.Get(TempEInvoiceExportHeader."Bill-to Customer No.") then begin
                AddNotEmptyNode(XMLCurrNode, 'Telephone', Customer."Phone No.", BasicCompSpaceNameTxt, CBCTxt);
                AddNotEmptyNode(XMLCurrNode, 'Telefax', Customer."Fax No.", BasicCompSpaceNameTxt, CBCTxt);
                AddNotEmptyNode(XMLCurrNode, 'ElectronicMail', Customer."E-Mail", BasicCompSpaceNameTxt, CBCTxt);
            end;
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;

        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddHeaderAccountingSupplierParty()
    var
        CompanyInfo: Record "Company Information";
        ResponsibilityCenter: Record "Responsibility Center";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Name: Text[250];
        Address: Text[250];
        Address2: Text[250];
        City: Text[250];
        PostCode: Text[250];
        County: Text[250];
        CountryRegionCode: Text[10];
    begin
        CompanyInfo.Get();

        if TempEInvoiceExportHeader."Responsibility Center" <> '' then begin
            ResponsibilityCenter.Get(TempEInvoiceExportHeader."Responsibility Center");
            Name := ResponsibilityCenter.Name;
            Address := ResponsibilityCenter.Address;
            Address2 := ResponsibilityCenter."Address 2";
            City := ResponsibilityCenter.City;
            PostCode := ResponsibilityCenter."Post Code";
            County := ResponsibilityCenter.County;
            CountryRegionCode := ResponsibilityCenter."Country/Region Code";
        end else begin
            Name := CompanyInfo.Name;
            Address := CompanyInfo.Address;
            Address2 := CompanyInfo."Address 2";
            City := CompanyInfo.City;
            PostCode := CompanyInfo."Post Code";
            County := CompanyInfo.County;
            CountryRegionCode := CompanyInfo."Country/Region Code";
        end;

        AddGroupNode(XMLCurrNode, 'AccountingSupplierParty', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNode(XMLCurrNode, 'Party', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeIDVAT(
          XMLCurrNode, 'EndpointID', EInvoiceDocumentEncode.GetVATRegNo(CompanyInfo."VAT Registration No.", false),
          BasicCompSpaceNameTxt, CBCTxt);

        // Header->AccountingSupplierParty->Party->PartyName
        AddGroupNode(XMLCurrNode, 'PartyName', AggregateCompSpaceNameTxt, CACTxt);
        AddLastNode(XMLCurrNode, 'Name', Name, BasicCompSpaceNameTxt, CBCTxt);

        // Header->AccountingSupplierParty->Party->PostalAddress
        AddGroupNode(XMLCurrNode, 'PostalAddress', AggregateCompSpaceNameTxt, CACTxt);

        AddNotEmptyNode(XMLCurrNode, 'StreetName', Address, BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'AdditionalStreetName', Address2, BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'CityName', City, BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'PostalZone', PostCode, BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'CountrySubentity', County, BasicCompSpaceNameTxt, CBCTxt);

        // Header->AccountingSupplierParty->Party->PostalAddress->Country
        AddCountry(CountryRegionCode);
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->AccountingSupplierParty->Party->PartyTextScheme
        AddGroupNode(XMLCurrNode, 'PartyTaxScheme', AggregateCompSpaceNameTxt, CACTxt);

        AddNotEmptyNode(
          XMLCurrNode, 'CompanyID', EInvoiceDocumentEncode.GetVATRegNo(CompanyInfo."VAT Registration No.", true),
          BasicCompSpaceNameTxt, CBCTxt);

        AddGroupNode(XMLCurrNode, 'TaxScheme', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(XMLCurrNode, 'ID', 'VAT', BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'schemeID', 'UN/ECE 5153');
        AddAttribute(XMLCurrNode, 'schemeAgencyID', '6');
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddPartyLegalEntity();

        if SalespersonPurchaser.Get(TempEInvoiceExportHeader."Salesperson Code") then
            if SalespersonPurchaser.Name <> '' then begin
                AddGroupNode(XMLCurrNode, 'Contact', AggregateCompSpaceNameTxt, CACTxt);
                AddNotEmptyNode(XMLCurrNode, 'ID', SalespersonPurchaser.Code, BasicCompSpaceNameTxt, CBCTxt);
                AddNotEmptyNode(XMLCurrNode, 'Name', SalespersonPurchaser.Name, BasicCompSpaceNameTxt, CBCTxt);
                AddNotEmptyNode(XMLCurrNode, 'Telephone', SalespersonPurchaser."Phone No.", BasicCompSpaceNameTxt, CBCTxt);
                AddLastNode(XMLCurrNode, 'ElectronicMail', SalespersonPurchaser."E-Mail", BasicCompSpaceNameTxt, CBCTxt);
            end;

        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddHeaderAllowanceCharge()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPercentage: Decimal;
        VATCalculationType: Enum "Tax Calculation Type";
        VATProdPostingGroup: Code[20];
        DiscountAmount: Decimal;
    begin
        if VATProductPostingGroup.FindSet() then
            repeat
                TempEInvoiceExportLine.SetRange("VAT Prod. Posting Group", VATProductPostingGroup.Code);
                if not TempEInvoiceExportLine.IsEmpty() then begin
                    VATPercentage := 0.0;
                    if TempEInvoiceExportLine.FindFirst() then begin
                        VATPercentage := TempEInvoiceExportLine."VAT %";
                        VATCalculationType := TempEInvoiceExportLine."VAT Calculation Type";
                        VATProdPostingGroup := TempEInvoiceExportLine."VAT Prod. Posting Group";
                    end;

                    // Header->AllowanceCharge
                    TempEInvoiceExportLine.CalcSums("Line Discount Amount", "Inv. Discount Amount");
                    DiscountAmount := TempEInvoiceExportLine."Line Discount Amount" + TempEInvoiceExportLine."Inv. Discount Amount";
                    if DiscountAmount > 0 then begin
                        AddGroupNode(XMLCurrNode, 'AllowanceCharge', AggregateCompSpaceNameTxt, CACTxt);

                        AddNotEmptyNode(XMLCurrNode, 'ChargeIndicator', 'false', BasicCompSpaceNameTxt, CBCTxt);
                        AddNotEmptyNode(XMLCurrNode, 'AllowanceChargeReason', 'Rabat', BasicCompSpaceNameTxt, CBCTxt);

                        AddGroupNodeWithData(
                          XMLCurrNode, 'Amount', EInvoiceDocumentEncode.DecimalToText(DiscountAmount),
                          BasicCompSpaceNameTxt, CBCTxt);
                        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
                        XMLCurrNode := XMLCurrNode.ParentNode();

                        // Header->AllowanceCharge->TaxCategory
                        AddGroupNode(XMLCurrNode, 'TaxCategory', AggregateCompSpaceNameTxt, CACTxt);

                        AddGroupNodeWithData(XMLCurrNode, 'ID', GetTaxCategoryID(VATPercentage, VATCalculationType.AsInteger(), VATProdPostingGroup, true),
                          BasicCompSpaceNameTxt, CBCTxt);
                        AddAttribute(XMLCurrNode, 'schemeID', 'UNCL5305');
                        XMLCurrNode := XMLCurrNode.ParentNode();

                        AddNotEmptyNode(XMLCurrNode, 'Percent', EInvoiceDocumentEncode.DecimalToText(VATPercentage),
                          BasicCompSpaceNameTxt, CBCTxt);

                        // Header->AllowanceCharge->TaxCategory->TaxScheme
                        AddGroupNode(XMLCurrNode, 'TaxScheme', AggregateCompSpaceNameTxt, CACTxt);
                        AddLastNode(XMLCurrNode, 'ID', 'VAT', BasicCompSpaceNameTxt, CBCTxt);
                        XMLCurrNode := XMLCurrNode.ParentNode();
                        XMLCurrNode := XMLCurrNode.ParentNode();
                    end;
                end;
            until VATProductPostingGroup.Next() = 0;
        TempEInvoiceExportLine.SetRange("VAT Prod. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure AddHeaderBillingReference()
    begin
        // Header->BillingReference
        AddGroupNode(XMLCurrNode, 'BillingReference', AggregateCompSpaceNameTxt, CACTxt);
        AddGroupNode(XMLCurrNode, 'InvoiceDocumentReference', AggregateCompSpaceNameTxt, CACTxt);

        AddLastNode(XMLCurrNode, 'ID', TempEInvoiceExportHeader."Document No.", BasicCompSpaceNameTxt, CBCTxt);

        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddHeaderCommonContent()
    begin
        AddNotEmptyNode(XMLCurrNode, 'UBLVersionID', UBLVersionID, BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'CustomizationID', TempEInvoiceExportHeader."Customization ID", BasicCompSpaceNameTxt, CBCTxt);

        AddNotEmptyNode(XMLCurrNode, 'ProfileID', TempEInvoiceExportHeader."Profile ID", BasicCompSpaceNameTxt, CBCTxt);

        AddNotEmptyNode(XMLCurrNode, 'ID', TempEInvoiceExportHeader."No.", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(
          XMLCurrNode, 'IssueDate', EInvoiceDocumentEncode.DateToText(TempEInvoiceExportHeader."Posting Date"), BasicCompSpaceNameTxt,
          CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure AddHeaderContractDocumentReference()
    begin
        // Header->ContractDocumentReference
        AddGroupNode(XMLCurrNode, 'ContractDocumentReference', AggregateCompSpaceNameTxt, CACTxt);

        if TempEInvoiceExportHeader."Order No." <> '' then begin
            AddNotEmptyNode(XMLCurrNode, 'ID', TempEInvoiceExportHeader."Order No.", BasicCompSpaceNameTxt, CBCTxt);
            AddLastNode(XMLCurrNode, 'DocumentType', 'Order', BasicCompSpaceNameTxt, CBCTxt);
        end else
            AddLastNode(XMLCurrNode, 'ID', TempEInvoiceExportHeader."Pre-Assigned No.", BasicCompSpaceNameTxt, CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure AddHeaderDocumentCurrencyCode()
    begin
        AddGroupNodeWithData(XMLCurrNode, 'DocumentCurrencyCode', TempEInvoiceExportHeader."Currency Code", BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'listID', 'ISO4217');
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddHeaderInvoiceTypeCode()
    begin
        AddGroupNodeWithData(XMLCurrNode, 'InvoiceTypeCode', '380', BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'listID', 'UNCL1001');
        AddAttribute(XMLCurrNode, 'listAgencyID', '6');
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddHeaderLegalMonetaryTotal()
    begin
        // Header->LegalMonetaryTotal
        AddGroupNode(XMLCurrNode, 'LegalMonetaryTotal', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(XMLCurrNode, 'LineExtensionAmount',
          EInvoiceDocumentEncode.DecimalToText(
            TempEInvoiceExportHeader."Legal Taxable Amount" + TempEInvoiceExportHeader."Total Invoice Discount Amount"),
          BasicCompSpaceNameTxt, CBCTxt);

        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddGroupNodeWithData(
          XMLCurrNode, 'TaxExclusiveAmount', EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportHeader."Legal Taxable Amount"),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddGroupNodeWithData(
          XMLCurrNode, 'TaxInclusiveAmount', EInvoiceDocumentEncode.DecimalToText(
            TempEInvoiceExportHeader."Total Amount" + TempEInvoiceExportHeader."Total Rounding Amount"),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        if TempEInvoiceExportHeader."Total Invoice Discount Amount" > 0 then begin
            AddGroupNodeWithData(
              XMLCurrNode, 'AllowanceTotalAmount',
              EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportHeader."Total Invoice Discount Amount"),
              BasicCompSpaceNameTxt, CBCTxt);
            AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;

        AddGroupNodeWithData(
          XMLCurrNode, 'PayableRoundingAmount', EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportHeader."Total Rounding Amount"),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddGroupNodeWithData(XMLCurrNode, 'PayableAmount',
          EInvoiceDocumentEncode.DecimalToText(
            TempEInvoiceExportHeader."Total Amount" + TempEInvoiceExportHeader."Total Rounding Amount"),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddHeaderNote()
    begin
        if TempEInvoiceExportHeader.Note <> '' then
            AddNotEmptyNode(XMLCurrNode, 'Note', TempEInvoiceExportHeader.Note, BasicCompSpaceNameTxt, CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure AddHeaderOrderReference()
    begin
        // Header->OrderReference
        if TempEInvoiceExportHeader."Document No." <> '' then begin
            AddGroupNode(XMLCurrNode, 'OrderReference', AggregateCompSpaceNameTxt, CACTxt);
            AddLastNode(XMLCurrNode, 'ID', TempEInvoiceExportHeader."Document No.", BasicCompSpaceNameTxt, CBCTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure AddHeaderPaymentMeans()
    var
        CompanyInfo: Record "Company Information";
        PaymentTerms: Record "Payment Terms";
        CompanyAndCustomerInSameCountry: Boolean;
        AtLeastOnePaymentMeansAdded: Boolean;
    begin
        CompanyInfo.Get();

        AtLeastOnePaymentMeansAdded := false;
        CompanyAndCustomerInSameCountry := AreCustomerAndSupplierInSameCountry();

        if (UBLVersionID = '2.1') and (CompanyInfo."Bank Account No." <> '') and CompanyAndCustomerInSameCountry then begin
            AddPaymentMeans(EInvoiceDocumentEncode.GetBBANNo(CompanyInfo."Bank Account No."), 'BBAN');
            AtLeastOnePaymentMeansAdded := true;
        end;

        if (UBLVersionID = '2.0') and (CompanyInfo.IBAN = '') then begin
            AddPaymentMeans(CompanyInfo."Bank Account No.", 'BANK');
            AtLeastOnePaymentMeansAdded := true;
        end;

        if CompanyInfo.IBAN <> '' then
            AddPaymentMeans(CompanyInfo.IBAN, 'IBAN')
        else
            if not AtLeastOnePaymentMeansAdded then
                Error(IbanEmptyAndNoOtherPaymentMeansErr);

        // Header->PaymentTerms
        if PaymentTerms.Get(TempEInvoiceExportHeader."Payment Terms Code") then begin
            AddGroupNode(XMLCurrNode, 'PaymentTerms', AggregateCompSpaceNameTxt, CACTxt);
            AddLastNode(XMLCurrNode, 'Note', PaymentTerms.Description, BasicCompSpaceNameTxt, CBCTxt);
        end;
    end;

    [Scope('OnPrem')]
    procedure AddHeaderTaxCurrencyCode()
    begin
        if DocumentHasForeignCurrency() then begin
            AddGroupNodeWithData(XMLCurrNode, 'TaxCurrencyCode', TempEInvoiceExportHeader."Currency Code", BasicCompSpaceNameTxt, CBCTxt);
            AddAttribute(XMLCurrNode, 'listID', 'ISO4217');
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;
    end;

    [Scope('OnPrem')]
    procedure AddHeaderTaxExchangeRate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not DocumentHasForeignCurrency() then
            exit;

        AddGroupNode(XMLCurrNode, 'TaxExchangeRate', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(XMLCurrNode, 'SourceCurrencyCode', TempEInvoiceExportHeader."Currency Code", BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'listID', 'ISO4217');
        XMLCurrNode := XMLCurrNode.ParentNode();

        GeneralLedgerSetup.Get();
        AddGroupNodeWithData(XMLCurrNode, 'TargetCurrencyCode', GeneralLedgerSetup."LCY Code", BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'listID', 'ISO4217');
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddNotEmptyNode(XMLCurrNode, 'CalculationRate', Format(GetCurrMultiplicationFactor(), 0, 9), BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'MathematicOperatorCode', 'Multiply', BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(
          XMLCurrNode, 'Date', Format(TempEInvoiceExportHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>'), BasicCompSpaceNameTxt, CBCTxt);

        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddHeaderTaxTotal()
    begin
        if TempEInvoiceExportHeader."Sales Line Found" then begin
            AddGroupNode(XMLCurrNode, 'TaxTotal', AggregateCompSpaceNameTxt, CACTxt);
            AddGroupNodeWithData(XMLCurrNode, 'TaxAmount',
              EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportHeader."Tax Amount"), BasicCompSpaceNameTxt, CBCTxt);
            AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
            XMLCurrNode := XMLCurrNode.ParentNode();
            AddTaxSubTotal();
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;
    end;

    [Scope('OnPrem')]
    procedure AddLineAccountingCost()
    begin
        AddNotEmptyNode(XMLCurrNode, 'AccountingCost', TempEInvoiceExportLine."Account Code", BasicCompSpaceNameTxt, CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure AddLineAllowanceCharge()
    begin
        // Header->Line->AllowanceCharge
        if TempEInvoiceExportLine.Type = TempEInvoiceExportLine.Type::"Charge (Item)" then begin
            AddGroupNode(XMLCurrNode, 'AllowanceCharge', AggregateCompSpaceNameTxt, CACTxt);

            if TempEInvoiceExportLine."Amount Including VAT" < 0 then begin
                AddNotEmptyNode(XMLCurrNode, 'ChargeIndicator', 'false', BasicCompSpaceNameTxt, CBCTxt);
                AddNotEmptyNode(XMLCurrNode, 'AllowanceChargeReason', 'Rabat', BasicCompSpaceNameTxt, CBCTxt);
            end else begin
                AddNotEmptyNode(XMLCurrNode, 'ChargeIndicator', 'true', BasicCompSpaceNameTxt, CBCTxt);
                AddNotEmptyNode(XMLCurrNode, 'AllowanceChargeReason', 'Gebyr', BasicCompSpaceNameTxt, CBCTxt);
            end;

            AddGroupNodeWithData(XMLCurrNode, 'Amount', EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine."Amount Including VAT"),
              BasicCompSpaceNameTxt, CBCTxt);
            AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
            XMLCurrNode := XMLCurrNode.ParentNode();
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;
    end;

    [Scope('OnPrem')]
    procedure AddLineInvCrMemoCommonContent()
    var
        TotalLineAmount: Decimal;
        unitCode: Text;
        unitCodeListID: Text;
    begin
        GetUnitCodeInfo(unitCode, unitCodeListID);
        AddGroupNodeWithData(
          XMLCurrNode, TempEInvoiceExportHeader."Quantity Name",
          EInvoiceDocumentEncode.DecimalExtToText(TempEInvoiceExportLine.Quantity),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'unitCode', unitCode);
        AddAttribute(XMLCurrNode, 'unitCodeListID', unitCodeListID);
        XMLCurrNode := XMLCurrNode.ParentNode();

        TotalLineAmount :=
          TempEInvoiceExportLine.Amount + TempEInvoiceExportLine."Line Discount Amount" + TempEInvoiceExportLine."Inv. Discount Amount";
        AddGroupNodeWithData(XMLCurrNode, 'LineExtensionAmount',
          EInvoiceDocumentEncode.DecimalToText(TotalLineAmount), BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddLineItem()
    begin
        // Header->Line->Item
        AddGroupNode(XMLCurrNode, 'Item', AggregateCompSpaceNameTxt, CACTxt);
        AddNotEmptyNode(XMLCurrNode, 'Description', TempEInvoiceExportLine."Description 2", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'Name', TempEInvoiceExportLine.Description, BasicCompSpaceNameTxt, CBCTxt);

        // Header->Line->Item->SellersItemIdentification
        AddGroupNode(XMLCurrNode, 'SellersItemIdentification', AggregateCompSpaceNameTxt, CACTxt);
        AddLastNode(XMLCurrNode, 'ID', TempEInvoiceExportLine."No.", BasicCompSpaceNameTxt, CBCTxt);

        // Header->Line->Item->ClassifiedTaxCategory
        AddGroupNode(XMLCurrNode, 'ClassifiedTaxCategory', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(
          XMLCurrNode, 'ID',
          GetTaxCategoryID(
            TempEInvoiceExportLine."VAT %", TempEInvoiceExportLine."VAT Calculation Type".AsInteger(),
            TempEInvoiceExportLine."VAT Prod. Posting Group", true),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'schemeID', 'UNCL5305');
        AddAttribute(XMLCurrNode, 'schemeAgencyID', '6');
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddNotEmptyNode(
          XMLCurrNode, 'Percent', EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine."VAT %"), BasicCompSpaceNameTxt, CBCTxt);

        AddGroupNode(XMLCurrNode, 'TaxScheme', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(XMLCurrNode, 'ID', 'VAT', BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'schemeID', 'UN/ECE 5153');
        AddAttribute(XMLCurrNode, 'schemeAgencyID', '6');
        XMLCurrNode := XMLCurrNode.ParentNode();

        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddLineNote()
    begin
        // Header->Line->Note
        if TempEInvoiceExportLine.Comment <> '' then
            AddNotEmptyNode(XMLCurrNode, 'Note', TempEInvoiceExportLine.Comment, BasicCompSpaceNameTxt, CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure AddLineOrderLineReference()
    begin
        AddGroupNode(XMLCurrNode, 'OrderLineReference', AggregateCompSpaceNameTxt, CACTxt);
        AddLastNode(XMLCurrNode, 'LineID', Format(TempEInvoiceExportLine."Line No."), BasicCompSpaceNameTxt, CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure AddLinePrice()
    var
        unitCode: Text;
        unitCodeListID: Text;
    begin
        // Header->Line->Price
        AddGroupNode(XMLCurrNode, 'Price', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(
          XMLCurrNode, 'PriceAmount',
          EInvoiceDocumentEncode.DecimalExtToText(TempEInvoiceExportLine."Unit Price"), BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        GetUnitCodeInfo(unitCode, unitCodeListID);
        AddGroupNodeWithData(
          XMLCurrNode, 'BaseQuantity', EInvoiceDocumentEncode.DecimalToText(1.0), BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'unitCode', unitCode);
        AddAttribute(XMLCurrNode, 'unitCodeListID', unitCodeListID);
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->Line->Price->AllowanceCharge
        AddGroupNode(XMLCurrNode, 'AllowanceCharge', AggregateCompSpaceNameTxt, CACTxt);

        AddNotEmptyNode(XMLCurrNode, 'ChargeIndicator', 'false', BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'AllowanceChargeReason', 'Rabat', BasicCompSpaceNameTxt, CBCTxt);

        AddNotEmptyNode(
          XMLCurrNode, 'MultiplierFactorNumeric', EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine."Line Discount %"),
          BasicCompSpaceNameTxt, CBCTxt);

        AddGroupNodeWithData(XMLCurrNode, 'Amount', EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine."Line Discount Amount"),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddGroupNodeWithData(XMLCurrNode, 'BaseAmount', EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine.Amount),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddLineReminderContent()
    var
        ElementName: Text[30];
    begin
        AddNotEmptyNode(XMLCurrNode, 'Note', TempEInvoiceExportLine.Description +
          EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine."Remaining Amount"),
          BasicCompSpaceNameTxt, CBCTxt);

        if TempEInvoiceExportLine.Amount > 0 then
            AddGroupNodeWithData(XMLCurrNode, 'DebitLineAmount',
              EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine.Amount), BasicCompSpaceNameTxt, CBCTxt)
        else
            AddGroupNodeWithData(XMLCurrNode, 'DebitLineAmount', '0', BasicCompSpaceNameTxt, CBCTxt);

        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        if TempEInvoiceExportLine.Amount < 0 then
            AddGroupNodeWithData(XMLCurrNode, 'CreditLineAmount',
              EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine.Amount), BasicCompSpaceNameTxt, CBCTxt)
        else
            AddGroupNodeWithData(XMLCurrNode, 'CreditLineAmount', '0', BasicCompSpaceNameTxt, CBCTxt);

        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->Line->BillingReference
        AddGroupNode(XMLCurrNode, 'BillingReference', AggregateCompSpaceNameTxt, CACTxt);
        if TempEInvoiceExportLine."Document No." <> '' then begin
            case TempEInvoiceExportLine."Document Type" of
                TempEInvoiceExportLine."Document Type"::Invoice,
              TempEInvoiceExportLine."Document Type"::Refund:
                    ElementName := 'InvoiceDocumentReference';
                TempEInvoiceExportLine."Document Type"::"Credit Memo",
              TempEInvoiceExportLine."Document Type"::Payment:
                    ElementName := 'CreditNoteDocumentReference';
                TempEInvoiceExportLine."Document Type"::Reminder,
              TempEInvoiceExportLine."Document Type"::"Finance Charge Memo":
                    ElementName := 'ReminderDocumentReference';
            end;
            AddGroupNode(XMLCurrNode, ElementName, AggregateCompSpaceNameTxt, CACTxt);
            AddLastNode(XMLCurrNode, 'ID', Format(TempEInvoiceExportLine."Document No."), BasicCompSpaceNameTxt, CBCTxt);
        end;
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure AddLineTaxTotal()
    begin
        // Header->Line->TaxTotal
        AddGroupNode(XMLCurrNode, 'TaxTotal', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(XMLCurrNode, 'TaxAmount',
          EInvoiceDocumentEncode.DecimalToText(TempEInvoiceExportLine."Amount Including VAT" - TempEInvoiceExportLine.Amount),
          BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    local procedure AddCountry(IdentificationCode: Code[10])
    begin
        AddGroupNode(XMLCurrNode, 'Country', AggregateCompSpaceNameTxt, CACTxt);
        if UBLVersionID = '2.1' then begin
            AddGroupNodeWithData(XMLCurrNode, 'IdentificationCode', IdentificationCode, BasicCompSpaceNameTxt, CBCTxt);
            AddAttribute(XMLCurrNode, 'listID', 'ISO3166-1:Alpha2');
            XMLCurrNode := XMLCurrNode.ParentNode();
            XMLCurrNode := XMLCurrNode.ParentNode();
        end else
            AddLastNode(XMLCurrNode, 'IdentificationCode', IdentificationCode, BasicCompSpaceNameTxt, CBCTxt);
    end;

    [Scope('OnPrem')]
    procedure AddDelivery()
    begin
        // Header->Delivery and
        // Header->Line->Delivery
        AddGroupNode(XMLCurrNode, 'Delivery', AggregateCompSpaceNameTxt, CACTxt);

        AddNotEmptyNode(XMLCurrNode, 'ActualDeliveryDate',
          EInvoiceDocumentEncode.DateToText(TempEInvoiceExportHeader."Shipment Date"), BasicCompSpaceNameTxt, CBCTxt);

        AddGroupNode(XMLCurrNode, 'DeliveryLocation', AggregateCompSpaceNameTxt, CACTxt);

        // Delivery->DeliveryLocation->Address
        AddGroupNode(XMLCurrNode, 'Address', AggregateCompSpaceNameTxt, CACTxt);

        AddNotEmptyNode(XMLCurrNode, 'StreetName', TempEInvoiceExportHeader."Ship-to Address", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'AdditionalStreetName', TempEInvoiceExportHeader."Ship-to Address 2", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'CityName', TempEInvoiceExportHeader."Ship-to City", BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'PostalZone', TempEInvoiceExportHeader."Ship-to Post Code", BasicCompSpaceNameTxt, CBCTxt);

        // Delivery->DeliveryLocation->Address->Country
        AddCountry(TempEInvoiceExportHeader."Ship-to Country/Region Code");

        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    local procedure AddPartyLegalEntity()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        AddGroupNode(XMLCurrNode, 'PartyLegalEntity', AggregateCompSpaceNameTxt, CACTxt);

        AddNotEmptyNode(XMLCurrNode, 'RegistrationName', CompanyInfo.Name, BasicCompSpaceNameTxt, CBCTxt);

        AddGroupNodeWithData(XMLCurrNode, 'CompanyID',
          WriteCompanyID(CompanyInfo."VAT Registration No."),
          BasicCompSpaceNameTxt, CBCTxt);

        AddAttribute(XMLCurrNode, 'schemeID', 'NO:ORGNR');
        if CompanyInfo.Enterpriseregister then
            AddAttribute(XMLCurrNode, 'schemeName', 'Foretaksregisteret');
        AddAttribute(XMLCurrNode, 'schemeAgencyID', '82');
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddGroupNode(XMLCurrNode, 'RegistrationAddress', AggregateCompSpaceNameTxt, CACTxt);
        AddNotEmptyNode(XMLCurrNode, 'CityName', CompanyInfo.City, BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'CountrySubentity', CompanyInfo.County, BasicCompSpaceNameTxt, CBCTxt);

        if CompanyInfo."Country/Region Code" <> '' then
            AddCountry(CompanyInfo."Country/Region Code");

        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    local procedure AddPaymentMeans(AccountId: Code[50]; AccountAttributeName: Code[4])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        // Header->PaymentMeans
        AddGroupNode(XMLCurrNode, 'PaymentMeans', AggregateCompSpaceNameTxt, CACTxt);

        AddGroupNodeWithData(XMLCurrNode, 'PaymentMeansCode', '31', BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'listID', 'UNCL4461');
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddNotEmptyNode(XMLCurrNode, 'PaymentDueDate',
          EInvoiceDocumentEncode.DateToText(TempEInvoiceExportHeader."Due Date"), BasicCompSpaceNameTxt, CBCTxt);
        AddNotEmptyNode(XMLCurrNode, 'PaymentID', TempEInvoiceExportHeader."Payment ID", BasicCompSpaceNameTxt, CBCTxt);

        // Header->PaymentMeans->PayeeFinancialAccount
        AddGroupNode(XMLCurrNode, 'PayeeFinancialAccount', AggregateCompSpaceNameTxt, CACTxt);

        SetSchemeID(AccountId, AccountAttributeName);

        // Header->PaymentMeans->PayeeFinancialAccount->FinancialInstitutionBranch
        AddGroupNode(XMLCurrNode, 'FinancialInstitutionBranch', AggregateCompSpaceNameTxt, CACTxt);

        if AccountId <> 'IBAN' then
            AddNotEmptyNode(XMLCurrNode, 'ID', CompanyInfo."Bank Branch No.", BasicCompSpaceNameTxt, CBCTxt);

        // Header->PaymentMeans->PayeeFinancialAccount->FinancialInstitutionBranch->FinancialInstitution
        AddGroupNode(XMLCurrNode, 'FinancialInstitution', AggregateCompSpaceNameTxt, CACTxt);

        SetSchemeID(CompanyInfo."SWIFT Code", 'BIC');

        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    local procedure AddTaxSubTotal()
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        FillVATAmountLines(TempVATAmountLine);
        if TempVATAmountLine.FindSet() then
            repeat
                WriteTaxSubTotal(TempVATAmountLine);
            until TempVATAmountLine.Next() = 0;
        TempVATAmountLine.DeleteAll();
    end;

    local procedure DocumentHasForeignCurrency(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if TempEInvoiceExportHeader."Currency Code" = '' then
            exit(false);

        GeneralLedgerSetup.Get();
        if TempEInvoiceExportHeader."Currency Code" = GeneralLedgerSetup."LCY Code" then
            exit(false);

        exit(true);
    end;

    local procedure FillVATAmountLines(var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        TempEInvoiceExportLine.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        if TempEInvoiceExportLine.FindSet() then
            repeat
                if not TempVATAmountLine.Get(TempEInvoiceExportLine."VAT Identifier", TempEInvoiceExportLine."VAT Calculation Type", '', false, false) then begin
                    TempVATAmountLine.Init();
                    TempVATAmountLine."VAT Identifier" := TempEInvoiceExportLine."VAT Identifier";
                    TempVATAmountLine."VAT Calculation Type" := TempEInvoiceExportLine."VAT Calculation Type";
                    TempVATAmountLine."VAT %" := TempEInvoiceExportLine."VAT %";
                    TempVATAmountLine.Insert();
                end;
                TempVATAmountLine."VAT Base" += TempEInvoiceExportLine.Amount;
                TempVATAmountLine."VAT Amount" += TempEInvoiceExportLine."Amount Including VAT" - TempEInvoiceExportLine.Amount;
                TempVATAmountLine.Modify();
            until TempEInvoiceExportLine.Next() = 0;
    end;

    local procedure AreCustomerAndSupplierInSameCountry(): Boolean
    var
        ResponsibilityCenter: Record "Responsibility Center";
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        CompanyCountryRegionCode: Code[10];
    begin
        CompanyInformation.Get();
        if TempEInvoiceExportHeader."Responsibility Center" <> '' then begin
            ResponsibilityCenter.Get(TempEInvoiceExportHeader."Responsibility Center");
            CompanyCountryRegionCode := ResponsibilityCenter."Country/Region Code";
        end else
            CompanyCountryRegionCode := CompanyInformation."Country/Region Code";

        if not Customer.Get(TempEInvoiceExportHeader."Bill-to Customer No.") then
            exit(false);

        exit(Customer."Country/Region Code" = CompanyCountryRegionCode);
    end;

    local procedure GetCurrMultiplicationFactor(): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        exit(1 / CurrencyExchangeRate.ExchangeRate(TempEInvoiceExportHeader."Posting Date", TempEInvoiceExportHeader."Currency Code"));
    end;

    local procedure GetTaxCategoryID(VATPercent: Decimal; Type: Option "Normal VAT","Reverse Charge VAT","Full VAT","Sales Tax"; VATProdPostingGroup: Code[20]; ReverseChargeKAuthorized: Boolean): Text[2]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        case VATPercent of
            0:
                begin
                    if Type = Type::"Reverse Charge VAT" then begin
                        if AreCustomerAndSupplierInSameCountry() or ReverseChargeKAuthorized then
                            exit('K'); // K: Emission allowances for private or public businesses - buyer calculates VAT
                        Error(ReverseChargeNotAuthorizedErr);
                    end;
                    VATProductPostingGroup.SetRange(Code, VATProdPostingGroup);
                    if VATProductPostingGroup.FindFirst() and VATProductPostingGroup."Outside Tax Area" then
                        exit('Z'); // Z: VAT exempt (Goods and services not included in the VAT regulations)
                    exit('E'); // E: VAT exempt
                end;
            10:
                exit('AA'); // AA: Outgoing VAT, low rate
            11.11:
                exit('R'); // R: Outgoing VAT, reduced rate - raw fish
            15:
                exit('H'); // H: Outgoing VAT, reduced rate - food & beverage
            25:
                exit('S'); // S: Outgoing VAT, ordinary rate
            else
                Error(NoCategoryMatchesVATPercentErr, Format(VATPercent));
        end;
    end;

    local procedure GetUBLVersionID(): Code[3]
    begin
        // based on the current UBL version per Doc. Type
        if (TempEInvoiceExportHeader."Schema Name" = 'CreditNote') or (TempEInvoiceExportHeader."Schema Name" = 'Invoice') then
            exit('2.1');
        exit('2.0');
    end;

    local procedure GetUnitCodeInfo(var unitCode: Text; var unitCodeListID: Text)
    var
        SalesLine: Record "Sales Line";
        PEPPOLManagement: Codeunit "PEPPOL Management";
    begin
        SalesLine.Quantity := TempEInvoiceExportLine.Quantity;
        SalesLine.Type := "Sales Document Type".FromInteger(TempEInvoiceExportLine.Type);
        SalesLine."Unit of Measure Code" := TempEInvoiceExportLine."Unit of Measure Code";
        PEPPOLManagement.GetLineUnitCodeInfo(SalesLine, unitCode, unitCodeListID);
    end;

    local procedure SetSchemeID(Id: Code[50]; AttributeName: Code[4])
    begin
        AddGroupNodeWithData(XMLCurrNode, 'ID', Id, BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'schemeID', AttributeName);
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    [Scope('OnPrem')]
    procedure WriteCompanyID(VATRegistrationNo: Code[20]): Text[30]
    var
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
    begin
        exit(EInvoiceDocumentEncode.GetVATRegNo(VATRegistrationNo, false));
    end;

    local procedure WriteTaxSubTotal(TempVATAmountLine: Record "VAT Amount Line" temporary)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxCategoryID: Text[2];
        TransactionCurrTaxAmount: Text[30];
    begin
        TempEInvoiceExportLine.Reset();
        TempEInvoiceExportLine.SetRange("VAT Identifier", TempVATAmountLine."VAT Identifier");
        TempEInvoiceExportLine.SetRange("VAT Calculation Type", TempVATAmountLine."VAT Calculation Type");
        TempEInvoiceExportLine.FindFirst();

        // Header->TaxTotal->TaxSubtotal
        AddGroupNode(XMLCurrNode, 'TaxSubtotal', AggregateCompSpaceNameTxt, CACTxt);
        AddGroupNodeWithData(XMLCurrNode, 'TaxableAmount',
          EInvoiceDocumentEncode.DecimalToText(TempVATAmountLine."VAT Base"), BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->TaxTotal->TaxSubTotal->TaxAmount
        AddGroupNodeWithData(XMLCurrNode, 'TaxAmount',
          EInvoiceDocumentEncode.DecimalToText(TempVATAmountLine."VAT Amount"), BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'currencyID', TempEInvoiceExportHeader."Currency Code");
        XMLCurrNode := XMLCurrNode.ParentNode();

        // Header->TaxTotal->TaxSubTotal->TransactionCurrencyTaxAmount
        if DocumentHasForeignCurrency() then begin
            GeneralLedgerSetup.Get();
            TransactionCurrTaxAmount :=
              EInvoiceDocumentEncode.DecimalToText(TempVATAmountLine."VAT Amount" * GetCurrMultiplicationFactor());
            AddGroupNodeWithData(
              XMLCurrNode, 'TransactionCurrencyTaxAmount', TransactionCurrTaxAmount, BasicCompSpaceNameTxt, CBCTxt);
            AddAttribute(XMLCurrNode, 'currencyID', GeneralLedgerSetup."LCY Code");
            XMLCurrNode := XMLCurrNode.ParentNode();
        end;

        // Header->TaxTotal->TaxSubtotal->TaxCategory
        AddGroupNode(XMLCurrNode, 'TaxCategory', AggregateCompSpaceNameTxt, CACTxt);

        TaxCategoryID :=
          GetTaxCategoryID(
            TempVATAmountLine."VAT %", TempVATAmountLine."VAT Calculation Type".AsInteger(), TempEInvoiceExportLine."VAT Prod. Posting Group", false);
        AddGroupNodeWithData(XMLCurrNode, 'ID', TaxCategoryID, BasicCompSpaceNameTxt, CBCTxt);
        AddAttribute(XMLCurrNode, 'schemeID', 'UNCL5305');
        XMLCurrNode := XMLCurrNode.ParentNode();

        AddNotEmptyNode(XMLCurrNode, 'Percent', EInvoiceDocumentEncode.DecimalToText(TempVATAmountLine."VAT %"),
          BasicCompSpaceNameTxt, CBCTxt);

        // Header->TaxTotal->TaxSubtotal->TaxCategory->TaxExemptionReason
        if TaxCategoryID in ['K', 'Z', 'E'] then begin
            VATProductPostingGroup.SetRange(Code, TempEInvoiceExportLine."VAT Prod. Posting Group");
            if VATProductPostingGroup.FindFirst() then
                AddNotEmptyNode(XMLCurrNode, 'TaxExemptionReason', VATProductPostingGroup.Description, BasicCompSpaceNameTxt, CBCTxt);
        end;

        // Header->TaxTotal->TaxSubtotal->TaxCategory->TaxScheme
        AddGroupNode(XMLCurrNode, 'TaxScheme', AggregateCompSpaceNameTxt, CACTxt);
        AddLastNode(XMLCurrNode, 'ID', 'VAT', BasicCompSpaceNameTxt, CBCTxt);
        XMLCurrNode := XMLCurrNode.ParentNode();
        XMLCurrNode := XMLCurrNode.ParentNode();
    end;

    local procedure AddAttribute(var XMLNode: DotNet XmlNode; Name: Text; Value: Text)
    begin
        XMLDOMMgt.AddAttribute(XMLNode, Name, Value);
    end;

    local procedure AddGroupNode(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NameSpace: Text[250]; Prefix: Text[30])
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, Prefix + ':' + NodeName, '', NameSpace, XMLNewChild);
        XMLNode := XMLNewChild;
    end;

    local procedure AddGroupNodeWithData(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; Prefix: Text[30])
    var
        XMLNewChild: DotNet XmlNode;
    begin
        XMLDOMMgt.AddElement(XMLNode, Prefix + ':' + NodeName, Format(NodeText, 0, 9), NameSpace, XMLNewChild);
        XMLNode := XMLNewChild;
    end;

    local procedure AddLastNode(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; Prefix: Text[30])
    begin
        AddNotEmptyNode(XMLNode, NodeName, NodeText, NameSpace, Prefix);
        XMLNode := XMLNode.ParentNode();
    end;

    local procedure AddNotEmptyNode(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; Prefix: Text[30])
    begin
        if NodeText <> '' then
            AddNodeNA(XMLNode, NodeName, NodeText, NameSpace, Prefix);
    end;

    local procedure AddNodeNA(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; Prefix: Text[30])
    var
        CreatedXMLNode: DotNet XmlNode;
    begin
        if NodeText = '' then
            NodeText := 'NA';
        XMLDOMMgt.AddElement(XMLNode, Prefix + ':' + NodeName, Format(NodeText, 0, 9), NameSpace, CreatedXMLNode);
    end;

    local procedure AddGroupNodeIDGLN(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; Prefix: Text[30])
    begin
        AddGroupNodeWithData(XMLCurrNode, NodeName, NodeText, NameSpace, Prefix);
        AddAttribute(XMLNode, 'schemeID', 'GLN');
        AddAttribute(XMLNode, 'schemeAgencyID', '9');
        XMLNode := XMLCurrNode.ParentNode();
    end;

    local procedure AddGroupNodeIDVAT(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; Prefix: Text[30])
    begin
        AddGroupNodeWithData(XMLNode, NodeName, NodeText, NameSpace, Prefix);
        AddAttribute(XMLNode, 'schemeID', 'NO:ORGNR');
        XMLNode := XMLNode.ParentNode();
    end;
}

