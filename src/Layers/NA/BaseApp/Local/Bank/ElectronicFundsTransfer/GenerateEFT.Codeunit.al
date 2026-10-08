// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.IO;

codeunit 10098 "Generate EFT"
{

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        DummyLastEFTExportWorkset: Record "EFT Export Workset";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        DataCompression: Codeunit "Data Compression";
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        ACHFileCreated: Boolean;
        IATFileCreated: Boolean;
        Path: Text;
        NothingToExportErr: Label 'There is nothing to export.';
        ProcessOrderNo: Integer;
        GeneratingFileMsg: Label 'The electronic funds transfer file is now being generated.';
        ZipFileName: Text;

    procedure ProcessAndGenerateEFTFile(BalAccountNo: Code[20]; SettlementDate: Date; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; var EFTValues: Codeunit "EFT Values")
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ExportEFTACH: Codeunit "Export EFT (ACH)";
        Window: Dialog;
    begin
        InitialChecks(BalAccountNo);
        OnProcessAndGenerateEFTFileOnAfterInitialChecks(SettlementDate, TempEFTExportWorkset);
        GenJnlLineChecks(TempEFTExportWorkset);

        ACHFileCreated := false;
        IATFileCreated := false;

        Window.Open(GeneratingFileMsg);

        TempEFTExportWorkset.SetRange("Bank Payment Type", 3, 3);
        OnProcessAndGenerateEFTFileOnAfterBankPaymentTypeSetFilters3(TempEFTExportWorkset);
        if TempEFTExportWorkset.FindFirst() then
            StartEFTProcess(SettlementDate, TempEFTExportWorkset, EFTValues);

        EFTValues.SetParentDefCode('');

        TempEFTExportWorkset.Reset();
        TempEFTExportWorkset.SetRange("Bank Payment Type", 4, 4);
        OnProcessAndGenerateEFTFileOnAfterBankPaymentTypeSetFilters4(TempEFTExportWorkset);
        if TempEFTExportWorkset.FindFirst() then
            StartEFTProcess(SettlementDate, TempEFTExportWorkset, EFTValues);

        if EFTValues.GetIATFileCreated() or EFTValues.GetEFTFileCreated() then
            if CustomLayoutReporting.IsWebClient() then
                ExportEFTACH.DownloadWebclientZip(TempNameValueBuffer, ZipFileName, DataCompression);

        Window.Close();
    end;

    local procedure InitialChecks(BankAccountNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitalChecks(BankAccountNo, IsHandled);
        if IsHandled then
            exit;

        BankAccount.LockTable();
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField(Blocked, false);
        BankAccount.TestField("Export Format");
        BankAccount.TestField("Last Remittance Advice No.");
    end;

    procedure GenJnlLineChecks(var EFTExportWorkset: Record "EFT Export Workset" temporary)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if EFTExportWorkset.FindSet() then
            repeat
                if GenJnlLine.Get(EFTExportWorkset."Journal Template Name", EFTExportWorkset."Journal Batch Name", EFTExportWorkset."Line No.") then
                    CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Check Line", GenJnlLine);
            until EFTExportWorkset.Next() = 0;
    end;

    local procedure CheckAndStartExport(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; var EFTValues: Codeunit "EFT Values")
    var
        ExpLauncherEFT: Codeunit "Exp. Launcher EFT";
    begin
        if (not ACHFileCreated and
            (TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment")) or
           (not IATFileCreated and
            (TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment-IAT"))
        then begin
            if not TempEFTExportWorkset.FindSet() then
                Error(NothingToExportErr);

            ExpLauncherEFT.EFTPaymentProcess(TempEFTExportWorkset, TempNameValueBuffer, DataCompression, ZipFileName, EFTValues);
        end;
    end;

    procedure SetGenJrnlCheckTransmitted(EFTExportWorkset: Record "EFT Export Workset")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", EFTExportWorkset."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", EFTExportWorkset."Journal Batch Name");
        GenJournalLine.SetRange("Line No.", EFTExportWorkset."Line No.");
        GenJournalLine.SetRange("EFT Export Sequence No.", EFTExportWorkset."Sequence No.");
        if GenJournalLine.FindFirst() then begin
            GenJournalLine."Check Transmitted" := true;
            GenJournalLine.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetSavePath(SavePath: Text)
    begin
        // This allows us to set the path ahead of setting request parameters if we know it or need to set it ahead of time
        // e.g. for unit tests
        Path := SavePath;
    end;

    [Scope('OnPrem')]
    procedure UpdateEFTExport(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    var
        EFTExport: Record "EFT Export";
    begin
        EFTExport.Get(TempEFTExportWorkset."Journal Template Name", TempEFTExportWorkset."Journal Batch Name",
          TempEFTExportWorkset."Line No.", TempEFTExportWorkset."Sequence No.");
        EFTExport."Posting Date" := TempEFTExportWorkset.UserSettleDate;
        EFTExport."Check Printed" := true;
        EFTExport."Check Exported" := true;
        EFTExport."Exported to Payment File" := true;
        EFTExport.Transmitted := true;
        EFTExport.Modify();
        SetGenJrnlCheckTransmitted(TempEFTExportWorkset);
    end;

    local procedure StartEFTProcess(SettlementDate: Date; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; var EFTValues: Codeunit "EFT Values")
    var
        DummyVendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        LocalBankAccount: Record "Bank Account";
        CheckDigitCheck: Boolean;
    begin
        ProcessOrderNo := 1;

        if TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment-IAT" then begin
            TempEFTExportWorkset.SetCurrentKey("Account Type", "Account No.", "Foreign Exchange Indicator", "Foreign Exchange Ref.Indicator",
              "Foreign Exchange Reference");
            DummyLastEFTExportWorkset."Account Type" := TempEFTExportWorkset."Account Type";
            DummyLastEFTExportWorkset."Account No." := TempEFTExportWorkset."Account No.";
            DummyLastEFTExportWorkset."Foreign Exchange Indicator" := TempEFTExportWorkset."Foreign Exchange Indicator";
            DummyLastEFTExportWorkset."Foreign Exchange Ref.Indicator" := TempEFTExportWorkset."Foreign Exchange Ref.Indicator";
            DummyLastEFTExportWorkset."Foreign Exchange Reference" := TempEFTExportWorkset."Foreign Exchange Reference";
        end;

        repeat
            TempEFTExportWorkset.Pathname := CopyStr(Path, 1, MaxStrLen(TempEFTExportWorkset.Pathname));
            TempEFTExportWorkset.UserSettleDate := SettlementDate;
            if TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment-IAT" then
                if (DummyLastEFTExportWorkset."Account Type" <> TempEFTExportWorkset."Account Type") or
                   (DummyLastEFTExportWorkset."Account No." <> TempEFTExportWorkset."Account No.") or
                   (DummyLastEFTExportWorkset."Foreign Exchange Indicator" <> TempEFTExportWorkset."Foreign Exchange Indicator") or
                   (DummyLastEFTExportWorkset."Foreign Exchange Ref.Indicator" <> TempEFTExportWorkset."Foreign Exchange Ref.Indicator") or
                   (DummyLastEFTExportWorkset."Foreign Exchange Reference" <> TempEFTExportWorkset."Foreign Exchange Reference")
                then begin
                    ProcessOrderNo := ProcessOrderNo + 1;
                    TempEFTExportWorkset.ProcessOrder := ProcessOrderNo;
                    DummyLastEFTExportWorkset."Account Type" := TempEFTExportWorkset."Account Type";
                    DummyLastEFTExportWorkset."Account No." := TempEFTExportWorkset."Account No.";
                    DummyLastEFTExportWorkset."Foreign Exchange Indicator" := TempEFTExportWorkset."Foreign Exchange Indicator";
                    DummyLastEFTExportWorkset."Foreign Exchange Ref.Indicator" := TempEFTExportWorkset."Foreign Exchange Ref.Indicator";
                    DummyLastEFTExportWorkset."Foreign Exchange Reference" := TempEFTExportWorkset."Foreign Exchange Reference";
                end else
                    TempEFTExportWorkset.ProcessOrder := ProcessOrderNo;
            if TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment" then
                TempEFTExportWorkset.ProcessOrder := 1;
            TempEFTExportWorkset.Modify();
        until TempEFTExportWorkset.Next() = 0;
        Commit();

        if TempEFTExportWorkset.FindFirst() then
            repeat
                LocalBankAccount.Get(TempEFTExportWorkset."Bank Account No.");
                CheckDigitCheck := not (LocalBankAccount."Export Format" in [LocalBankAccount."Export Format"::CA, LocalBankAccount."Export Format"::MX]);
                ExportPaymentsACH.CheckVendorTransitNum(TempEFTExportWorkset, TempEFTExportWorkset."Account No.", DummyVendor, VendorBankAccount, CheckDigitCheck);
                VendorBankAccount.TestField("Bank Account No.");
            until TempEFTExportWorkset.Next() = 0;

        TempEFTExportWorkset.FindFirst();

        if ProcessOrderNo >= 1 then
            repeat
                TempEFTExportWorkset.SetRange(ProcessOrder, ProcessOrderNo, ProcessOrderNo);
                CheckAndStartExport(TempEFTExportWorkset, EFTValues);
                ProcessOrderNo := ProcessOrderNo - 1;
            until ProcessOrderNo = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAndGenerateEFTFileOnAfterBankPaymentTypeSetFilters3(var TempEFTExportWorkset: Record "EFT Export Workset" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAndGenerateEFTFileOnAfterBankPaymentTypeSetFilters4(var TempEFTExportWorkset: Record "EFT Export Workset" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitalChecks(BankAccountNo: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessAndGenerateEFTFileOnAfterInitialChecks(var SettlementDate: Date; var TempEFTExportWorkset: Record "EFT Export Workset")
    begin
    end;
}

