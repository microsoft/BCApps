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
using System;
using System.IO;
using System.Xml;

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
        XMLDoc: DotNet XmlDocument;
        FileMgt: Codeunit "File Management";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ExportFileName: Text[250];
        AlwaysNewFileName: Boolean;
        ExportProtocolCode: Code[20];

    [Scope('OnPrem')]
    procedure ExportSEPAFile()
    var
        ReportChecksum: Codeunit "Report Checksum";
        XMLRootElement: DotNet XmlElement;
        XMLNodeCurr: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        XMLGroupHeader: DotNet XmlNode;
        XMLPaymentInformation: DotNet XmlNode;
        FileNameOnServer: Text[260];
    begin
        XMLDOMMgt.LoadXMLDocumentFromText('<?xml version="1.0" encoding="UTF-8"?><Document></Document>', XMLDoc);
        XMLRootElement := XMLDoc.DocumentElement;
        XMLRootElement.SetAttribute('xmlns', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02');
        XMLRootElement.SetAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        XMLNodeCurr := XMLDoc.SelectSingleNode('Document');
        XMLDOMMgt.AddElement(XMLNodeCurr, 'pain.001.001.02', '', '', XMLNewChild);

        ExportGroupHeader(XMLGroupHeader);
        XMLNewChild.AppendChild(XMLGroupHeader);

        ExportPaymentInformation(XMLPaymentInformation);
        if not IsNull(XMLPaymentInformation) then
            XMLNewChild.AppendChild(XMLPaymentInformation);

        FileNameOnServer := FileMgt.ServerTempFileName('');

        XMLDoc.Save(FileNameOnServer);
        ReportChecksum.GenerateChecksum("Payment History", FileNameOnServer, ExportProtocolCode);

        FileMgt.DownloadHandler(FileNameOnServer, '', '', '', ExportFileName);

        Clear(XMLDoc);
    end;

    [Scope('OnPrem')]
    procedure ExportGroupHeader(var XMLGroupHeader: DotNet XmlNode)
    var
        XMLNodeCurr: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        MessageId: Text[50];
    begin
        XMLGroupHeader := XMLDoc.CreateNode('element', 'GrpHdr', '');
        XMLNodeCurr := XMLGroupHeader;

        MessageId := "Payment History"."Our Bank" + "Payment History"."Run No.";
        if StrLen(MessageId) > 35 then
            MessageId := CopyStr(MessageId, StrLen(MessageId) - 34);

        XMLDOMMgt.AddElement(XMLNodeCurr, 'MsgId', MessageId, '', XMLNewChild);
        XMLDOMMgt.AddElement(XMLNodeCurr, 'CreDtTm', Format(CurrentDateTime, 19, 9), '', XMLNewChild);

        PaymentHistoryLine.Reset();
        PaymentHistoryLine.SetCurrentKey("Our Bank", Status, "Run No.", Order, Date);
        PaymentHistoryLine.SetRange("Our Bank", "Payment History"."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", "Payment History"."Run No.");
        PaymentHistoryLine.SetFilter(Status, '%1|%2|%3',
          PaymentHistoryLine.Status::New,
          PaymentHistoryLine.Status::Transmitted,
          PaymentHistoryLine.Status::"Request for Cancellation");

        XMLDOMMgt.AddElement(XMLNodeCurr, 'NbOfTxs', DelChr(Format(PaymentHistoryLine.Count, 15, 9), '=', ' '), '', XMLNewChild);
        PaymentHistoryLine.CalcSums(Amount);
        XMLDOMMgt.AddElement(XMLNodeCurr, 'CtrlSum', Format(PaymentHistoryLine.Amount, 18, 9), '', XMLNewChild);
        XMLDOMMgt.AddElement(XMLNodeCurr, 'Grpg', 'SNGL', '', XMLNewChild);
        XMLDOMMgt.AddElement(XMLNodeCurr, 'InitgPty', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        XMLDOMMgt.AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, '', XMLNewChild);
        XMLDOMMgt.AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        XMLDOMMgt.AddElement(XMLNodeCurr, 'OrgId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        XMLDOMMgt.AddElement(XMLNodeCurr, 'TaxIdNb', CompanyInfo."VAT Registration No.", '', XMLNewChild);
    end;

    [Scope('OnPrem')]
    procedure ExportPaymentInformation(var XMLPaymentInformation: DotNet XmlNode)
    var
        BankAcc: Record "Bank Account";
        DetailLine: Record "Detail Line";
        EmplLedgEntry: Record "Employee Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        XMLNodeCurr: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
        AddressLine1: Text[110];
        AddressLine2: Text[60];
        PaymentInformationId: Text[60];
        UnstructuredRemitInfo: Text[250];
        TempUnstructuredRemitInfo: Text[250];
        BreakRemitInfoLoop: Boolean;
    begin
        if PaymentHistoryLine.Find('-') then
            repeat
                XMLPaymentInformation := XMLDoc.CreateNode('element', 'PmtInf', '');
                XMLNodeCurr := XMLPaymentInformation;

                PaymentInformationId := PaymentHistoryLine."Our Bank" + PaymentHistoryLine."Run No." + Format(PaymentHistoryLine."Line No.");
                if StrLen(PaymentInformationId) > 35 then
                    PaymentInformationId := CopyStr(PaymentInformationId, StrLen(PaymentInformationId) - 34);

                XMLDOMMgt.AddElement(XMLNodeCurr, 'PmtInfId', PaymentInformationId, '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'PmtMtd', 'TRF', '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'PmtTpInf', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                if PaymentHistoryLine.Urgent then
                    XMLDOMMgt.AddElement(XMLNodeCurr, 'InstrPrty', 'HIGH', '', XMLNewChild)
                else
                    XMLDOMMgt.AddElement(XMLNodeCurr, 'InstrPrty', 'NORM', '', XMLNewChild);

                XMLDOMMgt.AddElement(XMLNodeCurr, 'SvcLvl', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Cd', 'SEPA', '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'CtgyPurp', 'SUPP', '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'ReqdExctnDt', Format(PaymentHistoryLine.Date, 0, 9), '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'Dbtr', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                AddressLine1 := DelChr(CompanyInfo.Address, '<>') + ' ' + DelChr(CompanyInfo."Address 2", '<>');
                XMLDOMMgt.AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine1, 1, 70), '', XMLNewChild);
                AddressLine2 := DelChr(CompanyInfo."Post Code", '<>') + ' ' + DelChr(CompanyInfo.City, '<>');
                XMLDOMMgt.AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 70), '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'Ctry', CopyStr(CompanyInfo."Country/Region Code", 1, 2), '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'DbtrAcct', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                BankAcc.Get(PaymentHistoryLine."Our Bank");
                XMLDOMMgt.AddElement(XMLNodeCurr, 'IBAN', CopyStr(BankAcc.IBAN, 1, 34), '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Tp', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                XMLDOMMgt.AddElement(XMLNodeCurr, 'Cd', 'CASH', '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'DbtrAgt', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'FinInstnId', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'BIC', CopyStr(BankAcc."SWIFT Code", 1, 11), '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'ChrgBr', 'SLEV', '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'CdtTrfTxInf', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'PmtId', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'EndToEndId', CopyStr(PaymentHistoryLine.Identification, 1, 35), '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Amt', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;
                XMLDOMMgt.AddElement(XMLNodeCurr, 'InstdAmt', Format(PaymentHistoryLine.Amount, 0, 9), '', XMLNewChild);
                XMLDOMMgt.AddAttribute(XMLNewChild, 'Ccy', 'EUR');
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'CdtrAgt', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'FinInstnId', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'BIC', CopyStr(PaymentHistoryLine."SWIFT Code", 1, 11), '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Cdtr', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Nm', PaymentHistoryLine."Account Holder Name", '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'AdrLine', PaymentHistoryLine."Account Holder Address", '', XMLNewChild);
                AddressLine2 := DelChr(PaymentHistoryLine."Account Holder Post Code", '<>') + ' ' +
                  DelChr(PaymentHistoryLine."Account Holder City", '<>');
                XMLDOMMgt.AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 70), '', XMLNewChild);
                XMLDOMMgt.AddElement(XMLNodeCurr, 'Ctry', CopyStr(PaymentHistoryLine."Acc. Hold. Country/Region Code", 1, 2), '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;
                XMLNodeCurr := XMLNodeCurr.ParentNode;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'CdtrAcct', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
                XMLNodeCurr := XMLNewChild;

                XMLDOMMgt.AddElement(XMLNodeCurr, 'IBAN', CopyStr(PaymentHistoryLine.IBAN, 1, 34), '', XMLNewChild);
                XMLNodeCurr := XMLNodeCurr.ParentNode;
                XMLNodeCurr := XMLNodeCurr.ParentNode;

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
                    XMLDOMMgt.AddElement(XMLNodeCurr, 'RmtInf', '', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;
                    XMLDOMMgt.AddElement(XMLNodeCurr, 'Ustrd', UnstructuredRemitInfo, '', XMLNewChild);
                    XMLNodeCurr := XMLNodeCurr.ParentNode;
                end else
                    if PaymentHistoryLine."Description 1" <> '' then begin
                        XMLDOMMgt.AddElement(XMLNodeCurr, 'RmtInf', '', '', XMLNewChild);
                        XMLNodeCurr := XMLNewChild;
                        XMLDOMMgt.AddElement(XMLNodeCurr, 'Unstrd', CopyStr(PaymentHistoryLine."Description 1", 1, 140), '', XMLNewChild);
                        XMLNodeCurr := XMLNodeCurr.ParentNode;
                    end;

                XMLNodeCurr := XMLNodeCurr.ParentNode;
                XMLNodeCurr := XMLNodeCurr.ParentNode;
            until PaymentHistoryLine.Next() = 0;
    end;
}

