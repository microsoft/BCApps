// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Check;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

codeunit 28090 PostDatedCheckMgt
{
    Permissions = TableData "Cust. Ledger Entry" = rim,
                  TableData "Vendor Ledger Entry" = rim;

    trigger OnRun()
    begin
    end;

    var
        GenJnlManagement: Codeunit GenJnlManagement;
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        PostDatedCheck: Record "Post Dated Check Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLSetup: Record "General Ledger Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        CreateVendorPmtSuggestion: Report "Suggest Vendor Payments";
        Text1500000: Label '%1 %2 %3 lines created.';
        Text1500001: Label 'Journal Template %1, Batch Name %2, Line Number %3 was not a Post Dated Check Entry.';
        Text1500002: Label 'Are you sure you want to cancel the post dated check?';
        Text1500003: Label 'Cancelled from Cash Receipt Journal.';
        Text1500004: Label 'Cancelled from Payment Journal.';
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        Text1500005: Label 'Account Type shall be vendor';
        DocPrint: Codeunit "Document-Print";
        Text1500006: Label 'Void Check %1?';
        CheckManagement: Codeunit CheckManagement;
        LineNumber: Integer;
        CheckCount: Integer;

    [Scope('OnPrem')]
    procedure Post(var PostDatedCheck: Record "Post Dated Check Line")
    begin
        PostDatedCheck.FindFirst();
        CheckCount := PostDatedCheck.Count();
        repeat
            GenJnlLine.Reset();
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Customer then begin
                SalesSetup.Get();
                SalesSetup.TestField("Post Dated Check Template");
                SalesSetup.TestField("Post Dated Check Batch");
                GenJnlLine.SetRange("Journal Template Name", SalesSetup."Post Dated Check Template");
                if PostDatedCheck."Batch Name" <> '' then
                    GenJnlLine.SetRange("Journal Batch Name", PostDatedCheck."Batch Name")
                else
                    GenJnlLine.SetRange("Journal Batch Name", SalesSetup."Post Dated Check Batch");
            end else
                if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then begin
                    PurchSetup.Get();
                    PurchSetup.TestField("Post Dated Check Template");
                    PurchSetup.TestField("Post Dated Check Batch");
                    GenJnlLine.SetRange("Journal Template Name", PurchSetup."Post Dated Check Template");
                    if PostDatedCheck."Batch Name" <> '' then
                        GenJnlLine.SetRange("Journal Batch Name", PostDatedCheck."Batch Name")
                    else
                        GenJnlLine.SetRange("Journal Batch Name", PurchSetup."Post Dated Check Batch");
                end;

            if GenJnlLine.FindLast() then begin
                LineNumber := GenJnlLine."Line No.";
                GenJnlLine2 := GenJnlLine;
            end else
                LineNumber := 0;
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Customer then begin
                GenJnlManagement.OpenJnl(SalesSetup."Post Dated Check Batch", GenJnlLine);
                Commit();
                GenJnlLine.Init();
                GenJnlLine."Journal Template Name" := SalesSetup."Post Dated Check Template";
                if PostDatedCheck."Batch Name" <> '' then
                    GenJnlLine.Validate("Journal Batch Name", PostDatedCheck."Batch Name")
                else
                    GenJnlLine.Validate("Journal Batch Name", SalesSetup."Post Dated Check Batch");
            end else
                if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then begin
                    GenJnlManagement.OpenJnl(PurchSetup."Post Dated Check Batch", GenJnlLine);
                    GenJnlLine.Init();
                    GenJnlLine."Journal Template Name" := PurchSetup."Post Dated Check Template";
                    if PostDatedCheck."Batch Name" <> '' then
                        GenJnlLine.Validate("Journal Batch Name", PostDatedCheck."Batch Name")
                    else
                        GenJnlLine.Validate("Journal Batch Name", PurchSetup."Post Dated Check Batch");
                end;
            GenJnlLine."Line No." := LineNumber + 10000;
            GenJnlLine.SetUpNewLine(GenJnlLine2, 0, true);
            GenJnlLine.Validate("Posting Date", PostDatedCheck."Check Date");
            GenJnlLine.Validate("Document Date", PostDatedCheck."Check Date");
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Customer then
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::"G/L Account" then
                GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
            GenJnlLine.Validate("Account No.", PostDatedCheck."Account No.");
            GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
            GenJnlLine."Interest Amount" := PostDatedCheck."Interest Amount";
            GenJnlLine."Interest Amount (LCY)" := PostDatedCheck."Interest Amount (LCY)";
            GenJnlLine."Applies-to Doc. Type" := PostDatedCheck."Applies-to Doc. Type";
            GenJnlLine."Applies-to Doc. No." := PostDatedCheck."Applies-to Doc. No.";
            if (PostDatedCheck."Document No." <> '') or PostDatedCheck."Check Printed" then
                GenJnlLine."Document No." := PostDatedCheck."Document No.";
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Customer then begin
                if PostDatedCheck."Applies-to ID" <> '' then begin
                    CustLedgEntry.SetRange("Applies-to ID", PostDatedCheck."Applies-to ID");
                    if CustLedgEntry.FindSet() then
                        repeat
                            CustLedgEntry."Applies-to ID" := GenJnlLine."Document No.";
                            CustLedgEntry.Modify();
                        until CustLedgEntry.Next() = 0;
                    GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
                end;
            end
            else
                if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then
                    if PostDatedCheck."Applies-to ID" <> '' then begin
                        VendLedgEntry.SetRange("Applies-to ID", PostDatedCheck."Applies-to ID");
                        if VendLedgEntry.FindSet() then
                            repeat
                                VendLedgEntry."Applies-to ID" := GenJnlLine."Document No.";
                                VendLedgEntry.Modify();
                            until VendLedgEntry.Next() = 0;
                        GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
                    end;

            GenJnlLine.Validate("Currency Code", PostDatedCheck."Currency Code");
            GenJnlLine.Validate(Amount, PostDatedCheck.Amount);
            GenJnlLine."Check No." := PostDatedCheck."Check No.";
            GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then
                if PostDatedCheck."Bank Account" <> '' then
                    GenJnlLine.Validate("Bal. Account No.", PostDatedCheck."Bank Account");
            GenJnlLine."Bank Payment Type" := PostDatedCheck."Bank Payment Type";
            GenJnlLine."Check Printed" := PostDatedCheck."Check Printed";
            GenJnlLine."Post Dated Check" := true;
            GenJnlLine.Insert(true);
            GenJnlLine2 := GenJnlLine;
            Commit();
        until PostDatedCheck.Next() = 0;
        PostDatedCheck.DeleteAll();

        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Customer:
                if CheckCount > 0 then
                    Message(Text1500000, CheckCount, SalesSetup."Post Dated Check Template",
                        SalesSetup."Post Dated Check Batch");
            GenJnlLine."Account Type"::Vendor:
                if CheckCount > 0 then
                    Message(Text1500000, CheckCount, PurchSetup."Post Dated Check Template",
                        PurchSetup."Post Dated Check Batch");
        end;
    end;

    [Scope('OnPrem')]
    procedure CancelCheck(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if not GenJnlLine."Post Dated Check" then
            Error(Text1500001, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Line No.");
        if not Confirm(Text1500002, false) then
            exit;
        PostDatedCheck.Reset();
        PostDatedCheck.SetCurrentKey("Line Number");
        if PostDatedCheck.FindLast() then
            LineNumber := PostDatedCheck."Line Number"
        else
            LineNumber := 0;
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::"G/L Account");
            GenJnlLine."Account Type"::Customer:
                PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::Customer);
            GenJnlLine."Account Type"::Vendor:
                PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::Vendor);
        end;

        PostDatedCheck.Init();
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::"G/L Account":
                PostDatedCheck.Validate("Account Type", PostDatedCheck."Account Type"::"G/L Account");
            GenJnlLine."Account Type"::Customer:
                PostDatedCheck.Validate("Account Type", PostDatedCheck."Account Type"::Customer);
            GenJnlLine."Account Type"::Vendor:
                PostDatedCheck.Validate("Account Type", PostDatedCheck."Account Type"::Vendor);
        end;
        PostDatedCheck.Validate("Batch Name", GenJnlLine."Journal Batch Name");
        PostDatedCheck.Validate("Account No.", GenJnlLine."Account No.");
        PostDatedCheck."Check Date" := GenJnlLine."Document Date";
        PostDatedCheck."Line Number" := LineNumber + 10000;
        PostDatedCheck.Validate("Currency Code", GenJnlLine."Currency Code");
        PostDatedCheck."Date Received" := WorkDate();
        PostDatedCheck."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
        PostDatedCheck."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        PostDatedCheck.Validate(Amount, GenJnlLine.Amount);
        PostDatedCheck."Check No." := GenJnlLine."Check No.";
        PostDatedCheck."Bank Payment Type" := GenJnlLine."Bank Payment Type";
        PostDatedCheck."Check Printed" := GenJnlLine."Check Printed";
        PostDatedCheck."Interest Amount" := GenJnlLine."Interest Amount";
        PostDatedCheck."Interest Amount (LCY)" := GenJnlLine."Interest Amount (LCY)";
        PostDatedCheck."Dimension Set ID" := GenJnlLine."Dimension Set ID";
        PostDatedCheck."Document No." := GenJnlLine."Document No.";
        PostDatedCheck."Bank Account" := GenJnlLine."Bal. Account No.";
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then begin
            if GenJnlLine."Applies-to ID" <> '' then begin
                CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                if CustLedgEntry.FindSet() then
                    repeat
                        CustLedgEntry."Applies-to ID" := PostDatedCheck."Document No.";
                        CustLedgEntry.Modify();
                    until CustLedgEntry.Next() = 0;
                PostDatedCheck."Applies-to ID" := PostDatedCheck."Document No.";
            end;
        end else
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then
                if GenJnlLine."Applies-to ID" <> '' then begin
                    VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                    if VendLedgEntry.FindSet() then
                        repeat
                            VendLedgEntry."Applies-to ID" := PostDatedCheck."Document No.";
                            VendLedgEntry.Modify();
                        until VendLedgEntry.Next() = 0;
                    PostDatedCheck."Applies-to ID" := PostDatedCheck."Document No.";
                end;

        if GenJnlLine."Check Printed" then begin
            PostDatedCheck."Bank Account" := GenJnlLine."Bal. Account No.";
            PostDatedCheck."Document No." := GenJnlLine."Document No.";
        end;

        if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Customer then
            PostDatedCheck.Comment := Text1500003
        else
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then
                PostDatedCheck.Comment := Text1500004;

        PostDatedCheck.Insert();
        if GenJnlLine.Find() then
            GenJnlLine.Delete();
    end;

    [Scope('OnPrem')]
    procedure CopySuggestedVendorPayments()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", GLSetup."Post Dated Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", GLSetup."Post Dated Journal Batch");
        GenJnlLine.SetFilter("Account No.", '<>%1', '');
        if GenJnlLine.FindSet() then begin
            repeat
                PostDatedCheck.Reset();
                PostDatedCheck.SetRange("Account Type", GenJnlLine."Account Type"::Vendor);
                PostDatedCheck.SetRange("Account No.", GenJnlLine."Account No.");
                PostDatedCheck.SetRange("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type");
                PostDatedCheck.SetRange("Applies-to Doc. No.", GenJnlLine."Applies-to Doc. No.");
                if not PostDatedCheck.FindFirst() then begin
                    PostDatedCheck.Reset();
                    case GenJnlLine."Account Type" of
                        GenJnlLine."Account Type"::"G/L Account":
                            PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::"G/L Account");
                        GenJnlLine."Account Type"::Customer:
                            PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::Customer);
                        GenJnlLine."Account Type"::Vendor:
                            PostDatedCheck.SetRange("Account Type", PostDatedCheck."Account Type"::Vendor);
                    end;
                    PostDatedCheck.SetRange("Account No.", GenJnlLine."Account No.");
                    if PostDatedCheck.FindLast() then
                        LineNumber := PostDatedCheck."Line Number" + 10000
                    else
                        LineNumber := 10000;

                    PostDatedCheck.Init();
                    case GenJnlLine."Account Type" of
                        GenJnlLine."Account Type"::"G/L Account":
                            PostDatedCheck.Validate("Account Type", PostDatedCheck."Account Type"::"G/L Account");
                        GenJnlLine."Account Type"::Customer:
                            PostDatedCheck.Validate("Account Type", PostDatedCheck."Account Type"::Customer);
                        GenJnlLine."Account Type"::Vendor:
                            PostDatedCheck.Validate("Account Type", PostDatedCheck."Account Type"::Vendor);
                    end;
                    PostDatedCheck.Validate("Account No.", GenJnlLine."Account No.");
                    PostDatedCheck."Check Date" := GenJnlLine."Document Date";
                    PostDatedCheck."Document No." := GenJnlLine."Document No.";
                    PostDatedCheck."Line Number" := LineNumber;
                    PostDatedCheck.Validate("Currency Code", GenJnlLine."Currency Code");
                    PostDatedCheck."Date Received" := WorkDate();
                    PostDatedCheck."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
                    PostDatedCheck."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
                    PostDatedCheck."Applies-to ID" := GenJnlLine."Applies-to ID";
                    PostDatedCheck.Validate(Amount, GenJnlLine.Amount);
                    PostDatedCheck."Check No." := GenJnlLine."Check No.";
                    PostDatedCheck."Bank Payment Type" := GenJnlLine."Bank Payment Type";
                    if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Bank Account" then
                        PostDatedCheck."Bank Account" := GenJnlLine."Bal. Account No.";
                    PostDatedCheck."Interest Amount" := GenJnlLine."Interest Amount";
                    PostDatedCheck."Interest Amount (LCY)" := GenJnlLine."Interest Amount (LCY)";
                    PostDatedCheck."Check Printed" := GenJnlLine."Check Printed";
                    PostDatedCheck.Insert();
                end;
            until GenJnlLine.Next() = 0;
            GenJnlLine.DeleteAll();
        end;
    end;

    [Scope('OnPrem')]
    procedure AssignGenJnlLine(var PostDatedCheck: Record "Post Dated Check Line")
    begin
        GLSetup.Get();
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", GLSetup."Post Dated Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", GLSetup."Post Dated Journal Batch");
        GenJnlLine.SetRange("Post Dated Check", true);
        if GenJnlLine.FindFirst() then
            GenJnlLine.DeleteAll();
        GenJnlLine."Line No." := PostDatedCheck."Line Number";
        GenJnlLine."Journal Template Name" := GLSetup."Post Dated Journal Template";
        GenJnlLine."Journal Batch Name" := GLSetup."Post Dated Journal Batch";
        GenJnlLine."Account No." := PostDatedCheck."Account No.";
        GenJnlLine."Posting Date" := PostDatedCheck."Check Date";
        GenJnlLine."Document Date" := PostDatedCheck."Check Date";
        GenJnlLine."Document No." := PostDatedCheck."Document No.";
        GenJnlLine.Description := PostDatedCheck.Description;
        GenJnlLine.Validate("Currency Code", PostDatedCheck."Currency Code");
        if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Customer then begin
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine.Amount := PostDatedCheck.Amount;
            if PostDatedCheck."Currency Code" = '' then
                GenJnlLine."Amount (LCY)" := PostDatedCheck.Amount
            else
                GenJnlLine."Amount (LCY)" := Round(
                    CurrExchRate.ExchangeAmtFCYToLCY(
                      PostDatedCheck."Date Received", PostDatedCheck."Currency Code",
                      PostDatedCheck.Amount, PostDatedCheck."Currency Factor"));
        end else
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::"G/L Account" then
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account"
            else begin
                if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                GenJnlLine.Validate(Amount, PostDatedCheck.Amount);
                GenJnlLine."Interest Amount" := PostDatedCheck."Interest Amount";
                GenJnlLine."Interest Amount (LCY)" := PostDatedCheck."Interest Amount (LCY)";
            end;

        GenJnlLine."Applies-to Doc. Type" := PostDatedCheck."Applies-to Doc. Type";
        GenJnlLine."Applies-to Doc. No." := PostDatedCheck."Applies-to Doc. No.";
        GenJnlLine."Applies-to ID" := PostDatedCheck."Applies-to ID";
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Post Dated Check" := true;
        GenJnlLine."Check No." := PostDatedCheck."Check No.";
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := PostDatedCheck."Bank Account";
        GenJnlLine."Bank Payment Type" := PostDatedCheck."Bank Payment Type";
        GenJnlLine."Check Printed" := PostDatedCheck."Check Printed";
    end;

    [Scope('OnPrem')]
    procedure ApplyEntries(var PostDatedCheckLine: Record "Post Dated Check Line")
    begin
        GenJnlLine.Init();
        AssignGenJnlLine(PostDatedCheckLine);
        GenJnlLine.Insert();
        Commit();
        GenJnlApply.Run(GenJnlLine);
        Clear(GenJnlApply);
        if GenJnlLine."Applies-to ID" = PostDatedCheckLine."Document No." then begin
            PostDatedCheckLine.Validate(Amount, GenJnlLine.Amount);
            PostDatedCheckLine.Validate("Applies-to ID", PostDatedCheckLine."Document No.");
            PostDatedCheckLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
            PostDatedCheckLine."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
            PostDatedCheckLine.Modify();
        end;
        GLSetup.Get();
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", GLSetup."Post Dated Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", GLSetup."Post Dated Journal Batch");
        GenJnlLine.SetRange("Post Dated Check", true);
        if GenJnlLine.FindFirst() then
            GenJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SuggestVendorPayments()
    begin
        GLSetup.Get();
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GLSetup."Post Dated Journal Template";
        GenJnlLine."Journal Batch Name" := GLSetup."Post Dated Journal Batch";
        CreateVendorPmtSuggestion.SetGenJnlLine(GenJnlLine);
        CreateVendorPmtSuggestion.RunModal();
        CopySuggestedVendorPayments();
        Clear(CreateVendorPmtSuggestion);
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", GLSetup."Post Dated Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", GLSetup."Post Dated Journal Batch");
        if GenJnlLine.FindFirst() then
            GenJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure PreviewCheck(var PostDatedCheckLine: Record "Post Dated Check Line")
    begin
        if PostDatedCheckLine."Account Type" <> PostDatedCheckLine."Account Type"::Vendor then
            Error(Text1500005);
        GenJnlLine.Init();
        AssignGenJnlLine(PostDatedCheckLine);
        GenJnlLine.Insert();
        Commit();
        PAGE.RunModal(PAGE::"Check Preview", GenJnlLine);
        GLSetup.Get();
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", GLSetup."Post Dated Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", GLSetup."Post Dated Journal Batch");
        GenJnlLine.SetRange("Post Dated Check", true);
        if GenJnlLine.FindFirst() then
            GenJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure PrintCheck(var PostDatedCheckLine: Record "Post Dated Check Line")
    begin
        if PostDatedCheckLine."Account Type" <> PostDatedCheckLine."Account Type"::Vendor then
            Error(Text1500005);
        GenJnlLine.Init();
        AssignGenJnlLine(PostDatedCheckLine);
        GenJnlLine.Insert();
        Commit();
        DocPrint.PrintCheck(GenJnlLine);
        if GenJnlLine.FindFirst() then begin
            PostDatedCheckLine."Check Printed" := GenJnlLine."Check Printed";
            PostDatedCheckLine."Check No." := GenJnlLine."Document No.";
            PostDatedCheckLine."Document No." := GenJnlLine."Document No.";
            PostDatedCheckLine.Modify();
            GenJnlLine.DeleteAll();
        end;
        GLSetup.Get();
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", GLSetup."Post Dated Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", GLSetup."Post Dated Journal Batch");
        GenJnlLine.SetRange("Post Dated Check", true);
        if GenJnlLine.FindFirst() then
            GenJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure VoidCheck(var PostDatedCheckLine: Record "Post Dated Check Line")
    begin
        if PostDatedCheckLine."Account Type" <> PostDatedCheckLine."Account Type"::Vendor then
            Error(Text1500000);
        PostDatedCheckLine.TestField("Bank Payment Type", PostDatedCheckLine."Bank Payment Type"::"Computer Check");
        PostDatedCheckLine.TestField("Check Printed", true);
        GenJnlLine.Init();
        AssignGenJnlLine(PostDatedCheckLine);
        GenJnlLine.Insert();
        Commit();
        if Confirm(Text1500006, false, PostDatedCheckLine."Document No.") then
            CheckManagement.VoidCheck(GenJnlLine);
        GLSetup.Get();
        GenJnlLine.Reset();
        GenJnlLine.SetRange("Journal Template Name", GLSetup."Post Dated Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", GLSetup."Post Dated Journal Batch");
        GenJnlLine.SetRange("Post Dated Check", true);
        if GenJnlLine.FindFirst() then begin
            PostDatedCheckLine."Check Printed" := GenJnlLine."Check Printed";
            PostDatedCheckLine.Modify();
            GenJnlLine.DeleteAll();
        end;
    end;
}

