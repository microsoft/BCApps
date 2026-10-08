// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

codeunit 10096 "Export EFT (Cecoban)"
{

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        FileManagement: Codeunit "File Management";
        EFTValues: Codeunit "EFT Values";
        FileHashTotal: Decimal;
        BatchHashTotal: Decimal;
        FileName: Text;
        FileDate: Date;
        PayeeAcctType: Integer;
        BatchDay: Integer;
        AlreadyExistsErr: Label 'The file already exists. Check the "Last E-Pay Export File Name" field in the bank account.';
        ReferErr: Label 'Either Account type or balance account type must refer to either a vendor or a customer for an electronic payment.';
        IsBlockedErr: Label 'Account type is blocked for processing.';
        PrivacyBlockedErr: Label 'Account type is blocked for privacy.';
        TransitNoErr: Label 'is not valid. Bank Account number must be either the 18 character CLABE format for checking, or 16 characters for Debit Card';
        OpCode: Integer;

    [Scope('OnPrem')]
    procedure StartExportFile(BankAccountNo: Code[20])
    begin
        CompanyInformation.Get();
        CompanyInformation.TestField("Federal ID No.");

        BankAccount.LockTable();
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Export Format", BankAccount."Export Format"::MX);
        BankAccount.TestField("Transit No.");
        BankAccount.TestField("Bank Acc. Posting Group");
        BankAccount.TestField(Blocked, false);

        FileName := '';
        BankAccount."Last E-Pay Export File Name" := IncStr(BankAccount."Last E-Pay Export File Name");
        FileName := FileManagement.ServerTempFileName('');
        if not EFTValues.IsSetFileCreationNumber() then
            BankAccount."Last E-Pay File Creation No." := BankAccount."Last E-Pay File Creation No." + 1;
        BankAccount.Modify();

        if Exists(FileName) then
            Error(AlreadyExistsErr);

        FileDate := Today;
        FileHashTotal := 0;
        EFTValues.SetFileHashTotal(FileHashTotal);
        EFTValues.SetTotalFileDebit(0);
        EFTValues.SetTotalFileCredit(0);
        EFTValues.SetFileEntryAddendaCount(0);
        EFTValues.SetBatchCount(0);
        EFTValues.SetBatchNo(0);
        EFTValues.SetFileCreationNumber(BankAccount."Last E-Pay File Creation No.");
    end;

    [Scope('OnPrem')]
    procedure StartExportBatch(SettleDate: Date; DataExchEntryNo: Integer)
    var
        ACHCecobanHeader: Record "ACH Cecoban Header";
    begin
        EFTValues.SetBatchNo(EFTValues.GetBatchNo() + 1);
        BatchHashTotal := 0;
        EFTValues.SetBatchHashTotal(BatchHashTotal);
        EFTValues.SetTotalBatchDebit(0);
        EFTValues.SetTotalBatchCredit(0);
        EFTValues.SetEntryAddendaCount(0);
        EFTValues.SetTraceNo(0);
        EFTValues.SetSequenceNo(EFTValues.GetSequenceNo() + 1);

        Evaluate(BatchDay, Format(Today, 2, '<Day>'));

        // Cecoban layout
        ACHCecobanHeader.Get(DataExchEntryNo);
        ACHCecobanHeader."Record Type" := '1';
        ACHCecobanHeader."Sequence No" := EFTValues.GetSequenceNo();
        ACHCecobanHeader."Operation Code" := 0;
        ACHCecobanHeader."Bank Account No" := BankAccount."Bank Account No.";
        ACHCecobanHeader."Export Type" := 'E';
        ACHCecobanHeader.Service := 2;
        ACHCecobanHeader."Batch Day" := BatchDay;
        ACHCecobanHeader."Batch No" := EFTValues.GetBatchNo();
        ACHCecobanHeader."Settlement Date" := SettleDate;
        ACHCecobanHeader."Rejection Code" := 0;
        ACHCecobanHeader.System := 2;
        ACHCecobanHeader."Future Cecoban Use" := ' ';
        ACHCecobanHeader."Future Bank Use" := ' ';
        ACHCecobanHeader."Currency Code" := '01';
        OnStartExportBatchOnBeforeACHCecobanHeaderModify(ACHCecobanHeader);
        ACHCecobanHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure ExportElectronicPayment(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; PaymentAmount: Decimal; SettleDate: Date; DataExchEntryNo: Integer; DataExchLineDefCode: Code[20]): Code[30]
    var
        ACHCecobanDetail: Record "ACH Cecoban Detail";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        ExportEFTACH: Codeunit "Export EFT (ACH)";
        EFTRecipientBankAccountMgt: Codeunit "EFT Recipient Bank Account Mgt";
        AcctType: Text[1];
        AcctNo: Code[20];
        AcctName: Text[40];
        BankAcctNo: Text[30];
        TransitNo: Text[20];
        RFCNo: Text[20];
        DemandCredit: Boolean;
    begin
        // NOTE:  If PaymentAmount is Positive, then we are Receiving money.
        // If PaymentAmount is Negative, then we are Sending money.
        if PaymentAmount = 0 then
            exit('');
        DemandCredit := (PaymentAmount < 0);
        PaymentAmount := Abs(PaymentAmount);
        OpCode := 30;

        if TempEFTExportWorkset."Account Type" = TempEFTExportWorkset."Account Type"::Vendor then begin
            AcctType := 'V';
            AcctNo := TempEFTExportWorkset."Account No.";
        end else
            if TempEFTExportWorkset."Account Type" = TempEFTExportWorkset."Account Type"::Customer then begin
                AcctType := 'C';
                AcctNo := TempEFTExportWorkset."Account No.";
            end else
                if TempEFTExportWorkset."Bal. Account Type" = TempEFTExportWorkset."Bal. Account Type"::Vendor then begin
                    AcctType := 'V';
                    AcctNo := TempEFTExportWorkset."Bal. Account No.";
                end else
                    if TempEFTExportWorkset."Bal. Account Type" = TempEFTExportWorkset."Bal. Account Type"::Customer then begin
                        AcctType := 'C';
                        AcctNo := TempEFTExportWorkset."Bal. Account No.";
                    end else
                        Error(ReferErr);

        if AcctType = 'V' then begin
            Vendor.Get(AcctNo);
            Vendor.TestField(Blocked, Vendor.Blocked::" ");
            Vendor.TestField("Privacy Blocked", false);
            AcctName := CopyStr(Vendor.Name, 1, MaxStrLen(AcctName));
            RFCNo := Vendor."VAT Registration No.";

            EFTRecipientBankAccountMgt.GetRecipientVendorBankAccount(VendorBankAccount, TempEFTExportWorkset, AcctNo);

            VendorBankAccount.TestField("Bank Account No.");
            TransitNo := VendorBankAccount."Transit No.";
            BankAcctNo := VendorBankAccount."Bank Account No.";
        end else
            if AcctType = 'C' then begin
                Customer.Get(AcctNo);
                if Customer."Privacy Blocked" then
                    Error(PrivacyBlockedErr);
                if Customer.Blocked in [Customer.Blocked::All] then
                    Error(IsBlockedErr);
                AcctName := CopyStr(Customer.Name, 1, MaxStrLen(AcctName));
                RFCNo := Customer."VAT Registration No.";

                EFTRecipientBankAccountMgt.GetRecipientCustomerBankAccount(CustomerBankAccount, TempEFTExportWorkset, AcctNo);

                if not PayeeCheckDigit(CustomerBankAccount."Transit No.") then
                    CustomerBankAccount.FieldError("Transit No.", TransitNoErr);
                CustomerBankAccount.TestField("Bank Account No.");
                TransitNo := CustomerBankAccount."Transit No.";
                BankAcctNo := CustomerBankAccount."Bank Account No.";
            end;

        EFTValues.SetSequenceNo(EFTValues.GetSequenceNo() + 1);
        EFTValues.SetTraceNo(EFTValues.GetTraceNo() + 1);
        EFTValues.SetEntryAddendaCount(EFTValues.GetEntryAddendaCount() + 1);

        if DemandCredit then
            EFTValues.SetTotalBatchCredit(EFTValues.GetTotalBatchCredit() + PaymentAmount)
        else
            EFTValues.SetTotalBatchDebit(EFTValues.GetTotalBatchDebit() + PaymentAmount);

        IncrementHashTotal(BatchHashTotal, MakeHash(CopyStr(TransitNo, 1, 8)));
        EFTValues.SetBatchHashTotal(BatchHashTotal);

        BankAccount.Get(TempEFTExportWorkset."Bank Account No.");
        // Cecoban Detail rec
        ACHCecobanDetail.Get(DataExchEntryNo, DataExchLineDefCode);
        ACHCecobanDetail."Record Type" := '02';
        ACHCecobanDetail."Sequence Number" := EFTValues.GetSequenceNo();
        ACHCecobanDetail."Operation Code" := OpCode;
        ACHCecobanDetail."Currency Code" := '01';
        ACHCecobanDetail."Transfer Date" := Today;
        ACHCecobanDetail.ODFI := BankAccount."Bank Account No.";
        ACHCecobanDetail.RDFI := BankAcctNo;
        ACHCecobanDetail."Operation Fee" := PaymentAmount;
        ACHCecobanDetail."Future Use" := '';
        ACHCecobanDetail."Operation Code" := OpCode;
        ACHCecobanDetail."Date Entered" := SettleDate;
        ACHCecobanDetail."Originator Account Type" := 1;
        ACHCecobanDetail."Originator Account no." := BankAccount."Transit No.";
        ACHCecobanDetail."Originator Account Name" := AcctName;
        ACHCecobanDetail."Originator RFC/CURP" := ' ';
        ACHCecobanDetail."Payee Account Type" := PayeeAcctType;
        ACHCecobanDetail."Payee Account No." := TransitNo;
        ACHCecobanDetail."Payee Account Name" := AcctName;
        ACHCecobanDetail."Payee RFC/CURP" := RFCNo;
        ACHCecobanDetail."Transmitter Service Reference" := '';
        ACHCecobanDetail."Service Owner" := '';
        ACHCecobanDetail."Operation Tax Cost" := 0;
        ACHCecobanDetail."Originator Numeric Reference" := 0;
        ACHCecobanDetail."Originator Alpha Reference" := '';
        ACHCecobanDetail."Tracking Code" := ExportEFTACH.GenerateTraceNoCode(EFTValues.GetTraceNo(), BankAccount."Transit No.");
        ACHCecobanDetail."Return Reason" := 0;
        ACHCecobanDetail."Initial Presentation Date" := Today;
        ACHCecobanDetail."Document No." := TempEFTExportWorkset."Document No.";
        ACHCecobanDetail."External Document No." := TempEFTExportWorkset."External Document No.";
        ACHCecobanDetail."Applies-to Doc. No." := TempEFTExportWorkset."Applies-to Doc. No.";
        ACHCecobanDetail."Payment Reference" := TempEFTExportWorkset."Payment Reference";
        OnBeforeACHCecobanDetailModify(ACHCecobanDetail, TempEFTExportWorkset, BankAccount."No.");
        ACHCecobanDetail.Modify();

        exit(GenerateFullTraceNoCode(EFTValues.GetTraceNo()));
    end;

    [Scope('OnPrem')]
    procedure EndExportBatch(DataExchEntryNo: Integer)
    var
        ACHCecobanFooter: Record "ACH Cecoban Footer";
    begin
        EFTValues.SetSequenceNo(EFTValues.GetSequenceNo() + 1);

        // cecoban batch summary
        ACHCecobanFooter.Get(DataExchEntryNo);
        ACHCecobanFooter."Record Type" := '9';
        ACHCecobanFooter."Sequence Number" := EFTValues.GetSequenceNo();
        ACHCecobanFooter."Op Code" := OpCode;
        ACHCecobanFooter."Batch Number day of month" := BatchDay;
        ACHCecobanFooter."Batch Number sequence part" := EFTValues.GetBatchNo();
        ACHCecobanFooter."Operation Number" := EFTValues.GetSequenceNo();
        ACHCecobanFooter.TCO := EFTValues.GetBatchHashTotal();
        ACHCecobanFooter.Modify();

        EFTValues.SetBatchCount(EFTValues.GetBatchCount() + 1);
        IncrementHashTotal(FileHashTotal, EFTValues.GetBatchHashTotal());
        EFTValues.SetFileHashTotal(FileHashTotal);
        EFTValues.SetTotalFileDebit(EFTValues.GetTotalFileDebit() + EFTValues.GetTotalBatchDebit());
        EFTValues.SetTotalFileCredit(EFTValues.GetTotalFileCredit() + EFTValues.GetTotalBatchCredit());
        EFTValues.SetFileEntryAddendaCount(EFTValues.GetFileEntryAddendaCount() + EFTValues.GetEntryAddendaCount());
    end;

    internal procedure PopulateACHCecobanHeaderWithEFTExportWorkset(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; DataExchEntryNo: Integer)
    var
        ACHCecobanHeader: Record "ACH Cecoban Header";
    begin
        if not ACHCecobanHeader.Get(DataExchEntryNo) then
            exit;

        if ACHCecobanHeader."Settlement Date" = 0D then
            ACHCecobanHeader."Settlement Date" := TempEFTExportWorkset.UserSettleDate;

        if ACHCecobanHeader."Currency Code" = '' then
            ACHCecobanHeader."Currency Code" := TempEFTExportWorkset."Currency Code";

        ACHCecobanHeader.Modify();
    end;

    local procedure GenerateFullTraceNoCode(TraceNo: Integer): Code[30]
    var
        TraceCode: Text;
    begin
        TraceCode := '';
        TraceCode := Format(FileDate, 0, '<Year,2><Month,2><Day,2>') + BankAccount."Last ACH File ID Modifier" +
          Format(EFTValues.GetBatchNo()) + Format(TraceNo);
        exit(TraceCode);
    end;

    [Scope('OnPrem')]
    procedure PayeeCheckDigit(DigitString: Code[20]): Boolean
    begin
        if StrLen(DigitString) = 18 then begin
            PayeeAcctType := 1;
            exit(true);                                   // checking Account
        end;
        if StrLen(DigitString) = 16 then begin
            PayeeAcctType := 3;                                   // debit card
            exit(true);                                   // checking Account
        end;
        exit(false);
    end;

    local procedure IncrementHashTotal(var HashTotal: Decimal; HashIncrement: Decimal): Decimal
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHCecobanDetailModify(var ACHCecobanDetail: Record "ACH Cecoban Detail"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; BankAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnStartExportBatchOnBeforeACHCecobanHeaderModify(var ACHCecobanHeader: Record "ACH Cecoban Header")
    begin
    end;
}

