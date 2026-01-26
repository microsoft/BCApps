// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 2000020 DomiciliationJnlManagement
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Domiciliation Journal Template" = imd,
                  TableData "Domiciliation Journal Batch" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'DEFAULT', Comment = 'DEFAULT means default batch name.';
        Text001: Label 'Default Domiciliation Journal';
        Text002: Label 'Default Journal';
        LastDomJnlLine: Record "Domiciliation Journal Line";
        DomJnlTemplate: Record "Domiciliation Journal Template";
        DomJnlLine: Record "Domiciliation Journal Line";
        PaymJnlManagement: Codeunit PmtJrnlManagement;

    [Scope('OnPrem')]
    procedure TemplateSelection(var DomJnlLine: Record "Domiciliation Journal Line"; var JnlSelected: Boolean)
    var
        DomJnlTemplate: Record "Domiciliation Journal Template";
    begin
        JnlSelected := true;

        DomJnlTemplate.Reset();

        case DomJnlTemplate.Count of
            0:
                begin
                    DomJnlTemplate.Init();
                    DomJnlTemplate.Name := Text000;
                    DomJnlTemplate.Description := Text001;
                    DomJnlTemplate."Page ID" := PAGE::"Domiciliation Journal";
                    DomJnlTemplate."Test Report ID" := REPORT::"Domiciliation Journal - Test";
                    DomJnlTemplate.Insert(true);
                    Commit();
                end;
            1:
                DomJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, DomJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            DomJnlLine.FilterGroup(2); // Formfilter
            DomJnlLine.SetRange("Journal Template Name", DomJnlTemplate.Name);
            DomJnlLine.FilterGroup(0); // Standardfilter
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenJournal(var CurrentJnlBatchName: Code[10]; var DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        CheckTemplateName(DomicJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        DomicJnlLine.FilterGroup(2); // Formfilter
        DomicJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        DomicJnlLine.FilterGroup(0); // Standardfilter
    end;

    local procedure CheckTemplateName(CurrenJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        DomJnlTemplate: Record "Domiciliation Journal Template";
        DomJnlBatch: Record "Domiciliation Journal Batch";
    begin
        DomJnlBatch.SetRange("Journal Template Name", CurrenJnlTemplateName);
        if not DomJnlBatch.Get(CurrenJnlTemplateName, CurrentJnlBatchName) then begin
            if not DomJnlBatch.FindLast() then begin
                DomJnlBatch.Init();
                DomJnlBatch."Journal Template Name" := CurrenJnlTemplateName;
                DomJnlBatch.Name := Text000;
                DomJnlBatch.Description := Text002;
                DomJnlBatch."Reason Code" := DomJnlTemplate."Reason Code";
                DomJnlBatch.Insert();
                Commit();
            end;
            CurrentJnlBatchName := DomJnlBatch.Name
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenJnlBatch(var DomJnlBatch: Record "Domiciliation Journal Batch")
    var
        DomJnlTemplate: Record "Domiciliation Journal Template";
        DomJnlLine: Record "Domiciliation Journal Line";
        JnlSelected: Boolean;
    begin
        if DomJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        DomJnlBatch.FilterGroup(2);
        if DomJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            DomJnlBatch.FilterGroup(0);
            exit;
        end;
        DomJnlBatch.FilterGroup(0);

        if DomJnlBatch.IsEmpty() then begin
            if not DomJnlTemplate.FindFirst() then
                TemplateSelection(DomJnlLine, JnlSelected);
            if DomJnlTemplate.FindFirst() then
                CheckTemplateName(DomJnlTemplate.Name, DomJnlBatch.Name);
        end;
        DomJnlBatch.FindFirst();
        JnlSelected := true;
        if DomJnlBatch.GetFilter("Journal Template Name") <> '' then
            DomJnlTemplate.SetRange(Name, DomJnlBatch.GetFilter("Journal Template Name"));
        case DomJnlTemplate.Count of
            1:
                DomJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, DomJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        DomJnlBatch.FilterGroup(0);
        DomJnlBatch.SetRange("Journal Template Name", DomJnlTemplate.Name);
        DomJnlBatch.FilterGroup(2);
    end;

    [Scope('OnPrem')]
    procedure TemplateSelectionFromBatch(var DomJnlBatch: Record "Domiciliation Journal Batch")
    var
        DomJnlLine: Record "Domiciliation Journal Line";
        DomJnlTemplate: Record "Domiciliation Journal Template";
    begin
        DomJnlTemplate.Get(DomJnlBatch."Journal Template Name");
        DomJnlTemplate.TestField("Page ID");
        DomJnlBatch.TestField(Name);

        DomJnlLine.FilterGroup := 2;
        DomJnlLine.SetRange("Journal Template Name", DomJnlTemplate.Name);
        DomJnlLine.FilterGroup := 0;

        DomJnlLine."Journal Template Name" := '';
        DomJnlLine."Journal Batch Name" := DomJnlBatch.Name;
        PAGE.Run(DomJnlTemplate."Page ID", DomJnlLine);
    end;

    [Scope('OnPrem')]
    procedure CheckName(CurrentJnlBatchName: Code[10]; var DomicJnlLine: Record "Domiciliation Journal Line")
    var
        DomicJnlBatch: Record "Domiciliation Journal Batch";
    begin
        DomicJnlBatch.Get(DomicJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    [Scope('OnPrem')]
    procedure SetName(CurrentJnlBatchName: Code[10]; var DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        DomicJnlLine.FilterGroup(2); // Formfilter
        DomicJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        DomicJnlLine.FilterGroup(0); // Standardfilter
        if DomicJnlLine.Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure LookupName(CurrenJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; var NewJnlBatchName: Text[10]): Boolean
    var
        DomJnlBatch: Record "Domiciliation Journal Batch";
    begin
        DomJnlBatch."Journal Template Name" := CurrenJnlTemplateName;
        DomJnlBatch.Name := CurrentJnlBatchName;
        DomJnlBatch.FilterGroup(2);

        DomJnlBatch.SetRange("Journal Template Name", CurrenJnlTemplateName);
        DomJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, DomJnlBatch) <> ACTION::LookupOK then
            exit(false);

        NewJnlBatchName := DomJnlBatch.Name;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetAccounts(var DomicJnlLine: Record "Domiciliation Journal Line"; var AccName: Text[100]; var BankAccName: Text[100])
    var
        Cust: Record Customer;
        Bank: Record "Bank Account";
    begin
        if DomicJnlLine."Customer No." <> LastDomJnlLine."Customer No." then begin
            AccName := '';
            if Cust.Get(DomicJnlLine."Customer No.") then
                AccName := Cust.Name;
        end;
        if DomicJnlLine."Bank Account No." <> LastDomJnlLine."Bank Account No." then begin
            BankAccName := '';
            if Bank.Get(DomicJnlLine."Bank Account No.") then
                BankAccName := Bank.Name;
        end;

        LastDomJnlLine := DomicJnlLine;
    end;

    [Scope('OnPrem')]
    procedure CalculateTotals(var DomicJnlLine: Record "Domiciliation Journal Line"; LastDomicJnlLine: Record "Domiciliation Journal Line"; var Balance: Decimal; var TotalAmount: Decimal; var ShowAmount: Boolean; var ShowTotalAmount: Boolean)
    var
        TempDomJnlLine: Record "Domiciliation Journal Line";
    begin
        TempDomJnlLine.CopyFilters(DomicJnlLine);
        if TempDomJnlLine.CalcSums("Amount (LCY)") then begin
            if DomicJnlLine."Line No." <> 0 then // 0 = New record
                TotalAmount := TempDomJnlLine."Amount (LCY)"
            else
                TotalAmount := TempDomJnlLine."Amount (LCY)" + LastDomicJnlLine."Amount (LCY)";
            ShowTotalAmount := true;
        end else
            ShowTotalAmount := false;

        if DomicJnlLine."Line No." = 0 then // 0 = New record
            ShowAmount := false
        else
            if DomicJnlLine."Customer No." <> '' then begin
                TempDomJnlLine.SetCurrentKey("Customer No.");
                TempDomJnlLine.SetRange("Customer No.", DomicJnlLine."Customer No.");
                if TempDomJnlLine.CalcSums("Amount (LCY)") then begin
                    Balance := TempDomJnlLine."Amount (LCY)";
                    ShowAmount := true;
                end else
                    ShowAmount := false;
            end;
    end;

    [Scope('OnPrem')]
    procedure SetUpNewLine(var DomicJnlLine: Record "Domiciliation Journal Line"; LastDomicJnlLine: Record "Domiciliation Journal Line")
    begin
        DomicJnlLine.Validate("Posting Date", LastDomicJnlLine."Posting Date");
        DomicJnlLine."Customer No." := LastDomicJnlLine."Customer No.";
        if DomJnlTemplate.Name <> DomicJnlLine."Journal Template Name" then
            DomJnlTemplate.Get(DomicJnlLine."Journal Template Name");
        if DomJnlTemplate."Bank Account No." <> '' then
            DomicJnlLine."Bank Account No." := DomJnlTemplate."Bank Account No."
        else
            DomicJnlLine."Bank Account No." := LastDomicJnlLine."Bank Account No.";
        DomicJnlLine.Validate("Bank Account No.")
    end;

    [Scope('OnPrem')]
    procedure ShowCard(DomicJnlLine: Record "Domiciliation Journal Line")
    var
        Cust: Record Customer;
    begin
        Cust."No." := DomicJnlLine."Customer No.";
        PAGE.Run(PAGE::"Customer Card", Cust);
    end;

    [Scope('OnPrem')]
    procedure ShowEntries(DomicJnlLine: Record "Domiciliation Journal Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetRange("Customer No.", DomicJnlLine."Customer No.");
        if CustLedgEntry.FindLast() then;
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure PrintTestReport(DomicJnlBatch: Record "Domiciliation Journal Batch")
    var
        DomicJnlTemplate: Record "Domiciliation Journal Template";
    begin
        DomicJnlBatch.SetRecFilter();
        DomicJnlTemplate.Get(DomicJnlBatch."Journal Template Name");
        DomicJnlTemplate.TestField("Test Report ID");
        REPORT.Run(DomicJnlTemplate."Test Report ID", true, false, DomicJnlBatch);
    end;

    [Scope('OnPrem')]
    procedure CreateDomiciliations(var DomicJnlLine: Record "Domiciliation Journal Line")
    begin
        DomJnlLine.Copy(DomicJnlLine);
        DomJnlLine.SetRange("Journal Template Name", DomJnlLine."Journal Template Name");
        DomJnlLine.SetRange("Journal Batch Name", DomJnlLine."Journal Batch Name");
        if DomJnlLine."Bank Account No." <> '' then
            DomJnlLine.SetRange("Bank Account No.", DomJnlLine."Bank Account No.");
        if DomJnlLine."Posting Date" <> 0D then
            DomJnlLine.SetRange("Posting Date", DomJnlLine."Posting Date");
        OnCreateDomiciliationsOnAfterSetFilters(DomJnlLine);
        DomJnlTemplate.Get(DomJnlLine."Journal Template Name");
        REPORT.RunModal(REPORT::"File Domiciliations", true, false, DomJnlLine);
    end;

    [Scope('OnPrem')]
    procedure AssignBankAccount(DomicJnlLine: Record "Domiciliation Journal Line"; BankName: Code[20])
    var
        DomicilJnlLine: Record "Domiciliation Journal Line";
    begin
        // Copies name of bank on all lines ...
        DomicilJnlLine.SetCurrentKey("Customer No.");
        DomicilJnlLine.SetRange("Journal Template Name", DomicJnlLine."Journal Template Name");
        DomicilJnlLine.SetRange("Journal Batch Name", DomicJnlLine."Journal Batch Name");
        DomicilJnlLine.SetRange("Customer No.", DomicJnlLine."Customer No.");
        DomicilJnlLine.SetRange("Bank Account No.", BankName);
        if DomicJnlLine."Bank Account No." = '' then
            DomicilJnlLine.SetRange(Status, DomicilJnlLine.Status::Marked)
        else
            DomicilJnlLine.SetRange(Status, DomicilJnlLine.Status::" ");
        // No MODIFYALL, but VALIDATE
        if DomicilJnlLine.FindSet(true) then
            repeat
                DomicilJnlLine.Validate("Bank Account No.", DomicJnlLine."Bank Account No.");
                DomicilJnlLine.Modify(true);
            until DomicilJnlLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateReference(CustLedgEntry: Record "Cust. Ledger Entry"): Text[16]
    var
        ReferenceDecimal: Decimal;
        ReferenceCheckSum: Decimal;
        Reference: Text[30];
    begin
        Reference := PaymJnlManagement.ConvertToDigit(CustLedgEntry."Document No.", 20);
        Evaluate(ReferenceDecimal, Reference);
        ReferenceCheckSum := ReferenceDecimal mod 97;
        if ReferenceCheckSum = 0 then
            ReferenceDecimal := ReferenceDecimal * 100 + 97
        else
            ReferenceDecimal := ReferenceDecimal * 100 + ReferenceCheckSum;
        exit(PaymJnlManagement.DecimalNumeralZeroFormat(ReferenceDecimal, 16));
    end;

    [Scope('OnPrem')]
    procedure CheckDomiciliationNo(DomiciliationNo: Text[30]): Boolean
    begin
        exit(PaymJnlManagement.Mod97Test(DomiciliationNo));
    end;

    [Scope('OnPrem')]
    procedure ModifyPmtDiscDueDate(DomicJnlLine: Record "Domiciliation Journal Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document Type", DomicJnlLine."Applies-to Doc. Type");
        CustLedgEntry.SetRange("Document No.", DomicJnlLine."Applies-to Doc. No.");
        CustLedgEntry.SetRange("Customer No.", DomicJnlLine."Customer No.");
        if CustLedgEntry.FindLast() then begin
            CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", -DomicJnlLine."Pmt. Disc. Possible");
            CustLedgEntry.Validate("Pmt. Discount Date", DomicJnlLine."Posting Date");
            CustLedgEntry.Modify(true)
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDomiciliationsOnAfterSetFilters(var DomiciliationJournalLine: Record "Domiciliation Journal Line")
    begin
    end;
}

