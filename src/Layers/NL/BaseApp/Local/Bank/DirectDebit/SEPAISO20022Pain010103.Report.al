// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System;
using System.IO;
using System.Telemetry;
using System.Text;
using System.Xml;

report 11000012 "SEPA ISO20022 Pain 01.01.03"
{
    Caption = 'SEPA ISO20022 Pain 01.01.03';
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
                OnPaymentHistoryOnPreDataItemOnAfterGetCompanyInfo(CompanyInfo);
                GLSetup.Get();
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
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
    begin
        FeatureTelemetry.LogUptake('0000N2N', SEPACTExportFile.FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000N2O', SEPACTExportFile.FeatureName(), 'Report (NL) SEPA ISO20022 Pain 001.001.03');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        StringConversionMgt: Codeunit StringConversionManagement;
        XMLDomDoc: DotNet XmlDocument;
        ExportFileName: Text[250];
        AlwaysNewFileName: Boolean;
        Worldpayment: Boolean;
        ExportProtocolCode: Code[20];

    local procedure ExportSEPAFile()
    var
        FileMgt: Codeunit "File Management";
        XMLDOMManagement: Codeunit "XML DOM Management";
        ReportChecksum: Codeunit "Report Checksum";
        XMLRootElement: DotNet XmlElement;
        XMLNodeCurr: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        StreamWriter: DotNet StreamWriter;
        UTF8Encoding: DotNet UTF8Encoding;
        ServerTempFileName: Text;
        IsHandled: Boolean;
    begin
        XMLDOMManagement.LoadXMLDocumentFromText('<?xml version="1.0" encoding="UTF-8"?><Document></Document>', XMLDomDoc);
        XMLRootElement := XMLDomDoc.DocumentElement;
        XMLRootElement.SetAttribute('xmlns', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03');
        XMLRootElement.SetAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchemainstance');
        XMLNodeCurr := XMLDomDoc.SelectSingleNode('Document');
        AddElement(XMLNodeCurr, 'CstmrCdtTrfInitn', '', '', XMLNewChild);

        ExportGroupHeader(XMLNewChild);
        ExportPaymentInformation(XMLNewChild);

        ServerTempFileName := FileMgt.ServerTempFileName('xml');
        StreamWriter := StreamWriter.StreamWriter(ServerTempFileName, false, UTF8Encoding.UTF8Encoding(false));
        OnBeforeXMLDomDocSave(XMLDomDoc);
        XMLDomDoc.Save(StreamWriter);
        StreamWriter.Close();

        ReportChecksum.GenerateChecksum("Payment History", ServerTempFileName, ExportProtocolCode);
        IsHandled := false;
        OnExportSEPAFileOnBeforeFileMgtDownloadHandler(ServerTempFileName, ExportFileName, IsHandled);
        if not IsHandled then
            FileMgt.DownloadHandler(ServerTempFileName, '', '', '', ExportFileName);

        Clear(XMLDomDoc);
    end;

    local procedure ExportGroupHeader(XMLNodeCurr: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
        XMLParent: DotNet XmlNode;
        MessageId: Text[50];
        TotalAmount: Text[50];
        LineCount: Text[20];
    begin
        XMLParent := XMLNodeCurr;
        AddElement(XMLNodeCurr, 'GrpHdr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        MessageId := "Payment History"."Our Bank" + "Payment History"."Run No.";
        if StrLen(MessageId) > 35 then
            MessageId := CopyStr(MessageId, StrLen(MessageId) - 34);

        AddElement(XMLNodeCurr, 'MsgId', MessageId, '', XMLNewChild);
        AddElement(XMLNodeCurr, 'CreDtTm', Format(CurrentDateTime, 19, 9), '', XMLNewChild);

        GetPmtHistLineCountAndAmt(TotalAmount, LineCount);
        AddElement(XMLNodeCurr, 'NbOfTxs', LineCount, '', XMLNewChild);
        AddElement(XMLNodeCurr, 'CtrlSum', TotalAmount, '', XMLNewChild);

        AddElement(XMLNodeCurr, 'InitgPty', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, '', XMLNewChild);
        AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'OrgId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Othr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', CompanyInfo."VAT Registration No.", '', XMLNewChild);

        XMLNodeCurr := XMLParent;
    end;

    local procedure ExportPaymentInformation(XMLNodeCurr: DotNet XmlNode)
    var
        BankAcc: Record "Bank Account";
        LastPaymentHistoryLine: Record "Payment History Line";
        PaymentHistoryLine: Record "Payment History Line";
        XMLParent: DotNet XmlNode;
    begin
        XMLParent := XMLNodeCurr;

        Clear(LastPaymentHistoryLine);
        PaymentHistoryLine.SetCurrentKey(Date, Urgent);
        PaymentHistoryLine.SetRange("Our Bank", "Payment History"."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", "Payment History"."Run No.");
        PaymentHistoryLine.SetFilter(Status, '%1|%2|%3', PaymentHistoryLine.Status::New, PaymentHistoryLine.Status::Transmitted, PaymentHistoryLine.Status::"Request for Cancellation");
        if PaymentHistoryLine.FindSet() then
            repeat
                if (PaymentHistoryLine.Date <> LastPaymentHistoryLine.Date) or (PaymentHistoryLine.Urgent <> LastPaymentHistoryLine.Urgent) then begin
                    LastPaymentHistoryLine := PaymentHistoryLine;
                    XMLNodeCurr := XMLParent;
                    AddPaymentInformation(XMLNodeCurr, PaymentHistoryLine, BankAcc);
                end;
                AddTrxInformation(XMLNodeCurr, PaymentHistoryLine);
            until PaymentHistoryLine.Next() = 0;

        XMLNodeCurr := XMLParent;
    end;

    local procedure AddPaymentInformation(XMLNodeCurr: DotNet XmlNode; PaymentHistoryLine: Record "Payment History Line"; var BankAcc: Record "Bank Account")
    var
        TransactionMode: Record "Transaction Mode";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        XMLNewChild: DotNet XmlNode;
        XMLParent: DotNet XmlNode;
        StreetName: Text[70];
        PostalCode: Text[16];
        TownName: Text[35];
        PaymentInformationId: Text[60];
        TotalAmount: Text[50];
        LineCount: Text[20];
        ServiceLevelCode: Code[10];
        ChargeBearer: Code[10];
        BtchBookg: Text[250];
    begin
        BtchBookg := 'false';
        OnBeforeAddPaymentInformation(PaymentHistoryLine, BankAcc, BtchBookg);

        XMLParent := XMLNodeCurr;
        AddElement(XMLNodeCurr, 'PmtInf', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        TransactionMode.Get(PaymentHistoryLine."Account Type", PaymentHistoryLine."Transaction Mode");

        Worldpayment :=
            TransactionMode.WorldPayment or
            (GLSetup."Local Currency" = GLSetup."Local Currency"::Euro) and
            (PaymentHistoryLine."Currency Code" <> '') or
            (GLSetup."Local Currency" = GLSetup."Local Currency"::Other) and
            (PaymentHistoryLine."Currency Code" <> GLSetup."Currency Euro") or
            (PaymentHistoryLine."Foreign Amount" <> 0);

        if Worldpayment then begin
            ServiceLevelCode := 'SDVA';
            case true of
                (TransactionMode."Transfer Cost Domestic" = TransactionMode."Transfer Cost Domestic"::Principal) and
                (TransactionMode."Transfer Cost Foreign" = TransactionMode."Transfer Cost Foreign"::Principal):
                    ChargeBearer := 'DEBT';
                (TransactionMode."Transfer Cost Domestic" = TransactionMode."Transfer Cost Domestic"::"Balancing Account Holder") and
                (TransactionMode."Transfer Cost Foreign" = TransactionMode."Transfer Cost Foreign"::"Balancing Account Holder"):
                    ChargeBearer := 'CRED';
                else
                    ChargeBearer := 'SHAR';
            end;
        end else begin
            ServiceLevelCode := 'SEPA';
            ChargeBearer := 'SLEV';
        end;
        OnAddPaymentInformationOnAfterAssignServiceLevelCode(ServiceLevelCode);

        PaymentInformationId := PaymentHistoryLine."Our Bank" + PaymentHistoryLine."Run No." + Format(PaymentHistoryLine."Line No.");
        if StrLen(PaymentInformationId) > 35 then
            PaymentInformationId := CopyStr(PaymentInformationId, StrLen(PaymentInformationId) - 34);

        AddElement(XMLNodeCurr, 'PmtInfId', PaymentInformationId, '', XMLNewChild);
        AddElement(XMLNodeCurr, 'PmtMtd', 'TRF', '', XMLNewChild);

        AddElement(XMLNodeCurr, 'BtchBookg', BtchBookg, '', XMLNewChild);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtPmtInf(TotalAmount, LineCount, "Payment History", PaymentHistoryLine);
        AddElement(XMLNodeCurr, 'NbOfTxs', LineCount, '', XMLNewChild);
        AddElement(XMLNodeCurr, 'CtrlSum', TotalAmount, '', XMLNewChild);

        AddElement(XMLNodeCurr, 'PmtTpInf', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if PaymentHistoryLine.Urgent then
            AddElement(XMLNodeCurr, 'InstrPrty', 'HIGH', '', XMLNewChild)
        else
            AddElement(XMLNodeCurr, 'InstrPrty', 'NORM', '', XMLNewChild);

        AddElement(XMLNodeCurr, 'SvcLvl', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Cd', ServiceLevelCode, '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'CtgyPurp', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        AddElement(XMLNodeCurr, 'Cd', 'SUPP', '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'ReqdExctnDt', Format(PaymentHistoryLine.Date, 0, 9), '', XMLNewChild);
        AddElement(XMLNodeCurr, 'Dbtr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, '', XMLNewChild);
        AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        if not Worldpayment then begin
            StreetName := CopyStr(DelChr(CompanyInfo.Address, '<>') + ' ' + DelChr(CompanyInfo."Address 2", '<>'), 1, MaxStrLen(StreetName));
            PostalCode := CopyStr(DelChr(CompanyInfo."Post Code", '<>'), 1, MaxStrLen(PostalCode));
            TownName := CopyStr(DelChr(CompanyInfo.City, '<>'), 1, MaxStrLen(TownName));

            if StreetName <> '' then
                AddElement(XMLNodeCurr, 'StrtNm', StreetName, '', XMLNewChild);
            if PostalCode <> '' then
                AddElement(XMLNodeCurr, 'PstCd', PostalCode, '', XMLNewChild);
            if TownName <> '' then
                AddElement(XMLNodeCurr, 'TwnNm', TownName, '', XMLNewChild);
        end;
        AddElement(XMLNodeCurr, 'Ctry', CopyStr(CompanyInfo."Country/Region Code", 1, 2), '', XMLNewChild);

        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'DbtrAcct', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        BankAcc.Get(PaymentHistoryLine."Our Bank");
        AddElement(XMLNodeCurr, 'IBAN', DelChr(CopyStr(BankAcc.IBAN, 1, 34)), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'Ccy', GetCurrencyCode(BankAcc."Currency Code"), '', XMLNewChild);

        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'DbtrAgt', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'BIC', CopyStr(BankAcc."SWIFT Code", 1, 11), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'ChrgBr', ChargeBearer, '', XMLNewChild);
    end;

    local procedure AddTrxInformation(XMLNodeCurr: DotNet XmlNode; PaymentHistoryLine: Record "Payment History Line")
    var
        XMLNewChild: DotNet XmlNode;
        XMLParent: DotNet XmlNode;
        AddrLine: array[3] of Text[70];
        UnstructuredRemitInfo: Text[250];
        StreetName: Text[70];
        PostalCode: Text[16];
        TownName: Text[35];
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        XMLParent := XMLNodeCurr;
        AddElement(XMLNodeCurr, 'CdtTrfTxInf', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'PmtId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'EndToEndId', CopyStr(PaymentHistoryLine.Identification, 1, 35), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'Amt', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if PaymentHistoryLine."Foreign Amount" <> 0 then begin
            Amount := PaymentHistoryLine."Foreign Amount";
            CurrencyCode := PaymentHistoryLine."Foreign Currency";
        end else begin
            Amount := PaymentHistoryLine.Amount;
            CurrencyCode := PaymentHistoryLine."Currency Code";
        end;

        AddElement(
          XMLNodeCurr, 'InstdAmt',
          Format(Amount, 0, '<Precision,2:2><Standard Format,9>'),
          '', XMLNewChild);
        AddAttribute(XMLDomDoc, XMLNewChild, 'Ccy', GetCurrencyCode(CurrencyCode));
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'CdtrAgt', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'BIC', CopyStr(PaymentHistoryLine."SWIFT Code", 1, 11), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'Cdtr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', PaymentHistoryLine."Account Holder Name", '', XMLNewChild);

        if PaymentHistoryLine.GetAccHolderPostalAddr(AddrLine) then begin
            AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            if Worldpayment then begin
                StreetName := CopyStr(PaymentHistoryLine."Account Holder Address", 1, MaxStrLen(StreetName));
                PostalCode := CopyStr(PaymentHistoryLine."Account Holder Post Code", 1, MaxStrLen(PostalCode));
                TownName := CopyStr(PaymentHistoryLine."Account Holder City", 1, MaxStrLen(TownName));

                if StreetName <> '' then
                    AddElement(XMLNodeCurr, 'StrtNm', StreetName, '', XMLNewChild);
                if PostalCode <> '' then
                    AddElement(XMLNodeCurr, 'PstCd', PostalCode, '', XMLNewChild);
                if TownName <> '' then
                    AddElement(XMLNodeCurr, 'TwnNm', TownName, '', XMLNewChild);
            end;

            if AddrLine[1] <> '' then
                AddElement(XMLNodeCurr, 'Ctry', AddrLine[1], '', XMLNewChild);

            if not Worldpayment then begin
                if AddrLine[2] <> '' then
                    AddElement(XMLNodeCurr, 'AdrLine', AddrLine[2], '', XMLNewChild);
                if AddrLine[3] <> '' then
                    AddElement(XMLNodeCurr, 'AdrLine', AddrLine[3], '', XMLNewChild);
            end;
            XMLNodeCurr := XMLNodeCurr.ParentNode;
            XMLNodeCurr := XMLNodeCurr.ParentNode;
        end;

        AddElement(XMLNodeCurr, 'CdtrAcct', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if Worldpayment and (PaymentHistoryLine."Bank Account No." <> '') then begin
            AddElement(XMLNodeCurr, 'Othr', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            AddElement(XMLNodeCurr, 'Id', DelChr(CopyStr(PaymentHistoryLine."Bank Account No.", 1, 30)), '', XMLNewChild);
            XMLNodeCurr := XMLNodeCurr.ParentNode;
        end else
            AddElement(XMLNodeCurr, 'IBAN', DelChr(CopyStr(PaymentHistoryLine.IBAN, 1, 34)), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        UnstructuredRemitInfo := PaymentHistoryLine.GetUnstrRemitInfo();
        if UnstructuredRemitInfo <> '' then begin
            AddElement(XMLNodeCurr, 'RmtInf', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            AddElement(XMLNodeCurr, 'Ustrd', UnstructuredRemitInfo, '', XMLNewChild);
            XMLNodeCurr := XMLNodeCurr.ParentNode;
        end;

        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        PaymentHistoryLine.WillBeSent();
        XMLNodeCurr := XMLParent;
    end;

    local procedure AddElement(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; var CreatedXMLNode: DotNet XmlNode): Boolean
    var
        NewChildNode: DotNet XmlNode;
    begin
        NewChildNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);
        if IsNull(NewChildNode) then
            exit(false);

        if NodeText <> '' then
            NewChildNode.InnerText := StringConversionMgt.WindowsToASCII(NodeText);

        XMLNode.AppendChild(NewChildNode);
        CreatedXMLNode := NewChildNode;
        Clear(NewChildNode);
        exit(true);
    end;

    local procedure AddAttribute(var XMLDomDocParam: DotNet XmlDocument; var XMLDomNode: DotNet XmlNode; AttribName: Text[250]; AttribValue: Text[250]): Boolean
    var
        XMLDomAttribute: DotNet XmlNode;
    begin
        XMLDomAttribute := XMLDomDocParam.CreateAttribute(AttribName);
        if IsNull(XMLDomAttribute) then
            exit(false);

        if AttribValue <> '' then
            XMLDomAttribute.Value := AttribValue;
        XMLDomNode.Attributes.SetNamedItem(XMLDomAttribute);
        Clear(XMLDomAttribute);
        exit(true);
    end;

    local procedure GetPmtHistLineCountAndAmt(var TotalAmount: Text[50]; var LineCount: Text[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
    begin
        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain("Payment History", PaymentHistoryLine, TotalAmount, LineCount);
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode = '' then
            exit(GLSetup."LCY Code");
        exit(CurrencyCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddPaymentInformationOnAfterAssignServiceLevelCode(var ServiceLevelCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPaymentInformation(PaymentHistoryLine: Record "Payment History Line"; var BankAccount: Record "Bank Account"; var BatchBookg: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeXMLDomDocSave(var XMLDomDoc: DotNet XmlDocument)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportSEPAFileOnBeforeFileMgtDownloadHandler(ServerTempFileName: Text; ExportFileName: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPaymentHistoryOnPreDataItemOnAfterGetCompanyInfo(var CompanyInfo: Record "Company Information")
    begin
    end;
}

