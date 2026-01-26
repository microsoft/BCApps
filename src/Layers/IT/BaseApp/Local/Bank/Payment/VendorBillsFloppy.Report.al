// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.IO;

report 12175 "Vendor Bills Floppy"
{
    Caption = 'Vendor Bills Floppy';
    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem("Vendor Bill Header"; "Vendor Bill Header")
        {
            DataItemTableView = sorting("No.") order(ascending);
            dataitem("Vendor Bill Line"; "Vendor Bill Line")
            {
                DataItemLink = "Vendor Bill List No." = field("No.");
                DataItemTableView = sorting("Vendor Bill List No.", "Vendor No.", "Due Date", "Vendor Bank Acc. No.", "Cumulative Transfers") order(ascending);

                trigger OnAfterGetRecord()
                begin
                    if "Vendor Bank Acc. No." = '' then
                        Error(Text007,
                          FieldCaption("Vendor Bank Acc. No."),
                          FieldCaption("Line No."),
                          "Line No.");

                    if OldVendor = '' then begin
                        OldVendor := "Vendor No.";
                        OldBankAcc := "Vendor Bank Acc. No.";
                    end;

                    if "Cumulative Transfers" then
                        if ("Vendor No." <> OldVendor) or
                           ("Vendor Bank Acc. No." <> OldBankAcc)
                        then begin
                            OldVendor := "Vendor No.";
                            OldBankAcc := "Vendor Bank Acc. No.";
                            if (OldVendorBillLine."Vendor Bank Acc. No." <> '') and
                               (CumAmount <> 0)
                            then
                                WriteRecord(OldVendorBillLine);
                            CumAmount := "Amount to Pay";
                        end else begin
                            CumAmount := CumAmount + "Amount to Pay";
                            OldVendorBillLine := "Vendor Bill Line";
                        end
                    else begin
                        if CumAmount <> 0 then begin
                            if OldVendorBillLine."Vendor Bank Acc. No." <> '' then
                                WriteRecord(OldVendorBillLine);
                            CumAmount := 0;
                        end;
                        WriteRecord("Vendor Bill Line");
                    end;

                    OldVendorBillLine := "Vendor Bill Line";
                end;

                trigger OnPostDataItem()
                begin
                    if CumAmount <> 0 then
                        WriteRecord("Vendor Bill Line");

                    WriteFooter();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Currency Code" <> '' then
                    Error(Text004, FieldCaption("Currency Code"));

                BankAccount.Get("Bank Account No.");

                BankAccount.TestField(IBAN);
                CheckVendorBankAccounts();

                TransfProgr := 0;
                TotAmount := 0;
                CurrCode := 'E';
                OldVendor := '';

                WriteHeader();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if FileName = '' then
            FileName := Text008;
    end;

    trigger OnPostReport()
    begin
        OutFile.Close();
        RBMgt.DownloadHandler(FileName, '', 'C:', '', ToFile);
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField("SIA Code");

        if "Vendor Bill Header".GetFilter("No.") = '' then
            Error(Text000, FormVendorBillListSentCard.ObjectId());

        if Exists(FileName) then
            if not Confirm(ReplaceExistingFileQst, false, FileName) then
                Error(Text001, FileName);

        FillChar := ' ';
        Dummy := '';
        Dummy := PadStr(Dummy, 120, FillChar);

        Clear(OutFile);
        OutFile.TextMode := true;
        OutFile.WriteMode := true;
        FileName := RBMgt.ServerTempFileName('');
        ToFile := Text008;
        OutFile.Create(FileName);
    end;

    var
        Text000: Label 'Please run this batch from %1.';
        Text001: Label 'File %1 still exists.';
        ReplaceExistingFileQst: Label 'File %1 still exists.\Do you want to replace the existing file?';
        Text004: Label 'You can run this batch only if %1 is blank.';
        Text007: Label 'Please specify %1 in %2 %3.';
        Text008: Label 'C:\BONIFICI.TXT';
        Text012: Label 'Sundry invoices';
        Text014: Label 'Please specify %1 and %2 and %3 for %4 %5.';
        CompanyInfo: Record "Company Information";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        OldVendorBillLine: Record "Vendor Bill Line";
        RBMgt: Codeunit "File Management";
        FormVendorBillListSentCard: Page "Vendor Bill List Sent Card";
        OutFile: File;
        FileName: Text[1024];
        OutText: Text[120];
        Dummy: Text[120];
        CurrCode: Text[10];
        FillChar: Text[1];
        ABI: Integer;
        CAB: Integer;
        TransfProgr: Integer;
        VendABI: Integer;
        VendCAB: Integer;
        LineAmount: Decimal;
        CumAmount: Decimal;
        TotAmount: Decimal;
        TRAmount: Decimal;
        OldVendor: Code[20];
        OldBankAcc: Code[20];
        InvalidBBANBankCodeErr: Label 'BBAN Code (%1) is incorrect in bank account %2.', Comment = '%1 - BBAN bank code, %2 - bank code.';
        InvalidBBANVendorBankCodeErr: Label 'BBAN Code (%1) is incorrect in vendor bank account Vendor No.:%2, Vendor Bank Acc. No.:%3.', Comment = '%1 - BBAN bank code, %2 - vendor number, %3 venodor bank code.';
        Text017: Label 'The Vendor Bill List %1 contains Vendor Bank Accounts without IBAN. The IBAN must be filled before you can create the payment file.\\Do you want to see the list of Vendor Bank Accounts with missing IBAN?';
        ToFile: Text[1024];

    [Scope('OnPrem')]
    procedure WriteHeader()
    begin
        ABI := 0;
        CAB := 0;

        Evaluate(ABI, BankAccount.ABI);
        Evaluate(CAB, BankAccount.CAB);

        OutText := ' PC' +
          Format(CompanyInfo."SIA Code", 5) +
          ConvertStr(Format(ABI, 5), ' ', '0') +
          Format("Vendor Bill Header"."List Date", 6, 5) +
          Format("Vendor Bill Header"."Vendor Bill List No.", 20) +
          CopyStr(Dummy, 40, 74) +
          CurrCode;

        OutText := PadStr(OutText, 120, ' ');
        OutFile.Write(OutText);
    end;

    [Scope('OnPrem')]
    procedure WriteFooter()
    begin
        OutText := '';
        ABI := 0;
        OutText := ' EF';

        TRAmount := TotAmount;

        Evaluate(ABI, BankAccount.ABI);

        OutText := OutText +
          Format(CompanyInfo."SIA Code", 5) +
          ConvertStr(Format(ABI, 5), ' ', '0') +
          Format("Vendor Bill Header"."List Date", 6, 5) +
          Format("Vendor Bill Header"."Vendor Bill List No.", 20) +
          CopyStr(Dummy, 40, 6) +
          ConvertStr(Format(TransfProgr, 7), ' ', '0') +
          ConvertStr(Format(0, 15, 1), ' ', '0') +
          ConvertStr(Format(Abs(TRAmount), 15, 1), ' ', '0') +
          ConvertStr(Format(TransfProgr * 8 + 2, 7), ' ', '0') +
          CopyStr(Dummy, 90, 24) +
          CurrCode;

        OutText := PadStr(OutText, 120, FillChar);
        OutFile.Write(OutText);
    end;

    [Scope('OnPrem')]
    procedure RECORD10(VendorBillLine: Record "Vendor Bill Line")
    var
        PostingDate: Date;
        BeneficiaryValueDate: Date;
    begin
        if VendorBillLine."Cumulative Transfers" then
            LineAmount := Round(CumAmount, 0.01) * 100
        else
            LineAmount := Round(VendorBillLine."Amount to Pay", 0.01) * 100;

        TotAmount := TotAmount + LineAmount;
        if VendorBillLine."Beneficiary Value Date" <> 0D then
            BeneficiaryValueDate := VendorBillLine."Beneficiary Value Date"
        else
            PostingDate := "Vendor Bill Header"."Posting Date";

        OutText := ' 10' +
          ConvertStr(Format(TransfProgr, 7), ' ', '0') +
          CopyStr(Dummy, 11, 6) +
          Format(PostingDate, 6, 5) +
          Format(BeneficiaryValueDate, 6, 5);

        if VendorBillLine."Transfer Type" = VendorBillLine."Transfer Type"::Transfer then
            OutText := OutText + '48000'
        else
            OutText := OutText + '27000';

        if StrLen(BankAccount.BBAN) < 12 then
            Error(InvalidBBANBankCodeErr, BankAccount.BBAN, BankAccount."No.");

        OutText := OutText +
          ConvertStr(Format(Abs(LineAmount), 13, 1), ' ', '0') +
          '+' +
          ConvertStr(Format(ABI, 5), ' ', '0') +
          ConvertStr(Format(CAB, 5), ' ', '0') +
          ConvertStr(CopyStr(BankAccount.BBAN, StrLen(BankAccount.BBAN) - 11, 12), ' ', '0');

        if VendorBankAccount.Get(VendorBillLine."Vendor No.", VendorBillLine."Vendor Bank Acc. No.") then begin
            if (VendorBankAccount.ABI = '') or
               (VendorBankAccount.CAB = '')
            then
                Error(Text014,
                  VendorBankAccount.FieldCaption(ABI),
                  VendorBankAccount.FieldCaption(CAB),
                  VendorBillLine.FieldCaption("Vendor Bank Acc. No."),
                  VendorBillLine."Vendor Bank Acc. No.");

            Evaluate(VendABI, VendorBankAccount.ABI);
            Evaluate(VendCAB, VendorBankAccount.CAB);
            if StrLen(VendorBankAccount.BBAN) < 12 then
                Error(InvalidBBANVendorBankCodeErr, VendorBankAccount.BBAN, VendorBankAccount."Vendor No.", VendorBankAccount.Code);
            OutText := OutText +
              ConvertStr(Format(VendABI, 5), ' ', '0') +
              ConvertStr(Format(VendCAB, 5), ' ', '0') +
              ConvertStr(CopyStr(VendorBankAccount.BBAN, StrLen(VendorBankAccount.BBAN) - 11, 12), ' ', '0');
        end else
            OutText := OutText + CopyStr(Dummy, 70, 22);

        OutText := OutText +
          Format(CompanyInfo."SIA Code", 5) +
          '5' +
          PadStr('', 16 - StrLen(Vendor."No."), ' ') + Vendor."No." +
          '1' +
          CopyStr(Dummy, 115, 5) +
          CurrCode;

        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure RECORD16(VendorBillLine: Record "Vendor Bill Line")
    begin
        OutText := ' 16' + ConvertStr(Format(TransfProgr, 7), ' ', '0');

        OutText += DelChr(BankAccount.IBAN);

        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure RECORD17(VendorBillLine: Record "Vendor Bill Line")
    begin
        OutText := ' 17' + ConvertStr(Format(TransfProgr, 7), ' ', '0');

        OutText += DelChr(VendorBankAccount.IBAN);

        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure RECORD20(VendorBillLine: Record "Vendor Bill Line")
    begin
        OutText := ' 20' + ConvertStr(Format(TransfProgr, 7), ' ', '0');

        OutText := OutText +
          Format(CompanyInfo.Name, 30) +
          Format(CompanyInfo.Address, 30) +
          Format(CompanyInfo."Post Code", 5) +
          Format(CompanyInfo.City, 25) +
          Format(CompanyInfo."VAT Registration No.", 15);

        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure RECORD30(VendorBillLine: Record "Vendor Bill Line")
    begin
        OutText := ' 30' + ConvertStr(Format(TransfProgr, 7), ' ', '0');

        OutText := OutText + Format(Vendor.Name, 30) + Format(Vendor."Name 2", 30) + CopyStr(Dummy, 71, 30);

        if Vendor."VAT Registration No." <> '' then
            OutText := OutText + Format(Vendor."VAT Registration No.", 16)
        else
            OutText := OutText + Format(Vendor."Fiscal Code", 16);

        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure RECORD40(VendorBillLine: Record "Vendor Bill Line")
    begin
        OutText := ' 40' + ConvertStr(Format(TransfProgr, 7), ' ', '0');

        if Vendor.Address = '' then
            OutText := OutText + ConvertStr(CopyStr(Dummy, 11, 30), ' ', '.')
        else
            OutText := OutText + Format(Vendor.Address, 30);

        OutText := OutText +
          Format(Vendor."Post Code", 5) +
          Format(Vendor.City, 23) +
          Format(Vendor.County, 2);

        if VendorBankAccount.Get(VendorBillLine."Vendor No.", VendorBillLine."Vendor Bank Acc. No.") then
            if (VendorBankAccount.ABI <> '') and
               (VendorBankAccount.CAB <> '')
            then begin
                Evaluate(VendABI, VendorBankAccount.ABI);
                Evaluate(VendCAB, VendorBankAccount.CAB);
                OutText := OutText +
                  ConvertStr(Format(VendABI, 5), ' ', '0') + ' ' +
                  ConvertStr(Format(VendCAB, 5), ' ', '0')
            end else
                OutText := OutText + Format(VendorBankAccount.Name + ' ' + VendorBankAccount.City, 50);

        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure RECORD50(VendorBillLine: Record "Vendor Bill Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRECORD50(VendorBillLine, TransfProgr, OutText, IsHandled);
        if IsHandled then
            exit;

        OutText := ' 50' + ConvertStr(Format(TransfProgr, 7), ' ', '0');
        if "Vendor Bill Line"."Cumulative Transfers" then
            OutText := OutText + Format(Text012, 60)
        else
            OutText := OutText +
              Format(VendorBillLine.Description, 30) +
              Format(VendorBillLine."Description 2", 30);

        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure RECORD70(VendorBillLine: Record "Vendor Bill Line")
    begin
        OutText := ' 70' + ConvertStr(Format(TransfProgr, 7), ' ', '0');
        OutText := PadStr(OutText, 120, FillChar);
    end;

    [Scope('OnPrem')]
    procedure WriteRecord(VendorBillLine: Record "Vendor Bill Line")
    begin
        TransfProgr := TransfProgr + 1;

        Vendor.Get(VendorBillLine."Vendor No.");

        RECORD10(VendorBillLine);
        OutFile.Write(OutText);

        RECORD16(VendorBillLine);
        OutFile.Write(OutText);

        RECORD17(VendorBillLine);
        OutFile.Write(OutText);

        RECORD20(VendorBillLine);
        OutFile.Write(OutText);

        RECORD30(VendorBillLine);
        OutFile.Write(OutText);

        RECORD40(VendorBillLine);
        OutFile.Write(OutText);

        RECORD50(VendorBillLine);
        OutFile.Write(OutText);

        RECORD70(VendorBillLine);
        OutFile.Write(OutText);
    end;

    [Scope('OnPrem')]
    procedure CheckVendorBankAccounts()
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBillLine.SetFilter("Vendor Bill List No.", '%1', "Vendor Bill Header"."No.");
        if VendorBillLine.FindSet() then
            repeat
                VendorBankAccount.Get(VendorBillLine."Vendor No.", VendorBillLine."Vendor Bank Acc. No.");
                VendorBankAccount.Mark := VendorBankAccount.IBAN = '';
            until VendorBillLine.Next() = 0;

        VendorBankAccount.MarkedOnly(true);
        if VendorBankAccount.FindFirst() then begin
            VendorBankAccount.FilterGroup := 2;
            VendorBankAccount.SetFilter(IBAN, '');
            VendorBankAccount.FilterGroup := 0;
            if Confirm(Text017, false, "Vendor Bill Header"."No.") then
                PAGE.RunModal(0, VendorBankAccount, VendorBankAccount.IBAN);
            Error('');
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRECORD50(VendorBillLine: Record "Vendor Bill Line"; TransfProgr: Integer; var OutText: Text[120]; var IsHandled: Boolean)
    begin
    end;
}

