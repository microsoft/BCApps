namespace System.IO;

using Microsoft.Bank.Reconciliation;
using System;
using System.Utilities;

codeunit 1240 "Read Data Exch. from File"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchMapping: Record "Data Exch. Mapping";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        RecordRef: RecordRef;
    begin
        OnBeforeFileImport(TempBlob, Rec."File Name");

        if not TempBlob.HasValue() then
            Rec."File Name" := CopyStr(
                FileMgt.BLOBImportWithFilter(TempBlob, ImportBankStmtTxt, '', FileFilterTxt, FileFilterExtensionTxt), 1, 250);

        if Rec."File Name" = '' then
            exit;

        DataExchMapping.SetRange("Data Exch. Def Code", Rec."Data Exch. Def Code");
        DataExchMapping.SetRange("Data Exch. Line Def Code", Rec."Data Exch. Line Def Code");
        DataExchMapping.SetRange("Table ID", DATABASE::"Bank Acc. Reconciliation Line");
        if DataExchMapping.FindFirst() then
            if DataExchMapping."Mapping Codeunit" = CODEUNIT::"SEPA CAMT 054 Bank Rec. Lines" then
                XMLSplitPaymentPerInvoices(TempBlob);

        OnRunOnBeforeGetTable(TempBlob, Rec);
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, Rec.FieldNo("File Content"));
        RecordRef.SetTable(Rec);
    end;

    var
        ImportBankStmtTxt: Label 'Select a file to import';
        FileFilterTxt: Label 'All Files(*.*)|*.*|XML Files(*.xml)|*.xml|Text Files(*.txt;*.csv;*.asc)|*.txt;*.csv;*.asc;*.nda';
        FileFilterExtensionTxt: Label 'txt,csv,asc,xml,nda', Locked = true;

    local procedure XMLSplitPaymentPerInvoices(var TempBlob: Codeunit "Temp Blob")
    var
        OrigXmlDocument: DotNet XmlDocument;
        NewXmlDocument: DotNet XmlDocument;
        OrigPmtXmlDocument: DotNet XmlDocument;
        OrigPaymentXMLNodeList: DotNet XmlNodeList;
        OrigInvoiceXMLNodeList: DotNet XmlNodeList;
        NewPmtParentXMLNode: DotNet XmlNode;
        NewInvParentXMLNode: DotNet XmlNode;
        OrigInvoiceXMLNode: DotNet XmlNode;
        NewInvoiceXMLNode: DotNet XmlNode;
        NewPmtXMLNode: DotNet XmlNode;
        NewPmtTemplateXMLNode: DotNet XmlNode;
        OutStream: OutStream;
        InStream: InStream;
        PmtParentNodeName: Text;
        InvParentNodeName: Text;
        PaymentNodeName: Text;
        InvoiceNodeName: Text;
        AmountNodeName: Text;
        CurrencyAttributeName: Text;
        PaymentIndex: Integer;
        InvoiceIndex: Integer;
        InvoiceCount: Integer;
        PaymentAmount: Decimal;
        InvoiceAmount: Decimal;
        PaymentCurrency: Text;
        InvoiceCurrency: Text;
        ValidPmtInfo: Boolean;
        ValidInvInfo: Boolean;
    begin
        // Split payment with several invoices (1 pmt <-> sev inv) per invoices (1 pmt <-> 1 inv) in case of the same currency code
        // Duplicate all payment information, split original payment amount by invoices amounts, use remaining for the last one invoice
        // Ignore result in case of any xml processing error
        PmtParentNodeName := 'Ntfctn';
        PaymentNodeName := 'Ntry';
        InvParentNodeName := 'NtryDtls';
        InvoiceNodeName := 'TxDtls';
        AmountNodeName := 'Amt';
        CurrencyAttributeName := 'Ccy';

        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        OrigXmlDocument := OrigXmlDocument.XmlDocument();
        OrigXmlDocument.Load(InStream);
        if IsNull(OrigXmlDocument) then
            exit;
        if not OrigXmlDocument.HasChildNodes then
            exit;

        // Create a new xml document: duplicate the old one and remove all payment nodes
        NewXmlDocument := OrigXmlDocument.Clone();
        XMLRemoveAllChildNodes(NewXmlDocument, PaymentNodeName);
        if not XMLFindFirstChild(NewPmtParentXMLNode, NewXmlDocument, PmtParentNodeName) then
            exit;

        // Read the old document by payment nodes
        OrigPaymentXMLNodeList := OrigXmlDocument.GetElementsByTagName(PaymentNodeName);
        for PaymentIndex := 0 to OrigPaymentXMLNodeList.Count - 1 do begin
            // Read next payment info
            OrigPmtXmlDocument := OrigPaymentXMLNodeList.Item(PaymentIndex);
            NewPmtTemplateXMLNode := OrigPmtXmlDocument.Clone();
            OrigInvoiceXMLNodeList := OrigPmtXmlDocument.GetElementsByTagName(InvoiceNodeName);
            InvoiceCount := OrigInvoiceXMLNodeList.Count();
            ValidPmtInfo :=
              XMLReadAmountNodeWithAttributeText(
                PaymentAmount, PaymentCurrency, OrigPmtXmlDocument, AmountNodeName, CurrencyAttributeName);

            // Check all invoices under current payment have the same currency code and payment amount equals to sum of invoices amounts
            if ValidPmtInfo and (InvoiceCount > 0) then
                ValidInvInfo := XMLCheckInvoices(OrigInvoiceXMLNodeList, AmountNodeName, CurrencyAttributeName, PaymentAmount, PaymentCurrency);

            // If all invoices correspond to current payment then process split else copy payment with invoices as is
            if ValidPmtInfo and ValidInvInfo and (InvoiceCount > 0) then begin
                // Prepare payment template without invoice nodes for duplication
                XMLRemoveAllChildNodes(NewPmtTemplateXMLNode, InvoiceNodeName);

                // Read the old document by invoice nodes within the given payment node
                for InvoiceIndex := 0 to InvoiceCount - 1 do begin
                    // Read next invoice info
                    OrigInvoiceXMLNode := OrigInvoiceXMLNodeList.Item(InvoiceIndex);
                    NewInvoiceXMLNode := OrigInvoiceXMLNode.Clone();
                    XMLReadAmountNodeWithAttributeText(
                      InvoiceAmount, InvoiceCurrency, OrigInvoiceXMLNode, AmountNodeName, CurrencyAttributeName);
                    // Prepare a new payment node from payment template and insert current invoice into it
                    NewPmtXMLNode := NewPmtTemplateXMLNode.Clone();
                    if not XMLWriteAmountNode(NewPmtXMLNode, AmountNodeName, InvoiceAmount) then
                        exit;
                    if not XMLFindFirstChild(NewInvParentXMLNode, NewPmtXMLNode, InvParentNodeName) then
                        exit;
                    NewInvParentXMLNode.AppendChild(NewInvoiceXMLNode);
                    // Insert the new payment node into the new document
                    XMLImportAppendChild(NewXmlDocument, NewPmtParentXMLNode, NewPmtXMLNode);
                end;
            end else
                XMLImportAppendChild(NewXmlDocument, NewPmtParentXMLNode, NewPmtTemplateXMLNode);
        end;

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        NewXmlDocument.Save(OutStream);
    end;

    local procedure XMLCheckInvoices(InvoiceXMLNodeList: DotNet XmlNodeList; AmountNodeName: Text; CurrencyAttributeName: Text; PaymentAmount: Decimal; PaymentCurrency: Text) Result: Boolean
    var
        InvoiceXMLNode: DotNet XmlNode;
        InvoiceCount: Integer;
        InvoiceIndex: Integer;
        InvoiceAmount: Decimal;
        InvoiceCurrency: Text;
    begin
        InvoiceCount := InvoiceXMLNodeList.Count();
        InvoiceIndex := 0;
        repeat
            InvoiceXMLNode := InvoiceXMLNodeList.Item(InvoiceIndex);
            Result :=
              XMLReadAmountNodeWithAttributeText(
                InvoiceAmount, InvoiceCurrency, InvoiceXMLNode, AmountNodeName, CurrencyAttributeName);
            Result := Result and (PaymentCurrency = InvoiceCurrency) and (PaymentAmount > 0);
            PaymentAmount -= InvoiceAmount;
            InvoiceIndex += 1;
        until not Result or (InvoiceIndex = InvoiceCount);
        Result := Result and (PaymentAmount = 0);
    end;

    local procedure XMLRemoveAllChildNodes(var XmlDocument: DotNet XmlDocument; ChildNodeName: Text)
    var
        XMLNode: DotNet XmlNode;
        ParentXMLNode: DotNet XmlNode;
        XMLNodeList: DotNet XmlNodeList;
        Index: Integer;
    begin
        XMLNodeList := XmlDocument.GetElementsByTagName(ChildNodeName);
        for Index := 1 to XMLNodeList.Count do begin
            XMLNode := XMLNodeList.Item(0);
            ParentXMLNode := XMLNode.ParentNode;
            ParentXMLNode.RemoveChild(XMLNode);
        end;
    end;

    local procedure XMLFindFirstChild(var XMLNode: DotNet XmlNode; XmlDocument: DotNet XmlDocument; ChildName: Text): Boolean
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XmlDocument.GetElementsByTagName(ChildName);
        if XMLNodeList.Count = 0 then
            exit(false);

        XMLNode := XMLNodeList.Item(0);
        exit(true);
    end;

    local procedure XMLImportAppendChild(var XmlDocument: DotNet XmlDocument; ParentXMLNode: DotNet XmlNode; XMLNode: DotNet XmlNode)
    begin
        XMLNode := XmlDocument.ImportNode(XMLNode, true);
        ParentXMLNode.AppendChild(XMLNode);
    end;

    local procedure XMLReadAmountNodeWithAttributeText(var Amount: Decimal; var AttributeText: Text; XmlDocument: DotNet XmlDocument; NodeName: Text; AttributeName: Text): Boolean
    var
        XMLNode: DotNet XmlNode;
        XMLAttribute: DotNet XmlAttribute;
    begin
        if not XMLFindFirstChild(XMLNode, XmlDocument, NodeName) then
            exit(false);

        if not Evaluate(Amount, XMLNode.InnerText, 9) then
            exit(false);

        XMLAttribute := XMLNode.Attributes.GetNamedItem(AttributeName);
        if IsNull(XMLAttribute) then
            exit(false);

        AttributeText := XMLAttribute.Value();
        exit(true);
    end;

    local procedure XMLWriteAmountNode(XmlDocument: DotNet XmlDocument; NodeName: Text; Amount: Decimal): Boolean
    var
        XMLNode: DotNet XmlNode;
    begin
        if not XMLFindFirstChild(XMLNode, XmlDocument, NodeName) then
            exit(false);

        XMLNode.InnerText := Format(Amount, 0, 9);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFileImport(var TempBlob: Codeunit "Temp Blob"; var FileName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGetTable(var TempBlob: Codeunit "Temp Blob"; DataExch: Record "Data Exch.")
    begin
    end;
}

