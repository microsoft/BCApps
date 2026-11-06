// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
#if not CLEAN30
using System;
using System.Utilities;
#endif

codeunit 12150 "VAT Pmt. Comm. XML Generator"
{

    trigger OnRun()
    begin
    end;

    var
        IVURLTxt: Label 'urn:www.agenziaentrate.gov.it:specificheTecniche:sco:ivp', Locked = true;
        VATPmtCommDataLookup: Codeunit "VAT Pmt. Comm. Data Lookup";

    [Scope('OnPrem')]
    procedure SetVATPmtCommDataLookup(VATPmtCommDataLookupValue: Codeunit "VAT Pmt. Comm. Data Lookup")
    begin
        VATPmtCommDataLookup := VATPmtCommDataLookupValue;
    end;

    /// <summary>
    /// Creates the VAT payment communication XML document. The document has no XML declaration node; when written with
    /// XmlDocument.WriteTo(OutStream) it is saved as UTF-8 with a byte order mark and an XML declaration.
    /// </summary>
    [Scope('OnPrem')]
    procedure CreateXml(var XmlDoc: XmlDocument)
    var
        XmlRootElement: XmlElement;
    begin
        XmlDoc := XmlDocument.Create();
        XmlRootElement := XmlElement.Create('Fornitura', IVURLTxt);
        XmlDoc.Add(XmlRootElement);
        PopulateHeader(XmlRootElement);
        PopulateComunicazione(XmlRootElement);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('XML DOM Management is being phased out. Use the CreateXml overload with the native XmlDocument type instead.', '30.0')]
    procedure CreateXml(var XMLDoc: DotNet XmlDocument)
    var
        TempBlob: Codeunit "Temp Blob";
        NativeXmlDocument: XmlDocument;
        OutStream: OutStream;
        InStream: InStream;
    begin
        CreateXml(NativeXmlDocument);
        TempBlob.CreateOutStream(OutStream);
        NativeXmlDocument.WriteTo(OutStream);
        TempBlob.CreateInStream(InStream);
        XMLDoc := XMLDoc.XmlDocument();
        XMLDoc.Load(InStream);
    end;
#endif

    local procedure PopulateHeader(var XmlRootElement: XmlElement)
    var
        ChildXmlElement: XmlElement;
        IntestazioneXmlElement: XmlElement;
    begin
        AddElement(XmlRootElement, 'Intestazione', '', IntestazioneXmlElement);
        AddElement(IntestazioneXmlElement, 'CodiceFornitura',
          VATPmtCommDataLookup.GetSupplyCode(), ChildXmlElement);
        if VATPmtCommDataLookup.HasTaxDeclarant() then
            AddElement(IntestazioneXmlElement, 'CodiceFiscaleDichiarante',
              VATPmtCommDataLookup.GetTaxDeclarant(), ChildXmlElement);
        if VATPmtCommDataLookup.HasChargeCode() then
            AddElement(IntestazioneXmlElement, 'CodiceCarica',
              VATPmtCommDataLookup.GetChargeCode(), ChildXmlElement);
    end;

    local procedure PopulateComunicazione(var XmlRootElement: XmlElement)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        XMLNode: XmlElement;
        TempXMLNode: XmlElement;
        StartDate: Date;
        FirstDateOfQuarter: Date;
        MonthlyStartDate: Date;
    begin
        AddElement(XmlRootElement, 'Comunicazione', '', XMLNode);
        XMLNode.SetAttribute('identificativo', VATPmtCommDataLookup.GetCommunicationID());
        AddElement(XMLNode, 'Frontespizio', '', XMLNode);
        AddElementIfNotEmpty(XMLNode, 'CodiceFiscale',
          VATPmtCommDataLookup.GetFiscalCode(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'AnnoImposta',
          VATPmtCommDataLookup.GetCurrentYear(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'PartitaIVA',
          VATPmtCommDataLookup.GetVATRegistrationNo(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CFDichiarante',
          VATPmtCommDataLookup.GetTaxDeclarantVATNo(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CodiceCaricaDichiarante',
          VATPmtCommDataLookup.GetTaxDeclarantPosionCode(), TempXMLNode);
        if not VATPmtCommDataLookup.WasIntermediarySet() then
            AddElementIfNotEmpty(XMLNode, 'CodiceFiscaleSocieta',
              VATPmtCommDataLookup.GetDeclarantFiscalCode(), TempXMLNode);
        AddElement(XMLNode, 'FirmaDichiarazione', VATPmtCommDataLookup.GetIsSigned(), TempXMLNode);
        if VATPmtCommDataLookup.WasIntermediarySet() then
            AddElementIfNotEmpty(XMLNode, 'CFIntermediario',
              VATPmtCommDataLookup.GetIntermediary(), TempXMLNode);
        if VATPmtCommDataLookup.HasCommitmentSubmission() then
            AddElementIfNotEmpty(XMLNode, 'ImpegnoPresentazione',
              VATPmtCommDataLookup.GetCommitmentSubmission(), TempXMLNode);
        if VATPmtCommDataLookup.HasIntermediary() then
            AddElementIfNotEmpty(XMLNode, 'DataImpegno',
              VATPmtCommDataLookup.GetIntermediaryDate(), TempXMLNode);
        if VATPmtCommDataLookup.HasIntermediary() then
            AddElementIfNotEmpty(XMLNode, 'FirmaIntermediario',
              VATPmtCommDataLookup.GetIsIntermediary(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'FlagConferma',
          VATPmtCommDataLookup.GetFlagDeviations(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'IdentificativoProdSoftware',
          UpperCase(VATPmtCommDataLookup.GetSoftware()), TempXMLNode);

        XMLNode.GetParent(XMLNode);
        AddElement(XMLNode, 'DatiContabili', '', XMLNode);
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

    local procedure PopulateModuloForMonth(DataContabiliNode: XmlElement; StartDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        XMLNode: XmlElement;
        TempXMLNode: XmlElement;
        AdvancedTaxAmount: Decimal;
    begin
        VATPmtCommDataLookup.SetStartDate(StartDate);
        AddElement(DataContabiliNode, 'Modulo', '', XMLNode);
        AddElementIfNotEmpty(XMLNode, 'NumeroModulo',
          Format(VATPmtCommDataLookup.GetModuleNumber()), TempXMLNode);
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."VAT Settlement Period" = GeneralLedgerSetup."VAT Settlement Period"::Month then
            AddElementIfNotEmpty(XMLNode, 'Mese',
              VATPmtCommDataLookup.GetMonth(), TempXMLNode)
        else
            AddElementIfNotEmpty(XMLNode, 'Trimestre',
              VATPmtCommDataLookup.GetQuarter(), TempXMLNode);

        if VATPmtCommDataLookup.HasSubcontracting() then
            AddElementIfNotEmpty(XMLNode, 'Subfornitura',
              VATPmtCommDataLookup.GetSubcontracting(), TempXMLNode);
        if VATPmtCommDataLookup.HasExceptionalEvents() then
            AddElementIfNotEmpty(XMLNode, 'EventiEccezionali',
              VATPmtCommDataLookup.GetExceptionalEvents(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'OperazioniStraordinarie',
          VATPmtCommDataLookup.GetExtraordinaryOperations(), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'TotaleOperazioniAttive',
          DecimalToText(VATPmtCommDataLookup.GetTotalSales()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'TotaleOperazioniPassive',
          DecimalToText(VATPmtCommDataLookup.GetTotalPurchases()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'IvaEsigibile',
          DecimalToText(VATPmtCommDataLookup.GetVATSales()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'IvaDetratta',
          DecimalToText(VATPmtCommDataLookup.GetVATPurchases()), TempXMLNode);
        if VATPmtCommDataLookup.HasVATDebit() then
            AddElementIfNotEmpty(XMLNode, 'IvaDovuta',
              DecimalToText(VATPmtCommDataLookup.GetVATDebit()), TempXMLNode);
        if VATPmtCommDataLookup.HasVATCredit() then
            AddElementIfNotEmpty(XMLNode, 'IvaCredito',
              DecimalToText(VATPmtCommDataLookup.GetVATCredit()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'DebitoPrecedente',
          DecimalToText(VATPmtCommDataLookup.GetPeriodVATDebit()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CreditoPeriodoPrecedente',
          DecimalToText(VATPmtCommDataLookup.GetPeriodVATCredit()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CreditoAnnoPrecedente',
          DecimalToText(VATPmtCommDataLookup.GetAnnualVATCredit()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'CreditiImposta',
          DecimalToText(VATPmtCommDataLookup.GetCreditVATCompensation()), TempXMLNode);
        AddElementIfNotEmpty(XMLNode, 'InteressiDovuti',
          DecimalToText(VATPmtCommDataLookup.GetTaxDebitVariationInterest()), TempXMLNode);

        AdvancedTaxAmount := VATPmtCommDataLookup.GetAdvancedTaxAmount();
        if AdvancedTaxAmount <> 0 then begin
            AddElementIfNotEmpty(XMLNode, 'Metodo',
              Format(VATPmtCommDataLookup.GetMethodOfCalcAdvancedNo()), TempXMLNode);
            AddElementIfNotEmpty(XMLNode, 'Acconto',
              DecimalToText(AdvancedTaxAmount), TempXMLNode);
        end;

        if VATPmtCommDataLookup.HasTaxDebit() then
            AddElementIfNotEmpty(XMLNode, 'ImportoDaVersare',
              DecimalToText(VATPmtCommDataLookup.GetTaxDebit()), TempXMLNode);
        if VATPmtCommDataLookup.HasTexCredit() then
            AddElementIfNotEmpty(XMLNode, 'ImportoACredito',
              DecimalToText(VATPmtCommDataLookup.GetTexCredit()), TempXMLNode);
    end;

    local procedure AddElementIfNotEmpty(var ParentXmlElement: XmlElement; NodeName: Text; NodeText: Text; var CreatedXmlElement: XmlElement)
    begin
        if (NodeText = '') or (NodeText = '0,00') then
            exit;
        AddElement(ParentXmlElement, NodeName, NodeText, CreatedXmlElement);
    end;

    local procedure AddElement(var ParentXmlElement: XmlElement; NodeName: Text; NodeText: Text; var CreatedXmlElement: XmlElement)
    var
        NewXmlElement: XmlElement;
    begin
        // All elements are in the default namespace declared on the root, so they are serialized without a prefix.
        NewXmlElement := XmlElement.Create(NodeName, IVURLTxt);
        if NodeText <> '' then
            NewXmlElement.Add(XmlText.Create(NodeText));
        ParentXmlElement.Add(NewXmlElement);
        CreatedXmlElement := NewXmlElement;
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

