// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Company;
#if not CLEAN30
using System;
#endif

codeunit 10525 "EC Sales List XML"
{
    trigger OnRun()
    begin
    end;

    var
        GovTalkXMLHelper: Codeunit "GovTalk XML Helper";
        GovTalkMessageManagement: Codeunit "GovTalk Message Management";
        ECSLDeclarationNameSpaceTok: Label 'http://www.govtalk.gov.uk/taxation/vat/europeansalesdeclaration/1', Locked = true;
        ECSLSchemaLocationTok: Label 'http://www.govtalk.gov.uk/taxation/vat/europeansalesdeclaration/1 EuropeanSalesDeclarationRequest.xsd', Locked = true;
        ECSLCoreComponentParamTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CoreComponentParameters-1.0', Locked = true;
        ECSLVATCoreNameSpaceTok: Label 'http://www.govtalk.gov.uk/taxation/vat/core/1', Locked = true;
        XMLSchemaInstanceTok: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        GMSNameSpaceTok: Label 'http://www.govtalk.gov.uk/CM/gms-xs', Locked = true;
        ECSLCurrencyCodeListTok: Label 'urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0', Locked = true;
        MonthsTok: Label 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';
        ContactPersonEmptyErr: Label 'A contact person is not specified for your company. This is the person the tax authority will contact. To continue, go to the Company Information page and choose a contact person, and then submit the report again.';
        LCYEmptyErr: Label 'The local currency (LCY) is not specified. To continue, go to the General Ledger Setup page, enter a currency in the LCY Code field, and then submit the report again.';

    local procedure PopulateXMLHeader(var GovTalkMessageBodyXmlElement: XmlElement; var BodyXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CompanyInformation: Record "Company Information";
        ECSLDeclarationRequestXmlElement: XmlElement;
        ECSLDeclarationHeaderXmlElement: XmlElement;
        DummyXmlElement: XmlElement;
    begin
        if not (CompanyInformation.Get() and GeneralLedgerSetup.Get()) then
            exit;

        if GeneralLedgerSetup."LCY Code" = '' then
            Error(LCYEmptyErr);

        if CompanyInformation."Contact Person" = '' then
            Error(ContactPersonEmptyErr);

        GovTalkXMLHelper.AddElement(GovTalkMessageBodyXmlElement, 'EuropeanSalesDeclarationRequest', '', ECSLDeclarationNameSpaceTok, ECSLDeclarationRequestXmlElement);
        AddGovTalkNamespaces(ECSLDeclarationRequestXmlElement);

        GovTalkXMLHelper.AddElement(ECSLDeclarationRequestXmlElement, 'Header', '', ECSLDeclarationNameSpaceTok, ECSLDeclarationHeaderXmlElement);
        GovTalkXMLHelper.AddElement(ECSLDeclarationRequestXmlElement, 'Body', '', ECSLDeclarationNameSpaceTok, BodyXmlElement);

        GovTalkXMLHelper.AddElement(ECSLDeclarationHeaderXmlElement, 'SubmittersContactName',
          CompanyInformation."Contact Person", ECSLVATCoreNameSpaceTok, DummyXmlElement);
        AddCurrencyElement(ECSLDeclarationHeaderXmlElement, GeneralLedgerSetup."LCY Code");
        AddPeriodElement(ECSLDeclarationHeaderXmlElement, VATReportHeader);

        GovTalkXMLHelper.AddElement(ECSLDeclarationHeaderXmlElement, 'ApplyStrictEuropeanSaleValidation',
          'true', ECSLVATCoreNameSpaceTok, DummyXmlElement);
    end;

    local procedure InsertECSLDeclarationRequestDetails(var EuropeanSalesListBodyXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header"; PartId: Guid)
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        SaleXmlElement: XmlElement;
        DummyXmlElement: XmlElement;
        IndicatorVar: Integer;
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetRange("XML Part Id GB", PartId);
        if ECSLVATReportLine.FindSet() then
            repeat
                GovTalkXMLHelper.AddElement(EuropeanSalesListBodyXmlElement, 'EuropeanSale', '', ECSLDeclarationNameSpaceTok, SaleXmlElement);
                GovTalkXMLHelper.AddElement(SaleXmlElement, 'SubmittersReference', Format(ECSLVATReportLine."Line No."),
                  ECSLVATCoreNameSpaceTok, DummyXmlElement);
                GovTalkXMLHelper.AddElement(SaleXmlElement, 'CountryCode', ECSLVATReportLine."Country Code",
                  ECSLVATCoreNameSpaceTok, DummyXmlElement);
                GovTalkXMLHelper.AddElement(SaleXmlElement, 'CustomerVATRegistrationNumber',
                  GovTalkMessageManagement.FormatVATRegNo(ECSLVATReportLine."Country Code", ECSLVATReportLine."Customer VAT Reg. No."),
                  ECSLVATCoreNameSpaceTok, DummyXmlElement);
                GovTalkXMLHelper.AddElement(SaleXmlElement, 'TotalValueOfSupplies',
                  Format(ECSLVATReportLine."Total Value Of Supplies", 0, '<Sign><Integer>'), ECSLVATCoreNameSpaceTok, DummyXmlElement);
                IndicatorVar := ECSLVATReportLine."Transaction Indicator";
                GovTalkXMLHelper.AddElement(SaleXmlElement, 'TransactionIndicator', Format(IndicatorVar),
                  ECSLVATCoreNameSpaceTok, DummyXmlElement);
            until ECSLVATReportLine.Next() = 0;
    end;

    local procedure GenerateEuropeanSalesDeclarationRequest(var EuropeanSalesListXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header"; PartId: Guid)
    var
        BodyXmlElement: XmlElement;
    begin
        PopulateXMLHeader(EuropeanSalesListXmlElement, BodyXmlElement, VATReportHeader);
        InsertECSLDeclarationRequestDetails(BodyXmlElement, VATReportHeader, PartId);
    end;

    local procedure GetMonthCode(MonthNo: Integer): Text
    begin
        exit(SelectStr(MonthNo, MonthsTok));
    end;

    local procedure AddGovTalkNamespaces(var ECSLDeclarationRequestXmlElement: XmlElement)
    begin
        ECSLDeclarationRequestXmlElement.SetAttribute('SchemaVersion', '1.0');
        ECSLDeclarationRequestXmlElement.Add(XmlAttribute.Create('schemaLocation', XMLSchemaInstanceTok, ECSLSchemaLocationTok));
        GovTalkXMLHelper.AddNamespaceDeclaration(ECSLDeclarationRequestXmlElement, 'ccts', ECSLCoreComponentParamTok);
        GovTalkXMLHelper.AddNamespaceDeclaration(ECSLDeclarationRequestXmlElement, 'VATCore', ECSLVATCoreNameSpaceTok);
        ECSLDeclarationRequestXmlElement.Add(XmlAttribute.Create('xmlns', ECSLDeclarationNameSpaceTok));
        GovTalkXMLHelper.AddNamespaceDeclaration(ECSLDeclarationRequestXmlElement, 'xsi', XMLSchemaInstanceTok);
        GovTalkXMLHelper.AddNamespaceDeclaration(ECSLDeclarationRequestXmlElement, 'n1', GMSNameSpaceTok);
        GovTalkXMLHelper.AddNamespaceDeclaration(ECSLDeclarationRequestXmlElement, 'UBLCurrencyCodelist', ECSLCurrencyCodeListTok);
    end;

    local procedure AddCurrencyElement(var ECSLDeclarationHeaderXmlElement: XmlElement; CurrencyCode: Code[10])
    var
        CurrencyXmlElement: XmlElement;
    begin
        GovTalkXMLHelper.AddElement(ECSLDeclarationHeaderXmlElement, 'CurrencyCode', CurrencyCode, ECSLVATCoreNameSpaceTok, CurrencyXmlElement);
        CurrencyXmlElement.SetAttribute('codeListName', 'Currency');
        CurrencyXmlElement.SetAttribute('codeListID', 'ISO 4217 Alpha');
        CurrencyXmlElement.SetAttribute('codeListAgencyName', 'United Nations Economic Commission for Europe');
        CurrencyXmlElement.SetAttribute('codeListSchemeURI', 'urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0');
        CurrencyXmlElement.SetAttribute('codeListURI',
          'http://www.bsi-global.com/Technical%2BInformation/Publications/_Publications/tig90x.doc');
        CurrencyXmlElement.SetAttribute('name', 'String');
        CurrencyXmlElement.SetAttribute('codeListAgencyID', '6');
        CurrencyXmlElement.SetAttribute('codeListVersionID', '0.3');
        CurrencyXmlElement.SetAttribute('languageID', 'en');
    end;

    local procedure AddPeriodElement(var ECSLDeclarationHeaderXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header")
    var
        DummyXmlElement: XmlElement;
        ECSLPeriodXmlElement: XmlElement;
    begin
        if VATReportHeader."Period Type" = VATReportHeader."Period Type"::Month then begin
            GovTalkXMLHelper.AddElement(ECSLDeclarationHeaderXmlElement, 'TaxMonthlyPeriod', '', ECSLVATCoreNameSpaceTok, ECSLPeriodXmlElement);
            GovTalkXMLHelper.AddElement(ECSLPeriodXmlElement, 'TaxMonth', GetMonthCode(VATReportHeader."Period No."),
              ECSLVATCoreNameSpaceTok, DummyXmlElement);
            GovTalkXMLHelper.AddElement(ECSLPeriodXmlElement, 'TaxMonthPeriodYear', Format(VATReportHeader."Period Year"),
              ECSLVATCoreNameSpaceTok, DummyXmlElement);
            exit;
        end;
        if VATReportHeader."Period Type" = VATReportHeader."Period Type"::Quarter then begin
            GovTalkXMLHelper.AddElement(ECSLDeclarationHeaderXmlElement, 'TaxQuarter', '', ECSLVATCoreNameSpaceTok, ECSLPeriodXmlElement);
            GovTalkXMLHelper.AddElement(ECSLPeriodXmlElement, 'TaxQuarterNumber', Format(VATReportHeader."Period No."),
              ECSLVATCoreNameSpaceTok, DummyXmlElement);
            GovTalkXMLHelper.AddElement(ECSLPeriodXmlElement, 'TaxQuarterYear', Format(VATReportHeader."Period Year"),
              ECSLVATCoreNameSpaceTok, DummyXmlElement);
        end;
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use GetECSLDeclarationRequestMessage with an XmlElement parameter instead.', '30.0')]
    procedure GetECSLDeclarationRequestMessage(var GovTalkRequestXMLNode: DotNet XmlNode; VATReportHeader: Record "VAT Report Header"; PartId: Guid): Boolean
    var
        GovTalkRequestXmlElement: XmlElement;
        XmlDoc: DotNet XmlDocument;
    begin
        if not GetECSLDeclarationRequestMessage(GovTalkRequestXmlElement, VATReportHeader, PartId) then
            exit(false);
        XmlDoc := XmlDoc.XmlDocument();
        XmlDoc.LoadXml(GovTalkXMLHelper.GetXmlAsText(GovTalkRequestXmlElement));
        GovTalkRequestXMLNode := XmlDoc.DocumentElement;
        exit(true);
    end;
#endif

    [Scope('OnPrem')]
    procedure GetECSLDeclarationRequestMessage(var GovTalkRequestXmlElement: XmlElement; VATReportHeader: Record "VAT Report Header"; PartId: Guid): Boolean
    var
        GovTalkMsgManagement: Codeunit "GovTalk Message Management";
        BodyXmlElement: XmlElement;
    begin
        if not GovTalkMsgManagement.CreateBlankGovTalkXmlMessage(
             GovTalkRequestXmlElement, BodyXmlElement, VATReportHeader, 'request', 'submit', true)
        then
            exit(false);
        GenerateEuropeanSalesDeclarationRequest(BodyXmlElement, VATReportHeader, PartId);
        exit(true);
    end;
}
