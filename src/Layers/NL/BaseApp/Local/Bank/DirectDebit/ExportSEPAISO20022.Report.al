// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
#if not CLEAN30
using System;
#endif
using System.IO;
using System.Utilities;

report 11000011 "Export SEPA ISO20022"
{
    Caption = 'Export SEPA ISO20022';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payment History"; "Payment History")
        {
            DataItemTableView = sorting("Our Bank", "Run No.");
            RequestFilterFields = "Our Bank", "Export Protocol", "Run No.", Status, Export;
            dataitem("Payment History Line"; "Payment History Line")
            {
                DataItemLink = "Run No." = field("Run No."), "Our Bank" = field("Our Bank");
                DataItemTableView = sorting("Our Bank", "Run No.", "Line No.") where(Status = filter(New | Transmitted | "Request for Cancellation"));

                trigger OnAfterGetRecord()
                begin
                    WillBeSent();
                end;
            }

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
                if FindSet(true) then;
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

    var
        PaymentHistoryLine: Record "Payment History Line";
        CompanyInfo: Record "Company Information";
        FileMgt: Codeunit "File Management";
        XMLDoc: XmlDocument;
        ExportFileName: Text[250];
        AlwaysNewFileName: Boolean;
        ExportProtocolCode: Code[20];
        XMLNameSpaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02', Locked = true;

    [Scope('OnPrem')]
    procedure ExportSEPAFile()
    var
        ReportChecksum: Codeunit "Report Checksum";
        TempBlob: Codeunit "Temp Blob";
        XMLRootElement: XmlElement;
        XMLNodeCurr: XmlElement;
        XMLNewChild: XmlElement;
        XMLGroupHeader: XmlElement;
        XMLPaymentInformation: XmlElement;
        BlobOutStream: OutStream;
        FileNameOnServer: Text[260];
    begin
        XmlDocument.ReadFrom(
          '<?xml version="1.0" encoding="UTF-8"?><Document xmlns="' + XMLNameSpaceTxt + '" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"></Document>', XMLDoc);
        XMLDoc.GetRoot(XMLRootElement);
        XMLNodeCurr := XMLRootElement;
        AddElement(XMLNodeCurr, 'pain.001.001.02', '', XMLNewChild);

        ExportGroupHeader(XMLGroupHeader);
        XMLNewChild.Add(XMLGroupHeader);

        if ExportPaymentInformation(XMLPaymentInformation) then
            XMLNewChild.Add(XMLPaymentInformation);

        FileNameOnServer := FileMgt.ServerTempFileName('');

        TempBlob.CreateOutStream(BlobOutStream);
        XMLDoc.WriteTo(BlobOutStream);
        if FileMgt.ServerFileExists(FileNameOnServer) then
            FileMgt.DeleteServerFile(FileNameOnServer);
        FileMgt.BLOBExportToServerFile(TempBlob, FileNameOnServer);
        ReportChecksum.GenerateChecksum("Payment History", FileNameOnServer, ExportProtocolCode);

        FileMgt.DownloadHandler(FileNameOnServer, '', '', '', ExportFileName);

        Clear(XMLDoc);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use the ExportGroupHeader overload with a native XmlElement parameter instead.', '30.0')]
    procedure ExportGroupHeader(var XMLGroupHeader: DotNet XmlNode)
    var
        GroupHeaderElement: XmlElement;
    begin
        ExportGroupHeader(GroupHeaderElement);
        ConvertToDotNetXmlNode(GroupHeaderElement, XMLGroupHeader);
    end;

    [Scope('OnPrem')]
    [Obsolete('Use the ExportPaymentInformation overload with a native XmlElement parameter instead.', '30.0')]
    procedure ExportPaymentInformation(var XMLPaymentInformation: DotNet XmlNode)
    var
        PaymentInformationElement: XmlElement;
    begin
        if ExportPaymentInformation(PaymentInformationElement) then
            ConvertToDotNetXmlNode(PaymentInformationElement, XMLPaymentInformation);
    end;

    local procedure ConvertToDotNetXmlNode(SourceXmlElement: XmlElement; var TargetXmlNode: DotNet XmlNode)
    var
        DotNetXmlDocument: DotNet XmlDocument;
        SourceXmlText: Text;
    begin
        SourceXmlElement.WriteTo(SourceXmlText);
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
        DotNetXmlDocument.LoadXml(SourceXmlText);
        TargetXmlNode := DotNetXmlDocument.DocumentElement;
    end;
#endif

    [Scope('OnPrem')]
    procedure ExportGroupHeader(var XMLGroupHeader: XmlElement)
    var
        XMLNodeCurr: XmlElement;
        XMLNewChild: XmlElement;
        MessageId: Text[50];
    begin
        XMLGroupHeader := XmlElement.Create('GrpHdr', XMLNameSpaceTxt);
        XMLNodeCurr := XMLGroupHeader;

        MessageId := "Payment History"."Our Bank" + "Payment History"."Run No.";
        if StrLen(MessageId) > 35 then
            MessageId := CopyStr(MessageId, StrLen(MessageId) - 34);

        AddElement(XMLNodeCurr, 'MsgId', MessageId, XMLNewChild);
        AddElement(XMLNodeCurr, 'CreDtTm', Format(CurrentDateTime, 19, 9), XMLNewChild);

        PaymentHistoryLine.Reset();
        PaymentHistoryLine.SetCurrentKey("Our Bank", Status, "Run No.", Order, Date);
        PaymentHistoryLine.SetRange("Our Bank", "Payment History"."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", "Payment History"."Run No.");
        PaymentHistoryLine.SetFilter(Status, '%1|%2|%3',
          PaymentHistoryLine.Status::New,
          PaymentHistoryLine.Status::Transmitted,
          PaymentHistoryLine.Status::"Request for Cancellation");

        AddElement(XMLNodeCurr, 'NbOfTxs', DelChr(Format(PaymentHistoryLine.Count, 15, 9), '=', ' '), XMLNewChild);
        PaymentHistoryLine.CalcSums(Amount);
        AddElement(XMLNodeCurr, 'CtrlSum', Format(PaymentHistoryLine.Amount, 18, 9), XMLNewChild);
        AddElement(XMLNodeCurr, 'Grpg', 'SNGL', XMLNewChild);
        AddElement(XMLNodeCurr, 'InitgPty', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, XMLNewChild);
        AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'OrgId', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'TaxIdNb', CompanyInfo."VAT Registration No.", XMLNewChild);
    end;

    [Scope('OnPrem')]
    procedure ExportPaymentInformation(var XMLPaymentInformation: XmlElement): Boolean
    var
        BankAcc: Record "Bank Account";
        DetailLine: Record "Detail Line";
        EmplLedgEntry: Record "Employee Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        XMLNodeCurr: XmlElement;
        XMLNewChild: XmlElement;
        AddressLine1: Text[110];
        AddressLine2: Text[60];
        PaymentInformationId: Text[60];
        UnstructuredRemitInfo: Text[250];
        TempUnstructuredRemitInfo: Text[250];
        BreakRemitInfoLoop: Boolean;
    begin
        if not PaymentHistoryLine.Find('-') then
            exit(false);

        repeat
            XMLPaymentInformation := XmlElement.Create('PmtInf', XMLNameSpaceTxt);
            XMLNodeCurr := XMLPaymentInformation;

            PaymentInformationId := PaymentHistoryLine."Our Bank" + PaymentHistoryLine."Run No." + Format(PaymentHistoryLine."Line No.");
            if StrLen(PaymentInformationId) > 35 then
                PaymentInformationId := CopyStr(PaymentInformationId, StrLen(PaymentInformationId) - 34);

            AddElement(XMLNodeCurr, 'PmtInfId', PaymentInformationId, XMLNewChild);
            AddElement(XMLNodeCurr, 'PmtMtd', 'TRF', XMLNewChild);
            AddElement(XMLNodeCurr, 'PmtTpInf', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            if PaymentHistoryLine.Urgent then
                AddElement(XMLNodeCurr, 'InstrPrty', 'HIGH', XMLNewChild)
            else
                AddElement(XMLNodeCurr, 'InstrPrty', 'NORM', XMLNewChild);

            AddElement(XMLNodeCurr, 'SvcLvl', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Cd', 'SEPA', XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'CtgyPurp', 'SUPP', XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'ReqdExctnDt', Format(PaymentHistoryLine.Date, 0, 9), XMLNewChild);
            AddElement(XMLNodeCurr, 'Dbtr', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, XMLNewChild);
            AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddressLine1 := DelChr(CompanyInfo.Address, '<>') + ' ' + DelChr(CompanyInfo."Address 2", '<>');
            AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine1, 1, 70), XMLNewChild);
            AddressLine2 := DelChr(CompanyInfo."Post Code", '<>') + ' ' + DelChr(CompanyInfo.City, '<>');
            AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 70), XMLNewChild);
            AddElement(XMLNodeCurr, 'Ctry', CopyStr(CompanyInfo."Country/Region Code", 1, 2), XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'DbtrAcct', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            BankAcc.Get(PaymentHistoryLine."Our Bank");
            AddElement(XMLNodeCurr, 'IBAN', CopyStr(BankAcc.IBAN, 1, 34), XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'Tp', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            AddElement(XMLNodeCurr, 'Cd', 'CASH', XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'DbtrAgt', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'FinInstnId', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'BIC', CopyStr(BankAcc."SWIFT Code", 1, 11), XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'ChrgBr', 'SLEV', XMLNewChild);
            AddElement(XMLNodeCurr, 'CdtTrfTxInf', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'PmtId', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'EndToEndId', CopyStr(PaymentHistoryLine.Identification, 1, 35), XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'Amt', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;
            AddElement(XMLNodeCurr, 'InstdAmt', Format(PaymentHistoryLine.Amount, 0, 9), XMLNewChild);
            XMLNewChild.SetAttribute('Ccy', 'EUR');
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'CdtrAgt', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'FinInstnId', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'BIC', CopyStr(PaymentHistoryLine."SWIFT Code", 1, 11), XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'Cdtr', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Nm', PaymentHistoryLine."Account Holder Name", XMLNewChild);
            AddElement(XMLNodeCurr, 'PstlAdr', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'AdrLine', PaymentHistoryLine."Account Holder Address", XMLNewChild);
            AddressLine2 := DelChr(PaymentHistoryLine."Account Holder Post Code", '<>') + ' ' +
              DelChr(PaymentHistoryLine."Account Holder City", '<>');
            AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 70), XMLNewChild);
            AddElement(XMLNodeCurr, 'Ctry', CopyStr(PaymentHistoryLine."Acc. Hold. Country/Region Code", 1, 2), XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            AddElement(XMLNodeCurr, 'CdtrAcct', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Id', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'IBAN', CopyStr(PaymentHistoryLine.IBAN, 1, 34), XMLNewChild);
            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);

            Clear(UnstructuredRemitInfo);
            Clear(TempUnstructuredRemitInfo);
            BreakRemitInfoLoop := false;
            DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches", "Connect Lines", Date);
            DetailLine.SetRange("Our Bank", PaymentHistoryLine."Our Bank");
            DetailLine.SetFilter(
              Status, '%1|%2|%3', DetailLine.Status::"In process", DetailLine.Status::Posted, DetailLine.Status::Correction);
            DetailLine.SetRange("Connect Batches", PaymentHistoryLine."Run No.");
            DetailLine.SetRange("Connect Lines", PaymentHistoryLine."Line No.");
            if DetailLine.Find('-') then
                repeat
                    TempUnstructuredRemitInfo := UnstructuredRemitInfo;
                    case DetailLine."Account Type" of
                        DetailLine."Account Type"::Vendor:
                            if VendLedgEntry.Get(DetailLine."Serial No. (Entry)") then begin
                                if TempUnstructuredRemitInfo = '' then
                                    TempUnstructuredRemitInfo := VendLedgEntry."External Document No."
                                else
                                    TempUnstructuredRemitInfo := TempUnstructuredRemitInfo + ', ' + VendLedgEntry."External Document No.";
                                if StrLen(TempUnstructuredRemitInfo) <= 140 then
                                    UnstructuredRemitInfo := TempUnstructuredRemitInfo
                                else
                                    BreakRemitInfoLoop := true;
                            end;
                        DetailLine."Account Type"::Customer:
                            if CustLedgEntry.Get(DetailLine."Serial No. (Entry)") then begin
                                if TempUnstructuredRemitInfo = '' then
                                    TempUnstructuredRemitInfo := CustLedgEntry."Document No."
                                else
                                    TempUnstructuredRemitInfo := TempUnstructuredRemitInfo + ', ' + CustLedgEntry."Document No.";
                                if StrLen(TempUnstructuredRemitInfo) <= 140 then
                                    UnstructuredRemitInfo := TempUnstructuredRemitInfo
                                else
                                    BreakRemitInfoLoop := true;
                            end;
                        DetailLine."Account Type"::Employee:
                            if EmplLedgEntry.Get(DetailLine."Serial No. (Entry)") then begin
                                if TempUnstructuredRemitInfo = '' then
                                    TempUnstructuredRemitInfo := EmplLedgEntry."Document No."
                                else
                                    TempUnstructuredRemitInfo := TempUnstructuredRemitInfo + ', ' + EmplLedgEntry."Document No.";
                                if StrLen(TempUnstructuredRemitInfo) <= 140 then
                                    UnstructuredRemitInfo := TempUnstructuredRemitInfo
                                else
                                    BreakRemitInfoLoop := true;
                            end;
                    end;
                until BreakRemitInfoLoop or (DetailLine.Next() = 0);

            if UnstructuredRemitInfo <> '' then begin
                AddElement(XMLNodeCurr, 'RmtInf', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                AddElement(XMLNodeCurr, 'Ustrd', UnstructuredRemitInfo, XMLNewChild);
                XMLNodeCurr.GetParent(XMLNodeCurr);
            end else
                if PaymentHistoryLine."Description 1" <> '' then begin
                    AddElement(XMLNodeCurr, 'RmtInf', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;
                    AddElement(XMLNodeCurr, 'Unstrd', CopyStr(PaymentHistoryLine."Description 1", 1, 140), XMLNewChild);
                    XMLNodeCurr.GetParent(XMLNodeCurr);
                end;

            XMLNodeCurr.GetParent(XMLNodeCurr);
            XMLNodeCurr.GetParent(XMLNodeCurr);
        until PaymentHistoryLine.Next() = 0;

        exit(true);
    end;

    local procedure AddElement(var ParentXmlElement: XmlElement; NodeName: Text; NodeText: Text; var CreatedXmlElement: XmlElement)
    begin
        if NodeText <> '' then
            CreatedXmlElement := XmlElement.Create(NodeName, XMLNameSpaceTxt, NodeText)
        else
            CreatedXmlElement := XmlElement.Create(NodeName, XMLNameSpaceTxt);
        ParentXmlElement.Add(CreatedXmlElement);
    end;
}

