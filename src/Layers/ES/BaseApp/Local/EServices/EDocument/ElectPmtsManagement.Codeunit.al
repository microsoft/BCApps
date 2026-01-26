// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.IO;
using System.Utilities;

codeunit 10701 "Elect. Pmts Management"
{
    Permissions = TableData "Check Ledger Entry" = m;

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        FileManagement: Codeunit "File Management";
        FileHandle: File;
        LineValue: Text[72];
        Filename: Text[1024];
        ToFile: Text[1024];
        ToFolder: Text[1024];
        Text1100000: Label 'In order to use Electronic Payments, one of the Bank Accounts for the vendor must have the field %1 selected.';
        Text1100001: Label 'You must have exactly one %1 with %2 checked for %3 %4.';
        Text1100002: Label 'Some data from the Bank Account of Vendor %1 are missing.';
        Text1100003: Label 'Text Files (*.txt)|*.txt|All Files (*.*)|*.*';
        TransferType: Option " ",Domestic,International,Special;
        TotalDomesticRegs: Integer;
        TotalInternationalRegs: Integer;
        TotalSpecialRegs: Integer;

    [Scope('OnPrem')]
    procedure NewLine()
    begin
        LineValue := '';
    end;

    [Scope('OnPrem')]
    procedure PadLine(FillCharacter: Text[1])
    begin
        LineValue := PadStr(LineValue, 72, FillCharacter);
        SaveLineValue();
    end;

    [Scope('OnPrem')]
    procedure CreateFile(Path: Text[250])
    begin
        Filename := CopyStr(FileManagement.ServerTempFileName('txt'), 1, 1024);
        ToFile := Path;

        FileHandle.TextMode(true);
        FileHandle.Create(Filename);
    end;

    [Scope('OnPrem')]
    procedure SaveLineValue()
    begin
        FileHandle.Write(LineValue);
    end;

    [Scope('OnPrem')]
    procedure InsertAlphaNumericValue(Value: Text[172]; Size: Integer; FillCharacter: Text[1])
    begin
        LineValue := LineValue + PadStr(CopyStr(Value, 1, Size), Size, FillCharacter);
    end;

    [Scope('OnPrem')]
    procedure InsertNumericValue(Value: Decimal; Size: Integer)
    begin
        LineValue := LineValue + ConvertStr(Format(Round(Value, 1, '<'), Size, 1), ' ', '0');
    end;

    [Scope('OnPrem')]
    procedure InsertIntegerValue(Value: Integer; Size: Integer)
    begin
        LineValue := LineValue + ConvertStr(Format(Value, Size, 0), ' ', '0');
    end;

    procedure GetCCCBankInfo(BankAccNo: Code[20]; var CCCBankNo: Text[4]; var CCCBankBranchNo: Text[4]; var CCCControlDigits: Text[2]; var CCCAccNo: Text[10])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);

        BankAccount.TestField("CCC Bank No.");
        BankAccount.TestField("CCC Bank Branch No.");
        BankAccount.TestField("CCC Bank Account No.");
        BankAccount.TestField("CCC Control Digits");
        BankAccount.TestField("Country/Region Code");

        CCCBankNo := BankAccount."CCC Bank No.";
        CCCBankNo := PadStr('', MaxStrLen(CCCBankNo) - StrLen(CCCBankNo), '0') + CCCBankNo;

        CCCBankBranchNo := BankAccount."CCC Bank Branch No.";
        CCCBankBranchNo := PadStr('', MaxStrLen(CCCBankBranchNo) - StrLen(CCCBankBranchNo), '0') + CCCBankBranchNo;

        CCCAccNo := BankAccount."CCC Bank Account No.";
        CCCAccNo := PadStr('', MaxStrLen(CCCAccNo) - StrLen(CCCAccNo), '0') + CCCAccNo;

        CCCControlDigits := BankAccount."CCC Control Digits";
        CCCControlDigits := PadStr('', MaxStrLen(CCCControlDigits) - StrLen(CCCControlDigits), '0') + CCCControlDigits;
    end;

    [Scope('OnPrem')]
    procedure GetLastEPayFileCreation(var Path: Text[150]; var BankAcc: Record "Bank Account")
    var
        ExportFileName: Text[12];
    begin
        ExportFileName := 'AEB001.txt';
        if BankAcc."Last E-Pay Export File Name" <> '' then
            BankAcc."Last E-Pay Export File Name" := IncStr(BankAcc."Last E-Pay Export File Name")
        else
            BankAcc."Last E-Pay Export File Name" := ExportFileName;

        if BankAcc."Las E-Pay File Creation No." <> 0 then
            BankAcc."Las E-Pay File Creation No." := BankAcc."Las E-Pay File Creation No." + 1
        else
            BankAcc."Las E-Pay File Creation No." := 1;

        Path := BankAcc."Last E-Pay Export File Name";
        ToFolder := BankAcc."E-Pay Export File Path";
        CreateFile(Path);
    end;

    procedure GetPayeeInfo(AccNo: Code[20]; var PayeeCCCBankNo: Text[4]; var PayeeCCCBankBranchNo: Text[4]; var PayeeCCCControlDigits: Text[2]; var PayeeCCCAccNo: Text[10]; var PayeeAddress: array[8] of Text[100]; var PayeeCCC: Text[20]; var IBAN: Text[34]; var SwiftCode: Text[11]; TransferType: Option National,International,Special)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        FormatAddr: Codeunit "Format Address";
    begin
        Vendor.Get(AccNo);
        FormatAddr.Vendor(PayeeAddress, Vendor);
        VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
        VendorBankAccount.SetRange("Use For Electronic Payments", true);
        if VendorBankAccount.Count <> 1 then
            Error(Text1100001,
              VendorBankAccount.TableCaption(), VendorBankAccount.FieldCaption("Use For Electronic Payments"),
              Vendor.TableCaption(), Vendor."No.");
        VendorBankAccount.FindFirst();
        if TransferType = TransferType::National then begin
            VendorBankAccount.TestField("CCC Bank No.");
            VendorBankAccount.TestField("CCC Bank Branch No.");
            VendorBankAccount.TestField("CCC Bank Account No.");
            VendorBankAccount.TestField("CCC Control Digits");

            PayeeCCCAccNo := VendorBankAccount."CCC Bank Account No.";
            PayeeCCCControlDigits := VendorBankAccount."CCC Control Digits";
            PayeeCCCBankNo := VendorBankAccount."CCC Bank No.";
            PayeeCCCBankBranchNo := VendorBankAccount."CCC Bank Branch No.";
            if (PayeeCCCBankNo = '') or (PayeeCCCBankBranchNo = '') or
               (PayeeCCCControlDigits = '') or (PayeeCCCAccNo = '')
            then
                Error(Text1100002, VendorBankAccount."Vendor No.");

            PayeeCCCAccNo := PadStr('', MaxStrLen(PayeeCCCAccNo) - StrLen(PayeeCCCAccNo), '0') + PayeeCCCAccNo;
            PayeeCCCControlDigits := PadStr('', MaxStrLen(PayeeCCCControlDigits) - StrLen(PayeeCCCControlDigits), '0') +
              PayeeCCCControlDigits;

            PayeeCCC := ConvertStr(PadStr(PayeeCCCBankNo, 4, ' '), ' ', '0') + ConvertStr(PadStr(PayeeCCCBankBranchNo, 4, ' '), ' ', '0') +
              PadStr(PayeeCCCControlDigits, 2, ' ') + ConvertStr(PadStr(PayeeCCCAccNo, 10, ' '), ' ', '0');
        end else begin
            VendorBankAccount.TestField(IBAN);
            IBAN := ConvertStr(PadStr(VendorBankAccount.IBAN, 34, ' '), ' ', '0');
            SwiftCode := PadStr(VendorBankAccount."SWIFT Code", 11, ' ');
        end;
    end;

    procedure GetTransferType(AccNo: Code[20]; Amount: Decimal; var TransferType: Option National,International,Special; UpdateFromPosting: Boolean)
    var
        CompanyInfo: Record "Company Information";
        OriginResident: Boolean;
        PayeeResident: Boolean;
        LowAmount: Boolean;
        Domestic: Boolean;
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("Country/Region Code");
        if CompanyInfo."Country/Region Code" = 'ES' then
            OriginResident := true
        else
            OriginResident := false;

        Vendor.Get(AccNo);
        VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
        VendorBankAccount.SetRange("Use For Electronic Payments", true);
        if not VendorBankAccount.FindFirst() then begin
            if not UpdateFromPosting then
                Error(Text1100000, VendorBankAccount.FieldCaption("Use For Electronic Payments"));
        end else begin
            if VendorBankAccount."Country/Region Code" = 'ES' then
                Domestic := true
            else
                Domestic := false;

            if Vendor."Country/Region Code" = 'ES' then
                PayeeResident := true
            else
                PayeeResident := false;

            if Amount >= 12500 then
                LowAmount := false
            else
                LowAmount := true;

            if Domestic then begin
                if PayeeResident then
                    TransferType := TransferType::National
                else
                    if OriginResident and (not LowAmount) then
                        TransferType := TransferType::Special
                    else
                        TransferType := TransferType::National;
            end else
                if OriginResident and (not LowAmount) then
                    TransferType := TransferType::Special
                else
                    TransferType := TransferType::International;
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertIntoCheckLedger(BankAccNo: Code[20]; DeliveryDate: Date; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; DescriptionText: Text[100]; BalAccNo: Code[20]; Amt: Decimal; RecordIdToPrint: RecordID)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
    begin
        CheckLedgerEntry.Init();
        CheckLedgerEntry."Bank Account No." := BankAccNo;
        CheckLedgerEntry."Posting Date" := DeliveryDate;
        CheckLedgerEntry."Document Type" := DocType;
        CheckLedgerEntry."Document No." := DocNo;
        CheckLedgerEntry.Description := DescriptionText;
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Electronic Payment";
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Exported;
        CheckLedgerEntry."Check Date" := DeliveryDate;
        CheckLedgerEntry."Check No." := DocNo;
        CheckLedgerEntry."Bal. Account Type" := CheckLedgerEntry."Bal. Account Type"::"Bank Account";
        CheckLedgerEntry."Bal. Account No." := BalAccNo;
        CheckLedgerEntry.Amount := Amt;
        CheckManagement.InsertCheck(CheckLedgerEntry, RecordIdToPrint);
    end;

    [Scope('OnPrem')]
    procedure EuroAmount(Amount: Decimal): Text[12]
    var
        TextAmount: Text[15];
    begin
        TextAmount := ConvertStr(Format(Amount), ' ', '0');
        if StrPos(TextAmount, ',') = 0 then
            TextAmount := TextAmount + '00'
        else begin
            if StrLen(CopyStr(TextAmount, StrPos(TextAmount, ','), StrLen(TextAmount))) = 2 then
                TextAmount := TextAmount + '0';
            TextAmount := DelChr(TextAmount, '=', ',');
        end;
        if StrPos(TextAmount, '.') = 0 then
            TextAmount := TextAmount
        else
            TextAmount := DelChr(TextAmount, '=', '.');

        while StrLen(TextAmount) < 12 do
            TextAmount := '0' + TextAmount;

        exit(TextAmount);
    end;

    [Scope('OnPrem')]
    procedure ProcessElectronicPayment(DocumentNo: Code[20]; BankAccountNo: Code[20])
    var
        CheckLedgEntry: Record "Check Ledger Entry";
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgEntry.Reset();
        CheckLedgEntry.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        CheckLedgEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgEntry.SetRange("Entry Status", CheckLedgEntry."Entry Status"::Exported);
        CheckLedgEntry.SetRange("Check No.", DocumentNo);
        if CheckLedgEntry.Find('-') then
            repeat
                CheckLedgEntry2 := CheckLedgEntry;
                CheckLedgEntry2."Original Entry Status" := CheckLedgEntry2."Original Entry Status"::Exported;
                CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Voided;
                CheckLedgEntry2.Modify();
            until CheckLedgEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertHeaderRecType1(DeliveryDate: Date; PostingDate: Date; CCCNo: Text[20]; Relation: Text[1])
    begin
        TransferType := TransferType::" ";
        TotalDomesticRegs := 0;
        TotalInternationalRegs := 0;
        TotalSpecialRegs := 0;

        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(3, 2);
        InsertIntegerValue(62, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(Format(DeliveryDate, 0, '<Day,2><Month,2><Year>'), 6, ' ');
        InsertAlphaNumericValue(Format(PostingDate, 0, '<Day,2><Month,2><Year>'), 6, ' ');
        InsertAlphaNumericValue(CCCNo, 20, ' ');
        InsertAlphaNumericValue(Relation, 1, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertHeaderRecType2()
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(3, 2);
        InsertIntegerValue(62, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertIntegerValue(2, 3);
        InsertAlphaNumericValue(CompanyInfo.Name, 36, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertHeaderRecType3()
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(3, 2);
        InsertIntegerValue(62, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertIntegerValue(3, 3);
        InsertAlphaNumericValue(CompanyInfo.Address, 36, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertHeaderRecType4()
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(3, 2);
        InsertIntegerValue(62, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertIntegerValue(4, 3);
        InsertAlphaNumericValue(CompanyInfo."Post Code" + ' ' + CompanyInfo.City, 36, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertDomesticTransferBlock(DocType: Code[10]; PaymentOrderConcept: Option Payroll,RetPayroll,Others; ExpensesCode: Option Payer,Payee; VatRegNoVend: Text[12]; Amount: Text[12]; PayeeCCC: Text[20]; VendorName: Text[100])
    var
        PmtOrderConcValue: Text[1];
        ExpensesCodeValue: Text[1];
    begin
        if TransferType <> TransferType::Domestic then begin
            InsertDomesticHeaderRec();
            TransferType := TransferType::Domestic;
            TotalDomesticRegs := TotalDomesticRegs + 1;
        end;

        TotalDomesticRegs := TotalDomesticRegs + 2;

        case PaymentOrderConcept of
            PaymentOrderConcept::Payroll:
                PmtOrderConcValue := '1';
            PaymentOrderConcept::RetPayroll:
                PmtOrderConcValue := '8';
            PaymentOrderConcept::Others:
                PmtOrderConcValue := '9';
        end;
        if ExpensesCode = ExpensesCode::Payer then
            ExpensesCodeValue := '1'
        else
            ExpensesCodeValue := '2';
        InsertDomesticRegsType1(VatRegNoVend, Amount, PayeeCCC, ExpensesCodeValue, PmtOrderConcValue, DocType);
        InsertDomesticRegsType1To8(VatRegNoVend, PadStr(VendorName, 36, ' '), DocType);
    end;

    [Scope('OnPrem')]
    procedure InsertDomesticHeaderRec()
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(4, 2);
        InsertIntegerValue(56, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertDomesticRegsType1(VatRegNoVend: Text[12]; JnlLineAmount: Text[12]; PayeeCCC: Text[20]; ExpensesCode: Text[1]; PmtOrderConcept: Text[1]; BillType: Code[10])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        if BillType = '4' then
            InsertIntegerValue(57, 2)
        else
            InsertIntegerValue(56, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(10, 3);
        InsertAlphaNumericValue(JnlLineAmount, 12, ' ');
        InsertAlphaNumericValue(PayeeCCC, 20, ' ');
        InsertAlphaNumericValue(ExpensesCode, 1, ' ');
        InsertAlphaNumericValue(PmtOrderConcept, 1, ' ');
        InsertIntegerValue(1, 1);
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertDomesticRegsType1To8(VatRegNoVend: Text[12]; VendorName: Text[100]; BillType: Code[10])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        if BillType = '4' then
            InsertIntegerValue(57, 2)
        else
            InsertIntegerValue(56, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(11, 3);
        InsertAlphaNumericValue(VendorName, 36, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertDomesticTrailer(TotalDom10Amount: Integer; TotalAmount: Text[12])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(8, 2);
        InsertIntegerValue(56, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertAlphaNumericValue(' ', 3, ' ');
        InsertAlphaNumericValue(TotalAmount, 12, '0');
        InsertNumericValue(TotalDom10Amount, 8);
        TotalDomesticRegs := TotalDomesticRegs + 1;
        InsertIntegerValue(TotalDomesticRegs, 10);
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertInterTransferBlock(PaymentOrderConcept: Option Payroll,RetPayroll,Others; ExpensesCode: Option Payer,Payee; ExpensesCodeInter: Boolean; VatRegNoVend: Text[12]; IBAN: Text[34]; AmountLCY: Text[12]; CountryCodeVendBankAcc: Text[2]; SwiftCode: Text[11]; VendorName: Text[100])
    var
        PmtOrderConcValue: Text[1];
        ExpensesCodeValue: Text[1];
    begin
        if TransferType <> TransferType::International then begin
            InsertInterTransferBlockHeader();
            TransferType := TransferType::International;
            TotalInternationalRegs := TotalInternationalRegs + 1;
        end;

        TotalInternationalRegs := TotalInternationalRegs + 3;

        case PaymentOrderConcept of
            PaymentOrderConcept::Payroll:
                PmtOrderConcValue := '2';
            PaymentOrderConcept::RetPayroll:
                PmtOrderConcValue := '6';
            PaymentOrderConcept::Others:
                PmtOrderConcValue := '7';
        end;
        if ExpensesCodeInter then
            ExpensesCodeValue := '3'
        else
            if ExpensesCode = ExpensesCode::Payer then
                ExpensesCodeValue := '1'
            else
                ExpensesCodeValue := '2';
        InsertInterTransferBlockType1(VatRegNoVend, IBAN, PmtOrderConcValue);

        InsertInterTransferBlockType2(VatRegNoVend, AmountLCY, ExpensesCodeValue,
          CountryCodeVendBankAcc, SwiftCode);

        InsertInterTransferBlockT3To9(VatRegNoVend, VendorName);
    end;

    [Scope('OnPrem')]
    procedure InsertInterTransferBlockHeader()
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(4, 2);
        InsertIntegerValue(60, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertInterTransferBlockType1(VatRegNoVend: Text[12]; IBAN: Text[34]; PmtOrderConcept: Text[1])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(60, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(33, 3);
        InsertAlphaNumericValue(IBAN, 34, ' ');
        InsertAlphaNumericValue(PmtOrderConcept, 1, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertInterTransferBlockType2(VATRegNoVend: Text[12]; JnlLineAmountLCY: Text[12]; ExpensesCode: Text[1]; CountryCodeVendBankAcc: Text[2]; SwiftCode: Text[11])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(60, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VATRegNoVend, 12, ' ');
        InsertIntegerValue(34, 3);
        InsertAlphaNumericValue(JnlLineAmountLCY, 12, ' ');
        InsertAlphaNumericValue(ExpensesCode, 1, ' ');
        InsertAlphaNumericValue(CountryCodeVendBankAcc, 2, ' ');
        InsertAlphaNumericValue(' ', 6, ' ');
        InsertAlphaNumericValue(SwiftCode, 11, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertInterTransferBlockT3To9(VatRegNoVend: Text[12]; VendorName: Text[100])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(60, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(35, 3);
        InsertAlphaNumericValue(VendorName, 36, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertInterTransferTrailer(TotalDom33Amount: Integer; TotalAmountLCY: Text[12])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(8, 2);
        InsertIntegerValue(60, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertAlphaNumericValue(' ', 3, ' ');
        InsertAlphaNumericValue(TotalAmountLCY, 12, '0');
        InsertNumericValue(TotalDom33Amount, 8);
        TotalInternationalRegs := TotalInternationalRegs + 1;
        InsertIntegerValue(TotalInternationalRegs, 10);
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransferBlock(PaymentOrderConcept: Option Payroll,RetPayroll,Others; ExpensesCode: Option Payer,Payee; VatRegNoVend: Text[12]; IBAN: Text[34]; AmountLCY: Text[12]; CountryCodeVendBankAcc: Text[2]; SwiftCode: Text[11]; VendorName: Text[100]; GenJnlLineDescription: Text[100]; PaymentType: Option " ","01","02"; StatisticalCode: Code[6]; VatSharesIssuer: Text[9]; FinanceOpNo: Text[8]; ISINCode: Text[12])
    var
        PmtOrderConcValue: Text[1];
        ExpensesCodeValue: Text[1];
        PmtType: Text[2];
    begin
        if TransferType <> TransferType::Special then begin
            InsertSpecialTransBlockHeader();
            TransferType := TransferType::Special;
            TotalSpecialRegs := TotalSpecialRegs + 1;
        end;

        TotalSpecialRegs := TotalSpecialRegs + 6;

        case PaymentOrderConcept of
            PaymentOrderConcept::Payroll:
                PmtOrderConcValue := '2';
            PaymentOrderConcept::RetPayroll:
                PmtOrderConcValue := '6';
            PaymentOrderConcept::Others:
                PmtOrderConcValue := '7';
        end;
        if ExpensesCode = ExpensesCode::Payer then
            ExpensesCodeValue := '1'
        else
            ExpensesCodeValue := '2';

        InsertSpecialTransBlockType1(VatRegNoVend, IBAN, PmtOrderConcValue);

        InsertSpecialTransBlockType2(VatRegNoVend, AmountLCY, ExpensesCodeValue, Format(CountryCodeVendBankAcc), SwiftCode);

        InsertSpecialTransBlockT3To9(VatRegNoVend, PadStr(VendorName, 36, ' '));

        InsertSpecialTransBlockType11(VatRegNoVend, PadStr(GenJnlLineDescription, 35, ' '));

        InsertSpecialTransBlockType12(VatRegNoVend, PadStr(GenJnlLineDescription, 35, ' '));

        case PaymentType of
            1:
                PmtType := '01';
            2:
                PmtType := '02';
            else
                PmtType := PadStr(' ', 2, ' ');
        end;

        InsertSpecialTransBlockType13(VatRegNoVend, PmtType, StatisticalCode, Format(CountryCodeVendBankAcc),
          PadStr(VatSharesIssuer, 9, ' '), PadStr(FinanceOpNo, 8, ' '), PadStr(ISINCode, 12, ' '));
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransBlockHeader()
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(4, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransBlockType1(VatRegNoVend: Text[12]; IBAN: Text[34]; PmtOrderConcept: Text[1])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(43, 3);
        InsertAlphaNumericValue(IBAN, 34, ' ');
        InsertAlphaNumericValue(PmtOrderConcept, 1, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransBlockType2(VATRegNoVend: Text[12]; JnlLineAmountLCY: Text[12]; ExpensesCode: Text[1]; CountryCodeVendBankAcc: Text[2]; SwiftCode: Text[11])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VATRegNoVend, 12, ' ');
        InsertIntegerValue(44, 3);
        InsertAlphaNumericValue(JnlLineAmountLCY, 12, ' ');
        InsertAlphaNumericValue(ExpensesCode, 1, ' ');
        InsertAlphaNumericValue(CountryCodeVendBankAcc, 2, ' ');
        InsertAlphaNumericValue(' ', 6, ' ');
        InsertAlphaNumericValue(SwiftCode, 11, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransBlockT3To9(VatRegNoVend: Text[12]; VendorName: Text[100])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(45, 3);
        InsertAlphaNumericValue(VendorName, 36, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransBlockType11(VatRegNoVend: Text[12]; JnlLineDescription: Text[35])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(53, 3);
        InsertAlphaNumericValue(JnlLineDescription, 35, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransBlockType12(VATRegNoVend: Text[12]; JnlLineDescription: Text[35])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VATRegNoVend, 12, ' ');
        InsertIntegerValue(54, 3);
        InsertAlphaNumericValue(JnlLineDescription, 35, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransBlockType13(VatRegNoVend: Text[12]; PmtType: Text[2]; StatisticalCode: Text[6]; CountryCodeVendBankAcc: Text[2]; VatSharesIssuer: Text[9]; FinanceOpNo: Text[8]; ISINCode: Text[12])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(6, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(VatRegNoVend, 12, ' ');
        InsertIntegerValue(55, 3);
        InsertAlphaNumericValue(PmtType, 2, ' ');
        InsertAlphaNumericValue(StatisticalCode, 6, ' ');
        InsertAlphaNumericValue(CountryCodeVendBankAcc, 2, ' ');
        InsertAlphaNumericValue(VatSharesIssuer, 9, ' ');
        InsertAlphaNumericValue(FinanceOpNo, 8, ' ');
        InsertAlphaNumericValue(ISINCode, 12, ' ');
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertSpecialTransTrailer(TotalDom33Amount: Integer; TotalAmountLCY: Text[12])
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(8, 2);
        InsertIntegerValue(61, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertAlphaNumericValue(' ', 3, ' ');
        InsertAlphaNumericValue(TotalAmountLCY, 12, '0');
        InsertNumericValue(TotalDom33Amount, 8);
        TotalSpecialRegs := TotalSpecialRegs + 1;
        InsertIntegerValue(TotalSpecialRegs, 10);
        PadLine(' ');
    end;

    [Scope('OnPrem')]
    procedure InsertGeneralTrailer(NoOfRegistersType1: Decimal; TotalAmountRegsType8: Decimal; SilentMode: Boolean; ServerFileCopy: Text)
    var
        FileMgt: Codeunit "File Management";
    begin
        CompanyInfo.Get();
        NewLine();
        InsertIntegerValue(9, 2);
        InsertIntegerValue(62, 2);
        InsertAlphaNumericValue(CompanyInfo."VAT Registration No.", 9, ' ');
        InsertIntegerValue(1, 3);
        InsertAlphaNumericValue(' ', 12, ' ');
        InsertAlphaNumericValue(' ', 3, ' ');
        InsertAlphaNumericValue(EuroAmount(TotalAmountRegsType8), 12, ' ');
        InsertNumericValue(NoOfRegistersType1, 8);
        InsertNumericValue(4 + TotalDomesticRegs + TotalInternationalRegs + TotalSpecialRegs + 1, 10);
        PadLine(' ');
        FileHandle.Close();

        if SilentMode then
            FileMgt.CopyServerFile(Filename, ServerFileCopy, true);
    end;

    internal procedure DownloadFile()
    begin
        if Download(Filename, '', ToFolder, Text1100003, ToFile) then;
    end;

    internal procedure GetFileContent(var TempBlob: Codeunit "Temp Blob")
    var
        TxtFile: File;
        InStream: InStream;
        OutStream: OutStream;
    begin
        if Filename = '' then
            exit;
        if not File.Exists(Filename) then
            exit;

        TxtFile.TextMode(true);
        TxtFile.Open(Filename);
        TxtFile.CreateInStream(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        TxtFile.Close();
    end;
}

