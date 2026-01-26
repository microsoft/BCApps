// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 10860 "Payment Management"
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm;

    trigger OnRun()
    begin
        CreatePaymentHeaders();
    end;

    var
        Text002: Label 'One or more acceptation codes are No.';
        Text003: Label 'One or more lines have an incorrect RIB code.';
        Text004: Label 'There is no Payment Header to create.';
        Text005: Label 'Ledger Posting';
        Text006: Label 'One or more due dates are not specified.';
        Text007: Label 'The action has been canceled.';
        Text008: Label 'The header RIB is not correct.';
        Text009: Label 'The combination of dimensions used in Payment Header %1 is blocked. %2.', Comment = '%1 - payment header no, %2 - dimension error';
        Text010: Label 'The combination of dimensions used in Payment Header %1, line no. %2 is blocked. %3.', Comment = '%1 - payment header no, %2 - payment line no, %3 - dimension error';
        InvPostingBuffer: array[2] of Record "Payment Post. Buffer" temporary;
        CustomerPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        Customer: Record Customer;
        Vendor: Record Vendor;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentLine: Record "Payment Line";
        OldPaymentLine: Record "Payment Line";
        StepLedger: Record "Payment Step Ledger";
        Step: Record "Payment Step";
        PaymentHeader: Record "Payment Header";
        PaymentClass: Record "Payment Class";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        N: Integer;
        Suffix: Text;
        EntryTypeDebit: Enum "Gen. Journal Account Type";
        EntryNoAccountDebit: Code[20];
        EntryPostGroupDebit: Code[20];
        EntryTypeCredit: Enum "Gen. Journal Account Type";
        EntryNoAccountCredit: Code[20];
        EntryPostGroupCredit: Code[20];
        GLEntryNoTmp: Integer;
        Text011: Label 'XX';
        Text012: Label 'Customer Posting Group %1 does not exist.';
        Text014: Label 'You must enter a G/L account for customer posting group %1.';
        Text016: Label 'A posted line cannot be deleted.';
        Text017: Label 'Source Code %1 does not exist.';
        HeaderAccountUsedGlobally: Boolean;
        Text018: Label 'You must specify a debit account number for step %1 of payment type %2.';
        Text019: Label 'You must specify a credit account number for step %1 of payment type %2.';
        Text020: Label 'You must specify an account number in the payment header.';
        Text022: Label 'The status of document %1 does not authorize archiving.';
        CheckDimVauePostingLineErr: Label 'A dimension used in %1 %2 %3 has caused an error. %4', Comment = '%1=Payment Header No., %2=tablecaption, %3=Payment Line No., %4=Error text';
        CheckDimVauePostingHeaderErr: Label 'A dimension used in %1 has caused an error. %2', Comment = '%1=Payment Header No., %2=Error text';
        Text100: Label 'Rounding on %1';

    local procedure ProcessPaymentStep(PaymentHeaderNo: Code[20]; PaymentStep: Record "Payment Step")
    var
        PaymentStatus: Record "Payment Status";
        ActionValidated: Boolean;
    begin
        OnBeforeProcessPaymentStep(PaymentHeaderNo, PaymentStep, PaymentLine);

        PaymentHeader.Get(PaymentHeaderNo);
        PaymentHeader.SetRange("No.", PaymentHeader."No.");

        if PaymentStep."Verify Header RIB" and not PaymentHeader."RIB Checked" then
            Error(Text008);

        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.SetRange("Copied To No.", '');

        if PaymentStep."Acceptation Code<>No" then begin
            PaymentLine.SetRange("Acceptation Code", PaymentLine."Acceptation Code"::No);
            if PaymentLine.Find('-') then
                Error(Text002);
            PaymentLine.SetRange("Acceptation Code");
        end;

        if PaymentStep."Verify Lines RIB" then begin
            PaymentLine.SetRange("RIB Checked", false);
            if PaymentLine.Find('-') then
                Error(Text003);
            PaymentLine.SetRange("RIB Checked");
        end;

        if PaymentStep."Verify Due Date" then begin
            PaymentLine.SetRange("Due Date", 0D);
            if PaymentLine.Find('-') then
                Error(Text006);
            PaymentLine.SetRange("Due Date");
        end;
        OnProcessPaymentStepOnAfterCheckPaymentStep(PaymentStep, PaymentHeader, PaymentLine);

        Step.Get(PaymentStep."Payment Class", PaymentStep.Line);

        ActionValidated := ProcessPaymentStepByActionType();

        if ActionValidated then begin
            PaymentHeader.Validate("Status No.", Step."Next Status");
            PaymentHeader.Modify();
            PaymentLine.SetRange("No.", PaymentHeader."No.");
            PaymentLine.ModifyAll("Status No.", Step."Next Status");
            PaymentStatus.Get(PaymentHeader."Payment Class", Step."Next Status");
            PaymentLine.ModifyAll("Payment in Progress", PaymentStatus."Payment in Progress");
        end else
            Message(Text007);

        OnAfterProcessPaymentStep(PaymentHeaderNo, PaymentStep);
    end;

    local procedure ProcessPaymentStepByActionType() ActionValidated: Boolean
    var
        Window: Dialog;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessPaymentStepByActionType(PaymentLine, Step, ActionValidated, IsHandled);
        if IsHandled then
            exit(ActionValidated);

        case Step."Action Type" of
            Step."Action Type"::None:
                exit(true);
            Step."Action Type"::"Cancel File":
                begin
                    PaymentHeader."File Export Completed" := false;
                    PaymentHeader.Modify();
                    exit(true);
                end;
            Step."Action Type"::File:
                begin
                    PaymentHeader."File Export Completed" := false;
                    PaymentHeader.Modify();
                    Commit();

                    case Step."Export Type" of
                        Step."Export Type"::Report:
                            REPORT.RunModal(Step."Export No.", true, false, PaymentHeader);
                        Step."Export Type"::XMLport:
                            RunXmlPortExport(Step."Export No.", PaymentHeader);
                    end;

                    PaymentHeader.Find();
                    exit(PaymentHeader."File Export Completed");
                end;
            Step."Action Type"::Report:
                begin
                    REPORT.RunModal(Step."Report No.", true, true, PaymentLine);
                    exit(true);
                end;
            Step."Action Type"::Ledger:
                begin
                    InvPostingBuffer[1].DeleteAll();
                    CheckDim();
                    Window.Open(
                      '#1#################################\\' +
                      Text005);
                    if PaymentLine.Find('-') then
                        repeat
                            Window.Update(1, Text005 + ' ' + PaymentLine."No." + ' ' + Format(PaymentLine."Line No."));
                            OldPaymentLine := PaymentLine;
                            HeaderAccountUsedGlobally := false;
                            GenerInvPostingBuffer();
                            PaymentLine."Acc. Type Last Entry Debit" := EntryTypeDebit;
                            PaymentLine."Acc. No. Last Entry Debit" := EntryNoAccountDebit;
                            PaymentLine."P. Group Last Entry Debit" := EntryPostGroupDebit;
                            PaymentLine."Acc. Type Last Entry Credit" := EntryTypeCredit;
                            PaymentLine."Acc. No. Last Entry Credit" := EntryNoAccountCredit;
                            PaymentLine."P. Group Last Entry Credit" := EntryPostGroupCredit;
                            PaymentLine.Validate("Status No.", Step."Next Status");
                            UpdateLastNoSeries();
                            PaymentLine.Posted := true;
                            PaymentLine.Modify();
                        until PaymentLine.Next() = 0;
                    Window.Close();
                    GenerEntries();
                    exit(true);
                end;
            else
                OnProcessPaymentStepOnCaseElse(Step, PaymentLine, ActionValidated, PaymentHeader);
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdtBuffer()
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        InvPostingBuffer[2] := InvPostingBuffer[1];
        if InvPostingBuffer[2].Find() then begin
            InvPostingBuffer[2].Validate(Amount, InvPostingBuffer[2].Amount + InvPostingBuffer[1].Amount);
            InvPostingBuffer[2]."Amount (LCY)" := Round(CurrExchRate.ExchangeAmtFCYToLCY(PaymentHeader."Posting Date",
                  PaymentHeader."Currency Code", InvPostingBuffer[2].Amount, PaymentHeader."Currency Factor"));
            InvPostingBuffer[2]."VAT Amount" :=
              InvPostingBuffer[2]."VAT Amount" + InvPostingBuffer[1]."VAT Amount";
            InvPostingBuffer[2]."Line Discount Amount" :=
              InvPostingBuffer[2]."Line Discount Amount" + InvPostingBuffer[1]."Line Discount Amount";
            if InvPostingBuffer[1]."Line Discount Account" <> '' then
                InvPostingBuffer[2]."Line Discount Account" := InvPostingBuffer[1]."Line Discount Account";
            InvPostingBuffer[2]."Inv. Discount Amount" :=
              InvPostingBuffer[2]."Inv. Discount Amount" + InvPostingBuffer[1]."Inv. Discount Amount";
            if InvPostingBuffer[1]."Inv. Discount Account" <> '' then
                InvPostingBuffer[2]."Inv. Discount Account" := InvPostingBuffer[1]."Inv. Discount Account";
            InvPostingBuffer[2]."VAT Base Amount" :=
              InvPostingBuffer[2]."VAT Base Amount" + InvPostingBuffer[1]."VAT Base Amount";
            InvPostingBuffer[2]."Amount (ACY)" :=
              InvPostingBuffer[2]."Amount (ACY)" + InvPostingBuffer[1]."Amount (ACY)";
            InvPostingBuffer[2]."VAT Amount (ACY)" :=
              InvPostingBuffer[2]."VAT Amount (ACY)" + InvPostingBuffer[1]."VAT Amount (ACY)";
            InvPostingBuffer[2]."VAT Difference" :=
              InvPostingBuffer[2]."VAT Difference" + InvPostingBuffer[1]."VAT Difference";
            InvPostingBuffer[2]."Line Discount Amt. (ACY)" :=
              InvPostingBuffer[2]."Line Discount Amt. (ACY)" +
              InvPostingBuffer[1]."Line Discount Amt. (ACY)";
            InvPostingBuffer[2]."Inv. Discount Amt. (ACY)" :=
              InvPostingBuffer[2]."Inv. Discount Amt. (ACY)" +
              InvPostingBuffer[1]."Inv. Discount Amt. (ACY)";
            InvPostingBuffer[2]."VAT Base Amount (ACY)" :=
              InvPostingBuffer[2]."VAT Base Amount (ACY)" +
              InvPostingBuffer[1]."VAT Base Amount (ACY)";
            InvPostingBuffer[2].Quantity :=
              InvPostingBuffer[2].Quantity + InvPostingBuffer[1].Quantity;
            if not InvPostingBuffer[1]."System-Created Entry" then
                InvPostingBuffer[2]."System-Created Entry" := false;
            InvPostingBuffer[2].Modify();
        end else begin
            GLEntryNoTmp += 1;
            InvPostingBuffer[1]."GL Entry No." := GLEntryNoTmp;
            InvPostingBuffer[1].Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyLigBor(var FromPaymentLine: Record "Payment Line"; NewStep: Integer; var PayNum: Code[20])
    var
        ToBord: Record "Payment Header";
        ToPaymentLine: Record "Payment Line";
        Step: Record "Payment Step";
        Process: Record "Payment Class";
        PaymentStatus: Record "Payment Status";
        NoSeries: Codeunit "No. Series";
        i: Integer;
    begin
        if FromPaymentLine.Find('-') then begin
            Step.Get(FromPaymentLine."Payment Class", NewStep);
            Process.Get(FromPaymentLine."Payment Class");
            if PayNum = '' then begin
                i := 10000;
                ToBord."No. Series" := Step."Header Nos. Series";
                ToBord."No." := NoSeries.GetNextNo(ToBord."No. Series");
                ToBord."Payment Class" := FromPaymentLine."Payment Class";
                ToBord."Status No." := Step."Next Status";
                PaymentStatus.Get(ToBord."Payment Class", ToBord."Status No.");
                ToBord."Archiving Authorized" := PaymentStatus."Archiving Authorized";
                ToBord."Currency Code" := FromPaymentLine."Currency Code";
                ToBord."Currency Factor" := FromPaymentLine."Currency Factor";
                OnCopyLigBorOnBeforeInitHeader(ToBord, Process, i);
                ToBord.InitHeader();
                ToBord.Insert();
            end else begin
                ToBord.Get(PayNum);
                ToPaymentLine.SetRange("No.", PayNum);
                if ToPaymentLine.FindLast() then
                    i := ToPaymentLine."Line No." + 10000
                else
                    i := 10000;
            end;
            repeat
                ToPaymentLine.Copy(FromPaymentLine);
                ToPaymentLine."No." := ToBord."No.";
                ToPaymentLine."Line No." := i;
                ToPaymentLine.IsCopy := true;
                ToPaymentLine."Status No." := Step."Next Status";
                ToPaymentLine."Copied To No." := '';
                ToPaymentLine."Copied To Line" := 0;
                ToPaymentLine.Posted := false;
                ToPaymentLine."Created from No." := FromPaymentLine."No.";
                ToPaymentLine."Dimension Set ID" := FromPaymentLine."Dimension Set ID";
                OnCopyLigBorOnBeforeToPaymentLineInsert(ToPaymentLine, Process);
                ToPaymentLine.Insert(true);
                FromPaymentLine."Copied To No." := ToPaymentLine."No.";
                FromPaymentLine."Copied To Line" := ToPaymentLine."Line No.";
                FromPaymentLine.Modify();
                i += 10000;
            until FromPaymentLine.Next() = 0;
            PayNum := ToBord."No.";
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteLigBorCopy(var FromPaymentLine: Record "Payment Line")
    var
        ToPaymentLine: Record "Payment Line";
    begin
        ToPaymentLine.SetCurrentKey("Copied To No.", "Copied To Line");

        if FromPaymentLine.Find('-') then
            if FromPaymentLine.Posted then
                Message(Text016)
            else
                repeat
                    ToPaymentLine.SetRange("Copied To No.", FromPaymentLine."No.");
                    ToPaymentLine.SetRange("Copied To Line", FromPaymentLine."Line No.");
                    ToPaymentLine.FindFirst();
                    ToPaymentLine."Copied To No." := '';
                    ToPaymentLine."Copied To Line" := 0;
                    ToPaymentLine.Modify();
                    FromPaymentLine.Delete(true);
                until FromPaymentLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GenerInvPostingBuffer()
    var
        PaymentClass: Record "Payment Class";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Description: Text[98];
    begin
        StepLedger.SetRange("Payment Class", Step."Payment Class");
        StepLedger.SetRange(Line, Step.Line);

        if StepLedger.Find('-') then begin
            repeat
                Clear(InvPostingBuffer[1]);
                SetPostingGroup();
                SetAccountNo();
                InvPostingBuffer[1]."System-Created Entry" := true;
                if StepLedger.Sign = StepLedger.Sign::Debit then begin
                    InvPostingBuffer[1].Validate(Amount, Abs(PaymentLine.Amount));
                    InvPostingBuffer[1].Validate("Amount (LCY)", Abs(PaymentLine."Amount (LCY)"));
                end else begin
                    InvPostingBuffer[1].Validate(Amount, Abs(PaymentLine.Amount) * -1);
                    InvPostingBuffer[1].Validate("Amount (LCY)", Abs(PaymentLine."Amount (LCY)") * -1);
                end;
                InvPostingBuffer[1]."Currency Code" := PaymentLine."Currency Code";
                InvPostingBuffer[1]."Currency Factor" := PaymentLine."Currency Factor";
                InvPostingBuffer[1].Correction := PaymentLine.Correction xor Step.Correction;
                if StepLedger."Detail Level" = StepLedger."Detail Level"::Line then
                    InvPostingBuffer[1]."Payment Line No." := PaymentLine."Line No."
                else
                    if StepLedger."Detail Level" = StepLedger."Detail Level"::"Due Date" then
                        InvPostingBuffer[1]."Due Date" := PaymentLine."Due Date";

                InvPostingBuffer[1]."Document Type" := StepLedger."Document Type";
                if StepLedger."Document No." = StepLedger."Document No."::"Header No." then
                    InvPostingBuffer[1]."Document No." := PaymentHeader."No."
                else begin
                    if (InvPostingBuffer[1].Sign = InvPostingBuffer[1].Sign::Positive) and
                       (PaymentLine."Entry No. Debit" = 0) and (PaymentLine."Entry No. Credit" = 0)
                    then
                        PaymentLine.TestField("Document No.");
                    InvPostingBuffer[1]."Document No." := PaymentLine."Document No.";
                end;
                InvPostingBuffer[1]."Header Document No." := PaymentHeader."No.";
                if StepLedger.Sign = StepLedger.Sign::Debit then begin
                    EntryTypeDebit := InvPostingBuffer[1]."Account Type";
                    EntryNoAccountDebit := InvPostingBuffer[1]."Account No.";
                    EntryPostGroupDebit := InvPostingBuffer[1]."Posting Group";
                end else begin
                    EntryTypeCredit := InvPostingBuffer[1]."Account Type";
                    EntryNoAccountCredit := InvPostingBuffer[1]."Account No.";
                    EntryPostGroupCredit := InvPostingBuffer[1]."Posting Group";
                end;
                InvPostingBuffer[1]."System-Created Entry" := true;
                Application();
                PaymentClass.Get(PaymentHeader."Payment Class");
                if (PaymentClass."Unrealized VAT Reversal" = PaymentClass."Unrealized VAT Reversal"::Delayed) and
                   Step."Realize VAT"
                then begin
                    InvPostingBuffer[1]."Applies-to Doc. Type" := PaymentLine."Applies-to Doc. Type";
                    InvPostingBuffer[1]."Applies-to Doc. No." := PaymentLine."Applies-to Doc. No.";
                    if InvPostingBuffer[1]."Applies-to ID" = '' then
                        InvPostingBuffer[1]."Applies-to ID" := PaymentLine."Applies-to ID";
                    InvPostingBuffer[1]."Created from No." := PaymentLine."Created from No.";
                end;
                Description := GetDescriptionForInvPostingBuffer();
                OnGenerInvPostingBufferOnAfterGetDescriptionForInvPostingBuffer(StepLedger, PaymentHeader, PaymentLine, Description);
                InvPostingBuffer[1].Description := CopyStr(Description, 1, 50);
                InvPostingBuffer[1]."Source Type" := PaymentLine."Account Type";
                InvPostingBuffer[1]."Source No." := PaymentLine."Account No.";
                InvPostingBuffer[1]."External Document No." := PaymentLine."External Document No.";
                InvPostingBuffer[1]."Dimension Set ID" := PaymentLine."Dimension Set ID";
                OnGenerInvPostingBufferOnBeforeUpdtBuffer(InvPostingBuffer, PaymentLine, StepLedger);
                UpdtBuffer();
                if (InvPostingBuffer[1].Amount >= 0) xor InvPostingBuffer[1].Correction then
                    PaymentLine."Entry No. Debit" := InvPostingBuffer[1]."GL Entry No."
                else
                    PaymentLine."Entry No. Credit" := InvPostingBuffer[1]."GL Entry No.";
            until StepLedger.Next() = 0;
            NoSeriesBatch.SaveState();
        end;
    end;

    local procedure GetDescriptionForInvPostingBuffer() Description: Text[98]
    begin
        Description :=
            StrSubstNo(StepLedger.Description, PaymentLine."Due Date", PaymentLine."Account No.", PaymentLine."Document No.");

        OnAfterGetDescriptionForInvPostingBuffer(StepLedger, PaymentLine, Description);
    end;

    [Scope('OnPrem')]
    procedure SetPostingGroup()
    var
        PostingGroup: Code[20];
    begin
        if PaymentLine."Account Type" = PaymentLine."Account Type"::Customer then
            if ((StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Payment Line Account") or
                (StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Associated G/L Account") or
                (StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Header Payment Account") or
                ((StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Setup Account") and
                 (StepLedger."Account Type" = StepLedger."Account Type"::Customer)))
            then begin
                if PaymentLine."Posting Group" <> '' then
                    PostingGroup := PaymentLine."Posting Group"
                else
                    if StepLedger."Customer Posting Group" <> '' then
                        PostingGroup := StepLedger."Customer Posting Group"
                    else begin
                        Customer.Get(PaymentLine."Account No.");
                        PostingGroup := Customer."Customer Posting Group";
                    end;
                OnSetPostingGroupOnBeforeCheckPostingGroup(PaymentLine, StepLedger, PostingGroup);
                if not CustomerPostingGroup.Get(PostingGroup) then
                    Error(Text012, PostingGroup);
                if CustomerPostingGroup."Receivables Account" = '' then
                    Error(Text014, PostingGroup);
            end;

        if PaymentLine."Account Type" = PaymentLine."Account Type"::Vendor then
            if ((StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Payment Line Account") or
                (StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Associated G/L Account") or
                (StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Header Payment Account") or
                ((StepLedger."Accounting Type" = StepLedger."Accounting Type"::"Setup Account") and
                 (StepLedger."Account Type" = StepLedger."Account Type"::Vendor)))
            then begin
                if PaymentLine."Posting Group" <> '' then
                    PostingGroup := PaymentLine."Posting Group"
                else
                    if StepLedger."Vendor Posting Group" <> '' then
                        PostingGroup := StepLedger."Vendor Posting Group"
                    else begin
                        Vendor.Get(PaymentLine."Account No.");
                        PostingGroup := Vendor."Vendor Posting Group";
                    end;
                if not VendorPostingGroup.Get(PostingGroup) then
                    Error(Text012, PostingGroup);
                if VendorPostingGroup."Payables Account" = '' then
                    Error(Text014, PostingGroup);
            end;
    end;

    local procedure UpdateLastNoSeries()
    var
        NoSeriesPaymentClass: Record "Payment Class";
        NoSeries: Codeunit "No. Series";
    begin
        NoSeriesPaymentClass.SetLoadFields("Line No. Series");
        NoSeriesPaymentClass.Get(PaymentHeader."Payment Class");
        if NoSeriesPaymentClass."Line No. Series" <> '' then
           if PaymentLine."Document No." = NoSeries.PeekNextNo(NoSeriesPaymentClass."Line No. Series", PaymentLine."Posting Date") then
              NoSeries.GetNextNo(NoSeriesPaymentClass."Line No. Series", PaymentLine."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure SetAccountNo()
    begin
        case StepLedger."Accounting Type" of
            StepLedger."Accounting Type"::"Payment Line Account":
                begin
                    InvPostingBuffer[1]."Account Type" := PaymentLine."Account Type";
                    InvPostingBuffer[1]."Account No." := PaymentLine."Account No.";
                    if PaymentLine."Account Type" = PaymentLine."Account Type"::Customer then
                        InvPostingBuffer[1]."Posting Group" := CustomerPostingGroup.Code;
                    if PaymentLine."Account Type" = PaymentLine."Account Type"::Vendor then
                        InvPostingBuffer[1]."Posting Group" := VendorPostingGroup.Code;
                    InvPostingBuffer[1]."Line No." := PaymentLine."Line No.";
                    DimMgt.UpdateGlobalDimFromDimSetID(PaymentLine."Dimension Set ID",
                      InvPostingBuffer[1]."Global Dimension 1 Code", InvPostingBuffer[1]."Global Dimension 2 Code");
                end;
            StepLedger."Accounting Type"::"Associated G/L Account":
                begin
                    InvPostingBuffer[1]."Account Type" := InvPostingBuffer[1]."Account Type"::"G/L Account";
                    if PaymentLine."Account Type" = PaymentLine."Account Type"::Customer then
                        InvPostingBuffer[1]."Account No." := CustomerPostingGroup."Receivables Account"
                    else
                        InvPostingBuffer[1]."Account No." := VendorPostingGroup."Payables Account";
                    InvPostingBuffer[1]."Line No." := PaymentLine."Line No.";
                end;
            StepLedger."Accounting Type"::"Setup Account":
                begin
                    InvPostingBuffer[1]."Account Type" := StepLedger."Account Type";
                    InvPostingBuffer[1]."Account No." := StepLedger."Account No.";
                    if StepLedger."Account No." = '' then begin
                        PaymentHeader.CalcFields("Payment Class Name");
                        if StepLedger.Sign = StepLedger.Sign::Debit then
                            Error(Text018, Step.Name, PaymentHeader."Payment Class Name");

                        Error(Text019, Step.Name, PaymentHeader."Payment Class Name");
                    end;
                    if StepLedger."Account Type" = StepLedger."Account Type"::Customer then
                        InvPostingBuffer[1]."Posting Group" := StepLedger."Customer Posting Group"
                    else
                        InvPostingBuffer[1]."Posting Group" := StepLedger."Vendor Posting Group";
                    InvPostingBuffer[1]."Line No." := PaymentLine."Line No.";
                end;
            StepLedger."Accounting Type"::"G/L Account / Month":
                begin
                    InvPostingBuffer[1]."Account Type" := InvPostingBuffer[1]."Account Type"::"G/L Account";
                    N := Date2DMY(PaymentLine."Due Date", 2);
                    if N < 10 then
                        Suffix := '0' + Format(N)
                    else
                        Suffix := Format(N);
                    InvPostingBuffer[1]."Account No." := CopyStr(StepLedger.Root + Suffix, 1, MaxStrLen(InvPostingBuffer[1]."Account No."));
                    InvPostingBuffer[1]."Line No." := PaymentLine."Line No.";
                end;
            StepLedger."Accounting Type"::"G/L Account / Week":
                begin
                    InvPostingBuffer[1]."Account Type" := InvPostingBuffer[1]."Account Type"::"G/L Account";
                    N := Date2DWY(PaymentLine."Due Date", 2);
                    if N < 10 then
                        Suffix := '0' + Format(N)
                    else
                        Suffix := Format(N);
                    InvPostingBuffer[1]."Account No." := CopyStr(StepLedger.Root + Suffix, 1, MaxStrLen(InvPostingBuffer[1]."Account No."));
                    InvPostingBuffer[1]."Line No." := PaymentLine."Line No.";
                end;
            StepLedger."Accounting Type"::"Bal. Account Previous Entry":
                begin
                    if (StepLedger.Sign = StepLedger.Sign::Debit) and not (PaymentLine.Correction xor Step.Correction) then begin
                        InvPostingBuffer[1]."Account Type" := PaymentLine."Acc. Type Last Entry Credit";
                        InvPostingBuffer[1]."Account No." := PaymentLine."Acc. No. Last Entry Credit";
                        InvPostingBuffer[1]."Posting Group" := PaymentLine."P. Group Last Entry Credit";
                    end else begin
                        InvPostingBuffer[1]."Account Type" := PaymentLine."Acc. Type Last Entry Debit";
                        InvPostingBuffer[1]."Account No." := PaymentLine."Acc. No. Last Entry Debit";
                        InvPostingBuffer[1]."Posting Group" := PaymentLine."P. Group Last Entry Debit";
                    end;
                    InvPostingBuffer[1]."Line No." := PaymentLine."Line No.";
                end;
            StepLedger."Accounting Type"::"Header Payment Account":
                begin
                    InvPostingBuffer[1]."Account Type" := PaymentHeader."Account Type";
                    InvPostingBuffer[1]."Account No." := PaymentHeader."Account No.";
                    if PaymentHeader."Account No." = '' then
                        Error(Text020);
                    if StepLedger."Detail Level" = StepLedger."Detail Level"::Account then
                        HeaderAccountUsedGlobally := true;
                    InvPostingBuffer[1]."Line No." := 0;
                    DimMgt.UpdateGlobalDimFromDimSetID(PaymentHeader."Dimension Set ID",
                      InvPostingBuffer[1]."Global Dimension 1 Code", InvPostingBuffer[1]."Global Dimension 2 Code");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure Application()
    begin
        if StepLedger.Application <> StepLedger.Application::None then
            if StepLedger.Application = StepLedger.Application::"Applied Entry" then begin
                InvPostingBuffer[1]."Applies-to Doc. Type" := PaymentLine."Applies-to Doc. Type";
                InvPostingBuffer[1]."Applies-to Doc. No." := PaymentLine."Applies-to Doc. No.";
                InvPostingBuffer[1]."Applies-to ID" := PaymentLine."Applies-to ID";
            end else
                if StepLedger.Application = StepLedger.Application::"Entry Previous Step" then begin
                    InvPostingBuffer[1]."Applies-to ID" := PaymentLine."No." + '/' + Format(PaymentLine."Line No.") + Text011;
                    if InvPostingBuffer[1]."Account Type" = InvPostingBuffer[1]."Account Type"::Customer then begin
                        if (InvPostingBuffer[1].Amount < 0) xor InvPostingBuffer[1].Correction then
                            CustLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Debit")
                        else
                            CustLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Credit");
                        if CustLedgerEntry.FindFirst() then begin
                            CustLedgerEntry."Applies-to ID" := InvPostingBuffer[1]."Applies-to ID";
                            CustLedgerEntry.CalcFields("Remaining Amount");
                            CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
                            CustLedgerEntry.Modify();
                        end;
                    end else
                        if InvPostingBuffer[1]."Account Type" = InvPostingBuffer[1]."Account Type"::Vendor then begin
                            if (InvPostingBuffer[1].Amount < 0) xor InvPostingBuffer[1].Correction then
                                VendorLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Debit")
                            else
                                VendorLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Credit");
                            if VendorLedgerEntry.FindFirst() then begin
                                VendorLedgerEntry."Applies-to ID" := InvPostingBuffer[1]."Applies-to ID";
                                VendorLedgerEntry.CalcFields("Remaining Amount");
                                VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
                                VendorLedgerEntry.Modify();
                            end;
                        end;
                end else
                    if StepLedger.Application = StepLedger.Application::"Memorized Entry" then begin
                        InvPostingBuffer[1]."Applies-to ID" := PaymentLine."No." + '/' + Format(PaymentLine."Line No.") + Text011;
                        if InvPostingBuffer[1]."Account Type" = InvPostingBuffer[1]."Account Type"::Customer then begin
                            CustLedgerEntry.Reset();
                            if (InvPostingBuffer[1].Amount < 0) xor InvPostingBuffer[1].Correction then
                                CustLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Debit Memo")
                            else
                                CustLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Credit Memo");
                            if CustLedgerEntry.FindFirst() then begin
                                CustLedgerEntry."Applies-to ID" := InvPostingBuffer[1]."Applies-to ID";
                                CustLedgerEntry.CalcFields("Remaining Amount");
                                CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
                                CustLedgerEntry.Modify();
                            end;
                        end else
                            if InvPostingBuffer[1]."Account Type" = InvPostingBuffer[1]."Account Type"::Vendor then begin
                                if (InvPostingBuffer[1].Amount < 0) xor InvPostingBuffer[1].Correction then
                                    VendorLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Debit Memo")
                                else
                                    VendorLedgerEntry.SetRange("Entry No.", OldPaymentLine."Entry No. Credit Memo");
                                if VendorLedgerEntry.FindFirst() then begin
                                    VendorLedgerEntry."Applies-to ID" := InvPostingBuffer[1]."Applies-to ID";
                                    VendorLedgerEntry.CalcFields("Remaining Amount");
                                    VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
                                    VendorLedgerEntry.Modify();
                                end;
                            end;
                    end;
        if StepLedger."Detail Level" = StepLedger."Detail Level"::Account then begin
            if (InvPostingBuffer[1]."Account Type" = InvPostingBuffer[1]."Account Type"::Vendor) or
               (InvPostingBuffer[1]."Account Type" = InvPostingBuffer[1]."Account Type"::Customer)
            then
                InvPostingBuffer[1]."Due Date" := PaymentLine."Due Date" // FR Payment due date
        end else
            InvPostingBuffer[1]."Due Date" := PaymentLine."Due Date"; // FR Payment due date

        OnAfterApplication(StepLedger, InvPostingBuffer, PaymentHeader, PaymentLine);
    end;

    [Scope('OnPrem')]
    procedure GenerEntries()
    var
        Currency: Record Currency;
        Difference: Decimal;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        LastGLEntryNo: Integer;
    begin
        if InvPostingBuffer[1].Find('+') then
            repeat
                LastGLEntryNo := PostInvPostingBuffer();
                PaymentLine.Reset();
                PaymentLine.SetRange("No.", PaymentHeader."No.");
                PaymentLine.SetRange("Line No.");
                if GenJnlLine.Amount >= 0 then begin
                    TotalDebit := TotalDebit + GenJnlLine."Amount (LCY)";
                    StepLedger.Get(Step."Payment Class", Step.Line, StepLedger.Sign::Debit);
                    PaymentLine.SetRange("Entry No. Debit", InvPostingBuffer[1]."GL Entry No.");
                    if StepLedger."Memorize Entry" then
                        PaymentLine.ModifyAll(PaymentLine."Entry No. Debit Memo", LastGLEntryNo);
                    PaymentLine.ModifyAll("Entry No. Debit", LastGLEntryNo);
                    PaymentLine.SetRange("Entry No. Debit");
                end else begin
                    TotalCredit := TotalCredit + Abs(GenJnlLine."Amount (LCY)");
                    StepLedger.Get(Step."Payment Class", Step.Line, StepLedger.Sign::Credit);
                    PaymentLine.SetRange("Entry No. Credit", InvPostingBuffer[1]."GL Entry No.");
                    if StepLedger."Memorize Entry" then
                        PaymentLine.ModifyAll(PaymentLine."Entry No. Credit Memo", LastGLEntryNo);
                    PaymentLine.ModifyAll("Entry No. Credit", LastGLEntryNo);
                    PaymentLine.SetRange("Entry No. Credit");
                end;
            until InvPostingBuffer[1].Next(-1) = 0;

        if HeaderAccountUsedGlobally then begin
            Difference := TotalDebit - TotalCredit;
            if Difference <> 0 then begin
                GenJnlLine.Init();
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                Currency.Get(PaymentHeader."Currency Code");
                if Difference < 0 then begin
                    GenJnlLine."Account No." := Currency."Unrealized Losses Acc.";
                    StepLedger.Get(Step."Payment Class", Step.Line, StepLedger.Sign::Debit);
                    GenJnlLine.Validate("Debit Amount", -Difference);
                end else begin
                    GenJnlLine."Account No." := Currency."Unrealized Gains Acc.";
                    StepLedger.Get(Step."Payment Class", Step.Line, StepLedger.Sign::Credit);
                    GenJnlLine.Validate("Credit Amount", Difference);
                end;
                GenJnlLine."Posting Date" := PaymentHeader."Posting Date";
                GenJnlLine."Document No." := PaymentHeader."No.";
                GenJnlLine.Description := StrSubstNo(
                  Text100, StrSubstNo(StepLedger.Description, PaymentHeader."Document Date", '', PaymentHeader."No."));
                GenJnlLine."Shortcut Dimension 1 Code" := PaymentHeader."Shortcut Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := PaymentHeader."Shortcut Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := PaymentHeader."Dimension Set ID";
                GenJnlLine."Source Code" := PaymentHeader."Source Code";
                GenJnlLine."Reason Code" := Step."Reason Code";
                GenJnlLine."Document Date" := PaymentHeader."Document Date";
                OnGenerEntriesOnBeforeGenJnlPostLineRunWithCheck(GenJnlLine, PaymentHeader, StepLedger);
                GenJnlPostLine.RunWithCheck(GenJnlLine);
            end;
        end;

        InvPostingBuffer[1].DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentHeaders()
    begin
        Step.SetRange("Action Type", Step."Action Type"::"Create New Document");

        if StepSelect('', -1, Step, true) then
            ExecuteCreatePaymtHead(Step);
    end;

    [Scope('OnPrem')]
    procedure ExecuteCreatePaymtHead(PaymtStep: Record "Payment Step"): Code[20]
    var
        Bor: Record "Payment Header";
        StatementForm: Page "Payment Slip";
        InserForm: Page "Payment Lines List";
        PayNum: Code[20];
    begin
        PaymentLine.SetRange("Payment Class", PaymtStep."Payment Class");
        PaymentLine.SetRange("Status No.", PaymtStep."Previous Status");
        PaymentLine.SetRange("Copied To No.", '');
        PaymentLine.FilterGroup(2);
        InserForm.SetSteps(PaymtStep.Line);
        InserForm.SetTableView(PaymentLine);
        InserForm.LookupMode(true);
        InserForm.RunModal();
        PayNum := InserForm.GetNumBor();
        if Bor.Get(PayNum) then begin
            StatementForm.SetRecord(Bor);
            StatementForm.Run();
        end else
            Error(Text004);
        exit(PayNum);
    end;

    [Scope('OnPrem')]
    procedure LinesInsert(HeaderNumber: Code[20])
    var
        Header: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        Step: Record "Payment Step";
        InserForm: Page "Payment Lines List";
    begin
        Header.Get(HeaderNumber);
        if StepSelect(Header."Payment Class", Header."Status No.", Step, false) then begin
            PaymentLine.SetRange("Payment Class", Header."Payment Class");
            PaymentLine.SetRange("Copied To No.", '');
            PaymentLine.SetFilter("Status No.", Format(Step."Previous Status"));
            PaymentLine.SetRange("Currency Code", Header."Currency Code");
            PaymentLine.FilterGroup(2);
            InserForm.SetSteps(Step.Line);
            InserForm.SetNumBor(Header."No.");
            InserForm.SetTableView(PaymentLine);
            InserForm.LookupMode(true);
            InserForm.RunModal();
        end;
    end;

    [Scope('OnPrem')]
    procedure StepSelect(Process: Text[30]; NextStatus: Integer; var Step: Record "Payment Step"; CreateDocumentFilter: Boolean) OK: Boolean
    var
        PaymentClass: Record "Payment Class";
        Options: Text;
        Choice: Integer;
        i: Integer;
    begin
        OK := false;
        i := 0;
        if Process = '' then begin
            PaymentClass.SetRange(Enable, true);
            if CreateDocumentFilter then
                PaymentClass.SetRange("Is Create Document", true);
            if PaymentClass.Find('-') then
                repeat
                    i += 1;
                    if Options = '' then
                        Options := PaymentClass.Code
                    else
                        Options := Options + ',' + PaymentClass.Code;
                until PaymentClass.Next() = 0;
            if i > 0 then
                Choice := StrMenu(Options, 1);
            i := 1;
            if Choice > 0 then begin
                PaymentClass.Find('-');
                while Choice > i do begin
                    i += 1;
                    PaymentClass.Next();
                end;
            end;
        end else begin
            PaymentClass.Get(Process);
            Choice := 1;
        end;
        if Choice > 0 then begin
            Options := '';
            Step.SetRange("Payment Class", PaymentClass.Code);
            Step.SetRange("Action Type", Step."Action Type"::"Create New Document");
            if NextStatus > -1 then
                Step.SetRange("Next Status", NextStatus);
            i := 0;
            if Step.Find('-') then begin
                i += 1;
                repeat
                    if Options = '' then
                        Options := Step.Name
                    else
                        Options := Options + ',' + Step.Name;
                until Step.Next() = 0;
                if i > 0 then begin
                    Choice := StrMenu(Options, 1);
                    i := 1;
                    if Choice > 0 then begin
                        Step.Find('-');
                        while Choice > i do begin
                            i += 1;
                            Step.Next();
                        end;
                        OK := true;
                    end;
                end;
            end;
        end;
    end;

    local procedure CheckDimCombAndValue(PaymentLine2: Record "Payment Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if PaymentLine."Line No." = 0 then begin
            if not DimMgt.CheckDimIDComb(PaymentHeader."Dimension Set ID") then
                Error(
                  Text009,
                  PaymentHeader."No.", DimMgt.GetDimCombErr());
            TableID[1] := DATABASE::"Payment Header";
            No[1] := PaymentHeader."No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, PaymentHeader."Dimension Set ID") then
                ThrowPmtPostError(PaymentLine2, CheckDimVauePostingHeaderErr, DimMgt.GetDimValuePostingErr());
        end;

        if PaymentLine."Line No." <> 0 then begin
            if not DimMgt.CheckDimIDComb(PaymentLine2."Dimension Set ID") then
                Error(
                  Text010,
                  PaymentHeader."No.", PaymentLine2."Line No.", DimMgt.GetDimCombErr());
            TableID[1] := TypeToTableID(PaymentLine2."Account Type".AsInteger());
            No[1] := PaymentLine2."Account No.";
            if not DimMgt.CheckDimValuePosting(TableID, No, PaymentLine2."Dimension Set ID") then
                ThrowPmtPostError(PaymentLine2, CheckDimVauePostingLineErr, DimMgt.GetDimValuePostingErr());
        end;
    end;

    local procedure CheckDim()
    begin
        PaymentLine."Line No." := 0;
        CheckDimCombAndValue(PaymentLine);

        PaymentLine.SetRange("No.", PaymentHeader."No.");
        if PaymentLine.FindSet() then
            repeat
                CheckDimCombAndValue(PaymentLine);
            until PaymentLine.Next() = 0;
    end;

    local procedure TypeToTableID(Type: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset"): Integer
    begin
        case Type of
            Type::"G/L Account":
                exit(DATABASE::"G/L Account");
            Type::Customer:
                exit(DATABASE::Customer);
            Type::Vendor:
                exit(DATABASE::Vendor);
            Type::"Bank Account":
                exit(DATABASE::"Bank Account");
            Type::"Fixed Asset":
                exit(DATABASE::"Fixed Asset");
        end;
    end;

    local procedure ThrowPmtPostError(ReceivedPaymentLine: Record "Payment Line"; ErrorTemplate: Text; ErrorText: Text)
    begin
        if ReceivedPaymentLine."Line No." <> 0 then
            Error(
              ErrorTemplate, PaymentHeader."No.", ReceivedPaymentLine.TableCaption(), ReceivedPaymentLine."Line No.", ErrorText);
        Error(ErrorTemplate, PaymentHeader."No.", ErrorText);
    end;

    [Scope('OnPrem')]
    procedure TestSourceCode("Code": Code[10])
    var
        SourceCode: Record "Source Code";
    begin
        if not SourceCode.Get(Code) then
            Error(Text017, Code);
    end;

    [Scope('OnPrem')]
    procedure PaymentAddr(var AddrArray: array[8] of Text[100]; PaymentAddress: Record "Payment Address")
    var
        FormatAddress: Codeunit "Format Address";
    begin
        FormatAddress.FormatAddr(
              AddrArray, PaymentAddress.Name, PaymentAddress."Name 2", PaymentAddress.Contact, PaymentAddress.Address, PaymentAddress."Address 2",
              PaymentAddress.City, PaymentAddress."Post Code", PaymentAddress.County, PaymentAddress."Country/Region Code");
    end;

    [Scope('OnPrem')]
    procedure PaymentBankAcc(var AddrArray: array[8] of Text[100]; BankAcc: Record "Payment Header")
    var
        FormatAddress: Codeunit "Format Address";
    begin
        FormatAddress.FormatAddr(
              AddrArray, BankAcc."Bank Name", BankAcc."Bank Name 2", BankAcc."Bank Contact", BankAcc."Bank Address", BankAcc."Bank Address 2",
              BankAcc."Bank City", BankAcc."Bank Post Code", BankAcc."Bank County", BankAcc."Bank Country/Region Code");
    end;

    [Scope('OnPrem')]
    procedure ArchiveDocument(Document: Record "Payment Header")
    var
        ArchiveHeader: Record "Payment Header Archive";
        ArchiveLine: Record "Payment Line Archive";
        PaymentLine: Record "Payment Line";
    begin
        Document.CalcFields("Archiving Authorized");
        if not Document."Archiving Authorized" then
            Error(Text022, Document."No.");
        ArchiveHeader.TransferFields(Document);
        ArchiveHeader.Insert();
        Document.Delete();
        PaymentLine.SetRange("No.", Document."No.");
        if PaymentLine.Find('-') then
            repeat
                ArchiveLine.TransferFields(PaymentLine);
                ArchiveLine.Insert();
                PaymentLine.Delete();
            until PaymentLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure PickPaymentStep(PaymentHeader: Record "Payment Header"; var PaymentStep: Record "Payment Step"): Boolean
    var
        PaymentSteps: Page "Payment Steps";
    begin
        PaymentStep.FilterGroup(2);
        // Filter on "Action Type" is passed with PaymentStep
        PaymentStep.SetRange("Payment Class", PaymentHeader."Payment Class");
        PaymentStep.SetRange("Previous Status", PaymentHeader."Status No.");
        PaymentStep.FilterGroup(0);
        if PaymentStep.IsEmpty() then
            exit(false);

        if PaymentStep.Count = 1 then begin
            PaymentStep.FindFirst();
            exit(Confirm(PaymentStep.Name, true));
        end;

        PaymentStep.FindSet();
        PaymentSteps.LookupMode(true);
        PaymentSteps.SetTableView(PaymentStep);
        PaymentSteps.SetRecord(PaymentStep);
        PaymentSteps.Editable(false);
        if PaymentSteps.RunModal() = ACTION::LookupOK then begin
            PaymentSteps.GetRecord(PaymentStep);
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ProcessPaymentSteps(PaymentHeader: Record "Payment Header"; var PaymentStep: Record "Payment Step")
    begin
        PaymentHeader.TestNbOfLines();
        if PickPaymentStep(PaymentHeader, PaymentStep) then
            ProcessPaymentStep(PaymentHeader."No.", PaymentStep);
    end;

    local procedure RunXmlPortExport(XMLPortID: Integer; var PaymentHeader: Record "Payment Header")
    begin
        PaymentClass.Get(PaymentHeader."Payment Class");
        case PaymentClass."SEPA Transfer Type" of
            PaymentClass."SEPA Transfer Type"::"Credit Transfer":
                ExportSEPACreditTransfer(XMLPortID, PaymentHeader);
            PaymentClass."SEPA Transfer Type"::"Direct Debit":
                ExportSEPADirectDebit(PaymentHeader);
            else
                XMLPORT.Run(XMLPortID, false, false, PaymentHeader);
        end;
    end;

    local procedure ExportSEPACreditTransfer(XMLPortId: Integer; var PaymentHeader: Record "Payment Header")
    var
        GenJnlLine: Record "Gen. Journal Line";
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
    begin
        GenJnlLine.SetRange("Journal Template Name", '');
        GenJnlLine.SetRange("Journal Batch Name", '');
        GenJnlLine.SetRange("Document No.", PaymentHeader."No.");
        OnExportSEPACreditTransferOnAfterGenJnlLineSetFilters(GenJnlLine, XMLPortId, PaymentHeader);
        if SEPACTExportFile.Export(GenJnlLine, XMLPortId) then begin
            PaymentHeader."File Export Completed" := true;
            PaymentHeader.Modify();
        end;
    end;

    local procedure ExportSEPADirectDebit(var PaymentHeader: Record "Payment Header")
    var
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        LastError: Text;
    begin
        PaymentHeader.TestField("Account Type", PaymentHeader."Account Type"::"Bank Account");
        DirectDebitCollection.CreateRecord(PaymentHeader."No.", PaymentHeader."Account No.", PaymentHeader."Partner Type");
        DirectDebitCollection."Source Table ID" := DATABASE::"Payment Header";
        DirectDebitCollection.Modify();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        Commit();
        ClearLastError();
        if CODEUNIT.Run(CODEUNIT::"SEPA DD-Export File", DirectDebitCollectionEntry) then begin
            DeleteDirectDebitCollection(DirectDebitCollection."No.");
            PaymentHeader."File Export Completed" := true;
            PaymentHeader.Modify();
            exit;
        end;

        LastError := GetLastErrorText;
        DeleteDirectDebitCollection(DirectDebitCollection."No.");
        Commit();
        Error(LastError);
    end;

    local procedure DeleteDirectDebitCollection(DirectDebitCollectionNo: Integer)
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        if DirectDebitCollection.Get(DirectDebitCollectionNo) then
            DirectDebitCollection.Delete(true);
    end;

    local procedure PostInvPostingBuffer(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GenJnlLine.Init();
        GenJnlLine."Posting Date" := PaymentHeader."Posting Date";
        GenJnlLine."Document Date" := PaymentHeader."Document Date";
        GenJnlLine.Description := InvPostingBuffer[1].Description;
        GenJnlLine."Reason Code" := Step."Reason Code";
        PaymentClass.Get(PaymentHeader."Payment Class");
        GenJnlLine."Delayed Unrealized VAT" :=
          (PaymentClass."Unrealized VAT Reversal" = PaymentClass."Unrealized VAT Reversal"::Delayed);
        GenJnlLine."Realize VAT" := Step."Realize VAT";
        GenJnlLine."Created from No." := InvPostingBuffer[1]."Created from No.";
        GenJnlLine."Document Type" := InvPostingBuffer[1]."Document Type";
        GenJnlLine."Document No." := InvPostingBuffer[1]."Document No.";
        GenJnlLine."Account Type" := InvPostingBuffer[1]."Account Type";
        GenJnlLine."Account No." := InvPostingBuffer[1]."Account No.";
        GenJnlLine."System-Created Entry" := InvPostingBuffer[1]."System-Created Entry";
        GenJnlLine."Currency Code" := InvPostingBuffer[1]."Currency Code";
        GenJnlLine."Currency Factor" := InvPostingBuffer[1]."Currency Factor";
        GenJnlLine.Validate(Amount, InvPostingBuffer[1].Amount);
        GenJnlLine.Correction := InvPostingBuffer[1].Correction;
        if PaymentHeader."Source Code" <> '' then begin
            TestSourceCode(PaymentHeader."Source Code");
            GenJnlLine."Source Code" := PaymentHeader."Source Code";
        end else begin
            Step.TestField("Source Code");
            TestSourceCode(Step."Source Code");
            GenJnlLine."Source Code" := Step."Source Code";
        end;
        GenJnlLine."Applies-to ID" := InvPostingBuffer[1]."Applies-to ID";
        if GenJnlLine."Applies-to ID" = '' then begin
            GenJnlLine."Applies-to Doc. Type" := InvPostingBuffer[1]."Applies-to Doc. Type";
            GenJnlLine."Applies-to Doc. No." := InvPostingBuffer[1]."Applies-to Doc. No.";
        end;
        GenJnlLine."Posting Group" := InvPostingBuffer[1]."Posting Group";
        GenJnlLine."Source Type" := InvPostingBuffer[1]."Source Type";
        GenJnlLine."Source No." := InvPostingBuffer[1]."Source No.";
        GenJnlLine."External Document No." := InvPostingBuffer[1]."External Document No.";
        GenJnlLine."Due Date" := InvPostingBuffer[1]."Due Date";
        GenJnlLine."Shortcut Dimension 1 Code" := InvPostingBuffer[1]."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := InvPostingBuffer[1]."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := InvPostingBuffer[1]."Dimension Set ID";

        OnPostInvPostingBufferOnBeforeGenJnlPostLineRunWithCheck(GenJnlLine, PaymentHeader, PaymentClass, PaymentLine);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        GLEntry.SetRange("Document Type", GenJnlLine."Document Type");
        GLEntry.SetRange("Document No.", GenJnlLine."Document No.");
        if GLEntry.FindLast() then
            exit(GLEntry."Entry No.");
        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplication(StepLedger: Record "Payment Step Ledger"; var InvPostingBuffer: array[2] of Record "Payment Post. Buffer" temporary; PaymentHeader: Record "Payment Header"; PaymentLine: Record "Payment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDescriptionForInvPostingBuffer(var StepLedger: Record "Payment Step Ledger"; var PaymentLine: Record "Payment Line"; var Description: Text[98])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessPaymentStep(PaymentHeaderNo: Code[20]; PaymentStep: Record "Payment Step"; PaymentLine: Record "Payment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessPaymentStepByActionType(var PaymentLine: Record "Payment Line"; PaymentStep: Record "Payment Step"; var ActionValidated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyLigBorOnBeforeInitHeader(var ToBord: Record "Payment Header"; var Process: Record "Payment Class"; var i: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyLigBorOnBeforeToPaymentLineInsert(var ToPaymentLine: Record "Payment Line"; var Process: Record "Payment Class")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessPaymentStep(PaymentHeaderNo: Code[20]; PaymentStep: Record "Payment Step")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerEntriesOnBeforeGenJnlPostLineRunWithCheck(var GenJnlLine: Record "Gen. Journal Line"; PaymentHeader: Record "Payment Header"; StepLedger: Record "Payment Step Ledger")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportSEPACreditTransferOnAfterGenJnlLineSetFilters(var GenJnlLine: Record "Gen. Journal Line"; var XMLPortId: Integer; var PaymentHeader: Record "Payment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerInvPostingBufferOnBeforeUpdtBuffer(var InvPostingBuffer: array[2] of Record "Payment Post. Buffer" temporary; PaymentLine: Record "Payment Line"; StepLedger: Record "Payment Step Ledger")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerInvPostingBufferOnAfterGetDescriptionForInvPostingBuffer(var StepLedger: record "Payment Step Ledger"; var PaymentHeader: record "Payment Header"; var PaymentLine: record "Payment Line"; var Description: Text[98])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvPostingBufferOnBeforeGenJnlPostLineRunWithCheck(var GenJnlLine: Record "Gen. Journal Line"; var PaymentHeader: Record "Payment Header"; var PaymentClass: Record "Payment Class"; PaymentLine: Record "Payment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessPaymentStepOnCaseElse(var Step: Record "Payment Step"; var PaymentLine: Record "Payment Line"; var ActionValidated: Boolean; var PaymentHeader: Record "Payment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessPaymentStepOnAfterCheckPaymentStep(var PaymentStep: Record "Payment Step"; var PaymentHeader: Record "Payment Header"; var PaymentLine: Record "Payment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPostingGroupOnBeforeCheckPostingGroup(var PaymentLine: Record "Payment Line"; var StepLedger: record "Payment Step Ledger"; var PostingGroup: Code[20])
    begin
    end;
}
