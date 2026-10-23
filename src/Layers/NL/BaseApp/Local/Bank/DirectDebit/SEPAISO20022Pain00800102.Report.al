// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
#if not CLEAN30
using System;
#endif
using System.IO;
using System.Telemetry;
using System.Text;
using System.Utilities;

report 11000013 "SEPA ISO20022 Pain 008.001.02"
{
    Caption = 'SEPA ISO20022 Pain 008.001.02';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payment History"; "Payment History")
        {
            DataItemTableView = sorting("Our Bank", "Run No.");
            RequestFilterFields = "Our Bank", "Export Protocol", "Run No.", Status, Export;

            trigger OnAfterGetRecord()
            begin
                ExportFileName := GenerateExportfilename(AlwaysNewFileName);
                ExportProtocolCode := "Export Protocol";
                ExportSEPAFile();

                Export := false;
                if Status = Status::New then
                    Validate(Status, Status::Transmitted);
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                if "Payment History".FindSet(true) then;
                CompanyInfo.Get();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AlwaysNewFileName; AlwaysNewFileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Always Create New File';
                        ToolTip = 'Specifies if a new file name is created every time you export a SEPA payment file or if the previous file name is used. ';
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

    trigger OnPreReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SEPADDExportFile: Codeunit "SEPA DD-Export File";     
    begin
        FeatureTelemetry.LogUptake('0000N2L', SEPADDExportFile.FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000N2M', SEPADDExportFile.FeatureName(), 'Report (NL) SEPA ISO20022 Pain 008.001.02');
    end;

    var
        CompanyInfo: Record "Company Information";
        StringConversionMgt: Codeunit StringConversionManagement;
        XMLDomDoc: XmlDocument;
        XMLNameSpace: Text;
        ExportFileName: Text[250];
        AlwaysNewFileName: Boolean;

    local procedure ExportSEPAFile()
    var
        FileMgt: Codeunit "File Management";
        ReportChecksum: Codeunit "Report Checksum";
        XMLRootElement: XmlElement;
        XMLNodeCurr: XmlElement;
        XMLNewChild: XmlElement;
        ServerTempFileName: Text[250];
    begin
        XMLNameSpace := 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.02';
        XmlDocument.ReadFrom(
          '<?xml version="1.0" encoding="utf-8"?><Document xmlns="' + XMLNameSpace + '" xmlns:xsi="http://www.w3.org/2001/XMLSchemainstance"></Document>', XMLDomDoc);
        XMLDomDoc.GetRoot(XMLRootElement);
        XMLNodeCurr := XMLRootElement;
        AddElement(XMLNodeCurr, 'CstmrDrctDbtInitn', '', XMLNewChild);

        ExportGroupHeader(XMLNewChild);
        ExportPaymentInformation(XMLNewChild);

        ServerTempFileName := FileMgt.ServerTempFileName('xml');
        OnBeforeXmlDocumentSave(XMLDomDoc);
        WriteXmlDocToServerFile(ServerTempFileName);

        ReportChecksum.GenerateChecksum("Payment History", ServerTempFileName, ExportProtocolCode);
        FileMgt.DownloadHandler(ServerTempFileName, '', '', '', ExportFileName);

        Clear(XMLDomDoc);
        FileMgt.DeleteServerFile(ServerTempFileName);
    end;

    local procedure WriteXmlDocToServerFile(ServerFileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        BlobOutStream: OutStream;
        XMLDocText: Text;
    begin
        XMLDomDoc.WriteTo(XMLDocText);
        TempBlob.CreateOutStream(BlobOutStream, TextEncoding::UTF8);
        BlobOutStream.WriteText(XMLDocText);
        FileMgt.BLOBExportToServerFile(TempBlob, ServerFileName);
    end;

    local procedure ExportGroupHeader(var XMLNodeCurr: XmlElement)
    var
        XMLNewChild: XmlElement;
        XMLParent: XmlElement;
        MessageId: Text[50];
        TotalAmount: Text[50];
        LineCount: Text[20];
    begin
        XMLParent := XMLNodeCurr;
        AddElement(XMLNodeCurr, 'GrpHdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        MessageId := "Payment History"."Our Bank" + "Payment History"."Run No.";
        if StrLen(MessageId) > 35 then
            MessageId := CopyStr(MessageId, StrLen(MessageId) - 34);

        AddElement(XMLNodeCurr, 'MsgId', MessageId, XMLNewChild);
        AddElement(XMLNodeCurr, 'CreDtTm', Format(CurrentDateTime, 19, 9), XMLNewChild);

        GetPmtHistLineCountAndAmtHead(TotalAmount, LineCount);
        AddElement(XMLNodeCurr, 'NbOfTxs', LineCount, XMLNewChild);
        AddElement(XMLNodeCurr, 'CtrlSum', TotalAmount, XMLNewChild);

        AddElement(XMLNodeCurr, 'InitgPty', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, XMLNewChild);
        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'OrgId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Othr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', CompanyInfo."VAT Registration No.", XMLNewChild);

        XMLNodeCurr := XMLParent;
    end;

    local procedure ExportPaymentInformation(var XMLNodeCurr: XmlElement)
    var
        BankAcc: Record "Bank Account";
        LastPaymentHistoryLine: Record "Payment History Line";
        PaymentHistoryLine: Record "Payment History Line";
        XMLParent: XmlElement;
    begin
        XMLParent := XMLNodeCurr;

        Clear(LastPaymentHistoryLine);
        PaymentHistoryLine.SetCurrentKey(Date, "Sequence Type");
        PaymentHistoryLine.SetFilter("Sequence Type", '>%1', PaymentHistoryLine."Sequence Type"::" ");
        PaymentHistoryLine.SetRange("Our Bank", "Payment History"."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", "Payment History"."Run No.");
        PaymentHistoryLine.SetFilter(
          Status,
          '%1|%2|%3',
          PaymentHistoryLine.Status::New,
          PaymentHistoryLine.Status::Transmitted,
          PaymentHistoryLine.Status::"Request for Cancellation");
        if PaymentHistoryLine.FindSet() then
            repeat
                if (PaymentHistoryLine.Date <> LastPaymentHistoryLine.Date) or (PaymentHistoryLine."Sequence Type" <> LastPaymentHistoryLine."Sequence Type") then begin
                    LastPaymentHistoryLine := PaymentHistoryLine;
                    XMLNodeCurr := XMLParent;
                    AddPaymentInformation(XMLNodeCurr, PaymentHistoryLine, BankAcc);
                end;
                AddTrxInformation(XMLNodeCurr, PaymentHistoryLine);
            until PaymentHistoryLine.Next() = 0;

        XMLNodeCurr := XMLParent;
    end;

    local procedure AddPaymentInformation(var XMLNodeCurr: XmlElement; PaymentHistoryLine: Record "Payment History Line"; var BankAcc: Record "Bank Account")
    var
        Customer: Record Customer;
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        XMLNewChild: XmlElement;
        PaymentInformationId: Text[60];
        TotalAmount: Text[50];
        LineCount: Text[20];
        BtchBookg: Text[250];
    begin
        BtchBookg := 'false';
        Customer.Get(PaymentHistoryLine."Account No.");

        OnBeforeAddPaymentInformation(PaymentHistoryLine, BankAcc, Customer, BtchBookg);

        AddElement(XMLNodeCurr, 'PmtInf', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        PaymentInformationId := PaymentHistoryLine."Our Bank" + PaymentHistoryLine."Run No." + Format(PaymentHistoryLine."Line No.");
        if StrLen(PaymentInformationId) > 35 then
            PaymentInformationId := CopyStr(PaymentInformationId, StrLen(PaymentInformationId) - 34);

        AddElement(XMLNodeCurr, 'PmtInfId', PaymentInformationId, XMLNewChild);
        AddElement(XMLNodeCurr, 'PmtMtd', 'DD', XMLNewChild);

        AddElement(XMLNodeCurr, 'BtchBookg', BtchBookg, XMLNewChild);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtPmtInf(TotalAmount, LineCount, "Payment History", PaymentHistoryLine);
        AddElement(XMLNodeCurr, 'NbOfTxs', LineCount, XMLNewChild);
        AddElement(XMLNodeCurr, 'CtrlSum', TotalAmount, XMLNewChild);

        AddElement(XMLNodeCurr, 'PmtTpInf', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'SvcLvl', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Cd', 'SEPA', XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'LclInstrm', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if Customer."Partner Type" = Customer."Partner Type"::Person then
            AddElement(XMLNodeCurr, 'Cd', 'CORE', XMLNewChild)
        else
            AddElement(XMLNodeCurr, 'Cd', 'B2B', XMLNewChild);

        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'SeqTp', Format(PaymentHistoryLine."Sequence Type"), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'ReqdColltnDt', Format(PaymentHistoryLine.Date, 0, 9), XMLNewChild);

        AddElement(XMLNodeCurr, 'Cdtr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        BankAcc.Get(PaymentHistoryLine."Our Bank");
        AddElement(XMLNodeCurr, 'Nm', BankAcc."Account Holder Name", XMLNewChild);
        AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'AdrLine', BankAcc."Account Holder Address", XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'CdtrAcct', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'IBAN', DelChr(CopyStr(BankAcc.IBAN, 1, 34)), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'CdtrAgt', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'BIC', CopyStr(BankAcc."SWIFT Code", 1, 11), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'UltmtCdtr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, XMLNewChild);
        AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'AdrLine', CompanyInfo.Address, XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'ChrgBr', 'SLEV', XMLNewChild);

        AddElement(XMLNodeCurr, 'CdtrSchmeId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, XMLNewChild);

        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'PrvtId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Othr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', BankAcc."Creditor Identifier", XMLNewChild);
        AddElement(XMLNodeCurr, 'SchmeNm', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'Prtry', 'SEPA', XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
    end;

    local procedure AddTrxInformation(var XMLNodeCurr: XmlElement; PaymentHistoryLine: Record "Payment History Line")
    var
        Customer: Record Customer;
        DirectDebitMandate: Record "SEPA Direct Debit Mandate";
        PaymentHistory: Record "Payment History";
        XMLNewChild: XmlElement;
        XMLParent: XmlElement;
        AddrLine: array[3] of Text[70];
        UnstructuredRemitInfo: Text[140];
    begin
        XMLParent := XMLNodeCurr;
        Customer.Get(PaymentHistoryLine."Account No.");
        DirectDebitMandate.Get(PaymentHistoryLine."Direct Debit Mandate ID");
        AddElement(XMLNodeCurr, 'DrctDbtTxInf', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'PmtId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'EndToEndId', PaymentHistoryLine.Identification, XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(
          XMLNodeCurr, 'InstdAmt',
          DelChr(Format(Abs(PaymentHistoryLine.Amount), 18, '<Precision,2:2><Standard Format,9>'), '=', ' '),
          XMLNewChild);
        AddAttribute(XMLNewChild, 'Ccy', 'EUR');

        AddElement(XMLNodeCurr, 'DrctDbtTx', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'MndtRltdInf', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'MndtId', Format(PaymentHistoryLine."Direct Debit Mandate ID"), XMLNewChild);

        AddElement(XMLNodeCurr, 'DtOfSgntr', Format(DirectDebitMandate."Date of Signature", 0, 9), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'DbtrAgt', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'BIC', CopyStr(PaymentHistoryLine."SWIFT Code", 1, 11), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'Dbtr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        PaymentHistory.Get(PaymentHistoryLine."Our Bank", PaymentHistoryLine."Run No.");
        AddElement(XMLNodeCurr, 'Nm', PaymentHistoryLine."Account Holder Name", XMLNewChild);

        if PaymentHistoryLine.GetAccHolderPostalAddr(AddrLine) then begin
            AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            if AddrLine[1] <> '' then
                AddElement(XMLNodeCurr, 'Ctry', AddrLine[1], XMLNewChild);
            if AddrLine[2] <> '' then
                AddElement(XMLNodeCurr, 'AdrLine', AddrLine[2], XMLNewChild);
            if AddrLine[3] <> '' then
                AddElement(XMLNodeCurr, 'AdrLine', AddrLine[3], XMLNewChild);

            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);
        end;

        AddElement(XMLNodeCurr, 'DbtrAcct', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'IBAN', DelChr(CopyStr(PaymentHistoryLine.IBAN, 1, 34)), XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        AddElement(XMLNodeCurr, 'UltmtDbtr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', Customer.Name, XMLNewChild);
        AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'AdrLine', Customer.Address, XMLNewChild);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);

        UnstructuredRemitInfo := PaymentHistoryLine.GetUnstrRemitInfo();
        if UnstructuredRemitInfo <> '' then begin
            AddElement(XMLNodeCurr, 'RmtInf', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            AddElement(XMLNodeCurr, 'Ustrd', UnstructuredRemitInfo, XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);
        end;

        XMLNodeCurr.GetParent(XMLNodeCurr);
        XMLNodeCurr.GetParent(XMLNodeCurr);
        PaymentHistoryLine.WillBeSent();
        XMLNodeCurr := XMLParent;
    end;

    local procedure AddElement(var XMLNode: XmlElement; NodeName: Text[250]; NodeText: Text[250]; var CreatedXMLNode: XmlElement): Boolean
    var
        NewChildNode: XmlElement;
    begin
        if NodeText <> '' then
            NewChildNode := XmlElement.Create(NodeName, XMLNameSpace, StringConversionMgt.WindowsToASCII(NodeText))
        else
            NewChildNode := XmlElement.Create(NodeName, XMLNameSpace);

        XMLNode.Add(NewChildNode);
        CreatedXMLNode := NewChildNode;
        exit(true);
    end;

    local procedure AddAttribute(var XMLDomNode: XmlElement; AttribName: Text[250]; AttribValue: Text[250]): Boolean
    begin
        XMLDomNode.SetAttribute(AttribName, AttribValue);
        exit(true);
    end;

    local procedure GetPmtHistLineCountAndAmtHead(var TotalAmount: Text[50]; var LineCount: Text[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
    begin
        PaymentHistoryLine.Reset();
        PaymentHistoryLine.SetFilter("Sequence Type", '>%1', PaymentHistoryLine."Sequence Type"::" ");
        LocalFunctionalityMgt.GetPmtHistLineCountAndAmt(PaymentHistoryLine, TotalAmount, LineCount, "Payment History");
    end;

    var
        ExportProtocolCode: Code[20];

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPaymentInformation(PaymentHistoryLine: Record "Payment History Line"; var BankAccount: Record "Bank Account"; var Customer: Record Customer; var BatchBookg: Text)
    begin
    end;

#if not CLEAN30
    [Obsolete('This event is no longer raised. The document is now built with the native XmlDocument type; use OnBeforeXmlDocumentSave instead.', '30.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeXMLDomDocSave(var XMLDomDoc: DotNet XmlDocument)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeXmlDocumentSave(var XmlDoc: XmlDocument)
    begin
    end;
}

