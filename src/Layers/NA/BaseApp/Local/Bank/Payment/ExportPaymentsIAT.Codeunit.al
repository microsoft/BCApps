// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

codeunit 10093 "Export Payments (IAT)"
{

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        VendorBankAcct: Record "Vendor Bank Account";
        Customer: Record Customer;
        CustBankAcct: Record "Customer Bank Account";
        RBMgt: Codeunit "File Management";
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        ExportFile: File;
        TotalFileDebit: Decimal;
        TotalFileCredit: Decimal;
        TotalBatchDebit: Decimal;
        TotalBatchCredit: Decimal;
        RecordLength: Integer;
        BlockingFactor: Integer;
        BlockCount: Integer;
        EntryAddendaCount: Integer;
        FileEntryAddendaCount: Integer;
        NoOfRec: Integer;
        Justification: Option Left,Right;
        BatchNo: Integer;
        BatchCount: Integer;
        FileHashTotal: Decimal;
        BatchHashTotal: Decimal;
        FileName: Text[250];
        FileIsInProcess: Boolean;
        BatchIsInProcess: Boolean;
        FileDate: Date;
        FileTime: Time;
        ModifierValues: array[26] of Code[1];
        TraceNo: Integer;
        ClientFile: Text[250];
        DestinationAcctType: Text[1];
        DestinationAcctNo: Code[20];
        DestinationName: Text[100];
        DestinationFederalIDNo: Text[30];
        DestinationAddress: Text[100];
        DestinationCity: Text[30];
        DestinationCountryCode: Code[10];
        DestinationCounty: Text[30];
        DestinationPostCode: Code[20];
        DestinationBankName: Text[100];
        DestinationBankTransitNo: Text[20];
        DestinationBankAcctNo: Text[30];
        DestinationBankCountryCode: Code[10];
        DestinationBankCurrencyCode: Code[10];
        ExportInProcessErr: Label 'Cannot start new Export File while %1 is in process.', Comment = 'CustomerBlockedErr';
        ExportFilePathErr: Label '%1 in %2 %3 is invalid.', Comment = '%1 = the export file path, %2 the field in the table, ie, bank, customer etc, %3 = the identifier for the record, ie, bankaccount number etc. ';
        FileAlreadyExistsErr: Label 'File %1 already exists. Check the %2 in %3 %4.', Comment = '%1 = file name, %2 file patch, the bank account table, the identifier in the bank account table, ie the .No';
        ExportFileNotStartedErr: Label 'Cannot start export batch until an export file is started.';
        ExportFileNotCompletedErr: Label 'Cannot start new export batch until previous batch is completed.';
        ExportDetailsFileNotStartedErr: Label 'Cannot export details until an export file is started.';
        ExportDetailsFileNotCompletedErr: Label 'Cannot export details until an export batch is started.';
        ExportBatchFileNotStartedErr: Label 'Cannot end export batch until an export file is started.';
        ExportBatchNotStartedErr: Label 'Cannot end export batch until an export batch is started.';
        ExportFileNotEndedFileNotStartedErr: Label 'Cannot end export file until an export file is started.';
        ExportFileNotEndedFileNotEndedErr: Label 'Cannot end export file until export batch is ended.';
        InvalidPaymentSpecErr: Label 'Either %1 or %2 must refer to either a %3 or a %4 for an electronic payment.', Comment = '%1 = Account Type, %2 = the account,%3 = Vendor table, %4 = Customer table';
        CustomerBlockedErr: Label '%1 is blocked for %2 processing.', Comment = '%1 = account type, %2 = customer.blocked';
        PrivacyBlockedErr: Label '%1 is blocked for privacy.', Comment = '%1 = account type';
        CustTransitNumNotValidErr: Label 'The specified transit number %1 for customer %2  is not valid.', Comment = '%1 the transit number, %2 The customer  No.';
        BankTransitNumNotValidErr: Label 'The specified transit number %1 for bank %2  is not valid.', Comment = '%1 the transit number, %2 The bank  No.';

    procedure StartExportFile(BankAccountNo: Code[20]; ReferenceCode: Code[10])
    var
        FileHeaderRec: Text[250];
        i: Integer;
    begin
        BuildIDModifier();
        if FileIsInProcess then
            Error(ExportInProcessErr, FileName);

        CompanyInformation.Get();
        CompanyInformation.TestField("Federal ID No.");

        BankAccount.LockTable();
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Export Format", BankAccount."Export Format"::US);
        BankAccount.TestField("Transit No.");
        if not ExportPaymentsACH.CheckDigit(BankAccount."Transit No.") then
            BankAccount.FieldError("Transit No.", StrSubstNo(BankTransitNumNotValidErr, BankAccount."Transit No.", BankAccount."No."));
        BankAccount.TestField("E-Pay Export File Path");
        if BankAccount."E-Pay Export File Path"[StrLen(BankAccount."E-Pay Export File Path")] <> '\' then
            Error(ExportFilePathErr,
              BankAccount.FieldCaption("E-Pay Export File Path"),
              BankAccount.TableCaption,
              BankAccount."No.");
        BankAccount.TestField("Last E-Pay Export File Name");
        BankAccount.TestField("Bank Acc. Posting Group");
        BankAccount.TestField(Blocked, false);
        BankAccount."Last E-Pay Export File Name" := IncStr(BankAccount."Last E-Pay Export File Name");
        FileName := RBMgt.ServerTempFileName('');

        if BankAccount."Last ACH File ID Modifier" = '' then
            BankAccount."Last ACH File ID Modifier" := 'A'
        else begin
            i := 1;
            while (i < ArrayLen(ModifierValues)) and
                  (BankAccount."Last ACH File ID Modifier" <> ModifierValues[i])
            do
                i := i + 1;
            if i = ArrayLen(ModifierValues) then
                i := 1
            else
                i := i + 1;
            BankAccount."Last ACH File ID Modifier" := ModifierValues[i];
        end;
        BankAccount.Modify();

        if Exists(FileName) then
            Error(FileAlreadyExistsErr,
              FileName,
              BankAccount.FieldCaption("Last E-Pay Export File Name"),
              BankAccount.TableCaption,
              BankAccount."No.");
        ExportFile.TextMode(true);
        ExportFile.WriteMode(true);
        ExportFile.Create(FileName);

        FileIsInProcess := true;
        FileDate := Today;
        FileTime := Time;
        NoOfRec := 0;
        FileHashTotal := 0;
        TotalFileDebit := 0;
        TotalFileCredit := 0;
        FileEntryAddendaCount := 0;
        BatchCount := 0;
        BlockingFactor := 10;
        RecordLength := 94;
        BatchNo := 0;

        FileHeaderRec := '';

        AddNumToPrnString(FileHeaderRec, 1, 1, 1);
        AddNumToPrnString(FileHeaderRec, 1, 2, 2);
        AddToPrnString(FileHeaderRec, BankAccount."Transit No.", 4, 10, Justification::Right, ' ');
        AddFedIDToPrnString(FileHeaderRec, CompanyInformation."Federal ID No.", 14, 10);
        AddToPrnString(FileHeaderRec, Format(FileDate, 0, '<Year,2><Month,2><Day,2>'), 24, 6, Justification::Right, '0');
        AddToPrnString(FileHeaderRec, Format(FileTime, 0, '<Hours24,2><Minutes,2>'), 30, 4, Justification::Right, '0');
        AddToPrnString(FileHeaderRec, BankAccount."Last ACH File ID Modifier", 34, 1, Justification::Right, '0');
        AddNumToPrnString(FileHeaderRec, RecordLength, 35, 3);
        AddNumToPrnString(FileHeaderRec, BlockingFactor, 38, 2);
        AddNumToPrnString(FileHeaderRec, 1, 40, 1);
        AddToPrnString(FileHeaderRec, BankAccount.Name, 41, 23, Justification::Left, ' ');
        AddToPrnString(FileHeaderRec, CompanyInformation.Name, 64, 23, Justification::Left, ' ');
        AddToPrnString(FileHeaderRec, ReferenceCode, 87, 8, Justification::Left, ' ');
        ExportPrnString(FileHeaderRec);
    end;

    procedure StartExportBatch(GenJournalLine: Record "Gen. Journal Line"; ServiceClassCode: Code[10]; SettleDate: Date)
    var
        GLSetup: Record "General Ledger Setup";
        EFTRecipientBankAccountMgt: codeunit "EFT Recipient Bank Account Mgt";
        BatchHeaderRec: Text[250];
    begin
        if not FileIsInProcess then
            Error(ExportFileNotStartedErr);
        if BatchIsInProcess then
            Error(ExportFileNotCompletedErr);

        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor then begin
            DestinationAcctType := 'V';
            DestinationAcctNo := GenJournalLine."Account No.";
        end else
            if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then begin
                DestinationAcctType := 'C';
                DestinationAcctNo := GenJournalLine."Account No.";
            end else
                if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Vendor then begin
                    DestinationAcctType := 'V';
                    DestinationAcctNo := GenJournalLine."Bal. Account No.";
                end else
                    if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Customer then begin
                        DestinationAcctType := 'C';
                        DestinationAcctNo := GenJournalLine."Bal. Account No.";
                    end else
                        Error(InvalidPaymentSpecErr,
                          GenJournalLine.FieldCaption("Account Type"), GenJournalLine.FieldCaption("Bal. Account Type"), Vendor.TableCaption(), Customer.TableCaption());

        if DestinationAcctType = 'V' then begin
            ExportPaymentsACH.CheckVendorTransitNum(GenJournalLine, DestinationAcctNo, Vendor, VendorBankAcct, true);
            DestinationName := Vendor.Name;
            DestinationFederalIDNo := Vendor."Federal ID No.";
            DestinationAddress := Vendor.Address + ' ' + Vendor."Address 2";
            DestinationCity := Vendor.City;
            DestinationCountryCode := Vendor."Country/Region Code";
            DestinationCounty := Vendor.County;
            DestinationPostCode := Vendor."Post Code";
            VendorBankAcct.TestField("Bank Account No.");
            DestinationBankName := VendorBankAcct.Name;
            DestinationBankTransitNo := VendorBankAcct."Transit No.";
            DestinationBankAcctNo := VendorBankAcct."Bank Account No.";
            DestinationBankCurrencyCode := VendorBankAcct."Currency Code";
            DestinationBankCountryCode := VendorBankAcct."Country/Region Code";
        end else
            if DestinationAcctType = 'C' then begin
                Customer.Get(DestinationAcctNo);
                if Customer."Privacy Blocked" then
                    Error(PrivacyBlockedErr, GenJournalLine."Account Type");
                if Customer.Blocked in [Customer.Blocked::All] then
                    Error(CustomerBlockedErr, GenJournalLine."Account Type", Customer.Blocked);
                DestinationName := Customer.Name;
                DestinationFederalIDNo := ' ';
                DestinationAddress := Customer.Address + ' ' + Customer."Address 2";
                DestinationCity := Customer.City;
                DestinationCountryCode := Customer."Country/Region Code";
                DestinationCounty := Customer.County;
                DestinationPostCode := Customer."Post Code";

                EFTRecipientBankAccountMgt.GetRecipientCustomerBankAccount(CustBankAcct, GenJournalLine, Customer."No.");

                if not ExportPaymentsACH.CheckDigit(CustBankAcct."Transit No.") then
                    CustBankAcct.FieldError("Transit No.", StrSubstNo(CustTransitNumNotValidErr, CustBankAcct."Transit No.", Customer."No."));
                CustBankAcct.TestField("Bank Account No.");
                DestinationBankName := CustBankAcct.Name;
                DestinationBankTransitNo := CustBankAcct."Transit No.";
                DestinationBankAcctNo := CustBankAcct."Bank Account No.";
                DestinationBankCurrencyCode := CustBankAcct."Currency Code";
                DestinationBankCountryCode := CustBankAcct."Country/Region Code";
            end;

        BatchIsInProcess := true;
        BatchNo := BatchNo + 1;
        BatchHashTotal := 0;
        TotalBatchDebit := 0;
        TotalBatchCredit := 0;
        EntryAddendaCount := 0;
        TraceNo := 0;
        BatchHeaderRec := '';

        AddNumToPrnString(BatchHeaderRec, 5, 1, 1);
        AddToPrnString(BatchHeaderRec, ServiceClassCode, 2, 3, Justification::Right, '0');
        AddToPrnString(BatchHeaderRec, ' ', 5, 16, Justification::Left, ' ');
        AddToPrnString(BatchHeaderRec, Format(GenJournalLine."Foreign Exchange Indicator"), 21, 2, Justification::Left, ' ');
        AddToPrnString(BatchHeaderRec, Format(GenJournalLine."Foreign Exchange Ref.Indicator"), 23, 1, Justification::Left, ' ');
        AddToPrnString(BatchHeaderRec, GenJournalLine."Foreign Exchange Reference", 24, 15, Justification::Left, ' ');
        AddToPrnString(BatchHeaderRec, DestinationCountryCode, 39, 2, Justification::Left, ' ');
        AddFedIDToPrnString(BatchHeaderRec, CompanyInformation."Federal ID No.", 41, 10);
        AddToPrnString(BatchHeaderRec, 'IAT', 51, 3, Justification::Left, ' ');
        AddToPrnString(BatchHeaderRec, GenJournalLine."Source Code", 54, 10, Justification::Left, ' ');
        if BankAccount."Currency Code" = '' then begin
            GLSetup.Get();
            AddToPrnString(BatchHeaderRec, GLSetup."LCY Code", 64, 3, Justification::Left, ' ');
        end else
            AddToPrnString(BatchHeaderRec, BankAccount."Currency Code", 64, 3, Justification::Left, ' ');

        if DestinationBankCurrencyCode = '' then begin
            GLSetup.Get();
            AddToPrnString(BatchHeaderRec, GLSetup."LCY Code", 67, 3, Justification::Left, ' ');
        end else
            AddToPrnString(BatchHeaderRec, DestinationBankCurrencyCode, 67, 3, Justification::Left, ' ');

        AddToPrnString(BatchHeaderRec, Format(SettleDate, 0, '<Year><Month,2><Day,2>'), 70, 6, Justification::Left, ' ');
        AddToPrnString(BatchHeaderRec, ' ', 76, 3, Justification::Left, ' ');
        AddNumToPrnString(BatchHeaderRec, 1, 79, 1);
        AddToPrnString(BatchHeaderRec, BankAccount."Transit No.", 80, 8, Justification::Left, ' ');
        AddNumToPrnString(BatchHeaderRec, BatchNo, 88, 7);
        ExportPrnString(BatchHeaderRec);
    end;

    procedure ExportElectronicPayment(GenJnlLine: Record "Gen. Journal Line"; PaymentAmount: Decimal): Code[30]
    var
        TransitNo: Text[20];
        DetailRec: Text[250];
        IATEntryTraceNo: Text[250];
        EntryDetailSeqNo: Text[7];
        FirstAddendaRec: Text[250];
        SecondAddendaRec: Text[250];
        ThirdAddendaRec: Text[250];
        FourthAddendaRec: Text[250];
        FifthAddendaRec: Text[250];
        SixthAddendaRec: Text[250];
        SeventhAddendaRec: Text[250];
        DemandCredit: Boolean;
    begin
        if not FileIsInProcess then
            Error(ExportDetailsFileNotStartedErr);
        if not BatchIsInProcess then
            Error(ExportDetailsFileNotCompletedErr);

        if PaymentAmount = 0 then
            exit('');
        DemandCredit := (PaymentAmount < 0);
        PaymentAmount := Abs(PaymentAmount);

        TraceNo := TraceNo + 1;

        ClearWorkingVars(DetailRec, IATEntryTraceNo, EntryDetailSeqNo, FirstAddendaRec, SecondAddendaRec, ThirdAddendaRec, FourthAddendaRec,
          FifthAddendaRec, SixthAddendaRec, SeventhAddendaRec, TransitNo);

        AddNumToPrnString(DetailRec, 6, 1, 1);
        if DemandCredit then
            AddNumToPrnString(DetailRec, 22, 2, 2)
        else
            AddNumToPrnString(DetailRec, 27, 2, 2);
        AddToPrnString(DetailRec, DestinationBankTransitNo, 4, 8, Justification::Right, ' ');
        AddToPrnString(DetailRec, CopyStr(Format(DestinationBankTransitNo), 9, 1), 12, 1, Justification::Right, ' ');
        AddNumToPrnString(DetailRec, 7, 13, 4);
        AddToPrnString(DetailRec, ' ', 17, 13, Justification::Left, ' ');
        AddAmtToPrnString(DetailRec, PaymentAmount, 30, 10);
        AddToPrnString(DetailRec, DelChr(DestinationBankAcctNo, '=', ' '), 40, 35, Justification::Left, ' ');
        AddToPrnString(DetailRec, ' ', 75, 2, Justification::Left, ' ');
        AddToPrnString(DetailRec, Format(GenJnlLine."Gateway Operator OFAC Scr.Inc"), 77, 1, Justification::Left, ' ');
        AddToPrnString(DetailRec, Format(GenJnlLine."Secondary OFAC Scr.Indicator"), 78, 1, Justification::Left, ' ');
        AddNumToPrnString(DetailRec, 1, 79, 1);
        IATEntryTraceNo := GenerateTraceNoCode(TraceNo);
        AddToPrnString(DetailRec, IATEntryTraceNo, 80, 15, Justification::Left, ' ');

        ExportPrnString(DetailRec);
        EntryAddendaCount := EntryAddendaCount + 1;
        if DemandCredit then
            TotalBatchCredit := TotalBatchCredit + PaymentAmount
        else
            TotalBatchDebit := TotalBatchDebit + PaymentAmount;
        IncrementHashTotal(BatchHashTotal, MakeHash(CopyStr(TransitNo, 1, 8)));

        AddNumToPrnString(FirstAddendaRec, 7, 1, 1);
        AddNumToPrnString(FirstAddendaRec, 10, 2, 2);
        AddToPrnString(FirstAddendaRec, Format(GenJnlLine."Transaction Type Code"), 4, 3, Justification::Left, ' ');
        AddAmtToPrnString(FirstAddendaRec, PaymentAmount, 7, 18);
        AddToPrnString(FirstAddendaRec, ' ', 25, 22, Justification::Left, ' ');
        AddToPrnString(FirstAddendaRec, DestinationName, 47, 35, Justification::Left, ' ');
        AddToPrnString(FirstAddendaRec, ' ', 82, 6, Justification::Left, ' ');
        EntryDetailSeqNo := CopyStr(IATEntryTraceNo, StrLen(IATEntryTraceNo) - 6, StrLen(IATEntryTraceNo));
        AddToPrnString(FirstAddendaRec, EntryDetailSeqNo, 88, 7, Justification::Right, '0');

        ExportPrnString(FirstAddendaRec);
        EntryAddendaCount := EntryAddendaCount + 1;

        AddNumToPrnString(SecondAddendaRec, 7, 1, 1);
        AddNumToPrnString(SecondAddendaRec, 11, 2, 2);
        AddToPrnString(SecondAddendaRec, CompanyInformation.Name, 4, 35, Justification::Left, ' ');
        AddToPrnString(SecondAddendaRec,
          CopyStr(CompanyInformation.Address + ' ' + CompanyInformation."Address 2", 1, MaxStrLen(SecondAddendaRec)),
          39, 35, Justification::Left, ' ');
        AddToPrnString(SecondAddendaRec, ' ', 74, 14, Justification::Left, ' ');
        AddToPrnString(SecondAddendaRec, EntryDetailSeqNo, 88, 7, Justification::Right, '0');

        ExportPrnString(SecondAddendaRec);
        EntryAddendaCount := EntryAddendaCount + 1;

        AddNumToPrnString(ThirdAddendaRec, 7, 1, 1);
        AddNumToPrnString(ThirdAddendaRec, 12, 2, 2);
        AddToPrnString(ThirdAddendaRec, CompanyInformation.City + '*' + CompanyInformation.County + '\'
          , 4, 35, Justification::Left, ' ');
        AddToPrnString(ThirdAddendaRec, CompanyInformation."Country/Region Code" + '*' + CompanyInformation."Post Code" + '\'
          , 39, 35, Justification::Left, ' ');
        AddToPrnString(ThirdAddendaRec, ' ', 74, 14, Justification::Left, ' ');
        AddToPrnString(ThirdAddendaRec, EntryDetailSeqNo, 88, 7, Justification::Right, '0');

        ExportPrnString(ThirdAddendaRec);
        EntryAddendaCount := EntryAddendaCount + 1;

        AddNumToPrnString(FourthAddendaRec, 7, 1, 1);
        AddNumToPrnString(FourthAddendaRec, 13, 2, 2);
        AddToPrnString(FourthAddendaRec, BankAccount.Name, 4, 35, Justification::Left, ' ');
        AddToPrnString(FourthAddendaRec, Format(GenJnlLine."Origin. DFI ID Qualifier"), 39, 2, Justification::Left, ' ');
        AddToPrnString(FourthAddendaRec, PadStr(BankAccount."Transit No.", 8), 41, 34, Justification::Left, ' ');
        AddToPrnString(FourthAddendaRec, BankAccount."Country/Region Code", 75, 3, Justification::Left, ' ');
        AddToPrnString(FourthAddendaRec, ' ', 78, 10, Justification::Left, ' ');
        AddToPrnString(FourthAddendaRec, EntryDetailSeqNo, 88, 7, Justification::Right, '0');

        ExportPrnString(FourthAddendaRec);
        EntryAddendaCount := EntryAddendaCount + 1;

        AddNumToPrnString(FifthAddendaRec, 7, 1, 1);
        AddNumToPrnString(FifthAddendaRec, 14, 2, 2);
        AddToPrnString(FifthAddendaRec, DestinationBankName, 4, 35, Justification::Left, ' ');
        AddToPrnString(FifthAddendaRec, Format(GenJnlLine."Receiv. DFI ID Qualifier"), 39, 2, Justification::Left, ' ');
        AddToPrnString(FifthAddendaRec, DestinationBankTransitNo, 41, 34, Justification::Left, ' ');
        AddToPrnString(FifthAddendaRec, DestinationBankCountryCode, 75, 3, Justification::Left, ' ');
        AddToPrnString(FifthAddendaRec, ' ', 78, 10, Justification::Left, ' ');
        AddToPrnString(FifthAddendaRec, EntryDetailSeqNo, 88, 7, Justification::Right, '0');

        ExportPrnString(FifthAddendaRec);
        EntryAddendaCount := EntryAddendaCount + 1;

        AddNumToPrnString(SixthAddendaRec, 7, 1, 1);
        AddNumToPrnString(SixthAddendaRec, 15, 2, 2);
        AddToPrnString(SixthAddendaRec, DestinationFederalIDNo, 4, 15, Justification::Left, ' ');
        AddToPrnString(SixthAddendaRec, DestinationAddress, 19, 35, Justification::Left, ' ');
        AddToPrnString(SixthAddendaRec, ' ', 54, 34, Justification::Left, ' ');
        AddToPrnString(SixthAddendaRec, EntryDetailSeqNo, 88, 7, Justification::Right, '0');

        ExportPrnString(SixthAddendaRec);
        EntryAddendaCount := EntryAddendaCount + 1;

        AddNumToPrnString(SeventhAddendaRec, 7, 1, 1);
        AddNumToPrnString(SeventhAddendaRec, 16, 2, 2);
        AddToPrnString(SeventhAddendaRec, DestinationCity + '*' + DestinationCounty + '\',
          4, 35, Justification::Left, ' ');
        AddToPrnString(SeventhAddendaRec, DestinationCountryCode + '*' + DestinationPostCode + '\',
          39, 35, Justification::Left, ' ');
        AddToPrnString(SeventhAddendaRec, ' ', 74, 14, Justification::Left, ' ');
        AddToPrnString(SeventhAddendaRec, EntryDetailSeqNo, 88, 7, Justification::Right, '0');

        ExportPrnString(SeventhAddendaRec);
        EntryAddendaCount := EntryAddendaCount + 1;

        exit(GenerateFullTraceNoCode(TraceNo));
    end;

    procedure EndExportBatch(ServiceClassCode: Code[10])
    var
        BatchControlRec: Text[250];
    begin
        if not FileIsInProcess then
            Error(ExportBatchFileNotStartedErr);
        if not BatchIsInProcess then
            Error(ExportBatchNotStartedErr);

        BatchIsInProcess := false;
        BatchControlRec := '';

        AddNumToPrnString(BatchControlRec, 8, 1, 1);
        AddToPrnString(BatchControlRec, ServiceClassCode, 2, 3, Justification::Right, '0');
        AddNumToPrnString(BatchControlRec, EntryAddendaCount, 5, 6);
        AddToPrnString(BatchControlRec, Format(BatchHashTotal, 0, 2), 11, 10, Justification::Right, '0');
        AddAmtToPrnString(BatchControlRec, TotalBatchDebit, 21, 12);
        AddAmtToPrnString(BatchControlRec, TotalBatchCredit, 33, 12);
        AddFedIDToPrnString(BatchControlRec, CompanyInformation."Federal ID No.", 45, 10);
        AddToPrnString(BatchControlRec, ' ', 55, 19, Justification::Right, ' ');
        AddToPrnString(BatchControlRec, ' ', 74, 6, Justification::Right, ' ');
        AddToPrnString(BatchControlRec, BankAccount."Transit No.", 80, 8, Justification::Left, ' ');
        AddNumToPrnString(BatchControlRec, BatchNo, 88, 7);
        ExportPrnString(BatchControlRec);

        BatchCount := BatchCount + 1;
        IncrementHashTotal(FileHashTotal, BatchHashTotal);
        TotalFileDebit := TotalFileDebit + TotalBatchDebit;
        TotalFileCredit := TotalFileCredit + TotalBatchCredit;
        FileEntryAddendaCount := FileEntryAddendaCount + EntryAddendaCount;
    end;

    procedure EndExportFile(): Boolean
    var
        FileControlRec: Text[250];
    begin
        if not FileIsInProcess then
            Error(ExportFileNotEndedFileNotStartedErr);
        if BatchIsInProcess then
            Error(ExportFileNotEndedFileNotEndedErr);

        FileIsInProcess := false;
        FileControlRec := '';
        BlockCount := (NoOfRec + 1) div BlockingFactor;
        if (NoOfRec + 1) mod BlockingFactor <> 0 then
            BlockCount := BlockCount + 1;

        AddNumToPrnString(FileControlRec, 9, 1, 1);
        AddNumToPrnString(FileControlRec, BatchCount, 2, 6);
        AddNumToPrnString(FileControlRec, BlockCount, 8, 6);
        AddNumToPrnString(FileControlRec, FileEntryAddendaCount, 14, 8);
        AddToPrnString(FileControlRec, Format(FileHashTotal, 0, 2), 22, 10, Justification::Right, '0');
        AddAmtToPrnString(FileControlRec, TotalFileDebit, 32, 12);
        AddAmtToPrnString(FileControlRec, TotalFileCredit, 44, 12);
        AddToPrnString(FileControlRec, ' ', 56, 39, Justification::Right, ' ');
        ExportPrnString(FileControlRec);

        while NoOfRec mod BlockingFactor <> 0 do begin
            FileControlRec := PadStr('', RecordLength, '9');
            ExportPrnString(FileControlRec);
        end;
        ExportFile.Close();

        ClientFile := BankAccount."E-Pay Export File Path" + BankAccount."Last E-Pay Export File Name";
        if not Download(FileName, '', '', '', ClientFile) then begin
            Erase(FileName);
            exit(false);
        end;
        Erase(FileName);

        exit(true);
    end;

    local procedure GenerateFullTraceNoCode(TraceNo: Integer): Code[30]
    var
        TraceCode: Text[250];
    begin
        TraceCode := '';
        AddToPrnString(TraceCode, Format(FileDate, 0, '<Year,2><Month,2><Day,2>'), 1, 6, Justification::Left, ' ');
        AddToPrnString(TraceCode, BankAccount."Last ACH File ID Modifier", 7, 1, Justification::Right, '0');
        AddNumToPrnString(TraceCode, BatchNo, 8, 7);
        AddToPrnString(TraceCode, GenerateTraceNoCode(TraceNo), 15, 15, Justification::Left, ' ');
        exit(TraceCode);
    end;

    local procedure GenerateTraceNoCode(TraceNo: Integer): Code[15]
    var
        TraceCode: Text[250];
    begin
        TraceCode := '';
        AddToPrnString(TraceCode, BankAccount."Transit No.", 1, 8, Justification::Left, ' ');
        AddNumToPrnString(TraceCode, TraceNo, 9, 7);
        exit(TraceCode);
    end;

    local procedure AddNumToPrnString(var PrnString: Text[250]; Number: Integer; StartPos: Integer; Length: Integer)
    var
        TmpString: Text[250];
    begin
        TmpString := DelChr(Format(Number), '=', '.,-');
        AddToPrnString(PrnString, TmpString, StartPos, Length, Justification::Right, '0');
    end;

    local procedure AddAmtToPrnString(var PrnString: Text[250]; Amount: Decimal; StartPos: Integer; Length: Integer)
    var
        TmpString: Text[250];
        I: Integer;
    begin
        TmpString := Format(Amount);
        I := StrPos(TmpString, '.');
        case true of
            I = 0:
                TmpString := TmpString + '.00';
            I = StrLen(TmpString) - 1:
                TmpString := TmpString + '0';
        end;
        TmpString := DelChr(TmpString, '=', '.,-');
        AddToPrnString(PrnString, TmpString, StartPos, Length, Justification::Right, '0');
    end;

    procedure AddFedIDToPrnString(var PrnString: Text[250]; FedID: Text[30]; StartPos: Integer; Length: Integer)
    begin
        AddToPrnString(PrnString, '1' + DelChr(FedID, '=', ' .,-'), StartPos, Length, Justification::Left, ' ');
    end;

    local procedure AddToPrnString(var PrnString: Text[251]; SubString: Text[250]; StartPos: Integer; Length: Integer; Justification: Option Left,Right; Filler: Text[1])
    var
        I: Integer;
        SubStrLen: Integer;
    begin
        SubString := UpperCase(DelChr(SubString, '<>', ' '));
        SubStrLen := StrLen(SubString);

        if SubStrLen > Length then begin
            SubString := CopyStr(SubString, 1, Length);
            SubStrLen := Length;
        end;

        if Justification = Justification::Right then
            for I := 1 to (Length - SubStrLen) do
                SubString := Filler + SubString
        else
            for I := SubStrLen + 1 to Length do
                SubString := SubString + Filler;

        if StrLen(PrnString) >= StartPos then
            if StartPos > 1 then
                PrnString := CopyStr(PrnString, 1, StartPos - 1) + SubString + CopyStr(PrnString, StartPos)
            else
                PrnString := SubString + PrnString
        else begin
            for I := StrLen(PrnString) + 1 to StartPos - 1 do
                PrnString := PrnString + ' ';
            PrnString := PrnString + SubString;
        end;
    end;

    local procedure ExportPrnString(var PrnString: Text[250])
    begin
        PrnString := PadStr(PrnString, RecordLength, ' ');
        ExportFile.Write(PrnString);
        NoOfRec := NoOfRec + 1;
        PrnString := '';
    end;

    local procedure IncrementHashTotal(var HashTotal: Decimal; HashIncrement: Decimal)
    var
        SubTotal: Decimal;
    begin
        SubTotal := HashTotal + HashIncrement;
        if SubTotal < 10000000000.0 then
            HashTotal := SubTotal
        else
            HashTotal := SubTotal - 10000000000.0;
    end;

    local procedure MakeHash(InputString: Text[30]): Decimal
    var
        HashAmt: Decimal;
    begin
        InputString := DelChr(InputString, '=', '.,- ');
        if Evaluate(HashAmt, InputString) then
            exit(HashAmt);

        exit(0);
    end;

    local procedure BuildIDModifier()
    begin
        ModifierValues[1] := 'A';
        ModifierValues[2] := 'B';
        ModifierValues[3] := 'C';
        ModifierValues[4] := 'D';
        ModifierValues[5] := 'E';
        ModifierValues[6] := 'F';
        ModifierValues[7] := 'G';
        ModifierValues[8] := 'H';
        ModifierValues[9] := 'I';
        ModifierValues[10] := 'J';
        ModifierValues[11] := 'K';
        ModifierValues[12] := 'L';
        ModifierValues[13] := 'M';
        ModifierValues[14] := 'N';
        ModifierValues[15] := 'O';
        ModifierValues[16] := 'P';
        ModifierValues[17] := 'Q';
        ModifierValues[18] := 'R';
        ModifierValues[19] := 'S';
        ModifierValues[20] := 'T';
        ModifierValues[21] := 'U';
        ModifierValues[22] := 'V';
        ModifierValues[23] := 'W';
        ModifierValues[24] := 'X';
        ModifierValues[25] := 'Y';
        ModifierValues[26] := 'Z';
    end;

    local procedure ClearWorkingVars(var DtlRec: Text[250]; var IATEntTraceNo: Text[250]; var EntryDtlSeqNo: Text[7]; var FirstAddRec: Text[250]; var SecondAddRec: Text[250]; var ThirdAddRec: Text[250]; var FourthAddRec: Text[250]; var FifthAddRec: Text[250]; var SixthAddRec: Text[250]; var SeventhAddRec: Text[250]; var TransitNo: Text[20])
    begin
        DtlRec := '';
        IATEntTraceNo := '';
        EntryDtlSeqNo := '';
        FirstAddRec := '';
        SecondAddRec := '';
        ThirdAddRec := '';
        FourthAddRec := '';
        FifthAddRec := '';
        SixthAddRec := '';
        SeventhAddRec := '';
        TransitNo := '';
    end;
}

