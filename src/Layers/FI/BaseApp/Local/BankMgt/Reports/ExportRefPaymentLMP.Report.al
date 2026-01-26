// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.IO;

report 32000006 "Export Ref. Payment -  LMP"
{
    Caption = 'Export Ref. Payment -  LMP';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {

            trigger OnAfterGetRecord()
            begin
                RefPmtExport.SetCurrentKey("Payment Date", "Vendor No.", "Entry No.");
                RefPmtExport.SetFilter("Payment Account", "Bank Account"."No.");
                RefPmtExport.SetRange("Foreign Payment", false);
                RefPmtExport.SetRange("Document Type", 2);
                RefPmtExport.SetRange(Transferred, false);
                if RefPmtExport.FindSet() then begin
                    RefFileSetup.SetFilter("No.", "Bank Account"."No.");
                    if not RefFileSetup.FindFirst() then
                        Error(Text1090000, "Bank Account"."No.");

                    RefPmtExport.TestField("Vendor No.");
                    RefPmtExport.TestField("Payment Account");
                    RefPmtExport.TestField("Payment Date");
                    RefPmtExport.TestField("Amount (LCY)");
                    RefPmtExport.TestField("Vendor Account");
                    RefPmtExport.TestField("Invoice Message");
                    CreatedLines := true;
                    Transferfile.Create(ServerFileName);
                    BankAccFormat.ConvertBankAcc("Bank Account"."Bank Account No.", "Bank Account"."No.");
                    BankAccNo := "Bank Account"."Bank Account No.";

                    BusinessIDCode := CompanyInfo."Business Identity Code";
                    LinePos := StrPos(CompanyInfo."Business Identity Code", '-');
                    if LinePos > 0 then
                        BusinessIDCode := CopyStr(BusinessIDCode, 1, LinePos - 1) + CopyStr(BusinessIDCode, LinePos + 1);

                    if CopyStr(BankAccNo, 1, 1) = '3' then
                        RecievingBankId := CopyStr(BankAccNo, 1, 2)
                    else
                        RecievingBankId := CopyStr(BankAccNo, 1, 1) + ' ';

                    CreationDate := Format(Today, 0, '<Year,2><Month,2><Day,2>');
                    CreationTime := Format(Time, 0, '<Hour,2><Filler Character,0><Minute,2>');

                    PaymentQty := '0';
                    AmountSum := 0;
                    CurrencyCode := '1';
                    PayersNameSpecifier := TextSpaceFormat(CompanyInfo.Name, 35, 1, ' ');
                    OVTCode := TextSpaceFormat(' ', 17, 1, ' ');
                    BusinessIDCode := TextSpaceFormat(BusinessIDCode, 9, 0, '0');
                    SpareHeder := TextSpaceFormat(' ', 65, 0, ' ');
                    ReservedForBank := TextSpaceFormat(' ', 100, 0, ' ');

                    CreateHeaderLines();
                    CreateTransactionlines();
                    CreateSumLines();
                end;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                GLSetup.Get();
                PurchSetup.Get();
                Transferfile.TextMode := true;
                ServerFileName := FileMgt.ServerTempFileName('txt');
                UniqueBatchID := '';
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
            Transferfile.Close();
            if not HideFileDialog then begin
                if not FileMgt.DownloadHandler(ServerFileName, '', '', '', 'fidompay.txt') then
                    Error('');
                Erase(ServerFileName);
            end;
        end else
            Message(Text1090003);
    end;

    var
        CompanyInfo: Record "Company Information";
        PurchSetup: Record "Purchases & Payables Setup";
        RefFileSetup: Record "Reference File Setup";
        Vend: Record Vendor;
        VendBankAcc: Record "Vendor Bank Account";
        VendLedgEntry: Record "Vendor Ledger Entry";
        RefPmtExport: Record "Ref. Payment - Exported";
        GLSetup: Record "General Ledger Setup";
        RefPmtMgt: Codeunit "Ref. Payment Management";
        BankAccFormat: Codeunit "Bank Nos Check";
        FileMgt: Codeunit "File Management";
        Transferfile: File;
        CreatedLines: Boolean;
        HideFileDialog: Boolean;
        EventType: Text[1];
        BankAccNo: Text[14];
        BusinessIDCode: Text[9];
        CreationDate: Text[6];
        CreationTime: Text[4];
        RecievingBankId: Text[2];
        DueDate: Text[6];
        PrevPaymDate: Date;
        PayersNameSpecifier: Text[35];
        UniqueBatchID: Code[35];
        UniqueBatchID2: Text[35];
        OVTCode: Text[17];
        CurrencyCode: Text[1];
        RecieverInfo: array[3] of Text[30];
        RecieverBankAccNo: Text[14];
        MessageType: Text[30];
        InvoiceMessage: Text[250];
        InvoiceMessage2: Text[250];
        Amount: Text[12];
        InternalInfo: Text[20];
        CostCenter: Text[20];
        Spare1: Text[3];
        Spare2: Text[2];
        Spare3: Text[1];
        Spare4: Text[4];
        Spare5: Text[12];
        Spare6: Text[5];
        Spare7: Text[6];
        Spare8: Text[13];
        Spare9: Text[6];
        Spare10: Text[69];
        Spare11: Text[20];
        Spare12: Text[21];
        ReservedForBank: Text[100];
        SpareHeder: Text[65];
        LinePos: Integer;
        AmountSum: Decimal;
        AmountSum2: Text[13];
        PaymentQty: Text[6];
        Text1090000: Label 'Define the transfer settings for Bank Account  %1.';
        Text1090003: Label 'There is nothing to send.';
        Text1090005: Label 'Credit memo %1 ';
        ServerFileName: Text;

    procedure CreateHeaderLines()
    var
        NoSeries: Codeunit "No. Series";
    begin
        UniqueBatchID := NoSeries.GetNextNo(PurchSetup."Bank Batch Nos.");
        UniqueBatchID2 := TextSpaceFormat(UniqueBatchID, 35, 1, ' ');
        DueDate := Format(RefPmtExport."Payment Date", 0, '<Year,2><Month,2><Day,2>');

        Transferfile.Write('LM0300' + BankAccNo +
          BusinessIDCode + CreationDate +
          CreationTime + RecievingBankId + DueDate +
          PayersNameSpecifier + RefPmtMgt.OEM2ANSI(UniqueBatchID2) +
          OVTCode + CurrencyCode + SpareHeder + ReservedForBank);
    end;

    procedure CreateTransactionlines()
    begin
        if RefPmtExport.FindSet() then
            repeat
                if (PrevPaymDate <> 0D) and (PrevPaymDate <> RefPmtExport."Payment Date") then begin
                    CreateSumLines();
                    UniqueBatchID := IncStr(UniqueBatchID);
                    CreateHeaderLines();
                end;
                Vend.Get(RefPmtExport."Vendor No.");
                RecieverBankAccNo := GetVendAccount(RefPmtExport."Vendor Account", Vend."No.");
                case RefPmtExport."Message Type" of
                    0:
                        MessageType := '1';
                    1:
                        MessageType := '2';
                    2:
                        MessageType := '5';
                    3:
                        MessageType := '6';
                    4:
                        MessageType := '7';
                end;

                InvoiceMessage := RefPmtExport."Invoice Message";
                InvoiceMessage2 := RefPmtExport."Invoice Message 2";

                if MessageType = '1' then
                    InvoiceMessage := TextSpaceFormat(InvoiceMessage, 20, 0, '0');
                if MessageType = '6' then
                    InvoiceMessage := CopyStr(InvoiceMessage, 1, 70);
                if MessageType = '7' then begin
                    InvoiceMessage := CopyStr(InvoiceMessage, 1, 20);
                    InvoiceMessage := TextSpaceFormat(InvoiceMessage, 35, 1, ' ');
                    InvoiceMessage := InvoiceMessage + CopyStr(InvoiceMessage2, 1, 35);
                end;

                InvoiceMessage := TextSpaceFormat(InvoiceMessage, 70, 1, ' ');
                DueDate := Format(RefPmtExport."Payment Date", 0, '<Year,2><Month,2><Day,2>');
                Amount := Format(Round(RefPmtExport."Amount (LCY)", 0.01) * 100, 0, 2);
                EventType := '0';
                Spare1 := TextSpaceFormat(' ', 3, 1, ' ');
                Spare2 := TextSpaceFormat(' ', 2, 1, ' ');
                Spare3 := TextSpaceFormat(' ', 1, 1, ' ');
                Spare4 := TextSpaceFormat(' ', 4, 1, ' ');
                Spare5 := TextSpaceFormat(' ', 12, 1, ' ');
                Spare6 := TextSpaceFormat(' ', 5, 1, ' ');
                Amount := TextSpaceFormat(Amount, 12, 0, '0');
                RecieverInfo[1] := TextSpaceFormat(Vend.Name, 30, 1, ' ');
                RecieverInfo[2] := TextSpaceFormat(' ', 20, 1, ' ');
                RecieverInfo[3] := TextSpaceFormat(Vend."Business Identity Code", 20, 1, ' ');
                CostCenter := TextSpaceFormat(CostCenter, 20, 1, ' ');
                InternalInfo := TextSpaceFormat(InternalInfo, 20, 1, ' ');
                ReservedForBank := '';
                ReservedForBank := TextSpaceFormat(ReservedForBank, 40, 1, ' ');
                AmountSum := AmountSum + Round(RefPmtExport."Amount (LCY)", 0.01);
                VendLedgEntry.SetRange(Open, false);
                VendLedgEntry.SetRange("Closed by Entry No.", RefPmtExport."Entry No.");

                if RefFileSetup."Inform. of Appl. Cr. Memos" then
                    if VendLedgEntry.FindFirst() then begin
                        MessageType := '5';
                        InvoiceMessage := TextSpaceFormat('', 70, 1, ' ');
                    end;

                Transferfile.Write('LM031' + EventType + BankAccNo +
                  RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + RefPmtMgt.OEM2ANSI(RecieverInfo[2]) +
                  RefPmtMgt.OEM2ANSI(RecieverInfo[3]) + RecieverBankAccNo +
                  Spare1 + MessageType + RefPmtMgt.OEM2ANSI(InvoiceMessage) + Spare2 +
                  DueDate + Amount + Spare3 + Spare4 + Spare5 + InternalInfo +
                  CostCenter + Spare6 + ReservedForBank);
                PaymentQty := IncStr(PaymentQty);
                PrevPaymDate := RefPmtExport."Payment Date";

                RefPmtExport.Transferred := true;
                RefPmtExport."Transfer Date" := Today;
                RefPmtExport."Transfer Time" := Time;
                RefPmtExport."Batch Code" := UniqueBatchID2;
                RefPmtExport.Modify();

                if RefFileSetup."Inform. of Appl. Cr. Memos" then
                    if VendLedgEntry.FindFirst() then
                        CreateDetailLines(VendLedgEntry, RefPmtExport."Entry No.");

                if MessageType > '5' then
                    CreateMessageLines(MessageType, RefPmtExport."Invoice Message", RefPmtExport."Invoice Message 2", '1');

            until RefPmtExport.Next() = 0;
    end;

    procedure CreateDetailLines(Rec: Record "Vendor Ledger Entry"; EntryNo: Integer)
    begin
        Rec.Get(EntryNo);
        Rec.SetRange(Open, false);
        Rec.SetRange("Closed by Entry No.", RefPmtExport."Entry No.");
        repeat
            case Rec."Message Type" of
                0:
                    MessageType := '1';
                1:
                    MessageType := '2';
                2:
                    MessageType := '5';
                3:
                    MessageType := '6';
                4:
                    MessageType := '7';
            end;
            InvoiceMessage := Rec."Invoice Message";
            InvoiceMessage2 := Rec."Invoice Message 2";

            if MessageType = '1' then
                InvoiceMessage := TextSpaceFormat(InvoiceMessage, 20, 0, '0');
            if Rec."Document Type" = "Gen. Journal Document Type"::Invoice then
                EventType := '0'
            else
                EventType := '2';

            if EventType = '2' then begin
                MessageType := '5';
                InvoiceMessage := StrSubstNo(Text1090005, Rec."External Document No.");
            end;

            Rec.CalcFields("Original Amt. (LCY)");
            InvoiceMessage := TextSpaceFormat(InvoiceMessage, 70, 1, ' ');
            Amount := TextSpaceFormat(Format(Round(Abs(Rec."Original Amt. (LCY)"), 0.01) * 100, 0, 2), 12, 0, '0');
            Transferfile.Write('LM032' + EventType + BankAccNo +
              RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + RefPmtMgt.OEM2ANSI(RecieverInfo[2]) +
              RefPmtMgt.OEM2ANSI(RecieverInfo[3]) + RecieverBankAccNo +
              Spare1 + MessageType + RefPmtMgt.OEM2ANSI(InvoiceMessage) +
              Spare2 + DueDate + Amount + Spare3 + Spare4 + Spare5 + InternalInfo +
              CostCenter + Spare6 + ReservedForBank);

            if MessageType > '5' then
                CreateMessageLines(MessageType, InvoiceMessage, InvoiceMessage2, '2');

        until Rec.Next() = 0;
    end;

    procedure CreateMessageLines(MsgType: Text[1]; InvMsg: Text[250]; InvMsg2: Text[250]; LineType: Text[1])
    var
        Len: Integer;
        Msg1: Text[175];
        Msg2: Text[175];
    begin
        Spare11 := TextSpaceFormat(' ', 20, 1, ' ');
        Spare12 := TextSpaceFormat(' ', 21, 1, ' ');

        case MsgType of
            '6':
                begin
                    Len := StrLen(InvMsg + InvMsg2) - 70;
                    if Len > 175 then begin
                        Msg1 := CopyStr(InvMsg, 71, 175);
                        Msg2 := CopyStr(InvMsg + InvMsg2, 175 + 71);
                        InvMsg := TextSpaceFormat(Msg1, 175, 1, ' ');
                        InvMsg2 := TextSpaceFormat(Msg2, 175, 1, ' ');
                        Transferfile.Write('LM03' + LineType + '9' + BankAccNo +
                          RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + Spare11 + Spare11 + RecieverBankAccNo +
                          RefPmtMgt.OEM2ANSI(InvMsg) + Spare12);
                        Transferfile.Write('LM03' + LineType + '9' + BankAccNo +
                          RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + Spare11 + Spare11 + RecieverBankAccNo +
                          RefPmtMgt.OEM2ANSI(InvMsg2) + Spare12);
                    end else begin
                        InvMsg := TextSpaceFormat(InvMsg, 175, 1, ' ');
                        Transferfile.Write('LM03' + LineType + '9' + BankAccNo +
                          RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + Spare11 + Spare11 + RecieverBankAccNo +
                          RefPmtMgt.OEM2ANSI(InvMsg) + Spare12);
                    end;
                end;
            '7':
                begin
                    Len := StrLen(InvMsg2) - 35;
                    if Len > 175 then begin
                        Msg1 := CopyStr(InvMsg2, 36, 175);
                        Msg2 := CopyStr(InvMsg2, 211);
                        Msg1 := TextSpaceFormat(Msg1, 175, 1, ' ');
                        Msg2 := TextSpaceFormat(Msg2, 175, 1, ' ');
                        Transferfile.Write('LM03' + LineType + '9' + BankAccNo +
                          RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + Spare11 + Spare11 + RecieverBankAccNo +
                          RefPmtMgt.OEM2ANSI(Msg1) + Spare12);
                        Transferfile.Write('LM03' + LineType + '9' + BankAccNo +
                          RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + Spare11 + Spare11 + RecieverBankAccNo +
                          RefPmtMgt.OEM2ANSI(Msg2) + Spare12);
                    end else begin
                        Msg1 := CopyStr(InvMsg2, 36);
                        Msg1 := TextSpaceFormat(Msg1, 175, 1, ' ');
                        Transferfile.Write('LM03' + LineType + '9' + BankAccNo +
                          RefPmtMgt.OEM2ANSI(RecieverInfo[1]) + Spare11 + Spare11 + RecieverBankAccNo +
                          RefPmtMgt.OEM2ANSI(Msg1) + Spare12);
                    end;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateSumLines()
    begin
        Spare7 := TextSpaceFormat(' ', 6, 0, ' ');
        Spare8 := TextSpaceFormat(' ', 13, 0, ' ');
        Spare9 := TextSpaceFormat(' ', 6, 0, ' ');
        Spare10 := TextSpaceFormat(' ', 69, 0, ' ');
        ReservedForBank := TextSpaceFormat(ReservedForBank, 100, 0, ' ');
        PaymentQty := TextSpaceFormat(PaymentQty, 6, 0, '0');
        AmountSum2 := TextSpaceFormat(Format(Round(AmountSum, 0.01) * 100, 0, 2), 13, 0, '0');

        Transferfile.Write(
          'LM0390' + BankAccNo + BusinessIDCode + CreationDate + PaymentQty +
          AmountSum2 + Spare7 + Spare8 + Spare9 + RefPmtMgt.OEM2ANSI(UniqueBatchID2) +
          OVTCode + Spare10 + ReservedForBank);

        PaymentQty := '0';
        AmountSum := 0;
    end;

    procedure GetVendAccount(AccountCode: Code[20]; VendNo: Code[20]) VendAccount: Text[14]
    begin
        VendBankAcc.Reset();
        VendBankAcc.SetFilter("Vendor No.", VendNo);
        VendBankAcc.SetRange(Code, AccountCode);
        VendBankAcc.FindFirst();
        BankAccFormat.ConvertBankAcc(VendBankAcc."Bank Account No.", VendBankAcc.Code);
        VendAccount := VendBankAcc."Bank Account No.";
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

