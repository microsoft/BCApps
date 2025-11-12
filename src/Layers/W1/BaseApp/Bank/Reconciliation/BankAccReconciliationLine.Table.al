// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.IO;
using System.Utilities;

table 274 "Bank Acc. Reconciliation Line"
{
    Caption = 'Bank Acc. Reconciliation Line';
    Permissions = TableData "Data Exch. Field" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(5; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Statement Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Statement Amount';

            trigger OnValidate()
            begin
                Difference := "Statement Amount" - "Applied Amount";
            end;
        }
        field(8; Difference; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Difference';

            trigger OnValidate()
            begin
                "Statement Amount" := "Applied Amount" + Difference;
            end;
        }
        field(9; "Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Applied Amount';
            Editable = false;

            trigger OnValidate()
            begin
                Difference := "Statement Amount" - "Applied Amount";
            end;
        }
        field(11; "Applied Entries"; Integer)
        {
            Caption = 'Applied Entries';
            Editable = false;

            trigger OnLookup()
            begin
                Rec.DisplayApplication();
            end;
        }
        field(12; "Value Date"; Date)
        {
            Caption = 'Value Date';
        }
        field(13; "Ready for Application"; Boolean)
        {
            Caption = 'Ready for Application';
        }
        field(14; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(15; "Related-Party Name"; Text[250])
        {
            Caption = 'Related-Party Name';
        }
        field(16; "Additional Transaction Info"; Text[100])
        {
            Caption = 'Additional Transaction Info';
        }
        field(17; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(18; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(20; "Statement Type"; Enum "Bank Acc. Rec. Stmt. Type")
        {
            Caption = 'Statement Type';
        }
        field(21; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                TestField("Applied Amount", 0);
                if "Account Type" = "Account Type"::"IC Partner" then
                    if not ConfirmManagement.GetResponse(ICPartnerAccountTypeQst, false) then begin
                        "Account Type" := xRec."Account Type";
                        exit;
                    end;
                if "Account Type" <> xRec."Account Type" then
                    Validate("Account No.", '');
            end;
        }
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                          Blocked = const(false))
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Account Type" = const(Employee)) Employee;

            trigger OnValidate()
            begin
                TestField("Applied Amount", 0);
                CreateDimFromDefaultDim();
            end;
        }
        field(23; "Transaction Text"; Text[140])
        {
            Caption = 'Transaction Text';

            trigger OnValidate()
            begin
                if ("Statement Type" = "Statement Type"::"Payment Application") or (Description = '') then
                    Description := CopyStr("Transaction Text", 1, MaxStrLen(Description));
            end;
        }
        field(24; "Related-Party Bank Acc. No."; Text[100])
        {
            Caption = 'Related-Party Bank Acc. No.';
        }
        field(25; "Related-Party Address"; Text[100])
        {
            Caption = 'Related-Party Address';
        }
        field(26; "Related-Party City"; Text[50])
        {
            Caption = 'Related-Party City';
        }
        field(27; "Payment Reference No."; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(32; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(50; "Match Confidence"; Enum "Bank Rec. Match Confidence")
        {
            CalcFormula = max("Applied Payment Entry"."Match Confidence" where("Statement Type" = field("Statement Type"),
                                                                                "Bank Account No." = field("Bank Account No."),
                                                                                "Statement No." = field("Statement No."),
                                                                                "Statement Line No." = field("Statement Line No.")));
            Caption = 'Match Confidence';
            Editable = false;
            FieldClass = FlowField;
            InitValue = "None";
        }
        field(51; "Match Quality"; Integer)
        {
            CalcFormula = max("Applied Payment Entry".Quality where("Bank Account No." = field("Bank Account No."),
                                                                     "Statement No." = field("Statement No."),
                                                                     "Statement Line No." = field("Statement Line No."),
                                                                     "Statement Type" = field("Statement Type")));
            Caption = 'Match Quality';
            Editable = false;
            FieldClass = FlowField;
        }
        field(60; "Sorting Order"; Integer)
        {
            Caption = 'Sorting Order';
        }
        field(61; "Parent Line No."; Integer)
        {
            Caption = 'Parent Line No.';
            Editable = false;
        }
        field(70; "Transaction ID"; Text[50])
        {
            Caption = 'Transaction ID';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Account Type", "Statement Amount")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        RemoveApplication();
        ClearDataExchEntries();
        RemoveAppliedPaymentEntries();
        DeletePaymentMatchingDetails();
        UpdateParentLineStatementAmount();
        if Find() then;
    end;

    trigger OnInsert()
    begin
        BankAccRecon.Get("Statement Type", "Bank Account No.", "Statement No.");
        "Applied Entries" := 0;
        Validate("Applied Amount", 0);
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, IsHandled);
        if IsHandled then
            exit;

        if xRec."Statement Amount" <> "Statement Amount" then
            RemoveApplication();
    end;

    trigger OnRename()
    begin
        Error(YouCannotRenameErr, TableCaption);
    end;

    var
        BankAccSetStmtNo: Codeunit "Bank Acc. Entry Set Recon.-No.";
        DimMgt: Codeunit DimensionManagement;
        ConfirmManagement: Codeunit "Confirm Management";

        YouCannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 - Table name';
        AmountWithinToleranceRangeTok: Label '>=%1&<=%2', Locked = true;
        AmountOustideToleranceRangeTok: Label '<%1|>%2', Locked = true;
        TransactionAmountMustNotBeZeroErr: Label 'The Transaction Amount field must have a value that is not 0.';
        CreditTheAccountQst: Label 'The remaining amount to apply is %2.\\Do you want to create a new payment application line that will debit or credit %1 with the remaining amount when you post the payment?', Comment = '%1 is the account name, %2 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';
        ExcessiveAmountErr: Label 'The remaining amount to apply is %1.', Comment = '%1 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';
        ImportPostedTransactionsQst: Label 'The bank statement contains payments that are already applied, but the related bank account ledger entries are not closed.\\Do you want to include these payments in the import?';
        ICPartnerAccountTypeQst: Label 'The resulting entry will be of type IC Transaction, but no Intercompany Outbox transaction will be created. \\Do you want to use the IC Partner account type anyway?';
        AppliedEntriesFilterLbl: Label '|%1', Locked = true;
        MatchedAutomaticallyFilterLbl: Label '=%1|%2|%3|%4', Locked = true;
        NotAppliedTxt: Label 'Not applied';
        MatchedAutomaticallyTxt: Label 'Matched Automatically';
        MatchedFromTextMappingRulesTxt: Label 'Matched - Text-To-Account Mapping';
        AppliedManuallyStatusTxt: Label 'Applied Manually';
        ReviewedStatusTxt: Label 'Application Reviewed';
        PaymentRecJournalFeatureNameTelemetryTxt: Label 'Payment Reconciliation', Locked = true;

    protected var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";

    internal procedure GetPaymentRecJournalTelemetryFeatureName(): Text
    begin
        exit(PaymentRecJournalFeatureNameTelemetryTxt);
    end;

    procedure DisplayApplication()
    var
        PaymentApplication: Page "Payment Application";
    begin
        case "Statement Type" of
            "Statement Type"::"Bank Reconciliation":
                begin
                    BankAccLedgEntry.Reset();
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open);
                    BankAccLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
                    BankAccLedgEntry.SetRange(Open, true);
                    BankAccLedgEntry.SetRange(
                        "Statement Status", BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
                    BankAccLedgEntry.SetRange("Statement No.", "Statement No.");
                    BankAccLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
                    OnDisplayApplicationOnAfterBankAccLedgEntrySetFilters(Rec, BankAccLedgEntry);
                    PAGE.Run(0, BankAccLedgEntry);
                end;
            "Statement Type"::"Payment Application":
                begin
                    if "Statement Amount" = 0 then
                        Error(TransactionAmountMustNotBeZeroErr);
                    PaymentApplication.SetBankAccReconcLine(Rec);
                    OnDisplayApplicationOnAfterSetBankAccReconcLine(PaymentApplication);
                    PaymentApplication.RunModal();
                end;
        end;
    end;

    procedure TransferFromPostedPaymentReconLine(PostedPaymentReconLine: Record "Posted Payment Recon. Line")
    begin
        Rec."Bank Account No." := PostedPaymentReconLine."Bank Account No.";
        Rec."Statement No." := PostedPaymentReconLine."Statement No.";
        Rec."Statement Line No." := PostedPaymentReconLine."Statement Line No.";
        Rec."Document No." := PostedPaymentReconLine."Document No.";
        Rec."Transaction Date" := PostedPaymentReconLine."Transaction Date";
        Rec.Description := PostedPaymentReconLine.Description;
        Rec."Statement Amount" := PostedPaymentReconLine."Statement Amount";
        Rec.Difference := PostedPaymentReconLine.Difference;
        Rec."Applied Amount" := PostedPaymentReconLine."Applied Amount";
        Rec."Applied Entries" := PostedPaymentReconLine."Applied Entries";
        Rec."Value Date" := PostedPaymentReconLine."Value Date";
        Rec."Check No." := PostedPaymentReconLine."Check No.";
        Rec."Related-Party Name" := PostedPaymentReconLine."Related-Party Name";
        Rec."Additional Transaction Info" := PostedPaymentReconLine."Additional Transaction Info";
        Rec."Data Exch. Entry No." := PostedPaymentReconLine."Data Exch. Entry No.";
        Rec."Data Exch. Line No." := PostedPaymentReconLine."Data Exch. Line No.";
        Rec."Statement Type" := Rec."Statement Type"::"Payment Application";
        Rec."Account Type" := PostedPaymentReconLine."Account Type";
        Rec."Account No." := PostedPaymentReconLine."Account No.";
        Rec."Transaction Text" := PostedPaymentReconLine.Description;
        Rec."Transaction ID" := CopyStr(PostedPaymentReconLine."Transaction ID", 1, MaxStrLen(Rec."Transaction ID"));
        OnAfterTransferFromPostedPaymentReconLine(Rec, PostedPaymentReconLine);
    end;

    procedure GetPaymentFile(var DataExchField: Record "Data Exch. Field"): Boolean
    begin
        if not DataExchField.ReadPermission() then
            exit(false);

        DataExchField.SetRange("Data Exch. No.", "Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", "Data Exch. Line No.");
        exit(DataExchField.FindFirst());
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        BankAccount: Record "Bank Account";
    begin
        if "Bank Account No." = BankAccount."No." then
            exit(BankAccount."Currency Code");

        if BankAccount.Get("Bank Account No.") then
            exit(BankAccount."Currency Code");

        exit('');
    end;

    procedure GetStyle() Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetStyle(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Applied Entries" <> 0 then
            exit('Favorable');

        exit('');
    end;

    procedure ClearDataExchEntries()
    var
        DataExchField: Record "Data Exch. Field";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", "Data Exch. Line No.");

        BankAccReconciliationLine.SetRange("Statement Type", "Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", "Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", "Statement No.");
        BankAccReconciliationLine.SetRange("Data Exch. Entry No.", "Data Exch. Entry No.");
        BankAccReconciliationLine.SetFilter("Statement Line No.", '<>%1', "Statement Line No.");
        if BankAccReconciliationLine.IsEmpty() then
            DataExchField.DeleteRelatedRecords("Data Exch. Entry No.", 0);
    end;

    procedure ShowDimensions()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDimensions(Rec, IsHandled);
        if IsHandled then
            exit;
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Statement No.", "Statement Line No."));
        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnAfterShowDimensions(Rec);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Payment Reconciliation Journal",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", BankAccReconciliation."Dimension Set ID", DATABASE::"Bank Account");

        DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure SetUpNewLine()
    begin
        "Transaction Date" := WorkDate();
        "Match Confidence" := "Match Confidence"::None;
        "Document No." := '';

        OnAfterSetUpNewLine(Rec, xRec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure AcceptAppliedPaymentEntriesSelectedLines()
    begin
        if FindSet() then
            repeat
                AcceptApplication();
            until Next() = 0;
    end;

    procedure RejectAppliedPaymentEntriesSelectedLines()
    begin
        if FindSet() then
            repeat
                RejectAppliedPayment();
            until Next() = 0;
    end;

    procedure RejectAppliedPayment()
    begin
        RemoveAppliedPaymentEntries();
        DeletePaymentMatchingDetails();
    end;

    procedure AcceptApplication()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        // For customer payments, the applied amount is positive, so positive difference means excessive amount.
        // For vendor payments, the applied amount is negative, so negative difference means excessive amount.
        // If "Applied Amount" and Difference have the same sign, then this is an overpayment situation.
        // Two non-zero numbers have the same sign if and only if their product is a positive number.
        if Difference * "Applied Amount" > 0 then begin
            if "Account Type" = "Account Type"::"Bank Account" then
                Error(ExcessiveAmountErr, Difference);
            SetAppliedPaymentEntryFromRec(AppliedPaymentEntry);
            if not AppliedPaymentEntry.Find() then begin
                if not Confirm(StrSubstNo(CreditTheAccountQst, GetAppliedToName(), Difference)) then
                    exit;
                TransferRemainingAmountToAccount();
            end;
        end;

        AppliedPaymentEntry.FilterAppliedPmtEntry(Rec);
        AppliedPaymentEntry.ModifyAll("Match Confidence", "Match Confidence"::Accepted);
    end;

    procedure FilterManyToOneMatches(var BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer")
    begin
        BankAccRecMatchBuffer.SetRange("Statement No.", Rec."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Statement Line No.", Rec."Statement Line No.");
    end;

    protected procedure RemoveApplication()
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ManyToOneBLEFound: Boolean;
    begin
        if "Statement Type" <> "Statement Type"::"Bank Reconciliation" then
            exit;
        FilterManyToOneMatches(BankAccRecMatchBuffer);
        if BankAccRecMatchBuffer.FindFirst() then begin
            BankAccLedgEntry.Reset();
            BankAccLedgEntry.SetRange("Entry No.", BankAccRecMatchBuffer."Ledger Entry No.");
            BankAccLedgEntry.SetRange(Open, true);
            BankAccLedgEntry.SetRange(
                "Statement Status", BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied");
            if BankAccLedgEntry.FindFirst() then begin
                ManyToOneBLEFound := true;
                BankAccSetStmtNo.RemoveReconNo(BankAccLedgEntry, Rec, false);
                BankAccRecMatchBuffer.Delete();
            end;
        end;

        BankAccRecMatchBuffer.Reset();
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", BankAccLedgEntry."Entry No.");
        BankAccRecMatchBuffer.SetRange("Statement No.", Rec."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", Rec."Bank Account No.");
        if (BankAccRecMatchBuffer.FindSet()) and (ManyToOneBLEFound) then begin
            repeat
                BankAccReconciliationLine.SetRange("Statement Line No.", BankAccRecMatchBuffer."Statement Line No.");
                BankAccReconciliationLine.SetRange("Statement No.", BankAccRecMatchBuffer."Statement No.");
                BankAccReconciliationLine.SetRange("Bank Account No.", BankAccRecMatchBuffer."Bank Account No.");
                if BankAccReconciliationLine.FindFirst() then begin
                    BankAccReconciliationLine."Applied Entries" := 0;
                    BankAccReconciliationLine.Validate("Applied Amount", 0);
                    BankAccReconciliationLine.Modify();
                end;
            until BankAccRecMatchBuffer.Next() = 0;

            BankAccRecMatchBuffer.DeleteAll();
        end;

        BankAccLedgEntry.Reset();
        BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open);
        BankAccLedgEntry.SetRange("Bank Account No.", "Bank Account No.");
        BankAccLedgEntry.SetRange(Open, true);
        BankAccLedgEntry.SetFilter(
            "Statement Status", '%1|%2', BankAccLedgEntry."Statement Status"::"Bank Acc. Entry Applied", BankAccLedgEntry."Statement Status"::"Check Entry Applied");
        BankAccLedgEntry.SetRange("Statement No.", "Statement No.");
        BankAccLedgEntry.SetRange("Statement Line No.", "Statement Line No.");
        OnRemoveApplicationOnAfterBankAccLedgEntrySetFilters(Rec, BankAccLedgEntry);
        BankAccLedgEntry.LockTable();
        CheckLedgEntry.LockTable();
        if BankAccLedgEntry.Find('-') then
            repeat
                BankAccSetStmtNo.RemoveReconNo(BankAccLedgEntry, Rec, true);
            until BankAccLedgEntry.Next() = 0;
        "Applied Entries" := 0;
        Validate("Applied Amount", 0);
        Modify();
    end;

    procedure SetManualApplication()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.FilterAppliedPmtEntry(Rec);
        AppliedPaymentEntry.ModifyAll("Match Confidence", "Match Confidence"::Manual)
    end;

    local procedure RemoveAppliedPaymentEntries()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        Validate("Applied Amount", 0);
        Validate("Applied Entries", 0);
        Validate("Account No.", '');
        Modify(true);

        AppliedPaymentEntry.FilterAppliedPmtEntry(Rec);
        AppliedPaymentEntry.DeleteAll(true);

        OnAfterRemoveAppliedPaymentEntries(Rec);
    end;

    local procedure DeletePaymentMatchingDetails()
    var
        PaymentMatchingDetails: Record "Payment Matching Details";
    begin
        PaymentMatchingDetails.SetRange("Statement Type", "Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", "Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", "Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", "Statement Line No.");
        PaymentMatchingDetails.DeleteAll(true);
    end;

    procedure GetAppliedEntryAccountName(AppliedToEntryNo: Integer): Text
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedEntryAccountType(AppliedToEntryNo);
        AccountNo := GetAppliedEntryAccountNo(AppliedToEntryNo);
        exit(GetAccountName(AccountType, AccountNo));
    end;

    procedure GetAppliedToName(): Text
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedToAccountType();
        AccountNo := GetAppliedToAccountNo();
        exit(GetAccountName(AccountType, AccountNo));
    end;

    procedure GetAppliedEntryAccountType(AppliedToEntryNo: Integer): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get(AppliedToEntryNo) then
                exit(BankAccountLedgerEntry."Bal. Account Type".AsInteger());
        exit("Account Type".AsInteger());
    end;

    procedure GetAppliedToAccountType(): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get(GetFirstAppliedToEntryNo()) then
                exit(BankAccountLedgerEntry."Bal. Account Type".AsInteger());
        exit("Account Type".AsInteger());
    end;

    procedure GetAppliedEntryAccountNo(AppliedToEntryNo: Integer) AccountNo: Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                if CustLedgerEntry.Get(AppliedToEntryNo) then
                    exit(CustLedgerEntry."Customer No.");
            "Account Type"::Vendor:
                if VendorLedgerEntry.Get(AppliedToEntryNo) then
                    exit(VendorLedgerEntry."Vendor No.");
            "Account Type"::"Bank Account":
                if BankAccountLedgerEntry.Get(AppliedToEntryNo) then
                    exit(BankAccountLedgerEntry."Bal. Account No.");
        end;
        AccountNo := "Account No.";

        OnAfterGetAppliedEntryAccountNo(Rec, AppliedToEntryNo, AccountNo);
    end;

    procedure GetAppliedToAccountNo(): Code[20]
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get(GetFirstAppliedToEntryNo()) then
                exit(BankAccountLedgerEntry."Bal. Account No.");
        exit("Account No.")
    end;

    local procedure GetAccountName(AccountType: Option; AccountNo: Code[20]) Name: Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        case AccountType of
            "Account Type"::Customer.AsInteger():
                if Customer.Get(AccountNo) then
                    Name := Customer.Name;
            "Account Type"::Vendor.AsInteger():
                if Vendor.Get(AccountNo) then
                    Name := Vendor.Name;
            "Account Type"::Employee.AsInteger():
                if Employee.Get(AccountNo) then
                    Name := Employee.FullName();
            "Account Type"::"G/L Account".AsInteger():
                if GLAccount.Get(AccountNo) then
                    Name := GLAccount.Name;
            "Account Type"::"Bank Account".AsInteger():
                if BankAccount.Get(AccountNo) then
                    Name := BankAccount.Name;
        end;

        OnAfterGetAccountName(AccountType, AccountNo, Name);
    end;

    local procedure SetAppliedPaymentEntryFromRec(var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
        AppliedPaymentEntry.TransferFromBankAccReconLine(Rec);
        AppliedPaymentEntry."Account Type" := Enum::"Gen. Journal Account Type".FromInteger(GetAppliedToAccountType());
        AppliedPaymentEntry."Account No." := GetAppliedToAccountNo();
    end;

    procedure AppliedEntryAccountDrillDown(AppliedEntryNo: Integer)
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedEntryAccountType(AppliedEntryNo);
        AccountNo := GetAppliedEntryAccountNo(AppliedEntryNo);
        OpenAccountPage(AccountType, AccountNo);
    end;

    procedure AppliedToDrillDown()
    var
        AccountType: Option;
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedToAccountType();
        AccountNo := GetAppliedToAccountNo();
        OpenAccountPage(AccountType, AccountNo);
    end;

    procedure OpenAccountPage(AccountType: Option; AccountNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
    begin
        case AccountType of
            "Account Type"::Customer.AsInteger():
                begin
                    Customer.Get(AccountNo);
                    PAGE.Run(PAGE::"Customer Card", Customer);
                end;
            "Account Type"::Vendor.AsInteger():
                begin
                    Vendor.Get(AccountNo);
                    PAGE.Run(PAGE::"Vendor Card", Vendor);
                end;
            "Account Type"::"G/L Account".AsInteger():
                begin
                    GLAccount.Get(AccountNo);
                    PAGE.Run(PAGE::"G/L Account Card", GLAccount);
                end;
            "Account Type"::"Bank Account".AsInteger():
                begin
                    BankAccount.Get(AccountNo);
                    PAGE.Run(PAGE::"Bank Account Card", BankAccount);
                end;
        end;

        OnAfterOpenAccountPage(AccountType, AccountNo);
    end;

    procedure DrillDownOnNoOfLedgerEntriesWithinAmountTolerance()
    begin
        DrillDownOnNoOfLedgerEntriesBasedOnAmount(AmountWithinToleranceRangeTok);
    end;

    procedure DrillDownOnNoOfLedgerEntriesOutsideOfAmountTolerance()
    begin
        DrillDownOnNoOfLedgerEntriesBasedOnAmount(AmountOustideToleranceRangeTok);
    end;

    local procedure DrillDownOnNoOfLedgerEntriesBasedOnAmount(AmountFilter: Text)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        MinAmount: Decimal;
        MaxAmount: Decimal;
    begin
        GetAmountRangeForTolerance(MinAmount, MaxAmount);

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    GetCustomerLedgerEntriesInAmountRange(CustLedgerEntry, "Account No.", AmountFilter, MinAmount, MaxAmount);
                    PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
                end;
            "Account Type"::Vendor:
                begin
                    GetVendorLedgerEntriesInAmountRange(VendorLedgerEntry, "Account No.", AmountFilter, MinAmount, MaxAmount);
                    PAGE.Run(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    GetBankAccountLedgerEntriesInAmountRange(BankAccountLedgerEntry, AmountFilter, MinAmount, MaxAmount);
                    PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccountLedgerEntry);
                end;
        end;

        OnAfterDrillDownOnNoOfLedgerEntriesBasedOnAmount(Rec, AmountFilter);
    end;

    local procedure GetCustomerLedgerEntriesInAmountRange(var CustLedgerEntry: Record "Cust. Ledger Entry"; AccountNo: Code[20]; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal): Integer
    var
        BankAccount: Record "Bank Account";
        Result: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomerLedgerEntriesInAmountRange(Rec, CustLedgerEntry, AccountNo, AmountFilter, MinAmount, MaxAmount, Result, IsHandled);
        if IsHandled then
            exit(Result);
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        BankAccount.Get("Bank Account No.");
        GetApplicableCustomerLedgerEntries(CustLedgerEntry, BankAccount."Currency Code", AccountNo);

        if BankAccount.IsInLocalCurrency() then
            CustLedgerEntry.SetFilter("Remaining Amt. (LCY)", AmountFilter, MinAmount, MaxAmount)
        else
            CustLedgerEntry.SetFilter("Remaining Amount", AmountFilter, MinAmount, MaxAmount);

        exit(CustLedgerEntry.Count);
    end;

    local procedure GetVendorLedgerEntriesInAmountRange(var VendorLedgerEntry: Record "Vendor Ledger Entry"; AccountNo: Code[20]; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal): Integer
    var
        BankAccount: Record "Bank Account";
        Result: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetVendorLedgerEntriesInAmountRange(Rec, VendorLedgerEntry, AccountNo, AmountFilter, MinAmount, MaxAmount, Result, IsHandled);
        if IsHandled then
            exit(Result);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");

        BankAccount.Get("Bank Account No.");
        GetApplicableVendorLedgerEntries(VendorLedgerEntry, BankAccount."Currency Code", AccountNo);

        if BankAccount.IsInLocalCurrency() then
            VendorLedgerEntry.SetFilter("Remaining Amt. (LCY)", AmountFilter, MinAmount, MaxAmount)
        else
            VendorLedgerEntry.SetFilter("Remaining Amount", AmountFilter, MinAmount, MaxAmount);

        exit(VendorLedgerEntry.Count);
    end;

    local procedure GetBankAccountLedgerEntriesInAmountRange(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal): Integer
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get("Bank Account No.");
        GetApplicableBankAccountLedgerEntries(BankAccountLedgerEntry, BankAccount."Currency Code", "Bank Account No.");

        BankAccountLedgerEntry.SetFilter("Remaining Amount", AmountFilter, MinAmount, MaxAmount);

        exit(BankAccountLedgerEntry.Count);
    end;

    local procedure GetApplicableCustomerLedgerEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10]; AccountNo: Code[20])
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetRange("Applies-to ID", '');
        CustLedgerEntry.SetFilter("Document Type", '<>%1&<>%2',
          CustLedgerEntry."Document Type"::Payment,
          CustLedgerEntry."Document Type"::Refund);

        if CurrencyCode <> '' then
            CustLedgerEntry.SetRange("Currency Code", CurrencyCode);

        if AccountNo <> '' then
            CustLedgerEntry.SetFilter("Customer No.", AccountNo);
    end;

    local procedure GetApplicableVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10]; AccountNo: Code[20])
    begin
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Applies-to ID", '');
        VendorLedgerEntry.SetFilter("Document Type", '<>%1&<>%2',
          VendorLedgerEntry."Document Type"::Payment,
          VendorLedgerEntry."Document Type"::Refund);

        if CurrencyCode <> '' then
            VendorLedgerEntry.SetRange("Currency Code", CurrencyCode);

        if AccountNo <> '' then
            VendorLedgerEntry.SetFilter("Vendor No.", AccountNo);
    end;

    local procedure GetApplicableBankAccountLedgerEntries(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; CurrencyCode: Code[10]; AccountNo: Code[20])
    begin
        BankAccountLedgerEntry.SetRange(Open, true);

        if CurrencyCode <> '' then
            BankAccountLedgerEntry.SetRange("Currency Code", CurrencyCode);

        if AccountNo <> '' then
            BankAccountLedgerEntry.SetRange("Bank Account No.", AccountNo);
    end;

    procedure FilterBankRecLinesByDate(BankAccReconciliation: Record "Bank Acc. Reconciliation"; Overwrite: Boolean)
    begin
        FilterBankRecLines(BankAccReconciliation, Overwrite);

        // Records sorted by transaction date to optimize matching
        Rec.SetCurrentKey("Transaction Date");
        Rec.SetAscending("Transaction Date", true);
    end;

    procedure FilterBankRecLines(BankAccReconciliation: Record "Bank Acc. Reconciliation"; Overwrite: Boolean)
    begin
        Rec.Reset();
        Rec.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        Rec.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        Rec.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if not Overwrite then
            Rec.SetRange("Applied Entries", 0);
        OnAfterFilterBankRecLines(Rec, BankAccReconciliation);
    end;

    procedure FilterBankRecLines(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        FilterBankRecLines(BankAccReconciliation, true);
    end;

    procedure LinesExist(BankAccRecon: Record "Bank Acc. Reconciliation"): Boolean
    begin
        FilterBankRecLines(BankAccRecon);
        exit(FindSet());
    end;

    procedure GetAppliedToDocumentNo(SeparatorTxt: Text): Text
    var
        ApplyType: Option "Document No.","Entry No.";
    begin
        exit(GetAppliedNo(ApplyType::"Document No.", SeparatorTxt));
    end;

    procedure GetAppliedToDocumentNo(): Text
    begin
        exit(GetAppliedToDocumentNo(', '));
    end;

    procedure GetAppliedToEntryNo(): Text
    var
        ApplyType: Option "Document No.","Entry No.";
    begin
        exit(GetAppliedNo(ApplyType::"Entry No.", ', '));
    end;

    procedure GetAppliedToEntryFilter(): Text
    var
        ApplyType: Option "Document No.","Entry No.";
    begin
        exit(GetAppliedNo(ApplyType::"Entry No.", '|'));
    end;

    local procedure GetFirstAppliedToEntryNo(): Integer
    var
        AppliedEntryNumbers: Text;
        AppliedToEntryNo: Integer;
    begin
        AppliedEntryNumbers := GetAppliedToEntryNo();
        if AppliedEntryNumbers = '' then
            exit(0);
        Evaluate(AppliedToEntryNo, SelectStr(1, AppliedEntryNumbers));
        exit(AppliedToEntryNo);
    end;

    local procedure GetAppliedNo(ApplyType: Option "Document No.","Entry No."; SeparatorText: Text): Text
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        AppliedNumbers: Text;
    begin
        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", "Statement Line No.");

        AppliedNumbers := '';
        if AppliedPaymentEntry.FindSet() then
            repeat
                if ApplyType = ApplyType::"Document No." then begin
                    if AppliedPaymentEntry."Document No." <> '' then
                        if AppliedNumbers = '' then
                            AppliedNumbers := AppliedPaymentEntry."Document No."
                        else
                            AppliedNumbers := AppliedNumbers + SeparatorText + AppliedPaymentEntry."Document No.";
                end else
                    if AppliedPaymentEntry."Applies-to Entry No." <> 0 then
                        if AppliedNumbers = '' then
                            AppliedNumbers := Format(AppliedPaymentEntry."Applies-to Entry No.")
                        else
                            AppliedNumbers := AppliedNumbers + SeparatorText + Format(AppliedPaymentEntry."Applies-to Entry No.");
            until AppliedPaymentEntry.Next() = 0;

        exit(AppliedNumbers);
    end;

    procedure ShowAppliedToEntries()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AppliedBankAccLedgEntry: Record "Bank Account Ledger Entry";
        GLEntry: Record "G/L Entry";
        AppliedEntriesNumbersFilter: Text;
    begin
        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", "Statement Line No.");

        if not AppliedPaymentEntry.FindSet() then
            exit;

        AppliedEntriesNumbersFilter := Format(AppliedPaymentEntry."Applies-to Entry No.");

        if (AppliedPaymentEntry.Next() <> 0) then
            repeat
                AppliedEntriesNumbersFilter += StrSubstNo(AppliedEntriesFilterLbl, AppliedPaymentEntry."Applies-to Entry No.");
            until AppliedPaymentEntry.Next() = 0;

        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLEntry.SetFilter("Entry No.", AppliedEntriesNumbersFilter);
                    PAGE.Run(0, GLEntry);
                end;
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetFilter("Entry No.", AppliedEntriesNumbersFilter);
                    PAGE.Run(0, CustLedgEntry);
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetFilter("Entry No.", AppliedEntriesNumbersFilter);
                    PAGE.Run(0, VendLedgEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    AppliedBankAccLedgEntry.SetFilter("Entry No.", AppliedEntriesNumbersFilter);
                    PAGE.Run(0, AppliedBankAccLedgEntry);
                end;
        end;
    end;

    procedure TransferRemainingAmountToAccount()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        TestField("Account No.");

        SetAppliedPaymentEntryFromRec(AppliedPaymentEntry);
        AppliedPaymentEntry.Validate("Applied Amount", Difference);
        AppliedPaymentEntry.Validate("Match Confidence", AppliedPaymentEntry."Match Confidence"::Manual);
        AppliedPaymentEntry.Insert(true);
    end;

    procedure GetStatusText(): Text
    begin
        if ("Applied Entries" = 0) and ("Match Confidence" = "Match Confidence"::None) then
            exit(NotAppliedTxt);

        case "Match Confidence" of
            "Match Confidence"::Manual:
                exit(AppliedManuallyStatusTxt);
            "Match Confidence"::Accepted:
                exit(ReviewedStatusTxt);
            "Match Confidence"::"High - Text-to-Account Mapping":
                exit(MatchedFromTextMappingRulesTxt);
            "Match Confidence"::None:
                if ("Applied Entries" > 0) then
                    exit(MatchedAutomaticallyTxt);
            "Match Confidence"::Low, "Match Confidence"::Medium, "Match Confidence"::High:
                exit(MatchedAutomaticallyTxt);
        end;

        Session.LogMessage('0000BN5', StrSubstNo('Unexpected - could not find the status text - Match Confidence %1, Match Quality %2, Applied Entries %3', "Match Confidence", "Match Quality", "Applied Entries"), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', '');
        exit('');
    end;

    procedure GetAmountRangeForTolerance(var MinAmount: Decimal; var MaxAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
        TempAmount: Decimal;
    begin
        BankAccount.Get("Bank Account No.");
        case BankAccount."Match Tolerance Type" of
            BankAccount."Match Tolerance Type"::Amount:
                begin
                    MinAmount := "Statement Amount" - BankAccount."Match Tolerance Value";
                    MaxAmount := "Statement Amount" + BankAccount."Match Tolerance Value";

                    if ("Statement Amount" >= 0) and (MinAmount < 0) then
                        MinAmount := 0
                    else
                        if ("Statement Amount" < 0) and (MaxAmount > 0) then
                            MaxAmount := 0;
                end;
            BankAccount."Match Tolerance Type"::Percentage:
                begin
                    MinAmount := "Statement Amount" * (1 - BankAccount."Match Tolerance Value" / 100);
                    MaxAmount := "Statement Amount" * (1 + BankAccount."Match Tolerance Value" / 100);

                    if "Statement Amount" < 0 then begin
                        TempAmount := MinAmount;
                        MinAmount := MaxAmount;
                        MaxAmount := TempAmount;
                    end;
                end;
        end;

        MinAmount := Round(MinAmount);
        MaxAmount := Round(MaxAmount);
    end;

    procedure GetAppliedPmtData(var AppliedPmtEntry: Record "Applied Payment Entry"; var RemainingAmountAfterPosting: Decimal; var DifferenceStatementAmtToApplEntryAmount: Decimal; PmtAppliedToTxt: Text)
    var
        CurrRemAmtAfterPosting: Decimal;
    begin
        AppliedPmtEntry.Init();
        RemainingAmountAfterPosting := 0;
        DifferenceStatementAmtToApplEntryAmount := 0;

        AppliedPmtEntry.FilterAppliedPmtEntry(Rec);
        AppliedPmtEntry.SetFilter("Applies-to Entry No.", '<>0');
        if AppliedPmtEntry.FindSet() then begin
            DifferenceStatementAmtToApplEntryAmount := "Statement Amount";
            repeat
                CurrRemAmtAfterPosting :=
                  AppliedPmtEntry.GetRemAmt() -
                  AppliedPmtEntry.GetAmtAppliedToOtherStmtLines();

                RemainingAmountAfterPosting += CurrRemAmtAfterPosting - AppliedPmtEntry."Applied Amount";
                DifferenceStatementAmtToApplEntryAmount -= CurrRemAmtAfterPosting - AppliedPmtEntry."Applied Pmt. Discount";
                OnGetAppliedPmtDataOnAfterLoopIteration(Rec, AppliedPmtEntry);
            until AppliedPmtEntry.Next() = 0;
        end;

        if "Applied Entries" > 1 then
            AppliedPmtEntry.Description := StrSubstNo(PmtAppliedToTxt, "Applied Entries");
    end;

    [Scope('OnPrem')]
    procedure GetAppliedPmtData(var AppliedPmtEntry: Record "Applied Payment Entry"; PmtAppliedToTxt: Text)
    begin
        AppliedPmtEntry.Init();

        AppliedPmtEntry.FilterAppliedPmtEntry(Rec);
        AppliedPmtEntry.SetFilter("Applies-to Entry No.", '<>0');
        if "Applied Entries" > 1 then
            AppliedPmtEntry.Description := StrSubstNo(PmtAppliedToTxt, "Applied Entries");
    end;

    local procedure UpdateParentLineStatementAmount()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if BankAccReconciliationLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Parent Line No.") then begin
            BankAccReconciliationLine.Validate("Statement Amount", "Statement Amount" + BankAccReconciliationLine."Statement Amount");
            BankAccReconciliationLine.Modify(true)
        end
    end;

    procedure IsTransactionPostedAndReconciled(): Boolean
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
        BankAccountStatementLine: Record "Bank Account Statement Line";
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeIsTransactionPostedAndReconciled(Rec, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if "Transaction ID" <> '' then begin
            PostedPaymentReconLine.SetRange("Bank Account No.", "Bank Account No.");
            PostedPaymentReconLine.SetRange("Transaction ID", "Transaction ID");
            PostedPaymentReconLine.SetRange(Reconciled, true);
            if not PostedPaymentReconLine.IsEmpty() then
                exit(true);
            BankAccountStatementLine.SetRange("Bank Account No.", "Bank Account No.");
            BankAccountStatementLine.SetRange("Transaction ID", "Transaction ID");
            exit(not BankAccountStatementLine.IsEmpty);
        end;
        exit(false);
    end;

    local procedure IsTransactionPostedAndNotReconciled(): Boolean
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
    begin
        if "Transaction ID" <> '' then begin
            PostedPaymentReconLine.SetRange("Bank Account No.", "Bank Account No.");
            PostedPaymentReconLine.SetRange("Transaction ID", "Transaction ID");
            PostedPaymentReconLine.SetRange(Reconciled, false);
            exit(not PostedPaymentReconLine.IsEmpty());
        end;
        exit(false);
    end;

    local procedure IsTransactionAlreadyImported(): Boolean
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        if "Transaction ID" <> '' then begin
            BankAccReconciliationLine.SetRange("Statement Type", "Statement Type");
            BankAccReconciliationLine.SetRange("Bank Account No.", "Bank Account No.");
            BankAccReconciliationLine.SetRange("Transaction ID", "Transaction ID");
            exit(not BankAccReconciliationLine.IsEmpty());
        end;
        exit(false);
    end;

    local procedure AllowImportDuplicatedTransactions(): Boolean
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.SetLoadFields("Allow Duplicated Transactions");
        BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
        exit(BankAccReconciliation."Allow Duplicated Transactions");
    end;

    local procedure AllowImportOfPostedNotReconciledTransactions(): Boolean
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
        if BankAccReconciliation."Import Posted Transactions" = BankAccReconciliation."Import Posted Transactions"::" " then begin
            BankAccReconciliation."Import Posted Transactions" := BankAccReconciliation."Import Posted Transactions"::No;
            if GuiAllowed then
                if Confirm(ImportPostedTransactionsQst) then
                    BankAccReconciliation."Import Posted Transactions" := BankAccReconciliation."Import Posted Transactions"::Yes;
            BankAccReconciliation.Modify();
        end;

        exit(BankAccReconciliation."Import Posted Transactions" = BankAccReconciliation."Import Posted Transactions"::Yes);
    end;

    procedure CanImport(): Boolean
    begin
        if IsTransactionPostedAndReconciled() then
            exit(false);

        if IsTransactionAlreadyImported() then
            if not AllowImportDuplicatedTransactions() then
                exit(false);

        if IsTransactionPostedAndNotReconciled() then
            exit(AllowImportOfPostedNotReconciledTransactions());

        exit(true);
    end;

    procedure BankStatementLinesListIsEmpty(StatementNo: Code[20]; StatementType: Option; BankAccountNo: Code[20]): Boolean
    var
        BankAccReconciliationLine: record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", StatementNo);
        BankAccReconciliationLine.SetRange("Statement Type", StatementType);

        exit(BankAccReconciliationLine.IsEmpty);
    end;

    local procedure GetSalepersonPurchaserCode(): Code[20]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        case "Account Type" of
            "Account Type"::Customer:
                if Customer.Get("Account No.") then
                    exit(Customer."Salesperson Code");
            "Account Type"::Vendor:
                if Vendor.Get("Account No.") then
                    exit(Vendor."Purchaser Code");
        end;
    end;

    internal procedure GetAppliesToIDForBankStatement(): Code[50]
    begin
        exit(CopyStr(Rec."Bank Account No." + '-' + Format(Rec."Statement No."), 1, 50));
    end;

    procedure GetAppliesToID(): Code[50]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        exit(
            CopyStr(
                GetAppliesToIDForBankStatement() + '-' + Format(Rec."Statement Line No."),
                1,
                MaxStrLen(CustLedgerEntry."Applies-to ID")));
    end;

    procedure GetDescription(): Text[100]
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        if Description <> '' then
            exit(Description);

        AppliedPaymentEntry.FilterAppliedPmtEntry(Rec);
        AppliedPaymentEntry.SetFilter("Applies-to Entry No.", '<>%1', 0);
        if AppliedPaymentEntry.FindSet() then
            if AppliedPaymentEntry.Next() = 0 then
                exit(AppliedPaymentEntry.Description);

        exit('');
    end;

    procedure GetMatchedAutomaticallyFilter(): Text
    begin
        exit(StrSubstNo(MatchedAutomaticallyFilterLbl, "Match Confidence"::None, "Match Confidence"::Low, "Match Confidence"::Medium, "Match Confidence"::High));
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, DimMgt.TypeToTableID1(Rec."Account Type".AsInteger()), Rec."Account No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::"Salesperson/Purchaser", GetSalepersonPurchaserCode());

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; xBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterBankRecLines(var Rec: Record "Bank Acc. Reconciliation Line"; BankAccRecon: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountName(AccountType: Option; AccountNo: Code[20]; var Name: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliedEntryAccountNo(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliedToEntryNo: Integer; var AccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenAccountPage(AccountType: Option; AccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRemoveAppliedPaymentEntries(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDrillDownOnNoOfLedgerEntriesBasedOnAmount(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AmountFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var xBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var xBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisplayApplicationOnAfterBankAccLedgEntrySetFilters(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsTransactionPostedAndReconciled(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDisplayApplicationOnAfterSetBankAccReconcLine(var PaymentApplication: Page "Payment Application");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRemoveApplicationOnAfterBankAccLedgEntrySetFilters(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetStyle(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var Result: text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomerLedgerEntriesInAmountRange(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; AccountNo: Code[20]; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendorLedgerEntriesInAmountRange(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; AccountNo: Code[20]; AmountFilter: Text; MinAmount: Decimal; MaxAmount: Decimal; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDimensions(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAppliedPmtDataOnAfterLoopIteration(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliedPmtEntry: Record "Applied Payment Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPostedPaymentReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PostedPaymentReconLine: Record "Posted Payment Recon. Line")
    begin
    end;
}