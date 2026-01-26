// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Utilities;

codeunit 12173 "Vendor Bill List - Post"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    TableNo = "Vendor Bill Header";

    trigger OnRun()
    begin
        if not Confirm(Text1130000) then
            exit;

        Code(Rec);

        Message(Text1130026);
    end;

    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        MustBeErr: Label '%1 must be %2.', Comment = '%1 = List Status, %2 = Status';
        SelectionTxt: Label 'Open,Sent';
        Window: Dialog;
        LineNo: Integer;
        BalanceAmount: Decimal;
        BalanceAmountLCY: Decimal;

        Text12100: Label 'Meanwhile %1 has been modified for %2 %3 %4 %5. New amount is %6. Please recreate the bill list.';
        Text1130000: Label 'Do you want to post the lines?';
        Text1130011: Label 'Posting Vendor Bill...\\';
        Text1130012: Label 'Post Line #1##########\';
        Text1130026: Label 'The lines has been successfully posted.';

    [Scope('OnPrem')]
    procedure "Code"(var LocalVendorBillHeader: Record "Vendor Bill Header")
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        TempVendorBillLine: Record "Vendor Bill Line" temporary;
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
        TempWithholdingSocSec: Record "Tmp Withholding Contribution" temporary;
        VendBillWithhTax: Record "Vendor Bill Withholding Tax";
        BillPostingGroup: Record "Bill Posting Group";
        BillCode: Record Bill;
        WithholdingSocSec: Codeunit "Withholding - Contribution";
        TaxType: Option " ",Withhold,"Free Lance",Company;
        AmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        VendorBillHeader := LocalVendorBillHeader;

        OnBeforePost(VendorBillHeader);

        CheckVendorBill(VendorBillHeader, BillPostingGroup, BillCode);

        VendorBillLine.Reset();
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        if not VendorBillLine.Find('-') then
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        Window.Open(Text1130011 + Text1130012);

        InsertPostedBillHeader(PostedVendorBillHeader, VendorBillHeader, VendorBillHeader."Vendor Bill List No.", VendorBillHeader."No.");
        InsertTempVendorBillLine(VendorBillLine, TempVendorBillLine);
        if VendorBillLine.FindSet() then
            repeat
                LineNo := LineNo + 1;
                Window.Update(1, LineNo);
                BalanceAmount := BalanceAmount + VendorBillLine."Amount to Pay";

                if not VendorBillLine."Manual Line" then begin
                    VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
                    VendLedgEntry.CalcFields("Remaining Amount");
                    if VendLedgEntry."Remaining Amount" + VendorBillLine."Remaining Amount" <> 0 then
                        Error(Text12100,
                          VendLedgEntry.FieldCaption("Remaining Amount"),
                          VendLedgEntry.FieldCaption("Document No."),
                          VendLedgEntry."Document No.",
                          VendLedgEntry.FieldCaption("Document Occurrence"),
                          VendLedgEntry."Document Occurrence",
                          Abs(VendLedgEntry."Remaining Amount"));
                end;
                if not VendorBillLine."Manual Line" then
                    PostVendorBillLine(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry, BillCode, AmountLCY)
                else begin
                    TempVendorBillLine.Get(VendorBillLine."Vendor Bill List No.", VendorBillLine."Line No.");
                    PostVendorBillLine(GenJnlLine, VendorBillHeader, TempVendorBillLine, VendLedgEntry, BillCode, AmountLCY);
                end;

                BalanceAmountLCY := BalanceAmountLCY + GenJnlLine."Amount (LCY)";
                if VendBillWithhTax.Get(VendorBillLine."Vendor Bill List No.", VendorBillLine."Line No.") then begin
                    if (VendBillWithhTax."Withholding Tax Code" <> '') and (VendBillWithhTax."Withholding Tax Amount" <> 0) then
                        PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::Withhold);
                    if (VendBillWithhTax."Social Security Code" <> '') and (VendBillWithhTax."Free-Lance Amount" <> 0) then
                        PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::"Free Lance");
                    if (VendBillWithhTax."Social Security Code" <> '') and (VendBillWithhTax."Company Amount" <> 0) then
                        PostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType::Company);

                    OnAfterPostTax(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType);

                    TempWithholdingSocSec.TransferFields(VendBillWithhTax);
                    WithholdingSocSec.PostPayments(TempWithholdingSocSec, GenJnlLine, true);
                end;

                IsHandled := false;
                OnBeforeInsertPostedBillLine(VendorBillHeader, VendorBillLine, VendBillWithhTax, VendLedgEntry, BillCode, TaxType, PostedVendorBillHeader, BalanceAmountLCY, IsHandled);
                if not IsHandled then
                    InsertPostedBillLine(VendorBillLine, PostedVendorBillHeader."No.", VendorBillLine."Vendor Bill No.");
            until VendorBillLine.Next() = 0;

        PostBalanceAccount(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry, BillCode);

        if VendorBillHeader."Bank Expense" > 0 then begin
            BillPostingGroup.TestField("Expense Bill Account No.");
            PostExpense(VendorBillHeader, VendLedgEntry, BillCode, BillPostingGroup."Expense Bill Account No.");
        end;

        VendorBillLine.DeleteAll(true);
        VendorBillHeader.Delete(true);
        TempVendorBillLine.Delete(true);
        Window.Close();
        Commit();

        OnAfterPost(VendorBillHeader);
    end;

    local procedure CheckVendorBill(VendorBillHeader: Record "Vendor Bill Header"; var BillPostingGroup: Record "Bill Posting Group"; var BillCode: Record Bill)
    var
        PaymentMethod: Record "Payment Method";
        BankAccount: Record "Bank Account";
    begin
        if VendorBillHeader."List Status" <> VendorBillHeader."List Status"::Sent then
            Error(MustBeErr, VendorBillHeader.FieldCaption("List Status"), SelectStr(2, SelectionTxt));

        BankAccount.Get(VendorBillHeader."Bank Account No.");
        PaymentMethod.Get(VendorBillHeader."Payment Method Code");
        BillCode.Get(PaymentMethod."Bill Code");
        BillPostingGroup.Get(VendorBillHeader."Bank Account No.", VendorBillHeader."Payment Method Code");
    end;

    local procedure InsertPostedBillHeader(var PostedVendorBillHeader: Record "Posted Vendor Bill Header"; VendorBillHeader: Record "Vendor Bill Header"; ListNo: Code[20]; BillNo: Code[20])
    begin
        PostedVendorBillHeader.Init();
        PostedVendorBillHeader.TransferFields(VendorBillHeader);
        PostedVendorBillHeader."No." := ListNo;
        PostedVendorBillHeader."Temporary Bill No." := BillNo;
        PostedVendorBillHeader."User ID" := UserId;
        PostedVendorBillHeader.Insert();
    end;

    local procedure InsertPostedBillLine(VendorBillLine: Record "Vendor Bill Line"; BillNo: Code[20]; ListNo: Code[20])
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        PostedVendorBillLine.Init();
        PostedVendorBillLine.TransferFields(VendorBillLine);
        PostedVendorBillLine."Vendor Bill No." := BillNo;
        PostedVendorBillLine."Vendor Bill List No." := ListNo;
        PostedVendorBillLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure PostVendorBillLine(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill; var AmountLCY: Decimal)
    var
        Tax: Option " ",Withhold,"Free Lance",Company;
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", VendorBillHeader."Posting Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := VendorBillHeader."Vendor Bill List No.";
        GenJnlLine."Document Date" := VendorBillHeader."List Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine.Validate("Account No.", VendorBillLine."Vendor No.");
        GenJnlLine."Due Date" := VendorBillLine."Due Date";
        GenJnlLine."External Document No." := VendorBillLine."Vendor Bill List No.";
        GenJnlLine.Validate(Amount, VendorBillLine."Amount to Pay");
        GenJnlLine.Validate("Currency Code", VendorBillHeader."Currency Code");
        if not VendorBillLine."Manual Line" then begin
            GenJnlLine.Validate("Salespers./Purch. Code", VendLedgEntry."Purchaser Code");
            ApplyInvAndUpdateLedgEntry(GenJnlLine, VendorBillLine, Tax::" ");
        end else
            GenJnlLine."Applies-to Occurrence No." := VendorBillLine."Document Occurrence";
        GenJnlLine.Description := Bill.Description;
        GenJnlLine."Source Code" := Bill."Vend. Bill Source Code";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Reason Code" := VendorBillHeader."Reason Code";
        GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        if not VendorBillLine."Manual Line" then
            GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID"
        else
            GenJnlLine."Dimension Set ID" := VendorBillLine."Dimension Set ID";
        GenJnlLine."Payment Method Code" := VendorBillHeader."Payment Method Code";
        AmountLCY := GenJnlLine."Amount (LCY)";

        OnBeforePostVendorBillLine(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PostBalanceAccount(GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill)
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", VendorBillHeader."Posting Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := VendorBillHeader."Vendor Bill List No.";
        GenJnlLine."Document Date" := VendorBillHeader."List Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Bank Account";
        GenJnlLine.Validate("Account No.", VendorBillHeader."Bank Account No.");
        GenJnlLine."Currency Code" := VendorBillHeader."Currency Code";
        GenJnlLine.Validate(Amount, -BalanceAmount);
        GenJnlLine.Validate("Amount (LCY)", -BalanceAmountLCY);
        GenJnlLine.Description := Bill.Description;
        GenJnlLine."Source Code" := Bill."Vend. Bill Source Code";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Reason Code" := VendorBillHeader."Reason Code";
        if not VendorBillLine."Manual Line" then
            GenJnlLine.Validate("Salespers./Purch. Code", VendLedgEntry."Purchaser Code");

        GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        if not VendorBillLine."Manual Line" then
            GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID"
        else
            GenJnlLine."Dimension Set ID" := VendorBillLine."Dimension Set ID";

        GenJnlLine.CreateDimFromDefaultDim(GenJnlLine.FieldNo("Account No."));
        OnBeforePostBalanceAccount(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PostExpense(VendorBillHeader: Record "Vendor Bill Header"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill; ExpenseAccNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", VendorBillHeader."Posting Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := VendorBillHeader."Vendor Bill List No.";
        GenJnlLine."Document Date" := VendorBillHeader."List Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine.Validate("Account No.", ExpenseAccNo);
        GenJnlLine.Description := Bill.Description;
        GenJnlLine."Source Code" := Bill."Vend. Bill Source Code";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Reason Code" := VendorBillHeader."Reason Code";
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine.Validate("Bal. Account No.", VendorBillHeader."Bank Account No.");
        GenJnlLine.Validate(Amount, VendorBillHeader."Bank Expense");
        if PurchInvHeader.GET(VendLedgEntry."Document No.") then begin
            GeneralLedgerSetup.GetRecordOnce();
            if GeneralLedgerSetup."Use Activity Code" then
                GenJnlLine.Validate("Activity Code", PurchInvHeader."Activity Code");
        end;

        OnBeforePostExpense(GenJnlLine, VendorBillHeader, VendLedgEntry);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    procedure PostTax(VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax"; VendLedgEntry: Record "Vendor Ledger Entry"; Bill: Record Bill; Tax: Option " ",Withhold,"Free Lance",Company)
    var
        GenJnlLine: Record "Gen. Journal Line";
        WithholdCode: Record "Withhold Code";
        ContributionCode: Record "Contribution Code";
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", VendorBillHeader."Posting Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := VendorBillHeader."Vendor Bill List No.";
        GenJnlLine."Document Date" := VendorBillHeader."List Date";
        GenJnlLine."External Document No." := VendorBillLine."Vendor Bill List No.";
        case Tax of
            Tax::Withhold:
                begin
                    WithholdCode.Get(VendorBillWithholdingTax."Withholding Tax Code");
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    GenJnlLine.Validate("Account No.", VendorBillLine."Vendor No.");
                    GenJnlLine.Validate(Amount, VendorBillLine."Withholding Tax Amount");
                    WithholdCode.TestField("Withholding Taxes Payable Acc.");
                    GenJnlLine."Bal. Account No." := WithholdCode."Withholding Taxes Payable Acc.";
                end;
            Tax::"Free Lance":
                begin
                    ContributionCode.Get(VendorBillWithholdingTax."Social Security Code");
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    GenJnlLine.Validate("Account No.", VendorBillLine."Vendor No.");
                    GenJnlLine.Validate(Amount, VendorBillWithholdingTax."Free-Lance Amount");
                    ContributionCode.TestField("Social Security Payable Acc.");
                    GenJnlLine."Bal. Account No." := ContributionCode."Social Security Payable Acc.";
                end;
            Tax::Company:
                begin
                    ContributionCode.Get(VendorBillWithholdingTax."Social Security Code");
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                    ContributionCode.TestField("Social Security Charges Acc.");
                    GenJnlLine.Validate("Account No.", ContributionCode."Social Security Charges Acc.");
                    GenJnlLine.Validate(Amount, VendorBillWithholdingTax."Company Amount");
                    ContributionCode.TestField("Social Security Payable Acc.");
                    GenJnlLine."Bal. Account No." := ContributionCode."Social Security Payable Acc.";
                end;
        end;
        GenJnlLine.Validate("Currency Code", VendorBillHeader."Currency Code");
        if not VendorBillLine."Manual Line" then begin
            GenJnlLine.Validate("Salespers./Purch. Code", VendLedgEntry."Purchaser Code");
            ApplyInvAndUpdateLedgEntry(GenJnlLine, VendorBillLine, Tax);
        end;
        GenJnlLine.Description := Bill.Description;
        GenJnlLine."Source Code" := Bill."Vend. Bill Source Code";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Reason Code" := VendorBillHeader."Reason Code";
        GenJnlLine."Shortcut Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        if not VendorBillLine."Manual Line" then
            GenJnlLine."Dimension Set ID" := VendLedgEntry."Dimension Set ID"
        else
            GenJnlLine."Dimension Set ID" := VendorBillLine."Dimension Set ID";

        OnBeforePostWithholdingTax(GenJnlLine, VendorBillHeader, VendorBillLine, VendLedgEntry, VendorBillWithholdingTax);
        GenJnlPostLine.RunWithCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ApplyInvAndUpdateLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; VendorBillLine: Record "Vendor Bill Line"; Tax: Option " ",Withhold,"Free Lance",Company)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
        if not (Tax = Tax::Company) then begin
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
            GenJnlLine."Applies-to Doc. No." := VendorBillLine."Document No.";
        end;
        GenJnlLine."Applies-to Occurrence No." := VendorBillLine."Document Occurrence";
        GenJnlLine."Allow Application" := true;
        if VendorBillLine."Amount to Pay" + VendorBillLine."Withholding Tax Amount" <> VendorBillLine."Remaining Amount" then begin
            VendLedgEntry."Vendor Bill List" := '';
            VendLedgEntry."Vendor Bill No." := '';
            VendLedgEntry.Modify();
        end;
    end;

    local procedure InsertTempVendorBillLine(VendorBillLine: Record "Vendor Bill Line"; var TempVendorBillLine: Record "Vendor Bill Line" temporary)
    begin
        TempVendorBillLine.DeleteAll(true);
        if not VendorBillLine.FindSet() then
            exit;

        repeat
            TempVendorBillLine.Copy(VendorBillLine);
            TempVendorBillLine.Insert();

            UpdateDocumentOccurrenceForManualLine(TempVendorBillLine, VendorBillLine);
        until VendorBillLine.Next() = 0;

    end;

    local procedure UpdateDocumentOccurrenceForManualLine(var TempVendorBillLine: Record "Vendor Bill Line"; VendorBillLine: Record "Vendor Bill Line")
    var
        Iterations: Integer;
    begin
        if not VendorBillLine."Manual Line" then
            exit;

        TempVendorBillLine.SetCurrentKey("Vendor Bill List No.", "Vendor No.", "Due Date");
        TempVendorBillLine.SetRange("Manual Line", true);
        TempVendorBillLine.SetRange("Vendor No.", VendorBillLine."Vendor No.");
        TempVendorBillLine.SetRange("Vendor Bill List No.", VendorBillLine."Vendor Bill List No.");
        TempVendorBillLine.SetFilter("Due Date", '<>%1', 0D);
        TempVendorBillLine.SetRange("Document Type", VendorBillLine."Document Type");
        TempVendorBillLine.SetRange("Document No.", VendorBillLine."Document No.");
        TempVendorBillLine.SetRange("External Document No.", VendorBillLine."External Document No.");
        if TempVendorBillLine.FindSet() then
            repeat
                Iterations := Iterations + 1;
                TempVendorBillLine."Document Occurrence" := Iterations;
                TempVendorBillLine.Modify(true);
            until TempVendorBillLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostTax(var VendorBillHeader: Record "Vendor Bill Header"; var VendorBillLine: Record "Vendor Bill Line"; var VendBillWithhTax: Record "Vendor Bill Withholding Tax"; var VendLedgEntry: Record "Vendor Ledger Entry"; BillCode: Record Bill; TaxType: Option);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostVendorBillLine(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalanceAccount(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostExpense(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWithholdingTax(var GenJnlLine: Record "Gen. Journal Line"; VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendLedgEntry: Record "Vendor Ledger Entry"; VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPostedBillLine(VendorBillHeader: Record "Vendor Bill Header"; VendorBillLine: Record "Vendor Bill Line"; VendBillWithhTax: Record "Vendor Bill Withholding Tax"; VendLedgEntry: Record "Vendor Ledger Entry"; BillCode: Record Bill; TaxType: Option " ",Withhold,"Free Lance",Company; PostedVendorBillHeader: Record "Posted Vendor Bill Header"; BalanceAmountLCY: Decimal; var IsHandled: Boolean)
    begin
    end;
}

