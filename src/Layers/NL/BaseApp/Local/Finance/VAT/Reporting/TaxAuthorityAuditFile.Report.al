// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System;
using System.Environment;
using System.IO;

report 11412 "Tax Authority - Audit File"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Authority - Audit File';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));

            trigger OnAfterGetRecord()
            begin
                CalcFields("Balance at Date");
                if ("Balance at Date" <> 0) and not ExcludeBeginBalance then
                    WriteAccountBeginBalance();
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Date Filter", '..%1', ClosingDate(StartDate - 1));
            end;
        }
        dataitem("Accounting Period"; "Accounting Period")
        {
            DataItemTableView = sorting("Starting Date");
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("G/L Account No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if ("Debit Amount" <> 0) or ("Credit Amount" <> 0) then begin
                        BufferGLAccount("G/L Account No.");
                        BufferCustomerVendor();
                        BufferTransactions();

                        TotalEntries := TotalEntries + 1;
                        TotalDebit := TotalDebit + "Debit Amount";
                        TotalCredit := TotalCredit + "Credit Amount";
                    end;

                    UpdateWindow(1);
                end;

                trigger OnPreDataItem()
                var
                    UseStartDate: Date;
                    UseStopDate: Date;
                begin
                    if "Accounting Period"."Starting Date" < StartDate then
                        UseStartDate := StartDate
                    else
                        UseStartDate := "Accounting Period"."Starting Date";
                    if EndPeriodDate > EndDate then
                        UseStopDate := EndDate
                    else
                        UseStopDate := EndPeriodDate;
                    SetRange("Posting Date", UseStartDate, ClosingDate(UseStopDate));
                end;
            }

            trigger OnAfterGetRecord()
            var
                NextAcctPeriod: Record "Accounting Period";
            begin
                FindPeriodNo("Accounting Period");
                NextAcctPeriod.Get("Starting Date");

                if NextAcctPeriod.Next() = 0 then
                    EndPeriodDate := CalcDate('<+1M-1D>', NextAcctPeriod."Starting Date")
                else
                    EndPeriodDate := CalcDate('<-1D>', NextAcctPeriod."Starting Date");
            end;

            trigger OnPreDataItem()
            begin
                PeriodNumber := 0;
                CopyFilters(AccountingPeriod);
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';

                        trigger OnValidate()
                        begin
                            StartDateOnAfterValidate();
                        end;
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the last date for which data is included in the file.';
                    }
                    field(ExcludeBalance; ExcludeBeginBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exclude Begin Balance';
                        Enabled = ExcludeBalanceEnable;
                        ToolTip = 'Specifies if the starting balance is included in the file. This option is available when the start date is equal to the first date of a fiscal year.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ExcludeBalanceEnable := true;
        end;

        trigger OnOpenPage()
        begin
            EnableBeginBalance();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        TempAuditFileBuffer.Reset();
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        CompanyInfo.Get();
    end;

    trigger OnPostReport()
    var
        FileMgmt: Codeunit "File Management";
        Encoding: DotNet Encoding;
        XmlWriterSettings: DotNet XmlWriterSettings;
        ServerFileName: Text;
    begin
        ServerFileName := FileMgmt.ServerTempFileName('.xaf');

        TotalCount := TempAuditFileBuffer.Count();
        StepEntries := Round(TotalCount / 1000, 1, '>');
        NextStep := StepEntries;
        CountEntries := 0;

        XmlWriterSettings := XmlWriterSettings.XmlWriterSettings();
        XmlWriterSettings.Encoding := Encoding.GetEncoding('windows-1252');
        XmlWriterSettings.OmitXmlDeclaration := false;
        XmlWriterSettings.Indent := true;

        XmlWriter := XmlWriter.Create(ServerFileName, XmlWriterSettings);

        XmlWriter.WriteStartDocument();
        XmlWriter.WriteStartElement('auditfile', XAFNameSpaceTxt);
        FlushOutput();

        WriteHeader();

        StartElement('company');
        WriteCompanyInformation();
        WriteCustomersVendors();
        WriteGLAccounts();
        WriteTransactions();
        EndElement();

        EndElement();
        XmlWriter.WriteEndDocument();
        FlushOutput();

        Clear(XmlWriter);

        if FileName = '' then
            FileMgmt.DownloadHandler(ServerFileName, '', '', Text015, ClientFileTxt)
        else
            FileMgmt.CopyServerFile(ServerFileName, FileName, true);

        Window.Close();
    end;

    trigger OnPreReport()
    var
        LocGLEntry: Record "G/L Entry";
        FilterStartDate: Date;
        FilterEndDate: Date;
        FirstRecord: Boolean;
    begin
        // Check User input
        if StartDate = 0D then
            Error(Text010);
        if EndDate = 0D then
            Error(Text011);
        if StartDate > EndDate then
            Error(Text004);
        if EndDate > Today then
            Error(Text005);

        // Filter Accounting Period
        AccountingPeriod.Reset();
        AccountingPeriod."Starting Date" := StartDate;
        if not AccountingPeriod.Find('=<') then
            Error(Text012);
        FilterStartDate := AccountingPeriod."Starting Date";
        AccountingPeriod."Starting Date" := EndDate;
        AccountingPeriod.Find('=<');
        FilterEndDate := AccountingPeriod."Starting Date";
        AccountingPeriod.SetFilter("Starting Date", '%1..%2', FilterStartDate, FilterEndDate);

        // Check Fiscal Year
        FirstRecord := true;
        if AccountingPeriod.Find('-') then
            repeat
                if AccountingPeriod."New Fiscal Year" and not FirstRecord then
                    Error(Text006);
                FirstRecord := false;
            until AccountingPeriod.Next() = 0;

        Window.Open(Text009);
        LocGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        LocGLEntry.SetRange("Posting Date", StartDate, ClosingDate(EndDate));
        TotalCount := LocGLEntry.Count();
        StepEntries := Round(TotalCount / 1000, 1, '>');
        NextStep := StepEntries;
        CountEntries := 0;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        TempAuditFileBuffer: Record "Audit File Buffer" temporary;
        AccountingPeriod: Record "Accounting Period";
        Window: Dialog;
        XmlWriter: DotNet XmlWriter;
        StartDate: Date;
        EndDate: Date;
        EndPeriodDate: Date;
        PeriodNumber: Integer;
        TotalEntries: BigInteger;
        TotalCount: BigInteger;
        CountEntries: BigInteger;
        StepEntries: BigInteger;
        NextStep: BigInteger;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        CustSupID: Code[35];
        ExcludeBeginBalance: Boolean;
        Text004: Label 'Start Date cannot be higher than End Date.';
        Text005: Label 'End Date cannot be higher than today.';
        Text006: Label 'Start/End Date must be within one fiscal year.';
        Text009: Label 'Processing Data @1@@@@@@@@@@@@@\\Exporting Data  @2@@@@@@@@@@@@@ ';
        Text010: Label 'Start Date cannot be blank.';
        Text011: Label 'End Date cannot be blank.';
        Text012: Label 'Start Date should be within one of the setup accounting periods. ';
        Text015: Label 'Audit File (*.xaf)|*.xaf|All Files|*.*';
        ExcludeBalanceEnable: Boolean;
        ClientFileTxt: Label 'Audit.xaf', Locked = true;
        XAFNameSpaceTxt: Label 'http://www.auditfiles.nl/XAF/3.2', Locked = true;
        FileName: Text;

    local procedure BufferGLAccount(AcctNo: Code[20])
    begin
        Clear(TempAuditFileBuffer);
        TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::"G/L Account";
        TempAuditFileBuffer.Code := AcctNo;
        if not TempAuditFileBuffer.Get(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code) then
            TempAuditFileBuffer.Insert();
    end;

    local procedure BufferCustomerVendor()
    begin
        Clear(CustSupID);
        Clear(TempAuditFileBuffer);

        if "G/L Entry"."Source Type" = "G/L Entry"."Source Type"::Customer then
            TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Customer
        else
            if "G/L Entry"."Source Type" = "G/L Entry"."Source Type"::Vendor then
                TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Vendor
            else
                if "G/L Entry"."Source Type" = "G/L Entry"."Source Type"::"Bank Account" then
                    TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::"Bank Account";

        if TempAuditFileBuffer.Rectype <> TempAuditFileBuffer.Rectype::" " then begin
            TempAuditFileBuffer.Code := "G/L Entry"."Source No.";
            CustSupID := GetFormatedCustSupID(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code);
            if not TempAuditFileBuffer.Get(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code) then
                TempAuditFileBuffer.Insert();
        end;
    end;

    local procedure BufferTransactions()
    var
        SourceCode: Record "Source Code";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Clear(TempAuditFileBuffer);
        TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Transaction;

        // Journal data
        TempAuditFileBuffer.JournalID := "G/L Entry"."Source Code";
        if SourceCode.Get("G/L Entry"."Source Code") then
            TempAuditFileBuffer.JournalDescription := SourceCode.Description;

        // Transaction data
        TempAuditFileBuffer.TransactionID := Format("G/L Entry"."Transaction No.", 0, 9);
        TempAuditFileBuffer.TransactionDate := "G/L Entry"."Posting Date";
        TempAuditFileBuffer.TransactionDescription := "G/L Entry".Description;
        TempAuditFileBuffer.Period := Format(PeriodNumber, 0, 9);

        // Line data
        TempAuditFileBuffer.RecordID := Format("G/L Entry"."Entry No.", 0, 9);
        TempAuditFileBuffer."Account ID" :=
          CopyStr("G/L Entry"."G/L Account No.", 1, MaxStrLen(TempAuditFileBuffer."Account ID"));
        TempAuditFileBuffer."Source ID" :=
          CopyStr(CustSupID, 1, MaxStrLen(TempAuditFileBuffer."Source ID"));
        TempAuditFileBuffer."Document ID" :=
          CopyStr("G/L Entry"."Document No.", 1, MaxStrLen(TempAuditFileBuffer."Document ID"));
        TempAuditFileBuffer.EffectiveDate := "G/L Entry"."Document Date";
        TempAuditFileBuffer.LineDescription := "G/L Entry".Description;
        TempAuditFileBuffer.DebitAmount := "G/L Entry"."Debit Amount";
        TempAuditFileBuffer.CreditAmount := "G/L Entry"."Credit Amount";
        TempAuditFileBuffer.CostDescription := "G/L Entry"."Global Dimension 1 Code";
        TempAuditFileBuffer.ProductDescription := "G/L Entry"."Global Dimension 2 Code";
        if "G/L Entry"."VAT Amount" <> 0 then begin
            TempAuditFileBuffer.VATCode := "G/L Entry"."VAT Prod. Posting Group";
            if VATPostingSetup.Get("G/L Entry"."VAT Bus. Posting Group", "G/L Entry"."VAT Prod. Posting Group") then
                TempAuditFileBuffer."VAT %" := VATPostingSetup."VAT %";
            TempAuditFileBuffer.VATAmount := "G/L Entry"."VAT Amount";
        end;
        TempAuditFileBuffer.Insert();
    end;

    local procedure StartElement(LocalName: Text[80])
    begin
        XmlWriter.WriteStartElement(LocalName);
    end;

    local procedure EndElement()
    begin
        XmlWriter.WriteEndElement();
    end;

    local procedure WriteElement(QualifiedName: Text[80]; Value: Text[1024])
    begin
        XmlWriter.WriteElementString(QualifiedName, Value);
    end;

    local procedure WriteElementWithValue(LocalName: Text[80]; Value: Text[1024])
    begin
        if Value <> '' then
            XmlWriter.WriteElementString(LocalName, Value);
    end;

    local procedure WriteHeader()
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        StartElement('header');
        WriteElement('fiscalYear', Format(StartDate, 0, '<YEAR4>'));
        WriteElement('startDate', FormatDate(StartDate));
        WriteElement('endDate', FormatDate(EndDate));
        WriteElement('curCode', CopyStr(GLSetup."LCY Code", 1, 3));
        WriteElement('dateCreated', FormatDate(Today));
        WriteElement('softwareDesc', 'Microsoft Dynamics NAV');
        WriteElement('softwareVersion', CopyStr(ApplicationSystemConstants.ApplicationVersion(), 1, 20));
        EndElement();
        FlushOutput();
    end;

    local procedure WriteCompanyInformation()
    var
        CountryRegion: Record "Country/Region";
        ShipToCountryRegion: Record "Country/Region";
    begin
        if CountryRegion.Get(CompanyInfo."Country/Region Code") then;
        if ShipToCountryRegion.Get(CompanyInfo."Ship-to Country/Region Code") then;

        WriteElement('companyIdent', CopyStr(CompanyName, 1, 35));
        WriteElement('companyName', ConvertStr(CompanyInfo.Name, '.,', '  '));
        WriteElementWithValue('taxRegistrationCountry', CountryRegion."ISO Code");
        WriteElement('taxRegIdent', CompanyInfo."VAT Registration No.");

        StartElement('streetAddress');
        WriteElement('streetname', CompanyInfo."Ship-to Address");
        WriteElement('number', '');
        WriteElement('numberExtension', '');
        WriteElement('city', CompanyInfo."Ship-to City");
        WriteElement('postalCode', CopyStr(CompanyInfo."Ship-to Post Code", 1, 10));
        WriteElementWithValue('country', ShipToCountryRegion."ISO Code");
        EndElement();

        StartElement('postalAddress');
        WriteElement('streetname', CompanyInfo.Address);
        WriteElement('number', '');
        WriteElement('numberExtension', '');
        WriteElement('city', CompanyInfo.City);
        WriteElement('postalCode', CopyStr(CompanyInfo."Post Code", 1, 10));
        WriteElementWithValue('country', CountryRegion."ISO Code");
        EndElement();
    end;

    local procedure WriteGLAccounts()
    var
        GLAcc: Record "G/L Account";
    begin
        TempAuditFileBuffer.Reset();
        TempAuditFileBuffer.SetRange(Rectype, TempAuditFileBuffer.Rectype::"G/L Account");
        StartElement('generalLedger');

        if TempAuditFileBuffer.FindSet() then
            repeat
                StartElement('ledgerAccount');
                if GLAcc.Get(TempAuditFileBuffer.Code) then begin
                    WriteElement('accID', TempAuditFileBuffer.Code);
                    WriteElement('accDesc', GLAcc.Name);
                    case GLAcc."Income/Balance" of
                        GLAcc."Income/Balance"::"Income Statement":
                            WriteElement('accTp', 'P');     // Profit and Loss
                        GLAcc."Income/Balance"::"Balance Sheet":
                            WriteElement('accTp', 'B');     // Balance
                    end;
                    WriteElement('leadCode', GLAcc."No.");
                    WriteElement('leadDescription', GLAcc.Name);
                end;
                EndElement();
                UpdateWindow(2);
                FlushOutput();
            until TempAuditFileBuffer.Next() = 0;

        EndElement();
    end;

    local procedure WriteCustomersVendors()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        CountryRegion: Record "Country/Region";
        ShipToCountryRegion: Record "Country/Region";
        ShipToAddress: Record "Ship-to Address";
        CustBankAccount: Record "Customer Bank Account";
        VendBankAccount: Record "Vendor Bank Account";
        CustBankAccountNo: Text;
        VendBankAccountNo: Text;
    begin
        TempAuditFileBuffer.Reset();
        TempAuditFileBuffer.SetFilter(Rectype, '%1|%2|%3', TempAuditFileBuffer.Rectype::Customer,
          TempAuditFileBuffer.Rectype::Vendor, TempAuditFileBuffer.Rectype::"Bank Account");
        StartElement('customersSuppliers');

        if TempAuditFileBuffer.FindSet() then
            repeat
                StartElement('customerSupplier');
                WriteElement('custSupID', CopyStr(GetFormatedCustSupID(TempAuditFileBuffer.Rectype, TempAuditFileBuffer.Code), 1, 35));
                case TempAuditFileBuffer.Rectype of
                    TempAuditFileBuffer.Rectype::Customer:
                        if Cust.Get(TempAuditFileBuffer.Code) then begin
                            WriteElement('custSupName', CopyStr(Cust.Name, 1, 50));
                            WriteElement('contact', CopyStr(Cust.Contact, 1, 50));
                            WriteElement('telephone', Cust."Phone No.");
                            WriteElement('fax', Cust."Fax No.");
                            WriteElement('eMail', DelChr(Cust."E-Mail"));
                            WriteElement('website', DelChr(Cust."Home Page", '<>', ' '));

                            Clear(CountryRegion);
                            if CountryRegion.Get(Cust."Country/Region Code") then;
                            WriteElementWithValue('taxRegistrationCountry', CountryRegion."ISO Code");

                            WriteElement('taxRegIdent', Cust."VAT Registration No.");
                            WriteElement('custSupTp', 'C'); // C - Customer
                            WriteElement('custCreditLimit', FormatAmount(Cust."Credit Limit (LCY)"));

                            ShipToAddress.SetRange("Customer No.", Cust."No.");
                            if ShipToAddress.FindSet() then
                                repeat
                                    Clear(ShipToCountryRegion);
                                    if ShipToCountryRegion.Get(ShipToAddress."Country/Region Code") then;
                                    StartElement('streetAddress');
                                    WriteElement('streetname', ShipToAddress.Address);
                                    WriteElement('number', '');
                                    WriteElement('numberExtension', '');
                                    WriteElement('city', ShipToAddress.City);
                                    WriteElement('postalCode', CopyStr(ShipToAddress."Post Code", 1, 10));
                                    WriteElementWithValue('country', ShipToCountryRegion."ISO Code");
                                    EndElement();
                                until ShipToAddress.Next() = 0;

                            StartElement('postalAddress');
                            WriteElement('streetname', Cust.Address);
                            WriteElement('number', '');
                            WriteElement('numberExtension', '');
                            WriteElement('city', Cust.City);
                            WriteElement('postalCode', CopyStr(Cust."Post Code", 1, 10));
                            WriteElementWithValue('country', CountryRegion."ISO Code");
                            EndElement();

                            CustBankAccount.SetRange("Customer No.", Cust."No.");
                            if CustBankAccount.FindSet() then
                                repeat
                                    CustBankAccountNo := CustBankAccount.GetBankAccountNo();
                                    StartElement('bankAccount');
                                    WriteElement('bankAccNr', CopyStr(CustBankAccountNo, 1, 35));
                                    WriteElement('bankIdCd', CustBankAccount."SWIFT Code");
                                    EndElement();
                                until CustBankAccount.Next() = 0;
                        end;
                    TempAuditFileBuffer.Rectype::Vendor:
                        if Vend.Get(TempAuditFileBuffer.Code) then begin
                            WriteElement('custSupName', CopyStr(Vend.Name, 1, 50));
                            WriteElement('contact', CopyStr(Vend.Contact, 1, 50));
                            WriteElement('telephone', Vend."Phone No.");
                            WriteElement('fax', Vend."Fax No.");
                            WriteElement('eMail', DelChr(Vend."E-Mail"));
                            WriteElement('website', DelChr(Vend."Home Page", '<>', ' '));

                            Clear(CountryRegion);
                            if CountryRegion.Get(Vend."Country/Region Code") then;
                            WriteElementWithValue('taxRegistrationCountry', CountryRegion."ISO Code");

                            WriteElement('taxRegIdent', Vend."VAT Registration No.");
                            WriteElement('custSupTp', 'S'); // S - Supplier

                            StartElement('postalAddress');
                            WriteElement('streetname', Vend.Address);
                            WriteElement('number', '');
                            WriteElement('numberExtension', '');
                            WriteElement('city', Vend.City);
                            WriteElement('postalCode', CopyStr(Vend."Post Code", 1, 10));
                            WriteElementWithValue('country', CountryRegion."ISO Code");
                            EndElement();

                            VendBankAccount.SetRange("Vendor No.", Vend."No.");
                            if VendBankAccount.FindSet() then
                                repeat
                                    VendBankAccountNo := VendBankAccount.GetBankAccountNo();
                                    StartElement('bankAccount');
                                    WriteElement('bankAccNr', CopyStr(VendBankAccountNo, 1, 35));
                                    WriteElement('bankIdCd', VendBankAccount."SWIFT Code");
                                    EndElement();
                                until VendBankAccount.Next() = 0;
                        end;
                    TempAuditFileBuffer.Rectype::"Bank Account":
                        if BankAcc.Get(TempAuditFileBuffer.Code) then begin
                            WriteElement('custSupName', CopyStr(BankAcc.Name, 1, 50));
                            WriteElement('contact', CopyStr(BankAcc.Contact, 1, 50));
                            WriteElement('telephone', BankAcc."Phone No.");
                            WriteElement('fax', BankAcc."Fax No.");
                            WriteElement('eMail', DelChr(BankAcc."E-Mail"));
                            WriteElement('website', DelChr(BankAcc."Home Page", '<>', ' '));
                            WriteElement('custSupTp', 'O'); // O - Other, not Customer or Supplier

                            Clear(CountryRegion);
                            if CountryRegion.Get(BankAcc."Country/Region Code") then;
                            StartElement('postalAddress');
                            WriteElement('streetname', BankAcc.Address);
                            WriteElement('number', '');
                            WriteElement('numberExtension', '');
                            WriteElement('city', BankAcc.City);
                            WriteElement('postalCode', CopyStr(BankAcc."Post Code", 1, 10));
                            WriteElementWithValue('country', CountryRegion."ISO Code");
                            EndElement();

                            StartElement('bankAccount');
                            WriteElement('bankAccNr', CopyStr(BankAcc.GetBankAccountNo(), 1, 35));
                            WriteElement('bankIdCd', BankAcc."SWIFT Code");
                            EndElement();
                        end;
                end;
                EndElement();
                UpdateWindow(2);
                FlushOutput();
            until TempAuditFileBuffer.Next() = 0;
        EndElement();
    end;

    local procedure WriteTransactions()
    var
        OldJournalID: Text[20];
        OldTransactionID: Text[20];
        TrLineAmount: Decimal;
        TrLineType: Text[1];
        FirstLoop: Boolean;
        JournalElementStarted: Boolean;
        TransactionElementStarted: Boolean;
    begin
        OldJournalID := '';
        FirstLoop := true;
        TempAuditFileBuffer.Reset();
        TempAuditFileBuffer.SetRange(Rectype, TempAuditFileBuffer.Rectype::Transaction);

        StartElement('transactions');
        WriteElement('linesCount', Format(TotalEntries));
        WriteElement('totalDebit', FormatAmount(TotalDebit));
        WriteElement('totalCredit', FormatAmount(TotalCredit));

        if TempAuditFileBuffer.FindSet() then
            repeat
                if FirstLoop or (OldJournalID <> TempAuditFileBuffer.JournalID) then begin
                    FirstLoop := false;
                    OldJournalID := TempAuditFileBuffer.JournalID;
                    OldTransactionID := '';
                    if TransactionElementStarted then begin
                        EndElement();
                        TransactionElementStarted := false;
                    end;
                    if JournalElementStarted then
                        EndElement();
                    StartElement('journal');
                    JournalElementStarted := true;
                    WriteElement('jrnID', TempAuditFileBuffer.JournalID);
                    WriteElement('desc', TempAuditFileBuffer.JournalDescription);
                end;
                if OldTransactionID <> TempAuditFileBuffer.TransactionID then begin
                    OldTransactionID := TempAuditFileBuffer.TransactionID;
                    if TransactionElementStarted then
                        EndElement();
                    StartElement('transaction');
                    TransactionElementStarted := true;
                    WriteElement('nr', TempAuditFileBuffer.TransactionID);
                    WriteElement('desc', TempAuditFileBuffer.TransactionDescription);
                    WriteElement('periodNumber', TempAuditFileBuffer.Period);
                    WriteElement('trDt', FormatDate(TempAuditFileBuffer.TransactionDate));
                end;
                StartElement('trLine');
                WriteElement('nr', TempAuditFileBuffer.RecordID);
                WriteElement('accID', TempAuditFileBuffer."Account ID");
                WriteElement('docRef', TempAuditFileBuffer."Document ID");
                WriteElement('effDate', FormatDate(TempAuditFileBuffer.EffectiveDate));
                WriteElement('desc', TempAuditFileBuffer.LineDescription);
                if TempAuditFileBuffer.DebitAmount <> 0 then begin
                    TrLineAmount := TempAuditFileBuffer.DebitAmount;
                    TrLineType := 'D';      // Debit amount type
                end else
                    if TempAuditFileBuffer.CreditAmount <> 0 then begin
                        TrLineAmount := TempAuditFileBuffer.CreditAmount;
                        TrLineType := 'C';  // Credit amount type
                    end;
                WriteElement('amnt', FormatAmount(TrLineAmount));
                WriteElement('amntTp', TrLineType);
                if TempAuditFileBuffer."Source ID" <> '' then
                    WriteElement('custSupID', TempAuditFileBuffer."Source ID");
                if TempAuditFileBuffer.CostDescription <> '' then
                    WriteElement('costID', TempAuditFileBuffer.CostDescription);
                if TempAuditFileBuffer.ProductDescription <> '' then
                    WriteElement('prodID', TempAuditFileBuffer.ProductDescription);
                if TempAuditFileBuffer.VATAmount <> 0 then begin
                    StartElement('vat');
                    WriteElement('vatID', TempAuditFileBuffer.VATCode);
                    WriteElement('vatPerc', FormatVATAmount(TempAuditFileBuffer."VAT %"));
                    WriteElement('vatAmnt', FormatAmount(TempAuditFileBuffer.VATAmount));
                    WriteElement('vatAmntTp', TrLineType);
                    EndElement();
                end;
                EndElement();
                UpdateWindow(2);
                FlushOutput();
            until TempAuditFileBuffer.Next() = 0;

        if TransactionElementStarted then
            EndElement();
        if JournalElementStarted then
            EndElement();
        EndElement();
    end;

    local procedure FormatDate(Date: Date): Text[30]
    begin
        exit(Format(Date, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure FormatAmount(InAmount: Decimal): Text[30]
    begin
        exit(Format(InAmount, 0, '<Precision,:2><Standard Format,9>'));
    end;

    local procedure FormatVATAmount(InAmount: Decimal): Text[10]
    begin
        exit(Format(InAmount, 0, '<Precision,:3><Standard Format,9>'));
    end;

    local procedure WriteAccountBeginBalance()
    begin
        BufferGLAccount("G/L Account"."No.");

        Clear(TempAuditFileBuffer);
        TempAuditFileBuffer.Rectype := TempAuditFileBuffer.Rectype::Transaction;

        // Journal data
        TempAuditFileBuffer.JournalID := 'BEGINBALANS';
        TempAuditFileBuffer.JournalDescription := 'Begin balans';

        // Transaction data
        TempAuditFileBuffer.TransactionID := '0';
        TempAuditFileBuffer.TransactionDate := StartDate;
        TempAuditFileBuffer.TransactionDescription := 'Begin balans grootboekrekeningen';
        TempAuditFileBuffer.Period := '0';

        // Line data
        TempAuditFileBuffer.RecordID := Format(FindBeginBalanceEntryNo("G/L Account"."No."), 0, 9);
        TempAuditFileBuffer."Account ID" :=
          CopyStr("G/L Account"."No.", 1, MaxStrLen(TempAuditFileBuffer."Account ID"));
        TempAuditFileBuffer.EffectiveDate := StartDate;
        TempAuditFileBuffer.LineDescription := 'Transactie beginbalans';
        if "G/L Account"."Balance at Date" > 0 then
            TempAuditFileBuffer.DebitAmount := "G/L Account"."Balance at Date"
        else
            TempAuditFileBuffer.CreditAmount := Abs("G/L Account"."Balance at Date");

        TempAuditFileBuffer.Insert();

        TotalEntries := TotalEntries + 1;
        TotalDebit := TotalDebit + TempAuditFileBuffer.DebitAmount;
        TotalCredit := TotalCredit + TempAuditFileBuffer.CreditAmount;
    end;

    local procedure EnableBeginBalance()
    begin
        PageEnableBeginBalance();
    end;

    local procedure UpdateWindow(ProgressBarNo: Integer)
    begin
        CountEntries := CountEntries + 1;
        if CountEntries >= NextStep then begin
            Window.Update(ProgressBarNo, Round(10000 * (CountEntries / TotalCount), 1));
            NextStep := NextStep + StepEntries;
        end;
    end;

    local procedure FlushOutput()
    begin
        XmlWriter.Flush();
    end;

    local procedure FindPeriodNo(ParamAccountingPeriod: Record "Accounting Period")
    var
        FoundFiscalYear: Boolean;
    begin
        if PeriodNumber <> 0 then
            PeriodNumber := PeriodNumber + 1
        else begin
            PeriodNumber := 1;
            FoundFiscalYear := false;
            if not ParamAccountingPeriod."New Fiscal Year" then
                while (ParamAccountingPeriod.Next(-1) <> 0) and not FoundFiscalYear do begin
                    PeriodNumber := PeriodNumber + 1;
                    if ParamAccountingPeriod."New Fiscal Year" then
                        FoundFiscalYear := true;
                end;
        end;
    end;

    local procedure FindBeginBalanceEntryNo(GLAccountNo: Code[20]): Integer
    var
        LocGLEntry: Record "G/L Entry";
    begin
        LocGLEntry.Reset();
        LocGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        LocGLEntry.SetRange("G/L Account No.", GLAccountNo);
        LocGLEntry.SetFilter("Posting Date", '..%1', ClosingDate(StartDate - 1));
        LocGLEntry.FindLast();
        exit(LocGLEntry."Entry No.");
    end;

    local procedure StartDateOnAfterValidate()
    begin
        EnableBeginBalance();
    end;

    local procedure PageEnableBeginBalance()
    var
        LocAccountingPeriod: Record "Accounting Period";
    begin
        ExcludeBeginBalance := true;
        ExcludeBalanceEnable := false;
        if LocAccountingPeriod.Get(StartDate) then
            if LocAccountingPeriod."New Fiscal Year" then begin
                ExcludeBeginBalance := false;
                ExcludeBalanceEnable := true;
            end;
    end;

    [Scope('OnPrem')]
    procedure SetFileName(ServerFileName: Text)
    begin
        FileName := ServerFileName;
    end;

    local procedure GetFormatedCustSupID(Rectype: Option; CustomerSupID: Code[20]): Code[35]
    var
        AuditFileBuffer: Record "Audit File Buffer";
    begin
        if Rectype = AuditFileBuffer.Rectype::" " then
            exit(CustomerSupID);
        exit(StrSubstNo('%1%2', Format(Rectype, 0, 2), CustomerSupID));
    end;
}

