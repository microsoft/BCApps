// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using System;
using System.Xml;

codeunit 12150 "VAT Pmt. Comm. XML Generator"
{

    trigger OnRun()
    begin
    end;

    var
        IVURLTxt: Label 'urn:www.agenziaentrate.gov.it:specificheTecniche:sco:ivp', Comment = 'Locked';
        VATPmtCommDataLookup: Codeunit "VAT Pmt. Comm. Data Lookup";
        XMLDOMManagement: Codeunit "XML DOM Management";

    [Scope('OnPrem')]
    procedure SetVATPmtCommDataLookup(VATPmtCommDataLookupValue: Codeunit "VAT Pmt. Comm. Data Lookup")
    begin
        VATPmtCommDataLookup := VATPmtCommDataLookupValue;
    end;

    [Scope('OnPrem')]
    procedure CreateXml(var XMLDoc: DotNet XmlDocument)
    var
        XMLRootNode: DotNet XmlNode;
    begin
        XMLDoc := XMLDoc.XmlDocument();
        PopulateXml(XMLRootNode, XMLDoc);
    end;

    local procedure PopulateXml(var XMLRootNode: DotNet XmlNode; var XMLDoc: DotNet XmlDocument)
    begin
        XMLDOMManagement.AddRootElement(XMLDoc, 'Fornitura', XMLRootNode);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'utf-8', '');
        XMLDOMManagement.AddAttribute(XMLRootNode, 'xmlns', IVURLTxt);
        PopulateHeader(XMLRootNode);
        PopulateComunicazione(XMLRootNode);
    end;

    local procedure PopulateHeader(var XMLRootNode: DotNet XmlNode)
    var
        XMLNode: DotNet XmlNode;
        IntestazioneXmlNode: DotNet XmlNode;
    begin
        XMLDOMManagement.AddElement(XMLRootNode, 'Intestazione', '', '', IntestazioneXmlNode);
        XMLDOMManagement.AddElement(IntestazioneXmlNode, 'CodiceFornitura',
          VATPmtCommDataLookup.GetSupplyCode(), '', XMLNode);
        if VATPmtCommDataLookup.HasTaxDeclarant() then
            XMLDOMManagement.AddElement(IntestazioneXmlNode, 'CodiceFiscaleDichiarante',
              VATPmtCommDataLookup.GetTaxDeclarant(), '', XMLNode);
        if VATPmtCommDataLookup.HasChargeCode() then
            XMLDOMManagement.AddElement(IntestazioneXmlNode, 'CodiceCarica',
              VATPmtCommDataLookup.GetChargeCode(), '', XMLNode);
    end;

    local procedure PopulateComunicazione(var XMLRootNode: DotNet XmlNode)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        XMLNode: DotNet XmlNode;
        TempXMLNode: DotNet XmlNode;
        StartDate: Date;
        FirstDateOfQuarter: Date;
        MonthlyStartDate: Date;
    begin
        XMLDOMManagement.AddElement(XMLRootNode, 'Comunicazione', '', '', XMLNode);
        XMLDOMManagement.AddAttribute(XMLNode, 'identificativo', VATPmtCommDataLookup.GetCommunicationID());
        XMLDOMManagement.AddElement(XMLNode, 'Frontespizio', '', '', XMLNode);
        AddElementIfNotEmpty(XMLNode, 'CodiceFiscale',
          VATPmtCommDataLookup.GetFiscalCode(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'AnnoImposta',
          VATPmtCommDataLookup.GetCurrentYear(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'PartitaIVA',
          VATPmtCommDataLookup.GetVATRegistrationNo(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CFDichiarante',
          VATPmtCommDataLookup.GetTaxDeclarantVATNo(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CodiceCaricaDichiarante',
          VATPmtCommDataLookup.GetTaxDeclarantPosionCode(), '', TempXMLNode);
        if not VATPmtCommDataLookup.WasIntermediarySet() then
            AddElementIfNotEmpty(XMLNode, 'CodiceFiscaleSocieta',
              VATPmtCommDataLookup.GetDeclarantFiscalCode(), '', TempXMLNode);
        XMLDOMManagement.AddElement(XMLNode, 'FirmaDichiarazione', VATPmtCommDataLookup.GetIsSigned(), '', TempXMLNode);
        if VATPmtCommDataLookup.WasIntermediarySet() then
            AddElementIfNotEmpty(XMLNode, 'CFIntermediario',
              VATPmtCommDataLookup.GetIntermediary(), '', TempXMLNode);
        if VATPmtCommDataLookup.HasCommitmentSubmission() then
            AddElementIfNotEmpty(XMLNode, 'ImpegnoPresentazione',
              VATPmtCommDataLookup.GetCommitmentSubmission(), '', TempXMLNode);
        if VATPmtCommDataLookup.HasIntermediary() then
            AddElementIfNotEmpty(XMLNode, 'DataImpegno',
              VATPmtCommDataLookup.GetIntermediaryDate(), '', TempXMLNode);
        if VATPmtCommDataLookup.HasIntermediary() then
            AddElementIfNotEmpty(XMLNode, 'FirmaIntermediario',
              VATPmtCommDataLookup.GetIsIntermediary(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'FlagConferma',
          VATPmtCommDataLookup.GetFlagDeviations(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'IdentificativoProdSoftware',
          UpperCase(VATPmtCommDataLookup.GetSoftware()), '', TempXMLNode);

        XMLDOMManagement.FindNode(XMLNode, '..', XMLNode);
        XMLDOMManagement.AddElement(XMLNode, 'DatiContabili', '', '', XMLNode);
        StartDate := VATPmtCommDataLookup.GetStartingDate();
        FirstDateOfQuarter := GetFirstDateOfQuarter(StartDate);
        MonthlyStartDate := FirstDateOfQuarter;
        PopulateModuloForMonth(XMLNode, MonthlyStartDate); // first month of quarter
        MonthlyStartDate := CalcDate('<1M>', MonthlyStartDate);
        GeneralLedgerSetup.Get();
        if (GeneralLedgerSetup."VAT Settlement Period" = GeneralLedgerSetup."VAT Settlement Period"::Month) and
           (MonthlyStartDate <= StartDate)
        then begin
            PopulateModuloForMonth(XMLNode, MonthlyStartDate); // second month of quarter
            MonthlyStartDate := CalcDate('<1M>', MonthlyStartDate);
            if MonthlyStartDate <= StartDate then
                PopulateModuloForMonth(XMLNode, MonthlyStartDate); // third month of quarter
        end;
    end;

    local procedure PopulateModuloForMonth(DataContabiliNode: DotNet XmlNode; StartDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        XMLNode: DotNet XmlNode;
        TempXMLNode: DotNet XmlNode;
        AdvancedTaxAmount: Decimal;
    begin
        VATPmtCommDataLookup.SetStartDate(StartDate);
        XMLDOMManagement.AddElement(DataContabiliNode, 'Modulo', '', '', XMLNode);
        AddElementIfNotEmpty(XMLNode, 'NumeroModulo',
          Format(VATPmtCommDataLookup.GetModuleNumber()), '', TempXMLNode);
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."VAT Settlement Period" = GeneralLedgerSetup."VAT Settlement Period"::Month then
            AddElementIfNotEmpty(XMLNode, 'Mese',
              VATPmtCommDataLookup.GetMonth(), '', TempXMLNode)
        else
            AddElementIfNotEmpty(XMLNode, 'Trimestre',
              VATPmtCommDataLookup.GetQuarter(), '', TempXMLNode);

        if VATPmtCommDataLookup.HasSubcontracting() then
            AddElementIfNotEmpty(XMLNode, 'Subfornitura',
              VATPmtCommDataLookup.GetSubcontracting(), '', TempXMLNode);
        if VATPmtCommDataLookup.HasExceptionalEvents() then
            AddElementIfNotEmpty(XMLNode, 'EventiEccezionali',
              VATPmtCommDataLookup.GetExceptionalEvents(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'OperazioniStraordinarie',
          VATPmtCommDataLookup.GetExtraordinaryOperations(), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'TotaleOperazioniAttive',
          DecimalToText(VATPmtCommDataLookup.GetTotalSales()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'TotaleOperazioniPassive',
          DecimalToText(VATPmtCommDataLookup.GetTotalPurchases()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'IvaEsigibile',
          DecimalToText(VATPmtCommDataLookup.GetVATSales()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'IvaDetratta',
          DecimalToText(VATPmtCommDataLookup.GetVATPurchases()), '', TempXMLNode);
        if VATPmtCommDataLookup.HasVATDebit() then
            AddElementIfNotEmpty(XMLNode, 'IvaDovuta',
              DecimalToText(VATPmtCommDataLookup.GetVATDebit()), '', TempXMLNode);
        if VATPmtCommDataLookup.HasVATCredit() then
            AddElementIfNotEmpty(XMLNode, 'IvaCredito',
              DecimalToText(VATPmtCommDataLookup.GetVATCredit()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'DebitoPrecedente',
          DecimalToText(VATPmtCommDataLookup.GetPeriodVATDebit()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CreditoPeriodoPrecedente',
          DecimalToText(VATPmtCommDataLookup.GetPeriodVATCredit()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CreditoAnnoPrecedente',
          DecimalToText(VATPmtCommDataLookup.GetAnnualVATCredit()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CreditiImposta',
          DecimalToText(VATPmtCommDataLookup.GetCreditVATCompensation()), '', TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'InteressiDovuti',
          DecimalToText(VATPmtCommDataLookup.GetTaxDebitVariationInterest()), '', TempXMLNode);

        AdvancedTaxAmount := VATPmtCommDataLookup.GetAdvancedTaxAmount();
        if AdvancedTaxAmount <> 0 then begin
            AddElementIfNotEmpty(XMLNode, 'Metodo',
              Format(VATPmtCommDataLookup.GetMethodOfCalcAdvancedNo()), '', TempXMLNode);
            AddElementIfNotEmpty(XMLNode, 'Acconto',
              DecimalToText(AdvancedTaxAmount), '', TempXMLNode);
        end;

        if VATPmtCommDataLookup.HasTaxDebit() then
            AddElementIfNotEmpty(XMLNode, 'ImportoDaVersare',
              DecimalToText(VATPmtCommDataLookup.GetTaxDebit()), '', TempXMLNode);
        if VATPmtCommDataLookup.HasTexCredit() then
            AddElementIfNotEmpty(XMLNode, 'ImportoACredito',
              DecimalToText(VATPmtCommDataLookup.GetTexCredit()), '', TempXMLNode);
    end;

    local procedure AddElementIfNotEmpty(var XMLNode: DotNet XmlNode; NodeName: Text; NodeText: Text; NameSpace: Text; var CreatedXMLNode: DotNet XmlNode)
    begin
        if (NodeText = '') or (NodeText = '0,00') then
            exit;
        XMLDOMManagement.AddElement(XMLNode, NodeName, NodeText, NameSpace, CreatedXMLNode);
    end;

    [Scope('OnPrem')]
    procedure DecimalToText(DecimalValue: Decimal): Text[16]
    begin
        exit(Format(DecimalValue, 0, '<Precision,2><Sign><Integer><Decimals><Comma,,>'));
    end;

    [Scope('OnPrem')]
    procedure GetFirstDateOfQuarter(Date: Date) Result: Date
    var
        EndOfQuarterDate: Date;
        EndOfPrevQuarterDate: Date;
        LastDateOfMonthDate: Date;
    begin
        EndOfQuarterDate := CalcDate('<CQ>', Date);
        EndOfPrevQuarterDate := CalcDate('<-1Q>', EndOfQuarterDate);
        LastDateOfMonthDate := CalcDate('<CM>', EndOfPrevQuarterDate);
        Result := CalcDate('<1D>', LastDateOfMonthDate);
    end;
}

