// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using System.IO;

report 32000004 "Export Ref. Payment -  LUM"
{
    Caption = 'Export Ref. Payment -  LUM';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {

            trigger OnAfterGetRecord()
            var
                InputDlg: Page "Input Dialog";
                Type: Option ,Boolean,"Integer",Decimal,Text,Date,Time;
            begin
                RefPmtExport.SetCurrentKey("Payment Date", "Vendor No.", "Entry No.");
                RefPmtExport.SetFilter("Payment Account", "Bank Account"."No.");
                RefPmtExport.SetRange("Foreign Payment", true);
                RefPmtExport.SetRange(Transferred, false);
                RefPmtExport.SetRange("Document Type", 2);
                RefPmtExport.SetRange("Applied Payments", false);

                if RefPmtExport.FindSet() then begin
                    CreatedLines := true;
                    RefFileSetup.SetFilter("No.", "Bank Account"."No.");
                    if not RefFileSetup.FindFirst() then
                        Error(Text1090003, "Bank Account"."No.");

                    RefPmtExport.TestField("Vendor No.");
                    RefPmtExport.TestField("Payment Account");
                    RefPmtExport.TestField("Payment Date");
                    RefPmtExport.TestField("Vendor Account");
                    RefPmtExport.TestField("Invoice Message");
                    TransferFile.Create(ServerFileName);
                    ExchangeRateNo := RefFileSetup."Exchange Rate Contract No.";
                    DueDateType := RefFileSetup."Due Date Handling";
                    if DueDateType = 0 then begin
                        InputDlg.SetCaption(Text1090000);
                        InputDlg.InitString(Format(RefPmtExport."Payment Date"), Type::Date);
                        if InputDlg.RunModal() = ACTION::OK then
                            BatchDate := InputDlg.GetDate();
                    end;
                    Window.Open(
                      '#1###################################\\' +
                      Text1090001 +
                      Text1090002);
                    ChargingAccCurrency := "Bank Account"."Currency Code";
                    FeedbackCurrency := '1';
                    if ChargingAccCurrency = '' then
                        ChargingAccCurrency := 'EUR';

                    FileID := 'LUM2';
                    RecID := '0';
                    EventType := '0';
                    CustomerID := CompanyInfo."Business Identity Code";
                    LinePos := StrPos(CustomerID, '-');
                    if LinePos > 0 then
                        CustomerID := CopyStr(CustomerID, 1, LinePos - 1) + CopyStr(CustomerID, LinePos + 1);
                    CustomerIDExtra := '     ';

                    BankAccFormat.ConvertBankAcc("Bank Account"."Bank Account No.", "Bank Account"."No.");
                    ChargingAcc := "Bank Account"."Bank Account No.";

                    CreationTime := Format(Today, 0, '<year,2><Month,2><day,2>');
                    CreationTime := CreationTime + Format(Time, 0, '<hour,2><minute,2>');
                    Spear1 := TextSpaceFormat(' ', 250, 1, ' ');
                    Spear2 := TextSpaceFormat(' ', 250, 1, ' ');
                    Spear3 := TextSpaceFormat(' ', 42, 1, ' ');
                    CustomerID := TextSpaceFormat(CustomerID, 11, 0, '0');
                    BatchPaymentDate := TextSpaceFormat(BatchPaymentDate, 8, 1, ' ');

                    HederConter := HederConter + 1;
                    if BatchDate = 0D then
                        BatchDate := RefPmtExport."Payment Date";
                    Window.Update(1, StrSubstNo('%1 %2', "Bank Account"."No.", "Bank Account".Name));
                    BatchPaymentDate := Format(BatchDate, 0, '<year4><month,2><day,2>');

                    Window.Update(3, HederConter);
                    Window.Update(4, 0);
                    PaymentsQty := '00000';

                    TransferFile.Write(FileID + RecID + EventType + ' ' + CustomerID + CustomerIDExtra + '  0' +
                      CreationTime + '00000000000000' + BatchPaymentDate +
                      Spear1 + Spear2 + Spear3);

                    CreatePaymentRecord();

                    FileID := 'LUM2';
                    RecID := '9';
                    EventType := '0';
                    Spear1 := TextSpaceFormat(' ', 250, 1, ' ');
                    Spear2 := TextSpaceFormat(' ', 250, 1, ' ');
                    Spear3 := TextSpaceFormat(' ', 49, 1, ' ');

                    PaymentsAmountSum := TextSpaceFormat(Format(PaymentsAmountDec * 100, 0, 2), 15, 0, '0');

                    TransferFile.Write(FileID + RecID + EventType + ' ' + CustomerID + CustomerIDExtra +
                      '   ' + PaymentsQty + '00000' + PaymentsAmountSum + Spear1 + Spear2 + Spear3);

                    PaymentsAmountDec := 0;
                    PaymentsQty := '0';
                    RowCounter := 0;
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompanyInfo.TestField("Business Identity Code");
                TransferFile.TextMode := true;
                ServerFileName := FileMgt.ServerTempFileName('txt');
            end;
        }
    }

    requestpage
    {

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

    trigger OnPostReport()
    begin
        if CreatedLines then begin
            TransferFile.Close();
            if not HideFileDialog then begin
                if not FileMgt.DownloadHandler(ServerFileName, '', '', '', 'fiforeign.txt') then
                    Error('');
                Erase(ServerFileName);
            end;
            RefPmtExport.Reset();
            RefPmtExport.SetRange("Foreign Payment", true);
            RefPmtExport.ModifyAll(Transferred, true);
            RefPmtExport.ModifyAll("Applied Payments", false);
            RefPmtExport.Modify();
        end else
            Message(Text1090006);
    end;

    var
        CompanyInfo: Record "Company Information";
        Vend: Record Vendor;
        VendBankAcc: Record "Vendor Bank Account";
        Country: Record "Country/Region";
        RefPmtExport: Record "Ref. Payment - Exported";
        RefFileSetup: Record "Reference File Setup";
        BankAccFormat: Codeunit "Bank Nos Check";
        FileMgt: Codeunit "File Management";
        TransferFile: File;
        Window: Dialog;
        HederConter: Integer;
        RowCounter: Integer;
        LinePos: Integer;
        Spear1: Text[250];
        Spear2: Text[250];
        Spear3: Text[250];
        DueDateType: Option "Eräkohtainen",Maksukohtainen;
        BatchDate: Date;
        CreatedLines: Boolean;
        HideFileDialog: Boolean;
        FileID: Code[4];
        RecID: Code[1];
        EventType: Code[1];
        CustomerID: Text[11];
        CustomerIDExtra: Text[5];
        CreationTime: Code[10];
        BatchPaymentDate: Text[8];
        RecieversInfo: array[4] of Text[35];
        CountryCode: Code[2];
        SWIFTCode: Text[11];
        RecieversBank: array[4] of Text[35];
        RecieverAcc: Text[34];
        RecieverIBAN: Text[34];
        PaymentSubject: array[4] of Text[35];
        Amount: Text[15];
        Currency: Code[3];
        ExchangeRateNo: Text[14];
        PaymentType: Code[1];
        ServiceCharge: Code[1];
        TransPaymentDate: Code[8];
        EquivalentValue: Text[15];
        PaymentExchangeRate: Text[11];
        ChargingAcc: Code[14];
        ChargingAccCurrency: Code[3];
        ChargedAmount: Text[15];
        FileingCode: Text[20];
        FeedbackCurrency: Code[1];
        PaymentsQty: Text[5];
        PaymentsAmountSum: Text[15];
        PaymentsAmountDec: Decimal;
        Text1090000: Label 'Batch Payment Date';
        Text1090001: Label 'Creating Batch Lines         #3######\';
        Text1090002: Label 'Creating Payment Lines       #4######';
        Text1090003: Label 'Set Transfer File settings for Bank Account %1.';
        Text1090006: Label 'There is nothing to send.';
        ServerFileName: Text;

    [Scope('OnPrem')]
    procedure CreatePaymentRecord()
    begin
        if RefPmtExport.FindSet() then
            repeat
                RefPmtExport.TestField("Vendor No.");
                RefPmtExport.TestField("Payment Account");
                RefPmtExport.TestField("Payment Date");
                RefPmtExport.TestField("Amount (LCY)");
                RefPmtExport.TestField("Vendor Account");
                RefPmtExport.TestField("Invoice Message");
                RefPmtExport.TestField("Foreign Payment Method");
                RefPmtExport.TestField("Foreign Banks Service Fee");

                Vend.Get(RefPmtExport."Vendor No.");
                Vend.TestField("Country/Region Code");
                VendBankAcc.Get(RefPmtExport."Vendor No.", RefPmtExport."Vendor Account");
                Country.Get(VendBankAcc."Country/Region Code");
                RecieverIBAN := DelChr(VendBankAcc.IBAN);

                FileID := 'LUM2';
                RecID := '1';
                CountryCode := Vend."Country/Region Code";
                if RefPmtExport."Currency Code" <> '' then
                    Currency := RefPmtExport."Currency Code"
                else
                    Currency := 'EUR';

                TransPaymentDate := Format(RefPmtExport."Payment Date", 0, '<day,2><month,2><year4>');
                ServiceCharge := RefPmtExport."Foreign Banks Service Fee";

                if VendBankAcc."SWIFT Code" = '' then
                    CountryCode := VendBankAcc."Country/Region Code";
                SWIFTCode := TextSpaceFormat(VendBankAcc."SWIFT Code", 11, 1, ' ');
                RecieversInfo[1] := TextSpaceFormat(Vend.Name, 35, 1, ' ');
                RecieversInfo[2] := TextSpaceFormat(Vend.Address, 35, 1, ' ');
                RecieversInfo[3] := TextSpaceFormat(Vend."Address 2", 35, 1, ' ');
                RecieversInfo[4] := TextSpaceFormat(Vend."Post Code" + ' ' + Vend.City, 35, 1, ' ');

                if VendBankAcc."Clearing Code" <> '' then begin
                    if CopyStr(VendBankAcc."Clearing Code", 1, 2) <> '//' then
                        VendBankAcc."Clearing Code" := '//' + VendBankAcc."Clearing Code";
                    RecieversBank[1] := TextSpaceFormat(VendBankAcc."Clearing Code", 35, 1, ' ');
                    RecieversBank[2] := TextSpaceFormat('', 35, 1, ' ');
                    RecieversBank[3] := TextSpaceFormat('', 35, 1, ' ');
                    RecieversBank[4] := TextSpaceFormat('', 35, 1, ' ');
                end else begin
                    RecieversBank[1] := TextSpaceFormat(VendBankAcc.Name, 35, 1, ' ');
                    RecieversBank[2] := TextSpaceFormat(VendBankAcc.Address, 35, 1, ' ');
                    RecieversBank[3] := TextSpaceFormat(VendBankAcc."Address 2", 35, 1, ' ');
                    RecieversBank[4] := TextSpaceFormat(VendBankAcc."Post Code" + ' ' + VendBankAcc.City, 35, 1, ' ');
                end;

                PaymentSubject[1] := TextSpaceFormat(CopyStr(RefPmtExport."Invoice Message", 1, 35), 35, 1, ' ');
                PaymentSubject[2] := TextSpaceFormat(CopyStr(RefPmtExport."Invoice Message", 36, 35), 35, 1, ' ');
                PaymentSubject[3] := TextSpaceFormat(' ', 35, 1, ' ');
                PaymentSubject[4] := TextSpaceFormat(' ', 35, 1, ' ');

                RecieverAcc := TextSpaceFormat(VendBankAcc."Bank Account No.", 34, 1, ' ');
                if RecieverIBAN <> '' then
                    RecieverAcc := TextSpaceFormat(RecieverIBAN, 34, 1, ' ');
                Amount := TextSpaceFormat(Format(RefPmtExport.Amount * 100, 0, 2), 15, 0, '0');
                ExchangeRateNo := TextSpaceFormat(RefFileSetup."Exchange Rate Contract No.", 14, 1, ' ');
                EquivalentValue := TextSpaceFormat('0', 15, 1, '0');
                PaymentExchangeRate := TextSpaceFormat('0', 11, 1, '0');
                ChargedAmount := TextSpaceFormat('0', 15, 1, '0');
                FileingCode := TextSpaceFormat(' ', 20, 1, ' ');
                PaymentType := TextSpaceFormat(RefPmtExport."Foreign Payment Method", 20, 1, ' ');

                PaymentsAmountDec := PaymentsAmountDec + RefPmtExport.Amount;
                RowCounter := RowCounter + 1;

                Window.Update(4, RowCounter);
                TransferFile.Write(FileID + RecID + ' ' + RecieversInfo[1] + RecieversInfo[2] +
                  RecieversInfo[3] + RecieversInfo[4] + CountryCode + SWIFTCode + RecieversBank[1] +
                  RecieversBank[2] + RecieversBank[3] + RecieversBank[4] + RecieverAcc +
                  PaymentSubject[1] + PaymentSubject[2] + PaymentSubject[3] + PaymentSubject[4] +
                  Amount + Currency + '   ' + ExchangeRateNo + PaymentType + ServiceCharge + TransPaymentDate +
                  EquivalentValue + PaymentExchangeRate + ChargingAcc + ChargingAccCurrency +
                  ChargedAmount + FileingCode + FeedbackCurrency + '   ');

                if DueDateType = 0 then
                    RefPmtExport."Payment Date" := BatchDate;
                PaymentsQty := IncStr(PaymentsQty);
                RefPmtExport.Transferred := true;
                RefPmtExport.Modify();
                RefPmtExport.MarkAffiliatedAsTransferred();
            until RefPmtExport.Next() = 0;
    end;

    local procedure TextSpaceFormat(Text: Text[250]; Length: Integer; Align: Integer; ExtraChr: Text[1]) NewText: Text[250]
    begin
        if StrLen(Text) > Length then begin
            NewText := CopyStr(Text, 1, Length);
            exit(NewText);
        end;

        if Align = 0 then
            Text := PadStr('', Length - StrLen(Text), ExtraChr) + Text
        else
            Text := Text + PadStr('', Length - StrLen(Text), ExtraChr);

        NewText := Text;
    end;

    procedure GetFileName(): Text[1024]
    begin
        exit(ServerFileName);
    end;

    procedure InitializeRequest(NewHideFileDialog: Boolean)
    begin
        HideFileDialog := NewHideFileDialog;
    end;
}

