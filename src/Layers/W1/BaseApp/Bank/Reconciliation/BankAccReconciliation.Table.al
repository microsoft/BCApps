// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using System.IO;

table 273 "Bank Acc. Reconciliation"
{
    Caption = 'Bank Acc. Reconciliation';
    DataCaptionFields = "Bank Account No.", "Statement No.";
    LookupPageID = "Bank Acc. Reconciliation List";
    Permissions = TableData "Bank Account" = rm,
                  TableData "Data Exch." = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;
            TableRelation = "Bank Account";

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "Statement No." = '' then begin
                    BankAcc.Get("Bank Account No.");

                    case "Statement Type" of
                        "Statement Type"::"Payment Application":
                            if BankAcc."Pmt. Rec. No. Series" = '' then begin
                                SetLastPaymentStatementNo(BankAcc);
                                "Statement No." := IncStr(BankAcc."Last Payment Statement No.");
                            end else
                                "Statement No." := NoSeries.GetNextNo(BankAcc."Pmt. Rec. No. Series", Today());
                        "Statement Type"::"Bank Reconciliation":
                            begin
                                SetLastStatementNo(BankAcc);
                                "Statement No." := IncStr(BankAcc."Last Statement No.");
                            end;
                    end;

                    "Balance Last Statement" := BankAcc."Balance Last Statement";
                end;

                CreateDimFromDefaultDim();
            end;
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            Editable = false;
            NotBlank = true;

            trigger OnValidate()
            begin
                TestField("Bank Account No.");
            end;
        }
        field(3; "Statement Ending Balance"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 2;
            Caption = 'Statement Ending Balance';
        }
        field(4; "Statement Date"; Date)
        {
            Caption = 'Statement Date';
        }
        field(5; "Balance Last Statement"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Balance Last Statement';

            trigger OnValidate()
            begin
                BankAcc.Get("Bank Account No.");
                if "Balance Last Statement" <> BankAcc."Balance Last Statement" then
                    if not
                       Confirm(
                         BalanceQst, false,
                         FieldCaption("Balance Last Statement"), BankAcc.FieldCaption("Balance Last Statement"),
                         BankAcc.TableCaption())
                    then
                        "Balance Last Statement" := xRec."Balance Last Statement";
            end;
        }
        field(6; "Bank Statement"; BLOB)
        {
            Caption = 'Bank Statement';
        }
        field(7; "Total Balance on Bank Account"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("Bank Account No.")));
            Caption = 'Total Balance on Bank Account';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Total Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line"."Applied Amount" where("Statement Type" = field("Statement Type"),
                                                                                      "Bank Account No." = field("Bank Account No."),
                                                                                      "Statement No." = field("Statement No.")));
            Caption = 'Total Applied Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Total Transaction Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line"."Statement Amount" where("Statement Type" = field("Statement Type"),
                                                                                        "Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No.")));
            Caption = 'Total Transaction Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Total Unposted Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line"."Applied Amount" where("Statement Type" = field("Statement Type"),
                                                                                      "Bank Account No." = field("Bank Account No."),
                                                                                      "Statement No." = field("Statement No."),
                                                                                      "Account Type" = filter(<> "Bank Account")));
            Caption = 'Total Unposted Applied Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Total Difference"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line".Difference where("Statement Type" = field("Statement Type"),
                                                                                "Bank Account No." = field("Bank Account No."),
                                                                                "Statement No." = field("Statement No.")));
            Caption = 'Total Difference';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Total Paid Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line"."Statement Amount" where("Statement Type" = field("Statement Type"),
                                                                                        "Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."),
                                                                                        "Statement Amount" = filter(< 0)));
            Caption = 'Total Paid Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Total Received Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line"."Statement Amount" where("Statement Type" = field("Statement Type"),
                                                                                        "Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."),
                                                                                        "Statement Amount" = filter(> 0)));
            Caption = 'Total Received Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Statement Type"; Enum "Bank Acc. Rec. Stmt. Type")
        {
            Caption = 'Statement Type';
        }
        field(21; "Shortcut Dimension 1 Code"; Code[20])
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
        field(22; "Shortcut Dimension 2 Code"; Code[20])
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
        field(23; "Post Payments Only"; Boolean)
        {
            Caption = 'Post Payments Only';
        }
        field(24; "Import Posted Transactions"; Option)
        {
            Caption = 'Import Posted Transactions';
            OptionCaption = ' ,Yes,No';
            OptionMembers = " ",Yes,No;
        }
        field(25; "Total Outstd Bank Transactions"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("Bank Account No."),
                                                                        Open = const(true),
                                                                        "Check Ledger Entries" = const(0)));
            Caption = 'Total Outstd Bank Transactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Total Outstd Payments"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Account Ledger Entry".Amount where("Bank Account No." = field("Bank Account No."),
                                                                        Open = const(true),
                                                                        "Check Ledger Entries" = filter(> 0)));
            Caption = 'Total Outstd Payments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Bank Account Balance (LCY)"; Decimal)
        {
            CalcFormula = sum("Bank Account Ledger Entry"."Amount (LCY)" where("Bank Account No." = field("Bank Account No.")));
            AutoFormatType = 1;
            Caption = 'Bank Account Balance (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Total Positive Adjustments"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line"."Applied Amount" where("Statement Type" = field("Statement Type"),
                                                                                      "Bank Account No." = field("Bank Account No."),
                                                                                      "Statement No." = field("Statement No."),
                                                                                      "Account Type" = filter(<> "Bank Account"),
                                                                                      "Statement Amount" = filter(> 0)));
            Caption = 'Total Positive Adjustments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Total Negative Adjustments"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            CalcFormula = sum("Bank Acc. Reconciliation Line"."Applied Amount" where("Statement Type" = field("Statement Type"),
                                                                                      "Bank Account No." = field("Bank Account No."),
                                                                                      "Statement No." = field("Statement No."),
                                                                                      "Account Type" = filter(<> "Bank Account"),
                                                                                      "Statement Amount" = filter(< 0)));
            Caption = 'Total Negative Adjustments';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Copy VAT Setup to Jnl. Line"; Boolean)
        {
            Caption = 'Copy VAT Setup to Jnl. Line';
            InitValue = true;
        }
        field(50; "Bank Account Name"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Bank Account".Name where("No." = field("Bank Account No.")));
        }
        field(51; "Allow Duplicated Transactions"; Boolean)
        {
            Caption = 'Allow Duplicated Transactions';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDocDim();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Statement Type", "Bank Account No.", "Statement No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if BankAccReconLine.LinesExist(Rec) then
            BankAccReconLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        OnInsertValidations(Rec);
        SetLastStatementNoInBankAccount(Rec);
    end;

    trigger OnRename()
    begin
        Error(RenameErr, TableCaption);
    end;

    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        DimMgt: Codeunit DimensionManagement;

        DuplicateStatementErr: Label 'A statement with number %1 has already been posted. Make sure that the fields "Last Statement No." and "Last Payment Statement No." in the bank account are correct. If you are changing the statement number, you can choose a different target number or undo the existing bank statement. ', Comment = '%1=Statement No. value';
        RenameErr: Label 'You cannot rename a %1.', Comment = '%1=Table name caption';
        BalanceQst: Label '%1 is different from %2 on the %3. Do you want to change the value?', Comment = '%1=Balance Last Statement field caption;%2=field caption;%3=table caption';
        YouChangedDimQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        NoBankAccountsMsg: Label 'You have not set up a bank account.\To use the payments import process, set up a bank account.';
        NoBankAccWithFileFormatMsg: Label 'No bank account exists that is ready for import of bank statement files.\Fill the Bank Statement Import Format field on the card of the bank account that you want to use.';
        PostHighConfidentLinesQst: Label 'All imported bank statement lines were applied with high confidence level.\Do you want to post the payment applications?';
#pragma warning disable AA0470
        MustHaveValueQst: Label 'The bank account must have a value in %1. Do you want to open the bank account card?';
#pragma warning restore AA0470
        NoTransactionsImportedMsg: Label 'No bank transactions were imported. For example, because the transactions were imported in other bank account reconciliations, or because they are already applied to bank account ledger entries. You can view the applied transactions on the Bank Account Statement List page and on the Posted Payment Reconciliations page.';
        BankReconciliationFeatureNameTelemetryTxt: Label 'Bank reconciliation', Locked = true;
        PaymentRecJournalFeatureNameTelemetryTxt: Label 'Payment Reconciliation', Locked = true;

    protected var
        BankAcc: Record "Bank Account";

    local procedure OnInsertValidations(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        BankAccReconciliation.TestField("Statement No.");
        BankAccReconciliation.TestField("Bank Account No.");
        OnInsertValidations(BankAccReconciliation."Statement Type", BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
    end;

    internal procedure OnInsertValidations(StatementType: Enum "Bank Acc. Rec. Stmt. Type"; BankAccountNo: Code[20]; StatementNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankAccountStatement: Record "Bank Account Statement";
        PostedPaymentReconciliationHeader: Record "Posted Payment Recon. Hdr";
    begin
        BankAccount.Get(BankAccountNo);
        case StatementType of
            StatementType::"Bank Reconciliation":
                if BankAccountStatement.Get(BankAccountNo, StatementNo) then
                    Error(DuplicateStatementErr, StatementNo);
            StatementType::"Payment Application":
                if PostedPaymentReconciliationHeader.Get(BankAccountNo, StatementNo) then
                    Error(DuplicateStatementErr, StatementNo);
        end;
    end;

    local procedure SetLastStatementNoInBankAccount(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        case BankAccReconciliation."Statement Type" of
            "Bank Acc. Rec. Stmt. Type"::"Bank Reconciliation":
                BankAccount."Last Statement No." := BankAccReconciliation."Statement No.";
            "Bank Acc. Rec. Stmt. Type"::"Payment Application":
                if BankAccount."Pmt. Rec. No. Series" = '' then
                    BankAccount."Last Payment Statement No." := BankAccReconciliation."Statement No.";
        end;
        BankAccount.Modify();
    end;

    internal procedure GetPaymentRecJournalTelemetryFeatureName(): Text
    begin
        exit(PaymentRecJournalFeatureNameTelemetryTxt);
    end;

    internal procedure GetBankReconciliationTelemetryFeatureName(): Text
    begin
        exit(BankReconciliationFeatureNameTelemetryTxt);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        OldDimSetID: Integer;
    begin
        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Payment Reconciliation Journal",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnCreateDimOnAfterSetDimensionSetID(Rec, OldDimSetID, DefaultDimSource);

        if (OldDimSetID <> "Dimension Set ID") and LinesExist() then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc2: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc2."No." then
            exit(BankAcc2."Currency Code");

        if BankAcc2.Get("Bank Account No.") then
            exit(BankAcc2."Currency Code");

        exit('');
    end;

    procedure MatchSingle(DateRange: Integer)
    var
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMatchSingle(Rec, DateRange, IsHandled);
        if IsHandled then
            exit;

        MatchBankRecLines.BankAccReconciliationAutoMatch(Rec, DateRange);
    end;

    procedure ImportBankStatement()
    var
        DataExch: Record "Data Exch.";
        ProcessBankAccRecLines: Codeunit "Process Bank Acc. Rec Lines";
    begin
        CreateBankAccountReconcillation();
        if BankAccountCouldBeUsedForImport() then begin
            DataExch.Init();
            BindSubscription(ProcessBankAccRecLines);
            ProcessBankAccRecLines.SetBankAccountNo(Rec."Bank Account No.");
            ProcessBankAccRecLines.ImportBankStatement(Rec, DataExch);
            UnBindSubscription(ProcessBankAccRecLines);
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure ShowDocDim()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Statement No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            UpdateAllLineDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure UpdateAllLineDim(NewParentDimSetID: Integer; OldParentDimSetID: Integer)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        NewDimSetID: Integer;
    begin
        // Update all lines with changed dimensions.
        if NewParentDimSetID = OldParentDimSetID then
            exit;

        BankAccReconciliationLine.LockTable();
        if BankAccReconciliationLine.LinesExist(Rec) then begin
            if not Confirm(YouChangedDimQst) then
                exit;

            repeat
                NewDimSetID :=
                  DimMgt.GetDeltaDimSetID(BankAccReconciliationLine."Dimension Set ID", NewParentDimSetID, OldParentDimSetID);
                if BankAccReconciliationLine."Dimension Set ID" <> NewDimSetID then begin
                    BankAccReconciliationLine."Dimension Set ID" := NewDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      BankAccReconciliationLine."Dimension Set ID",
                      BankAccReconciliationLine."Shortcut Dimension 1 Code",
                      BankAccReconciliationLine."Shortcut Dimension 2 Code");
                    OnUpdateAllLineDimOnAfterUpdateGlobalDimFromDimSetID(BankAccReconciliationLine);
                    BankAccReconciliationLine.Modify();
                end;
            until BankAccReconciliationLine.Next() = 0;
        end;
    end;

    procedure OpenNewWorksheet()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        if not SelectBankAccountToUse(BankAccount, false) then
            exit;

        CreateNewBankPaymentAppBatch(BankAccount."No.", BankAccReconciliation);
        OpenWorksheet(BankAccReconciliation);
    end;

    procedure ImportAndProcessToNewStatement()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DummyBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        LastStatementNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeImportAndProcessToNewStatement(BankAccReconciliation, DataExch, DataExchDef, IsHandled);
        if IsHandled then
            exit;

        if not SelectBankAccountToUse(BankAccount, true) then
            exit;
        BankAccount.GetDataExchDef(DataExchDef);

        DataExch."Related Record" := BankAccount.RecordId;
        if not DataExch.ImportFileContent(DataExchDef) then
            exit;

        BankAccount.LockTable();
        LastStatementNo := BankAccount."Last Statement No.";
        CreateNewBankPaymentAppBatch(BankAccount."No.", BankAccReconciliation);

        if not ImportStatement(BankAccReconciliation, DataExch) then begin
            DeleteBankAccReconciliation(BankAccReconciliation, BankAccount, LastStatementNo);
            Message(NoTransactionsImportedMsg);
            exit;
        end;

        if DummyBankAccReconciliationLine.BankStatementLinesListIsEmpty(BankAccReconciliation."Statement No.", BankAccReconciliation."Statement Type".AsInteger(), BankAccReconciliation."Bank Account No.") then begin
            DeleteBankAccReconciliation(BankAccReconciliation, BankAccount, LastStatementNo);
            Message(NoTransactionsImportedMsg);
            exit;
        end;

        Commit();

        if BankAccount.Get(BankAccReconciliation."Bank Account No.") then
            if BankAccount."Disable Automatic Pmt Matching" then
                exit;

        ProcessStatement(BankAccReconciliation);
    end;

    local procedure DeleteBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccount: Record "Bank Account"; LastStatementNo: Code[20])
    begin
        BankAccReconciliation.Delete();
        BankAccount.Get(BankAccount."No.");
        BankAccount."Last Statement No." := LastStatementNo;
        BankAccount.Modify();
        Commit();
    end;

    procedure ImportStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; DataExch: Record "Data Exch."): Boolean
    var
        ProcessBankAccRecLines: Codeunit "Process Bank Acc. Rec Lines";
    begin
        exit(ProcessBankAccRecLines.ImportBankStatement(BankAccReconciliation, DataExch))
    end;

    procedure ProcessStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);

        if ConfidenceLevelPermitToPost(BankAccReconciliation) then begin
            Commit();
            CODEUNIT.Run(CODEUNIT::"Bank Acc. Reconciliation Post", BankAccReconciliation)
        end else
            OpenWorksheetFromProcessStatement(BankAccReconciliation);
    end;

    local procedure OpenWorksheetFromProcessStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenWorksheetFromProcessStatement(BankAccReconciliation, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed then
            OpenWorksheet(BankAccReconciliation);
    end;

    procedure CreateNewBankPaymentAppBatch(BankAccountNo: Code[20]; var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Payment Application";
        BankAccReconciliation.Validate("Bank Account No.", BankAccountNo);
        BankAccReconciliation.Insert(true);
    end;

    procedure SelectBankAccountToUse(var BankAccount: Record "Bank Account"; OnlyWithImportFormatSet: Boolean): Boolean
    var
        TempBankAccount: Record "Bank Account" temporary;
        TempLinkedBankAccount: Record "Bank Account" temporary;
        NoOfAccounts: Integer;
    begin
        if OnlyWithImportFormatSet then begin
            // copy to temp as we need OR filter
            BankAccount.SetFilter("Bank Statement Import Format", '<>%1', '');
            CopyBankAccountsToTemp(TempBankAccount, BankAccount);

            // clear filters
            BankAccount.SetRange("Bank Statement Import Format");
            TempLinkedBankAccount.SetRange("Bank Statement Import Format");

            BankAccount.GetLinkedBankAccounts(TempLinkedBankAccount);
            CopyBankAccountsToTemp(TempBankAccount, TempLinkedBankAccount);

            NoOfAccounts := TempBankAccount.Count();
        end else
            NoOfAccounts := BankAccount.Count();

        case NoOfAccounts of
            0:
                begin
                    if not BankAccount.Get(CantFindBancAccToUseInPaymentFileImport()) then
                        exit(false);

                    exit(true);
                end;
            1:
                if TempBankAccount.Count > 0 then begin
                    TempBankAccount.FindFirst();
                    BankAccount.Get(TempBankAccount."No.");
                end else
                    BankAccount.FindFirst();
            else begin
                if TempBankAccount.Count > 0 then begin
                    if PAGE.RunModal(PAGE::"Payment Bank Account List", TempBankAccount) = ACTION::LookupOK then begin
                        BankAccount.Get(TempBankAccount."No.");
                        exit(true)
                    end;
                    exit(false);
                end;
                exit(PAGE.RunModal(PAGE::"Payment Bank Account List", BankAccount) = ACTION::LookupOK);
            end;
        end;

        exit(true);
    end;

    procedure OpenWorksheet(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        SetFiltersOnBankAccReconLineTable(BankAccReconciliation, BankAccReconciliationLine);
        PAGE.Run(PAGE::"Payment Reconciliation Journal", BankAccReconciliationLine);
    end;

    procedure OpenList(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        SetFiltersOnBankAccReconLineTable(BankAccReconciliation, BankAccReconciliationLine);
        PAGE.Run(PAGE::"Pmt. Recon. Journal Overview", BankAccReconciliationLine);
    end;

    local procedure CantFindBancAccToUseInPaymentFileImport(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.Count = 0 then
            Message(NoBankAccountsMsg)
        else
            Message(NoBankAccWithFileFormatMsg);

        if PAGE.RunModal(PAGE::"Payment Bank Account List", BankAccount) = ACTION::LookupOK then
            if (BankAccount."Bank Statement Import Format" <> '') or
               BankAccount.IsLinkedToBankStatementServiceProvider()
            then
                exit(BankAccount."No.");

        exit('');
    end;

    local procedure SetLastPaymentStatementNo(var BankAccount: Record "Bank Account")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        if BankAccount."Last Payment Statement No." = '' then begin
            BankAccReconciliation.SetRange("Bank Account No.", BankAccount."No.");
            BankAccReconciliation.SetRange("Statement Type", "Statement Type"::"Payment Application");
            if BankAccReconciliation.FindLast() then
                BankAccount."Last Payment Statement No." := IncStr(BankAccReconciliation."Statement No.")
            else
                BankAccount."Last Payment Statement No." := '0';

            BankAccount.Modify();
        end;
    end;

    local procedure SetLastStatementNo(var BankAccount: Record "Bank Account")
    begin
        if BankAccount."Last Statement No." = '' then begin
            BankAccount."Last Statement No." := '0';
            BankAccount.Modify();
        end;
    end;

    procedure SetFiltersOnBankAccReconLineTable(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconciliationLine.FilterGroup := 2;
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FilterGroup := 0;
    end;

    local procedure ConfidenceLevelPermitToPost(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Boolean
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        SetFiltersOnBankAccReconLineTable(BankAccReconciliation, BankAccReconciliationLine);
        if BankAccReconciliationLine.Count = 0 then
            exit(false);

        BankAccReconciliationLine.SetFilter("Match Confidence", '<>%1', BankAccReconciliationLine."Match Confidence"::High);
        if BankAccReconciliationLine.Count <> 0 then
            exit(false);

        if Confirm(PostHighConfidentLinesQst) then
            exit(true);

        exit(false);
    end;

    local procedure LinesExist(): Boolean
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        exit(BankAccReconciliationLine.LinesExist(Rec));
    end;

    local procedure BankAccountCouldBeUsedForImport(): Boolean
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get("Bank Account No.");
        if BankAccount."Bank Statement Import Format" <> '' then
            exit(true);

        if BankAccount.IsLinkedToBankStatementServiceProvider() then
            exit(true);

        if not Confirm(MustHaveValueQst, true, BankAccount.FieldCaption("Bank Statement Import Format")) then
            exit(false);

        if PAGE.RunModal(PAGE::"Bank Account Card", BankAccount) = ACTION::LookupOK then
            if BankAccount."Bank Statement Import Format" <> '' then
                exit(true);

        exit(false);
    end;

    procedure DrillDownOnBalanceOnBankAccount()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange(Open, true);
        BankAccountLedgerEntry.SetRange("Bank Account No.", "Bank Account No.");
        PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccountLedgerEntry);
    end;

    procedure MatchCandidateFilterDate(): Date
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", "Statement Type");
        BankAccReconciliationLine.SetRange("Statement No.", "Statement No.");
        BankAccReconciliationLine.SetRange("Bank Account No.", "Bank Account No.");
        BankAccReconciliationLine.SetCurrentKey("Transaction Date");
        BankAccReconciliationLine.Ascending := false;
        if BankAccReconciliationLine.FindFirst() then
            if BankAccReconciliationLine."Transaction Date" > "Statement Date" then
                exit(BankAccReconciliationLine."Transaction Date");

        exit("Statement Date");
    end;

    local procedure CopyBankAccountsToTemp(var TempBankAccount: Record "Bank Account" temporary; var FromBankAccount: Record "Bank Account")
    begin
        if FromBankAccount.FindSet() then
            repeat
                TempBankAccount := FromBankAccount;
                if TempBankAccount.Insert() then;
            until FromBankAccount.Next() = 0;
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
        DimMgt.AddDimSource(DefaultDimSource, Database::"Bank Account", Rec."Bank Account No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    procedure CreateBankAccountReconcillation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        if not BankAccReconciliation.Get(
            Rec."Statement Type",
            Rec."Bank Account No.",
            Rec."Statement No.") and
            (Rec."Bank Account No." <> '') and
            (Rec."Statement Type" = Rec."Statement Type"::"Bank Reconciliation")
        then
            Rec.Insert(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var xBankAccReconciliation: Record "Bank Acc. Reconciliation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportAndProcessToNewStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var DataExch: Record "Data Exch."; var DataExchDef: Record "Data Exch. Def"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatchSingle(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; DateRange: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenWorksheetFromProcessStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var xBankAccReconciliation: Record "Bank Acc. Reconciliation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateDimOnAfterSetDimensionSetID(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; OldDimSetID: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllLineDimOnAfterUpdateGlobalDimFromDimSetID(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;
}
