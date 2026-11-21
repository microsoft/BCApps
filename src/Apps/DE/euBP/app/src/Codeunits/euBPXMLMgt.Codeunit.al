// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Receivables;

codeunit 6545 "euBP XML Mgt."
{
    var
        LohnRootMissingErr: Label 'The imported LOHN payload must have root element EntgeltDaten.';
        LohnRequiredNodeMissingErr: Label 'The imported LOHN payload must contain node %1.', Comment = '%1 = Node name';

    internal procedure ValidateLohnPayload(LohnPayloadXml: Text)
    var
        LohnDocument: XmlDocument;
        RootNode: XmlNode;
    begin
        if LohnPayloadXml = '' then
            Error(LohnRootMissingErr);

        XmlDocument.ReadFrom(LohnPayloadXml, LohnDocument);

        if not LohnDocument.SelectSingleNode('/*[local-name()=''EntgeltDaten'']', RootNode) then
            Error(LohnRootMissingErr);

        AssertNodeExists(LohnDocument, '//*[local-name()=''DSAG'']', 'DSAG');
        AssertNodeExists(LohnDocument, '//*[local-name()=''DSAN'']', 'DSAN');
        AssertNodeExists(LohnDocument, '//*[local-name()=''DSLA'']', 'DSLA');
    end;

    internal procedure GenerateLohnEnvelope(EUBPSetup: Record "euBP Setup"; StartingDate: Date; EndingDate: Date): Text
    var
        LohnPayload: Text;
    begin
        LohnPayload := EUBPSetup.GetLohnPayloadText();
        ValidateLohnPayload(LohnPayload);
        exit(BuildTransportEnvelope(EUBPSetup, StartingDate, EndingDate, 'eubp:EntgeltDaten', GetPayloadRootElementXml(LohnPayload)));
    end;

    internal procedure GenerateFibuEnvelope(EUBPSetup: Record "euBP Setup"; StartingDate: Date; EndingDate: Date): Text
    begin
        exit(BuildTransportEnvelope(EUBPSetup, StartingDate, EndingDate, 'fibu:FinanzDaten', BuildFibuPayload(EUBPSetup, StartingDate, EndingDate)));
    end;

    local procedure BuildTransportEnvelope(EUBPSetup: Record "euBP Setup"; StartingDate: Date; EndingDate: Date; DataType: Text; PayloadXml: Text): Text
    var
        TextBuilder: TextBuilder;
    begin
        TextBuilder.Append('<Transport xmlns="http://www.extra-standard.de/namespace/transport">');
        TextBuilder.Append('<TransportHeader>');
        TextBuilder.Append('<SenderID>' + EscapeXml(EUBPSetup."Sender ID") + '</SenderID>');
        TextBuilder.Append('<ReceiverID>' + EscapeXml(EUBPSetup."Receiver ID") + '</ReceiverID>');
        TextBuilder.Append('<TimeStamp>' + FormatDateTimeAsIso(CurrentDateTime()) + '</TimeStamp>');
        TextBuilder.Append('<PeriodFrom>' + FormatDateAsIso(StartingDate) + '</PeriodFrom>');
        TextBuilder.Append('<PeriodTo>' + FormatDateAsIso(EndingDate) + '</PeriodTo>');
        TextBuilder.Append('<DataType>' + DataType + '</DataType>');
        TextBuilder.Append('</TransportHeader>');
        TextBuilder.Append('<TransportBody><Data>');
        TextBuilder.Append(PayloadXml);
        TextBuilder.Append('</Data></TransportBody>');
        TextBuilder.Append('</Transport>');
        exit(TextBuilder.ToText());
    end;

    local procedure BuildFibuPayload(EUBPSetup: Record "euBP Setup"; StartingDate: Date; EndingDate: Date): Text
    var
        CompanyInformation: Record "Company Information";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNameByNo: Dictionary of [Code[20], Text];
        VendorName: Text;
        TextBuilder: TextBuilder;
    begin
        CompanyInformation.Get();

        TextBuilder.Append('<fibu:FinanzDaten xmlns:fibu="http://www.deutsche-rentenversicherung.de/fibu">');
        TextBuilder.Append('<DSAG>');
        TextBuilder.Append('<Mandant>' + EscapeXml(EUBPSetup."Sender ID") + '</Mandant>');
        TextBuilder.Append('<Name>' + EscapeXml(CompanyInformation.Name) + '</Name>');
        TextBuilder.Append('<CompanyTaxID>' + EscapeXml(CompanyInformation."VAT Registration No.") + '</CompanyTaxID>');
        TextBuilder.Append('</DSAG>');

        TextBuilder.Append('<DSST>');
        TextBuilder.Append('<Betriebsnummer>' + EscapeXml(EUBPSetup."Sender ID") + '</Betriebsnummer>');
        TextBuilder.Append('<ZeitraumVon>' + FormatDateAsIso(StartingDate) + '</ZeitraumVon>');
        TextBuilder.Append('<ZeitraumBis>' + FormatDateAsIso(EndingDate) + '</ZeitraumBis>');
        TextBuilder.Append('</DSST>');

        TextBuilder.Append('<ChartOfAccounts>');
        if GLAccount.FindSet() then
            repeat
                TextBuilder.Append('<Account>');
                TextBuilder.Append('<No>' + EscapeXml(GLAccount."No.") + '</No>');
                TextBuilder.Append('<Name>' + EscapeXml(GLAccount.Name) + '</Name>');
                TextBuilder.Append('<AccountType>' + EscapeXml(Format(GLAccount."Account Type")) + '</AccountType>');
                TextBuilder.Append('</Account>');
            until GLAccount.Next() = 0;
        TextBuilder.Append('</ChartOfAccounts>');

        TextBuilder.Append('<GLEntries>');
        GLEntry.SetRange("Posting Date", StartingDate, EndingDate);
        if GLEntry.FindSet() then
            repeat
                TextBuilder.Append('<Buchung>');
                TextBuilder.Append('<Datum>' + FormatDateAsIso(GLEntry."Posting Date") + '</Datum>');
                TextBuilder.Append('<Konto>' + EscapeXml(GLEntry."G/L Account No.") + '</Konto>');
                TextBuilder.Append('<Betrag>' + FormatDecimalAsInvariant(GLEntry.Amount) + '</Betrag>');
                TextBuilder.Append('<Belegnummer>' + EscapeXml(GLEntry."Document No.") + '</Belegnummer>');
                TextBuilder.Append('<Beschreibung>' + EscapeXml(GLEntry.Description) + '</Beschreibung>');
                TextBuilder.Append('<DocumentType>' + EscapeXml(Format(GLEntry."Document Type")) + '</DocumentType>');
                TextBuilder.Append('</Buchung>');
            until GLEntry.Next() = 0;
        TextBuilder.Append('</GLEntries>');

        TextBuilder.Append('<CustomerLedgerEntries>');
        CustLedgerEntry.SetRange("Posting Date", StartingDate, EndingDate);
        if CustLedgerEntry.FindSet() then
            repeat
                TextBuilder.Append('<CustomerLedgerEntry>');
                TextBuilder.Append('<CustomerNo>' + EscapeXml(CustLedgerEntry."Customer No.") + '</CustomerNo>');
                TextBuilder.Append('<PostingDate>' + FormatDateAsIso(CustLedgerEntry."Posting Date") + '</PostingDate>');
                TextBuilder.Append('<Amount>' + FormatDecimalAsInvariant(CustLedgerEntry.Amount) + '</Amount>');
                TextBuilder.Append('</CustomerLedgerEntry>');
            until CustLedgerEntry.Next() = 0;
        TextBuilder.Append('</CustomerLedgerEntries>');

        TextBuilder.Append('<VendorLedgerEntries>');
        VendorLedgerEntry.SetRange("Posting Date", StartingDate, EndingDate);
        if VendorLedgerEntry.FindSet() then
            repeat
                TextBuilder.Append('<VendorLedgerEntry>');
                TextBuilder.Append('<VendorNo>' + EscapeXml(VendorLedgerEntry."Vendor No.") + '</VendorNo>');
                VendorName := GetVendorName(VendorLedgerEntry."Vendor No.", VendorNameByNo);
                if VendorName <> '' then
                    TextBuilder.Append('<VendorName>' + EscapeXml(VendorName) + '</VendorName>');
                TextBuilder.Append('<PostingDate>' + FormatDateAsIso(VendorLedgerEntry."Posting Date") + '</PostingDate>');
                TextBuilder.Append('<Amount>' + FormatDecimalAsInvariant(VendorLedgerEntry.Amount) + '</Amount>');
                TextBuilder.Append('</VendorLedgerEntry>');
            until VendorLedgerEntry.Next() = 0;
        TextBuilder.Append('</VendorLedgerEntries>');

        AppendPayrollMapping(EUBPSetup, StartingDate, EndingDate, TextBuilder);
        TextBuilder.Append('</fibu:FinanzDaten>');
        exit(TextBuilder.ToText());
    end;

    local procedure AppendPayrollMapping(EUBPSetup: Record "euBP Setup"; StartingDate: Date; EndingDate: Date; var TextBuilder: TextBuilder)
    var
        GLEntry: Record "G/L Entry";
    begin
        TextBuilder.Append('<PayrollMapping>');

        AppendAccountsByFilter('PayrollExpenseAccounts', EUBPSetup."Payroll Expense Filter", TextBuilder);
        AppendAccountsByFilter('EmployerContributionAccounts', EUBPSetup."Employer Contr. Filter", TextBuilder);
        AppendAccountsByFilter('PayrollTaxAccounts', EUBPSetup."Payroll Tax Filter", TextBuilder);

        TextBuilder.Append('<PayrollPostingEntries>');
        GLEntry.SetRange("Posting Date", StartingDate, EndingDate);
        if EUBPSetup."Payroll Posting Filter" <> '' then
            GLEntry.SetFilter("G/L Account No.", EUBPSetup."Payroll Posting Filter");
        if GLEntry.FindSet() then
            repeat
                TextBuilder.Append('<PayrollPostingEntry>');
                TextBuilder.Append('<PostingDate>' + FormatDateAsIso(GLEntry."Posting Date") + '</PostingDate>');
                TextBuilder.Append('<DocumentNo>' + EscapeXml(GLEntry."Document No.") + '</DocumentNo>');
                TextBuilder.Append('<Amount>' + FormatDecimalAsInvariant(GLEntry.Amount) + '</Amount>');
                TextBuilder.Append('<GLAccountNo>' + EscapeXml(GLEntry."G/L Account No.") + '</GLAccountNo>');
                TextBuilder.Append('</PayrollPostingEntry>');
            until GLEntry.Next() = 0;
        TextBuilder.Append('</PayrollPostingEntries>');

        AppendPayrollVendors(EUBPSetup, StartingDate, EndingDate, TextBuilder);
        TextBuilder.Append('</PayrollMapping>');
    end;

    local procedure AppendAccountsByFilter(ContainerTag: Text; GLFilter: Text; var TextBuilder: TextBuilder)
    var
        GLAccount: Record "G/L Account";
    begin
        TextBuilder.Append('<' + ContainerTag + '>');
        if GLFilter <> '' then
            GLAccount.SetFilter("No.", GLFilter);
        if GLAccount.FindSet() then
            repeat
                TextBuilder.Append('<Account>');
                TextBuilder.Append('<No>' + EscapeXml(GLAccount."No.") + '</No>');
                TextBuilder.Append('<Name>' + EscapeXml(GLAccount.Name) + '</Name>');
                TextBuilder.Append('</Account>');
            until GLAccount.Next() = 0;
        TextBuilder.Append('</' + ContainerTag + '>');
    end;

    local procedure AppendPayrollVendors(EUBPSetup: Record "euBP Setup"; StartingDate: Date; EndingDate: Date; var TextBuilder: TextBuilder)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNameByNo: Dictionary of [Code[20], Text];
        VendorName: Text;
    begin
        TextBuilder.Append('<PayrollVendors>');
        VendorLedgerEntry.SetRange("Posting Date", StartingDate, EndingDate);
        if EUBPSetup."Payroll Vendor Filter" <> '' then
            VendorLedgerEntry.SetFilter("Vendor No.", EUBPSetup."Payroll Vendor Filter");
        if VendorLedgerEntry.FindSet() then
            repeat
                TextBuilder.Append('<PayrollVendor>');
                TextBuilder.Append('<VendorNo>' + EscapeXml(VendorLedgerEntry."Vendor No.") + '</VendorNo>');
                VendorName := GetVendorName(VendorLedgerEntry."Vendor No.", VendorNameByNo);
                if VendorName <> '' then
                    TextBuilder.Append('<Name>' + EscapeXml(VendorName) + '</Name>');
                TextBuilder.Append('<Amount>' + FormatDecimalAsInvariant(VendorLedgerEntry.Amount) + '</Amount>');
                TextBuilder.Append('</PayrollVendor>');
            until VendorLedgerEntry.Next() = 0;
        TextBuilder.Append('</PayrollVendors>');
    end;

    local procedure GetPayloadRootElementXml(PayloadXml: Text): Text
    var
        PayloadDocument: XmlDocument;
        RootNode: XmlNode;
        RootElementXml: Text;
    begin
        XmlDocument.ReadFrom(PayloadXml, PayloadDocument);
        if not PayloadDocument.SelectSingleNode('/*', RootNode) then
            exit(PayloadXml);

        RootNode.WriteTo(RootElementXml);
        exit(RootElementXml);
    end;

    local procedure GetVendorName(VendorNo: Code[20]; var VendorNameByNo: Dictionary of [Code[20], Text]): Text
    var
        Vendor: Record Vendor;
        VendorName: Text;
    begin
        if VendorNameByNo.Get(VendorNo, VendorName) then
            exit(VendorName);

        if Vendor.Get(VendorNo) then
            VendorName := Vendor.Name
        else
            VendorName := '';

        VendorNameByNo.Add(VendorNo, VendorName);
        exit(VendorName);
    end;

    local procedure AssertNodeExists(var XmlDocument: XmlDocument; XPath: Text; NodeName: Text)
    var
        Node: XmlNode;
    begin
        if not XmlDocument.SelectSingleNode(XPath, Node) then
            Error(LohnRequiredNodeMissingErr, NodeName);
    end;

    local procedure EscapeXml(Value: Text): Text
    begin
        Value := ConvertStr(Value, '&', '§');
        Value := Value.Replace('§', '&amp;');
        Value := Value.Replace('<', '&lt;');
        Value := Value.Replace('>', '&gt;');
        Value := Value.Replace('"', '&quot;');
        Value := Value.Replace('''', '&apos;');
        exit(Value);
    end;

    local procedure FormatDateAsIso(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure FormatDateTimeAsIso(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>Z'));
    end;

    local procedure FormatDecimalAsInvariant(Value: Decimal): Text
    begin
        exit(Format(Value, 0, 9));
    end;
}
