// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System;
using System.Environment;
using System.IO;
using System.Telemetry;
using System.Utilities;
using System.Xml;

report 2000005 "File SEPA Payments"
{
    Caption = 'File SEPA Payments';
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem("Payment Journal Line"; "Payment Journal Line")
        {
            DataItemTableView = sorting("Bank Account", "Beneficiary Bank Account No.", "Beneficiary IBAN", Status, "Account Type", "Account No.", "Currency Code", "Posting Date");

            trigger OnAfterGetRecord()
            var
                NewPaymentGroup: Boolean;
            begin
                NewPaymentGroup := CheckNewGroup("Payment Journal Line");
                if NewConsolidatedPayment("Payment Journal Line") then begin
                    ExportTransactionInformation(PmtInfNode, ConsolidatedPmtJnlLine, ConsolidatedPmtMessage);
                    InitConsolidatedPayment("Payment Journal Line");
                end else
                    UpdateConsolidatedPayment("Payment Journal Line");

                if NewPaymentGroup then
                    ExportPaymentInformation(CstmrCdtTrfInitnNode, "Payment Journal Line");
            end;

            trigger OnPostDataItem()
            begin
                if not EmptyConsolidatedPayment() then
                    ExportTransactionInformation(PmtInfNode, ConsolidatedPmtJnlLine, ConsolidatedPmtMessage);
                PostPmtLines("Payment Journal Line");
            end;

            trigger OnPreDataItem()
            begin
                OnBeforePreDataItemPaymentJournalLine("Payment Journal Line");

                if ExecutionDate <> 0D then
                    ModifyAll("Posting Date", ExecutionDate);

                SetRange("Separate Line", false);
                Clear(ConsolidatedPmtJnlLine);
            end;
        }
        dataitem(SeparatePmtJnlLine; "Payment Journal Line")
        {
            DataItemTableView = sorting("Bank Account", "Beneficiary Bank Account No.", Status, "Account Type", "Account No.", "Currency Code", "Posting Date");

            trigger OnAfterGetRecord()
            begin
                if CheckNewGroup(SeparatePmtJnlLine) then
                    ExportPaymentInformation(CstmrCdtTrfInitnNode, SeparatePmtJnlLine);
                ExportTransactionInformation(PmtInfNode, SeparatePmtJnlLine, "Payment Message");
                if EmptyConsolidatedPayment() then
                    InitConsolidatedPayment(SeparatePmtJnlLine);
            end;

            trigger OnPostDataItem()
            begin
                PostPmtLines(SeparatePmtJnlLine);
            end;

            trigger OnPreDataItem()
            begin
                OnBeforePreDataItemSeparatePmtJnlLine(SeparatePmtJnlLine);

                Copy("Payment Journal Line");
                SetRange("Separate Line", true);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(JournalTemplateName; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        NotBlank = true;
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
                            GenJnlTemplate.Name := GenJnlLine."Journal Template Name";
                            if GenJnlTemplate.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK then
                                GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlLineJournalTemplateNameOnAfterValidate();
                        end;
                    }
                    field(JournalBatch; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Lookup = true;
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the general journal batch to which you want the journal lines to be transferred.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if GenJnlBatch.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
                                GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                            GenJnlBatch.TestField("No. Series");
                        end;
                    }
                    field(AutomaticPosting; AutomaticPosting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post General Journal Lines';
                        ToolTip = 'Specifies whether to automatically post General Journal Lines.';
                    }
                    field(IncludeDimText; IncludeDimText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Dimensions';
                        Editable = false;
                        Enabled = IncludeDimTextEnable;
                        ToolTip = 'Specifies the dimensions that you want to include in the report. The option is only available if the Summarize Gen. Jnl. Lines field in the Electronic Banking Setup window is selected.';

                        trigger OnAssistEdit()
                        var
                            DimSelectionBuf: Record "Dimension Selection Buffer";
                        begin
                            DimSelectionBuf.SetDimSelectionMultiple(3, REPORT::"File SEPA Payments", IncludeDimText);
                        end;
                    }
                    field(ExecutionDate; ExecutionDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Execution Date';
                        ToolTip = 'Specifies the desired execution date if you want an execution date that is different than the posting date on the payment journal lines. The date you enter here will overwrite the posting date on the selected journal lines.';
                    }
                    field(FileName; FileName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'File Name';
                        ToolTip = 'Specifies the name or path of the file that will be exported.';
                        Visible = false;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            IncludeDimTextEnable := true;
        end;

        trigger OnOpenPage()
        begin
            IncludeDimTextEnable := EBSetup."Summarize Gen. Jnl. Lines";
            FileName := DefaultFileNameTxt;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        OutStream: OutStream;
        IsHandled: Boolean;
    begin
        FinishGroupHeader();
        TempBlob.CreateOutStream(OutStream);
        XMLDomDoc.Save(OutStream);
        OnBeforeDownloadXmlFile(TempBlob, IsHandled);
        if not IsHandled then begin
            FileMgt.BLOBExportToServerFile(TempBlob, ServerFileName);
            if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::Desktop, ClientType::Windows]) then
                FullFileName := RBMgt.GetFileName(FileName)
            else
                FullFileName := FileName;

            if FullFileName = '' then
                FullFileName := SEPAPaymentsFileNameTxt;

            Download(ServerFileName, '', '', AllFilesDescriptionTxt, FullFileName);
        end;
        Clear(XMLDomDoc);
    end;

    trigger OnPreReport()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
        XMLRootElement: DotNet XmlElement;
        XMLNodeCurr: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
    begin
        FeatureTelemetry.LogUptake('0000N2H', SEPACTExportFile.FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000N2I', SEPACTExportFile.FeatureName(), 'Report (BE) File SEPA Payments');

        EBSetup.Get();
        CompanyInfo.Get();

        OnBeforePreReport("Payment Journal Line", GenJnlLine, AutomaticPosting, IncludeDimText, ExecutionDate, FileName);

        XMLDOMManagement.LoadXMLDocumentFromText('<?xml version="1.0" encoding="UTF-8"?><Document></Document>', XMLDomDoc);
        XMLRootElement := XMLDomDoc.DocumentElement;
        XMLRootElement.SetAttribute('xmlns', 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03');
        XMLRootElement.SetAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        XMLNodeCurr := XMLDomDoc.SelectSingleNode('Document');
        AddElement(XMLNodeCurr, 'CstmrCdtTrfInitn', '', '', XMLNewChild);
        CstmrCdtTrfInitnNode := XMLNewChild;
        MessageId := GetMessageID(GetExportProtocolCode("Payment Journal Line"));
        StartGroupHeader(XMLNewChild);
        PaymentInformationCounter := 0;
        NumberOfTransactions := 0;
        ControlSum := 0;
        ServerFileName := RBMgt.ServerTempFileName('.xml');
    end;

    var
        EBSetup: Record "Electronic Banking Setup";
        ConsolidatedPmtJnlLine: Record "Payment Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        BankAcc: Record "Bank Account";
        VendorBankAcc: Record "Vendor Bank Account";
        CustomerBankAcc: Record "Customer Bank Account";
        Vendor: Record Vendor;
        Customer: Record Customer;
        ExportProtocol: Record "Export Protocol";
        RBMgt: Codeunit "File Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        XMLDomDoc: DotNet XmlDocument;
        CstmrCdtTrfInitnNode: DotNet XmlNode;
        PmtInfNode: DotNet XmlNode;
        ConsolidatedPmtMessage: Text[140];
        Text002: Label 'Journal %1 is not a general journal.';
        ServerFileName: Text;
        MessageId: Text[35];
        FullFileName: Text;
        PaymentInformationCounter: Integer;
        NumberOfTransactions: Integer;
        ControlSum: Decimal;
        IncludeDimTextEnable: Boolean;
        AllFilesDescriptionTxt: Label 'All Files (*.*)|*.*', Comment = '{Split=r''\|''}{Locked=s''1''}';
        DefaultFileNameTxt: Label 'Export.xml';
        SEPAPaymentsFileNameTxt: Label 'SEPAPayments.txt';

    protected var
        GenJnlLine: Record "Gen. Journal Line";
        AutomaticPosting: Boolean;
        IncludeDimText: Text[250];
        ExecutionDate: Date;
        FileName: Text;

    local procedure PostPmtLines(var PmtJnlLine: Record "Payment Journal Line")
    var
        BalancingPostingDate: Date;
    begin
        if PmtJnlLine.IsEmpty() then
            exit;
        if ExecutionDate <> 0D then
            BalancingPostingDate := ExecutionDate
        else
            BalancingPostingDate := Today;

        PostPaymentJournal(GenJnlLine, PmtJnlLine, BalancingPostingDate);

        if AutomaticPosting and (IncStr(GenJnlLine."Journal Batch Name") <> '') then
            GenJnlLine."Journal Batch Name" := IncStr(GenJnlLine."Journal Batch Name");
    end;

    local procedure PostPaymentJournal(var GenJnlLine: Record "Gen. Journal Line"; var PaymentJournalLine: Record "Payment Journal Line"; BalancingPostingDate: Date)
    var
        PaymentJournalPost: Report "Payment Journal Post";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostPaymentJournal(GenJnlLine, PaymentJournalLine, AutomaticPosting, BalancingPostingDate, IsHandled);
        if IsHandled then
            exit;

        PaymentJournalPost.SetParameters(GenJnlLine, AutomaticPosting, REPORT::"File SEPA Payments", BalancingPostingDate);
        PaymentJournalPost.SetTableView(PaymentJournalLine);
        PaymentJournalPost.RunModal();
    end;

    local procedure StartGroupHeader(XMLNodeCurr: DotNet XmlNode)
    var
        XMLNewChild: DotNet XmlNode;
    begin
        AddElement(XMLNodeCurr, 'GrpHdr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'MsgId', MessageId, '', XMLNewChild);
        AddElement(XMLNodeCurr, 'CreDtTm', Format(CurrentDateTime, 19, 9), '', XMLNewChild);
    end;

    local procedure FinishGroupHeader()
    var
        XMLNodeCurr: DotNet XmlNode;
        XMLNewChild: DotNet XmlNode;
    begin
        // Insert Number of Transactions and ControlSum in the Group Header
        XMLNodeCurr := XMLDomDoc.SelectSingleNode('Document');
        XMLNodeCurr := XMLNodeCurr.FirstChild;
        XMLNodeCurr := XMLNodeCurr.FirstChild;

        AddElement(XMLNodeCurr, 'NbOfTxs', Format(NumberOfTransactions, 0, 9), '', XMLNewChild);
        AddElement(XMLNodeCurr, 'CtrlSum', Format(ControlSum, 0, 9), '', XMLNewChild);

        AddElement(XMLNodeCurr, 'InitgPty', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, '', XMLNewChild);
        AddEnterpriseNo(XMLNodeCurr, CompanyInfo."Enterprise No.");
    end;

    local procedure ExportPaymentInformation(XMLNodeCurr: DotNet XmlNode; PmtJnlLine: Record "Payment Journal Line")
    var
        XMLNewChild: DotNet XmlNode;
        AddressLine1: Text[110];
        AddressLine2: Text[60];
    begin
        PaymentInformationCounter := PaymentInformationCounter + 1;
        AddElement(XMLNodeCurr, 'PmtInf', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;
        PmtInfNode := XMLNodeCurr;

        AddElement(XMLNodeCurr, 'PmtInfId', MessageId + '-' + Format(PaymentInformationCounter), '', XMLNewChild);
        AddElement(XMLNodeCurr, 'PmtMtd', 'TRF', '', XMLNewChild);
        if ExportProtocol."Grouped Payment" then
            AddElement(XMLNodeCurr, 'BtchBookg', 'true', '', XMLNewChild)
        else
            AddElement(XMLNodeCurr, 'BtchBookg', 'false', '', XMLNewChild);
        AddElement(XMLNodeCurr, 'PmtTpInf', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'SvcLvl', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Cd', 'SEPA', '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'ReqdExctnDt', Format(PmtJnlLine."Posting Date", 0, 9), '', XMLNewChild);
        AddElement(XMLNodeCurr, 'Dbtr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Nm', CompanyInfo.Name, '', XMLNewChild);

        AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        GetCountry(CompanyInfo."Country/Region Code");

        if Country."ISO Code" <> '' then
            AddElement(XMLNodeCurr, 'Ctry', CopyStr(Country."ISO Code", 1, 2), '', XMLNewChild);

        AddressLine1 := DelChr(CompanyInfo.Address, '<>') + ' ' + DelChr(CompanyInfo."Address 2", '<>');
        if DelChr(AddressLine1) <> '' then
            AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine1, 1, 35), '', XMLNewChild);

        AddressLine2 := DelChr(CompanyInfo."Post Code", '<>') + ' ' + DelChr(CompanyInfo.City, '<>');
        if DelChr(AddressLine2) <> '' then
            AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 35), '', XMLNewChild);

        XMLNodeCurr := XMLNodeCurr.ParentNode;
        AddEnterpriseNo(XMLNodeCurr, CompanyInfo."Enterprise No.");
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'DbtrAcct', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        GetBankAccount(PmtJnlLine."Bank Account");
        AddElement(XMLNodeCurr, 'IBAN', CopyStr(DelChr(BankAcc.IBAN), 1, 34), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'Ccy', 'EUR', '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'DbtrAgt', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if AddBICTag(BankAcc."SWIFT Code") then
            AddElement(XMLNodeCurr, 'BIC', CopyStr(DelChr(BankAcc."SWIFT Code"), 1, 11), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'ChrgBr', 'SLEV', '', XMLNewChild);

        XMLNodeCurr := XMLNodeCurr.ParentNode;
    end;

    local procedure AddBICTag(SwiftCode: Code[20]) AddTag: Boolean
    begin
        AddTag := true;
        OnAddBICTag(SwiftCode, AddTag);
    end;

    local procedure ExportTransactionInformation(XMLNodeCurr: DotNet XmlNode; PmtJnlLine: Record "Payment Journal Line"; PaymentMessage: Text[140])
    var
        XMLNewChild: DotNet XmlNode;
        RootNode: DotNet XmlNode;
        AddressLine1: Text[110];
        AddressLine2: Text[60];
    begin
        OnBeforeExportTransactionInformation(PmtJnlLine, PaymentMessage);

        GetCVAccount(PmtJnlLine);
        RootNode := XMLNodeCurr;
        NumberOfTransactions += 1;
        ControlSum += PmtJnlLine.Amount;

        AddElement(XMLNodeCurr, 'CdtTrfTxInf', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'PmtId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'EndToEndId', CutText(PaymentMessage, 35), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'Amt', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'InstdAmt', Format(PmtJnlLine.Amount, 0, 9), '', XMLNewChild);
        AddAttribute(XMLDomDoc, XMLNewChild, 'Ccy', 'EUR');
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        AddElement(XMLNodeCurr, 'CdtrAgt', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'FinInstnId', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if AddBICTag(PmtJnlLine."SWIFT Code") then
            AddElement(XMLNodeCurr, 'BIC', CopyStr(DelChr(PmtJnlLine."SWIFT Code"), 1, 11), '', XMLNewChild);
        case PmtJnlLine."Account Type" of
            PmtJnlLine."Account Type"::Vendor:
                begin
                    GetVendorBankAccount(PmtJnlLine."Account No.", PmtJnlLine."Beneficiary Bank Account");
                    if DelChr(VendorBankAcc.Name) <> '' then
                        AddElement(XMLNodeCurr, 'Nm', VendorBankAcc.Name, '', XMLNewChild);
                    AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;

                    GetCountry(VendorBankAcc."Country/Region Code");
                    if Country."ISO Code" <> '' then
                        AddElement(XMLNodeCurr, 'Ctry', CopyStr(Country."ISO Code", 1, 2), '', XMLNewChild);

                    AddressLine1 := DelChr(VendorBankAcc.Address, '<>') + ' ' + DelChr(VendorBankAcc."Address 2", '<>');
                    if DelChr(AddressLine1) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine1, 1, 35), '', XMLNewChild);

                    AddressLine2 := DelChr(VendorBankAcc."Post Code", '<>') + ' ' + DelChr(VendorBankAcc.City, '<>');
                    if DelChr(AddressLine2) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 35), '', XMLNewChild);
                    XMLNodeCurr := XMLNodeCurr.ParentNode;
                    XMLNodeCurr := XMLNodeCurr.ParentNode;
                    XMLNodeCurr := XMLNodeCurr.ParentNode;

                    AddElement(XMLNodeCurr, 'Cdtr', '', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;

                    AddElement(XMLNodeCurr, 'Nm', CopyStr(Vendor.Name, 1, 70), '', XMLNewChild);
                    AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;

                    GetCountry(Vendor."Country/Region Code");
                    if Country."ISO Code" <> '' then
                        AddElement(XMLNodeCurr, 'Ctry', CopyStr(Country."ISO Code", 1, 2), '', XMLNewChild);

                    AddressLine1 := DelChr(Vendor.Address, '<>') + ' ' + DelChr(Vendor."Address 2", '<>');
                    if DelChr(AddressLine1) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine1, 1, 35), '', XMLNewChild);

                    AddressLine2 := DelChr(Vendor."Post Code", '<>') + ' ' + DelChr(Vendor.City, '<>');
                    if DelChr(AddressLine2) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 35), '', XMLNewChild);

                    XMLNodeCurr := XMLNodeCurr.ParentNode;
                    AddEnterpriseNo(XMLNodeCurr, Vendor."Enterprise No.");
                end;
            PmtJnlLine."Account Type"::Customer:
                begin
                    GetCustomerBankAccount(PmtJnlLine."Account No.", PmtJnlLine."Beneficiary Bank Account");
                    if DelChr(CustomerBankAcc.Name) <> '' then
                        AddElement(XMLNodeCurr, 'Nm', CustomerBankAcc.Name, '', XMLNewChild);
                    AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;

                    GetCountry(CustomerBankAcc."Country/Region Code");
                    if Country."ISO Code" <> '' then
                        AddElement(XMLNodeCurr, 'Ctry', CopyStr(Country."ISO Code", 1, 2), '', XMLNewChild);

                    AddressLine1 := DelChr(CustomerBankAcc.Address, '<>') + ' ' + DelChr(CustomerBankAcc."Address 2", '<>');
                    if DelChr(AddressLine1) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine1, 1, 35), '', XMLNewChild);

                    AddressLine2 := DelChr(CustomerBankAcc."Post Code", '<>') + ' ' + DelChr(CustomerBankAcc.City, '<>');
                    if DelChr(AddressLine2) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 35), '', XMLNewChild);
                    XMLNodeCurr := XMLNodeCurr.ParentNode;
                    XMLNodeCurr := XMLNodeCurr.ParentNode;
                    XMLNodeCurr := XMLNodeCurr.ParentNode;

                    AddElement(XMLNodeCurr, 'Cdtr', '', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;

                    AddElement(XMLNodeCurr, 'Nm', CopyStr(Customer.Name, 1, 70), '', XMLNewChild);
                    AddElement(XMLNodeCurr, 'PstlAdr', '', '', XMLNewChild);
                    XMLNodeCurr := XMLNewChild;

                    GetCountry(Customer."Country/Region Code");
                    if Country."ISO Code" <> '' then
                        AddElement(XMLNodeCurr, 'Ctry', CopyStr(Country."ISO Code", 1, 2), '', XMLNewChild);

                    AddressLine1 := DelChr(Customer.Address, '<>') + ' ' + DelChr(Customer."Address 2", '<>');
                    if DelChr(AddressLine1) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine1, 1, 35), '', XMLNewChild);

                    AddressLine2 := DelChr(Customer."Post Code", '<>') + ' ' + DelChr(Customer.City, '<>');
                    if DelChr(AddressLine2) <> '' then
                        AddElement(XMLNodeCurr, 'AdrLine', CopyStr(AddressLine2, 1, 35), '', XMLNewChild);

                    XMLNodeCurr := XMLNodeCurr.ParentNode;
                    AddEnterpriseNo(XMLNodeCurr, Customer."Enterprise No.");
                end;
        end;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'CdtrAcct', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        AddElement(XMLNodeCurr, 'IBAN', CopyStr(DelChr(PmtJnlLine."Beneficiary IBAN"), 1, 34), '', XMLNewChild);
        XMLNodeCurr := XMLNodeCurr.ParentNode;
        XMLNodeCurr := XMLNodeCurr.ParentNode;

        AddElement(XMLNodeCurr, 'RmtInf', '', '', XMLNewChild);
        XMLNodeCurr := XMLNewChild;

        if not CheckValidStandardFormatMessage(PmtJnlLine."Payment Message") then
            AddElement(XMLNodeCurr, 'Ustrd', PaymentMessage, '', XMLNewChild)
        else begin
            AddElement(XMLNodeCurr, 'Strd', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'CdtrRefInf', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Tp', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'CdOrPrtry', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Cd', 'SCOR', '', XMLNewChild);
            XMLNodeCurr := XMLNodeCurr.ParentNode;

            AddElement(XMLNodeCurr, 'Issr', GetIssuer(PmtJnlLine."Payment Message"), '', XMLNewChild);
            XMLNodeCurr := XMLNodeCurr.ParentNode;

            AddElement(XMLNodeCurr, 'Ref', PmtJnlLine."Payment Message", '', XMLNewChild);
        end;

        XMLNodeCurr := RootNode;
    end;

    local procedure GetMessageID(ExportProtocolCode: Code[20]): Text[35]
    var
        NoSeries: Codeunit "No. Series";
    begin
        ExportProtocol.Get(ExportProtocolCode);
        exit(NoSeries.GetNextNo(ExportProtocol."Export No. Series", Today()));
    end;

    local procedure GetExportProtocolCode(var PmtJnlLine: Record "Payment Journal Line"): Code[20]
    var
        ExportProtocolCode: Code[20];
    begin
        PmtJnlLine.FilterGroup(2);
        ExportProtocolCode := PmtJnlLine.GetRangeMax("Export Protocol Code");
        PmtJnlLine.FilterGroup(0);
        exit(ExportProtocolCode);
    end;

    local procedure GetCountry(CountryCode: Code[10])
    begin
        if CountryCode <> Country.Code then
            if not Country.Get(CountryCode) then
                Clear(Country);
    end;

    local procedure GetBankAccount(BankAccCode: Code[20])
    begin
        if BankAcc."No." <> BankAccCode then
            if not BankAcc.Get(BankAccCode) then
                BankAcc.Init();
    end;

    local procedure GetVendorBankAccount(VendorNo: Code[20]; BankAccCode: Code[20])
    begin
        if (VendorNo <> VendorBankAcc."Vendor No.") or (BankAccCode <> VendorBankAcc.Code) then
            if not VendorBankAcc.Get(VendorNo, BankAccCode) then
                VendorBankAcc.Init();
    end;

    local procedure GetCustomerBankAccount(CustomerNo: Code[20]; BankAccCode: Code[20])
    begin
        if (CustomerNo <> CustomerBankAcc."Customer No.") or (BankAccCode <> CustomerBankAcc.Code) then
            if not CustomerBankAcc.Get(CustomerNo, BankAccCode) then
                CustomerBankAcc.Init();

        OnAfterGetCustomerBankAccount(CustomerBankAcc, "Payment Journal Line");
    end;

    local procedure GetVendor(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if Vendor."No." <> VendorNo then begin
            if not Vendor.Get(VendorNo) then
                Vendor.Init();
            Vendor.CheckBlockedVendOnJnls(Vendor, VendorLedgerEntry."Document Type"::Payment, false);
        end;
    end;

    local procedure GetCustomer(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if Customer."No." <> CustomerNo then begin
            if not Customer.Get(CustomerNo) then
                Customer.Init();
            Customer.CheckBlockedCustOnJnls(Customer, CustLedgerEntry."Document Type"::Payment, false);
        end;
    end;

    procedure CheckNewGroup(PmtJnlLine: Record "Payment Journal Line"): Boolean
    var
        ReturnValue: Boolean;
    begin
        if EmptyConsolidatedPayment() then
            exit(true);

        ReturnValue :=
            (ConsolidatedPmtJnlLine."Bank Account" <> PmtJnlLine."Bank Account") or
            (ConsolidatedPmtJnlLine."Posting Date" <> PmtJnlLine."Posting Date") or
            (ConsolidatedPmtJnlLine."Instruction Priority" <> PmtJnlLine."Instruction Priority");

        OnAfterCheckNewGroup(PmtJnlLine, ConsolidatedPmtJnlLine, ReturnValue);

        exit(ReturnValue);
    end;

    local procedure EmptyConsolidatedPayment(): Boolean
    begin
        exit(ConsolidatedPmtJnlLine."Bank Account" = '');
    end;

    local procedure NewConsolidatedPayment(PmtJnlLine: Record "Payment Journal Line"): Boolean
    var
        ReturnValue: Boolean;
    begin
        if EmptyConsolidatedPayment() then
            exit(false);

        ReturnValue :=
            CheckNewGroup(PmtJnlLine) or
            IsPaymentMessageTooLong(PmtJnlLine."Payment Message") or
            (ConsolidatedPmtJnlLine."Account Type" <> PmtJnlLine."Account Type") or
            (ConsolidatedPmtJnlLine."Account No." <> PmtJnlLine."Account No.") or
            (ConsolidatedPmtJnlLine."Beneficiary Bank Account No." <> PmtJnlLine."Beneficiary Bank Account No.") or
            (ConsolidatedPmtJnlLine."Beneficiary IBAN" <> PmtJnlLine."Beneficiary IBAN");

        OnAfterNewConsolidatedPayment(PmtJnlLine, ConsolidatedPmtJnlLine, ReturnValue);

        exit(ReturnValue);
    end;

    local procedure InitConsolidatedPayment(PmtJnlLine: Record "Payment Journal Line")
    begin
        ConsolidatedPmtJnlLine := PmtJnlLine;
        ConsolidatedPmtMessage := ConsolidatedPmtJnlLine."Payment Message";
    end;

    local procedure UpdateConsolidatedPayment(PmtJnlLine: Record "Payment Journal Line")
    begin
        if EmptyConsolidatedPayment() then
            InitConsolidatedPayment(PmtJnlLine)
        else begin
            ConsolidatedPmtJnlLine.Amount := ConsolidatedPmtJnlLine.Amount + PmtJnlLine.Amount;
            UpdateConsolidatedPmtMessage(PmtJnlLine."Payment Message");
        end;
    end;

    local procedure UpdateConsolidatedPmtMessage(PaymentMessage: Text[100])
    var
        NewMessage: Text[1024];
    begin
        NewMessage := ConcatenatedPmtMessage(PaymentMessage);
        if EBSetup."Cut off Payment Message Texts" then
            ConsolidatedPmtMessage := CopyStr(
                CutText(NewMessage, MaxStrLen(ConsolidatedPmtMessage)),
                1, MaxStrLen(ConsolidatedPmtMessage))
        else
            ConsolidatedPmtMessage := CopyStr(NewMessage, 1, MaxStrLen(ConsolidatedPmtMessage));
    end;

    procedure IsPaymentMessageTooLong(PaymentMessage: Text[100]): Boolean
    begin
        if not EBSetup."Cut off Payment Message Texts" then
            exit(StrLen(ConcatenatedPmtMessage(PaymentMessage)) > MaxStrLen(ConsolidatedPmtMessage));
        exit(false);
    end;

    local procedure ConcatenatedPmtMessage(PaymentMessage: Text[100]): Text[1024]
    begin
        exit(ConsolidatedPmtMessage + ' ' + PaymentMessage);
    end;

    local procedure CutText(OriginalText: Text[1024]; MaxLength: Integer) Text: Text[1024]
    begin
        Text := OriginalText;
        if DelChr(Text, '<>') = '' then
            Text := 'NOTPROVIDED';
        AddCutMarker(Text, MaxLength);
    end;

    local procedure AddCutMarker(var Text: Text[1024]; MaxLength: Integer)
    var
        CutMarker: Text[30];
    begin
        CutMarker := '...';
        if StrLen(Text) > MaxLength then
            Text := CopyStr(Text, 1, MaxLength - StrLen(CutMarker)) + CutMarker;
    end;

    local procedure AddEnterpriseNo(XMLNodeCurr: DotNet XmlNode; EnterpriseNo: Text[50])
    var
        XMLNewChild: DotNet XmlNode;
    begin
        OnBeforeAddEnterpriseNo(EnterpriseNo);
        if DelChr(EnterpriseNo, '<>') <> '' then begin
            AddElement(XMLNodeCurr, 'Id', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'OrgId', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Othr', '', '', XMLNewChild);
            XMLNodeCurr := XMLNewChild;

            AddElement(XMLNodeCurr, 'Id', EnterpriseNo, '', XMLNewChild);
            AddElement(XMLNodeCurr, 'Issr', 'KBO-BCE', '', XMLNewChild);

            XMLNodeCurr := XMLNodeCurr.ParentNode;
            XMLNodeCurr := XMLNodeCurr.ParentNode;
            XMLNodeCurr := XMLNodeCurr.ParentNode;
        end;
    end;

    local procedure AddElement(var XMLNode: DotNet XmlNode; NodeName: Text[250]; NodeText: Text[250]; NameSpace: Text[250]; var CreatedXMLNode: DotNet XmlNode): Boolean
    var
        NewChildNode: DotNet XmlNode;
    begin
        NewChildNode := XMLNode.OwnerDocument.CreateNode('element', NodeName, NameSpace);

        if IsNull(NewChildNode) then
            exit(false);

        if NodeText <> '' then
            NewChildNode.InnerText := NodeText;
        XMLNode.AppendChild(NewChildNode);
        CreatedXMLNode := NewChildNode;
        exit(true);
    end;

    local procedure AddAttribute(var XMLDomDocParam: DotNet XmlDocument; var XMLDomNode: DotNet XmlNode; AttribName: Text[250]; AttribValue: Text[250]): Boolean
    var
        XMLDomAttribute: DotNet XmlAttribute;
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

    local procedure GenJnlLineJournalTemplateNameOnAfterValidate()
    begin
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        if GenJnlTemplate.Type <> GenJnlTemplate.Type::General then
            Error(Text002, GenJnlTemplate.Name);
    end;

    local procedure GetCVAccount(PaymentJournalLine: Record "Payment Journal Line")
    begin
        case PaymentJournalLine."Account Type" of
            PaymentJournalLine."Account Type"::Vendor:
                GetVendor(PaymentJournalLine."Account No.");
            PaymentJournalLine."Account Type"::Customer:
                GetCustomer(PaymentJournalLine."Account No.");
        end;
    end;

    local procedure CheckValidStandardFormatMessage(PmtMessage: text[250]) IsValid: boolean;
    var
        PmtJnlManagement: Codeunit PmtJrnlManagement;
        IsHandled: boolean;
    begin
        OnBeforeCheckValidStandardFormatMessage(PmtMessage, IsValid, IsHandled);
        if Ishandled then
            exit;

        exit(PmtJnlManagement.Mod97Test(PmtMessage));
    end;

    local procedure GetIssuer(PmtMessage: text[250]) Issuer: text
    var
        IsHandled: boolean;
    begin
        OnBeforeGetIssuer(PmtMessage, Issuer, IsHandled);
        if Ishandled then
            exit;

        exit('BBA');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckNewGroup(PaymentJournalLine: Record "Payment Journal Line"; ConsolidatedPaymentJournalLine: Record "Payment Journal Line"; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; PaymentJournalLine: Record "Payment Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterNewConsolidatedPayment(PaymentJournalLine: Record "Payment Journal Line"; ConsolidatedPaymentJournalLine: Record "Payment Journal Line"; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddEnterpriseNo(var EnterpriseNo: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportTransactionInformation(var PaymentJournalLine: Record "Payment Journal Line"; var PaymentMessage: Text[140])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPaymentJournal(var GenJournalLine: Record "Gen. Journal Line"; var PaymentJournalLine: Record "Payment Journal Line"; AutomaticPosting: Boolean; BalancingPostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreDataItemPaymentJournalLine(var PaymentJournalLine: Record "Payment Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreDataItemSeparatePmtJnlLine(var PaymentJournalLine: Record "Payment Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadXmlFile(var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport(var PaymentJournalLine: Record "Payment Journal Line"; var GenJournalLine: Record "Gen. Journal Line"; var AutomaticPosting: Boolean; var IncludeDimText: Text[250]; var ExecutionDate: Date; var FileName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddBICTag(SwiftCode: Code[20]; var AddTag: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValidStandardFormatMessage(PmtMessage: text[250]; var IsValid: boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetIssuer(PmtMessage: text[250]; var Issuer: text; var IsHandled: Boolean)
    begin
    end;
}