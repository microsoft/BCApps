// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 2677 "Gen. Journal Alloc. Acc. Mgt."
{
    internal procedure GetOrGenerateAllocationLines(var AllocationLine: Record "Allocation Line"; var ParentSystemId: Guid)
    var
        AmountToAllocate: Decimal;
        PostingDate: Date;
    begin
        GetOrGenerateAllocationLines(AllocationLine, ParentSystemId, AmountToAllocate, PostingDate);
    end;

    internal procedure GetOrGenerateAllocationLines(var AllocationLine: Record "Allocation Line"; var ParentSystemId: Guid; var AmountToAllocate: Decimal; var PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        GenJournalLine.ReadIsolation := IsolationLevel::ReadCommitted;
        GenJournalLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        GenJournalLine.GetBySystemId(ParentSystemId);
        AmountToAllocate := GenJournalLine.Amount;
        PostingDate := GenJournalLine."Posting Date";

        if GenJournalLine."Alloc. Acc. Modified by User" then
            LoadManualAllocationLines(GenJournalLine, AllocationLine)
        else begin
            GetAllocationAccount(GenJournalLine, AllocationAccount);
            AllocationAccountMgt.GenerateAllocationLines(AllocationAccount, AllocationLine, GenJournalLine.Amount, PostingDate, GenJournalLine."Dimension Set ID", GenJournalLine."Currency Code");
            ReplaceInheritFromParent(AllocationLine, GenJournalLine);
        end;
    end;

    internal procedure LoadManualAllocationLines(var GenJournalLine: Record "Gen. Journal Line"; var AllocationLine: Record "Allocation Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", GenJournalLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Gen. Journal Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.FindSet() then
            exit;

        repeat
            AllocationLine."Line No." := AllocAccManualOverride."Line No.";
            AllocationLine."Destination Account Type" := AllocAccManualOverride."Destination Account Type";
            AllocationLine."Destination Account Number" := AllocAccManualOverride."Destination Account Number";
            AllocationLine."Global Dimension 1 Code" := AllocAccManualOverride."Global Dimension 1 Code";
            AllocationLine."Global Dimension 2 Code" := AllocAccManualOverride."Global Dimension 2 Code";
            AllocationLine."Allocation Account No." := AllocAccManualOverride."Allocation Account No.";
            AllocationLine.Quantity := AllocAccManualOverride.Quantity;
            AllocationLine."Dimension Set ID" := AllocAccManualOverride."Dimension Set ID";
            AllocationLine.Amount := AllocAccManualOverride.Amount;
            OnLoadManualAllocationLinesOnBeforeInsertAllocationLine(AllocAccManualOverride, AllocationLine);
            AllocationLine.Insert();
        until AllocAccManualOverride.Next() = 0;
    end;

    internal procedure VerifyAllGLAccountsUsed(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if (GenJournalLine."Account Type" <> GenJournalLine."Account Type"::"Allocation Account") then
            exit(false);

        if GenJournalLine."Account No." = '' then
            exit(false);

        AllocAccountDistribution.SetRange("Allocation Account No.", GenJournalLine."Account No.");
        AllocAccountDistribution.SetRange("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"G/L Account");
        if AllocAccountDistribution.IsEmpty() then
            exit(false);

        AllocAccountDistribution.SetFilter("Destination Account Type", '<>%1', AllocAccountDistribution."Destination Account Type"::"G/L Account");
        exit(AllocAccountDistribution.IsEmpty());
    end;

    internal procedure PreventAllocationAccountsFromThisPage(GenJournalAccountType: Enum "Gen. Journal Account Type")
    begin
        if GenJournalAccountType = GenJournalAccountType::"Allocation Account" then
            Error(AllocationAccountsCannotBeUsedOnThisPageErr);
    end;

    local procedure ReplaceInheritFromParent(var AllocationLine: Record "Allocation Line"; var GenJournalLine: Record "Gen. Journal Line")
    var
        CurrentFilters: Text;
    begin
        CurrentFilters := AllocationLine.GetView();
        AllocationLine.Reset();
        AllocationLine.SetRange(AllocationLine."Destination Account Type", AllocationLine."Destination Account Type"::"Inherit from Parent");
        if AllocationLine.IsEmpty then begin
            AllocationLine.Reset();
            AllocationLine.SetView(CurrentFilters);
            exit;
        end;

        if GenJournalLine."Account No." = '' then
            Error(MustProvideAccountNoForInheritFromParentErr);

        AllocationLine.ModifyAll("Destination Account Number", GenJournalLine."Account No.");

        case GenJournalLine."Account Type" of
            "Gen. Journal Account Type"::"G/L Account":
                AllocationLine.ModifyAll("Destination Account Type", AllocationLine."Destination Account Type"::"G/L Account");
            "Gen. Journal Account Type"::"Bank Account":
                AllocationLine.ModifyAll("Destination Account Type", AllocationLine."Destination Account Type"::"Bank Account");
            else
                Error(InvalidAccountTypeForInheritFromParentErr, GenJournalLine."Account Type");
        end;

        AllocationLine.Reset();
        AllocationLine.SetView(CurrentFilters);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeCode', '', false, false)]
    local procedure PostAllocationJournalLine(var GenJnlLine: Record "Gen. Journal Line"; CheckLine: Boolean; var IsPosted: Boolean; var GLReg: Record "G/L Register"; var GLEntryNo: Integer)
    begin
        if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Allocation Account") or (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Allocation Account") then
            Error(PostFromBatchErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnBeforeCode', '', false, false)]
    local procedure HandleBatchPost(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    var
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
        ContainsAllocationAccountLines: Boolean;
    begin
        VerifyLinesFromBatch(GenJournalLine, ContainsAllocationAccountLines);
        if not ContainsAllocationAccountLines then
            exit;

        AllocAccTelemetry.LogGeneralJournalPostingUsage();
        CreateLinesFromBatch(GenJournalLine)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertGLEntryBuffer', '', false, false)]
    local procedure HandleBeforeInsertGLEntryBuffer(var TempGLEntryBuf: Record "G/L Entry" temporary; var GenJournalLine: Record "Gen. Journal Line"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var NextEntryNo: Integer; var TotalAmount: Decimal; var TotalAddCurrAmount: Decimal; var GLEntry: Record "G/L Entry")
    begin
        TempGLEntryBuf."Allocation Account No." := GenJournalLine."Allocation Account No.";
        TempGLEntryBuf."Alloc. Journal Line SystemId" := GenJournalLine."Alloc. Journal Line SystemId";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeShowDimensions', '', false, false)]
    local procedure HandleShowDimensions(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; xGenJournalLine: Record "Gen. Journal Line")
    begin
        if IsHandled then
            exit;

        if (GenJournalLine."Account Type" <> GenJournalLine."Account Type"::"Allocation Account") and (GenJournalLine."Bal. Account Type" <> GenJournalLine."Bal. Account Type"::"Allocation Account") then
            exit;

        if GuiAllowed() then
            if not Confirm(ChangeDimensionsOnAllocationDistributionsQst) then
                Error('');
    end;


    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckBeforeModifyLine(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        DeleteManualDistributionsIfLineChanged(Rec);
    end;

    local procedure DeleteManualDistributionsIfLineChanged(var GenJournalLine: Record "Gen. Journal Line")
    var
        PreviousGenJournalLine: Record "Gen. Journal Line";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        DeleteAllocAccManualOverrideNeeded: Boolean;
    begin
        if GenJournalLine.IsTemporary() then
            exit;

        if (not AllocationAccountUsed(GenJournalLine)) then
            exit;

        PreviousGenJournalLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not PreviousGenJournalLine.GetBySystemId(GenJournalLine.SystemId) then
            exit;

        AllocAccManualOverride.SetRange("Parent System Id", GenJournalLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Gen. Journal Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocAccManualOverride.IsEmpty() then
            exit;

        DeleteAllocAccManualOverrideNeeded := (GenJournalLine."Account Type" <> PreviousGenJournalLine."Account Type") or
                                              (GenJournalLine."Account No." <> PreviousGenJournalLine."Account No.") or
                                              (GenJournalLine."Bal. Account Type" <> PreviousGenJournalLine."Bal. Account Type") or
                                                (GenJournalLine."Bal. Account No." <> PreviousGenJournalLine."Bal. Account No.") or
                                                 (GenJournalLine.Amount <> PreviousGenJournalLine.Amount);

        if not DeleteAllocAccManualOverrideNeeded then
            exit;

        if GuiAllowed() then
            if not Confirm(DeleteManualOverridesQst) then
                Error('');

        AllocAccManualOverride.DeleteAll();
    end;

    local procedure CreateLinesFromBatch(var GenJournalLine: Record "Gen. Journal Line")
    var
        AllocationAccountGenJournalLine: Record "Gen. Journal Line";
    begin
        if (GenJournalLine.GetFilter("Journal Batch Name") = '') and (GenJournalLine."Journal Batch Name" = '') then
            Error(PostFromBatchFilterWasNotSetErr);

        AllocationAccountGenJournalLine.CopyFilters(GenJournalLine);
        AllocationAccountGenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        AllocationAccountGenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        AllocationAccountGenJournalLine.SetRange("Bal. Account Type", AllocationAccountGenJournalLine."Bal. Account Type"::"Allocation Account");
        CreateLines(AllocationAccountGenJournalLine);
        AllocationAccountGenJournalLine.DeleteAll();

        AllocationAccountGenJournalLine.SetRange("Bal. Account Type");
        AllocationAccountGenJournalLine.SetRange("Account Type", AllocationAccountGenJournalLine."Account Type"::"Allocation Account");
        CreateLines(AllocationAccountGenJournalLine);
        AllocationAccountGenJournalLine.DeleteAll();

        AllocationAccountGenJournalLine.CopyFilters(GenJournalLine);
        AllocationAccountGenJournalLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        CreateLines(AllocationAccountGenJournalLine);
        AllocationAccountGenJournalLine.DeleteAll();
    end;

    procedure CreateLines(var AllocationAccountGenJournalLine: Record "Gen. Journal Line")
    begin
        AllocationAccountGenJournalLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if AllocationAccountGenJournalLine.IsEmpty() then
            exit;

        AllocationAccountGenJournalLine.ReadIsolation := IsolationLevel::UpdLock;
        AllocationAccountGenJournalLine.FindSet();

        repeat
            GenJnlLineCount := 0;
            SumAmountLCY := 0;
            CreateLinesFromAllocationAccountLine(AllocationAccountGenJournalLine);
        until AllocationAccountGenJournalLine.Next() = 0;
    end;

    local procedure AllocationAccountUsed(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        exit((GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Allocation Account") or (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Allocation Account") or (GenJournalLine."Selected Alloc. Account No." <> ''));
    end;

    local procedure CreateLinesFromAllocationAccountLine(var AllocationAccountGenJournalLine: Record "Gen. Journal Line")
    var
        ExistingAccountGenJournalLine: Record "Gen. Journal Line";
        AllocationLine: Record "Allocation Line";
        AllocationAccount: Record "Allocation Account";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        NextJournalLineNo: Integer;
        LastJournalLineNo: Integer;
        Increment: Integer;
        DescriptionChanged: Boolean;
    begin
        VerifyAccountsMustMatchIfBothAccountTypeAndBalancingAccountTypeAreAllocationAccounts(AllocationAccountGenJournalLine);

        if not GetAllocationAccount(AllocationAccountGenJournalLine, AllocationAccount) then
            Error(CannotGetAllocationAccountFromLineErr, AllocationAccountGenJournalLine."Line No.");

        GetOrGenerateAllocationLines(AllocationLine, AllocationAccountGenJournalLine.SystemId);
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        if AllocationLine.Count = 0 then
            Error(NoLinesGeneratedLbl, AllocationAccountGenJournalLine.RecordId);

        NextJournalLineNo := GetNextGenJournalLine(AllocationAccountGenJournalLine);
        LastJournalLineNo := AllocationAccountGenJournalLine."Line No.";

        Increment := GetLineIncrement(AllocationAccountGenJournalLine."Line No.", NextJournalLineNo, AllocationLine.Count);
        if Increment < -1 then begin
            Increment := 10000;
            LastJournalLineNo := GetLastGenJournalLine(AllocationAccountGenJournalLine)
        end;

        AllocationLine.Reset();
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        AllocationLine.FindSet();
        ExistingAccountGenJournalLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        ExistingAccountGenJournalLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        ExistingAccountGenJournalLine.GetBySystemId(AllocationAccountGenJournalLine.SystemId);
        DescriptionChanged := GetDescriptionChanged(ExistingAccountGenJournalLine.Description, ExistingAccountGenJournalLine."Account Type", ExistingAccountGenJournalLine."Account No.");
        repeat
            CreateGLLine(ExistingAccountGenJournalLine, AllocationLine, LastJournalLineNo, Increment, DescriptionChanged);
        until AllocationLine.Next() = 0;

        AllocAccManualOverride.SetRange("Parent System Id", AllocationAccountGenJournalLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Gen. Journal Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.IsEmpty() then
            AllocAccManualOverride.DeleteAll();
    end;

    local procedure VerifyLinesFromBatch(var GenJournalLine: Record "Gen. Journal Line"; var ContainsAllocationAccountLines: Boolean)
    var
        AllocationAccountGenJournalLine: Record "Gen. Journal Line";
    begin
        AllocationAccountGenJournalLine.CopyFilters(GenJournalLine);
        AllocationAccountGenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        AllocationAccountGenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        AllocationAccountGenJournalLine.SetRange("Bal. Account Type", AllocationAccountGenJournalLine."Bal. Account Type"::"Allocation Account");
        if not AllocationAccountGenJournalLine.IsEmpty() then begin
            ContainsAllocationAccountLines := true;
            VerifyGenJournalLines(AllocationAccountGenJournalLine);
        end;

        AllocationAccountGenJournalLine.SetRange("Bal. Account Type");
        AllocationAccountGenJournalLine.SetRange("Account Type", AllocationAccountGenJournalLine."Account Type"::"Allocation Account");
        if not AllocationAccountGenJournalLine.IsEmpty() then begin
            ContainsAllocationAccountLines := true;
            VerifyGenJournalLines(AllocationAccountGenJournalLine);
        end;

        AllocationAccountGenJournalLine.CopyFilters(GenJournalLine);
        AllocationAccountGenJournalLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        if not AllocationAccountGenJournalLine.IsEmpty() then begin
            ContainsAllocationAccountLines := true;
            VerifyGenJournalLines(AllocationAccountGenJournalLine);
        end;
    end;

    local procedure CreateGLLine(var AllocationAccountGenJournalLine: Record "Gen. Journal Line"; var AllocationLine: Record "Allocation Line"; var LastJournalLineNo: Integer; Increment: Integer; DescriptionChanged: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        AllocationLineCount: Integer;
    begin
        AllocationLineCount := AllocationLine.Count;
        GenJnlLineCount += 1;
        GenJournalLine.TransferFields(AllocationAccountGenJournalLine, true);
        GenJournalLine."Journal Batch Name" := AllocationAccountGenJournalLine."Journal Batch Name";
        GenJournalLine."Journal Template Name" := AllocationAccountGenJournalLine."Journal Template Name";
        GenJournalLine."Line No." := LastJournalLineNo + Increment;
        GenJournalLine."Alloc. Journal Line SystemId" := AllocationAccountGenJournalLine.SystemId;
        UpdateAccountNumbersAndTypesOnGenJournalLine(AllocationAccountGenJournalLine, GenJournalLine, AllocationLine);

        GenJournalLine.Validate(Amount, AllocationLine.Amount);
        TransferDimensionSetID(GenJournalLine, AllocationLine, AllocationAccountGenJournalLine."Alloc. Acc. Modified by User");
        if DescriptionChanged and (AllocationAccountGenJournalLine.Description <> '') then
            GenJournalLine.Description := AllocationAccountGenJournalLine.Description;

        SumAmountLCY += GenJournalLine."Amount (LCY)";
        if GenJnlLineCount = AllocationLineCount then
            if SumAmountLCY <> AllocationAccountGenJournalLine."Amount (LCY)" then
                GenJournalLine.Validate("Amount (LCY)", GenJournalLine."Amount (LCY)" + (AllocationAccountGenJournalLine."Amount (LCY)" - SumAmountLCY));

        OnBeforeCreateGeneralJournalLine(GenJournalLine, AllocationLine, AllocationAccountGenJournalLine);
        GenJournalLine.Insert(true);
        LastJournalLineNo := GenJournalLine."Line No.";
    end;

    local procedure UpdateAccountNumbersAndTypesOnGenJournalLine(var AllocationAccountGenJournalLine: Record "Gen. Journal Line"; var GenJournalLine: Record "Gen. Journal Line"; var AllocationLine: Record "Allocation Line")
    var
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        TranslateAccountTypeToGenJournalLineAccountType(AllocationLine, GenJournalAccountType);
        if (AllocationAccountGenJournalLine."Account Type" = AllocationAccountGenJournalLine."Account Type"::"Allocation Account") or (AllocationAccountGenJournalLine."Selected Alloc. Account No." <> '') then begin
            GenJournalLine."Account Type" := GenJournalAccountType;
            GenJournalLine."Account No." := AllocationLine."Destination Account Number";
            if GenJournalLine."Selected Alloc. Account No." = '' then
                GenJournalLine."Allocation Account No." := AllocationAccountGenJournalLine."Account No."
            else begin
                GenJournalLine."Allocation Account No." := GenJournalLine."Selected Alloc. Account No.";
                GenJournalLine."Selected Alloc. Account No." := '';
            end;
            exit;
        end;

        if AllocationAccountGenJournalLine."Bal. Account Type" = AllocationAccountGenJournalLine."Bal. Account Type"::"Allocation Account" then begin
            GenJournalLine."Bal. Account Type" := GenJournalAccountType;
            GenJournalLine."Bal. Account No." := AllocationLine."Destination Account Number";
            GenJournalLine."Allocation Account No." := AllocationAccountGenJournalLine."Bal. Account No.";
            exit;
        end;
    end;

    local procedure TranslateAccountTypeToGenJournalLineAccountType(var AllocationLine: Record "Allocation Line"; var GenJournalAccountType: Enum "Gen. Journal Account Type")
    var
        Handled: Boolean;
    begin
        OnBeforeGetGeneralJournalLineType(AllocationLine, GenJournalAccountType, Handled);

        if Handled then
            exit;

        case AllocationLine."Destination Account Type" of
            AllocationLine."Destination Account Type"::"G/L Account":
                GenJournalAccountType := GenJournalAccountType::"G/L Account";
            AllocationLine."Destination Account Type"::"Bank Account":
                GenJournalAccountType := GenJournalAccountType::"Bank Account";
        end;
    end;

    local procedure GetNextGenJournalLine(var AllocationAccountGenJournalLine: Record "Gen. Journal Line"): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", AllocationAccountGenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", AllocationAccountGenJournalLine."Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '>%1', AllocationAccountGenJournalLine."Line No.");
        GenJournalLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if GenJournalLine.FindFirst() then
            exit(GenJournalLine."Line No.");

        exit(AllocationAccountGenJournalLine."Line No." + 10000);
    end;

    local procedure GetLastGenJournalLine(var AllocationAccountGenJournalLine: Record "Gen. Journal Line"): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", AllocationAccountGenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", AllocationAccountGenJournalLine."Journal Batch Name");
        GenJournalLine.SetFilter("Line No.", '>%1', AllocationAccountGenJournalLine."Line No.");
        GenJournalLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if GenJournalLine.FindLast() then
            exit(GenJournalLine."Line No.");

        exit(AllocationAccountGenJournalLine."Line No.");
    end;

    local procedure GetDescriptionChanged(ExistingDescription: Text; AccountType: Enum "Gen. Journal Account Type"; AccountValue: Code[20]): Boolean
    var
        GLAccount: Record "G/L Account";
        AllocationAccount: Record "Allocation Account";
        ExpectedDescription: Text;
    begin
        case AccountType of
            AccountType::"G/L Account":
                begin
                    if not GLAccount.Get(AccountValue) then
                        exit(false);

                    ExpectedDescription := GLAccount.Name;
                end;
            AccountType::"Allocation Account":
                begin
                    if not AllocationAccount.Get(AccountValue) then
                        exit(false);

                    ExpectedDescription := AllocationAccount.Name;
                end;
            else
                exit(false);
        end;

        exit(ExistingDescription <> ExpectedDescription);
    end;

    local procedure GetLineIncrement(CurrentLineNo: Integer; NextLineNo: Integer; LinesToInsert: Integer): Integer
    var
        Increment: Integer;
    begin
        Increment := Round((NextLineNo - CurrentLineNo) / LinesToInsert, 1);
        if Increment < LinesToInsert then
            exit(-1);

        if Increment >= 1000 then
            exit(100);

        if Increment >= 100 then
            exit(10);

        if Increment >= 10 then
            exit(1);

        exit(Increment);
    end;

    local procedure GetAllocationAccount(var AllocationAccountGenJournalLine: Record "Gen. Journal Line"; var AllocationAccount: Record "Allocation Account"): Boolean
    begin
        if AllocationAccountGenJournalLine."Selected Alloc. Account No." <> '' then
            exit(AllocationAccount.Get(AllocationAccountGenJournalLine."Selected Alloc. Account No."));

        if AllocationAccountGenJournalLine."Account Type" = AllocationAccountGenJournalLine."Account Type"::"Allocation Account" then
            exit(AllocationAccount.Get(AllocationAccountGenJournalLine."Account No."));

        if AllocationAccountGenJournalLine."Bal. Account Type" = AllocationAccountGenJournalLine."Bal. Account Type"::"Allocation Account" then
            exit(AllocationAccount.Get(AllocationAccountGenJournalLine."Bal. Account No."));

        exit(false);
    end;

    local procedure VerifyAccountsMustMatchIfBothAccountTypeAndBalancingAccountTypeAreAllocationAccounts(var AllocationAccountGenJournalLine: Record "Gen. Journal Line")
    begin
        if (AllocationAccountGenJournalLine."Account Type" = AllocationAccountGenJournalLine."Account Type"::"Allocation Account") and (AllocationAccountGenJournalLine."Bal. Account Type" = AllocationAccountGenJournalLine."Bal. Account Type"::"Allocation Account") then
            Error(CannotSetTheAllocationAccountToBothErr);
    end;

    local procedure TransferDimensionSetID(var GenJournalLine: Record "Gen. Journal Line"; var AllocationLine: Record "Allocation Line"; ModifiedByUser: Boolean)
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        if AllocationLine."Dimension Set ID" = 0 then
            exit;

        if GenJournalLine."Dimension Set ID" = AllocationLine."Dimension Set ID" then
            exit;

        if (GenJournalLine."Dimension Set ID" = 0) or ModifiedByUser then begin
            GenJournalLine."Dimension Set ID" := AllocationLine."Dimension Set ID";
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              GenJournalLine."Dimension Set ID", GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");

            exit;
        end;

        DimensionSetIDArr[1] := GenJournalLine."Dimension Set ID";
        DimensionSetIDArr[2] := AllocationLine."Dimension Set ID";
        GenJournalLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterModifyEvent, '', false, false)]
    local procedure VerifyGeneralJournalLineOnAfterModify(RunTrigger: Boolean; var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    begin
        VerifyGeneralJournalLine(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGeneralJournalLineType(var AllocationLine: Record "Allocation Line"; var GenJournalAccountType: Enum "Gen. Journal Account Type"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var AllocationLine: Record "Allocation Line"; var AllocationAccountGenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    local procedure VerifyGenJournalLines(var AllocationAccountGenJournalLine: Record "Gen. Journal Line")
    begin
        AllocationAccountGenJournalLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if not AllocationAccountGenJournalLine.FindSet() then
            exit;

        repeat
            VerifyGeneralJournalLine(AllocationAccountGenJournalLine);
        until AllocationAccountGenJournalLine.Next() = 0;
    end;

    local procedure VerifyGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        if not AllocationAccountUsed(GenJournalLine) then
            exit;

        OnBeforeVerifyGeneralJournalLine(GenJournalLine);
        if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Allocation Account") and (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Allocation Account") then
            Error(CannotUseBothAccountTypeAndBalancingAccountTypeAsAllocationAccountErr);

        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Allocation Account" then
            AllocationAccountMgt.VerifyNoInheritFromParentUsed(GenJournalLine."Account No.");

        if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Allocation Account" then
            AllocationAccountMgt.VerifyNoInheritFromParentUsed(GenJournalLine."Bal. Account No.");

        if GenJournalLine."Selected Alloc. Account No." <> '' then
            VerifySelectedAllocationAccountNo(GenJournalLine);
    end;

    procedure VerifySelectedAllocationAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Selected Alloc. Account No." = '' then
            exit;

        if not (GenJournalLine."Account Type" in [GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account"]) then
            Error(InvalidAccountTypeForInheritFromParentErr, GenJournalLine."Account Type");

        VerifyParentAccountIsDefined(GenJournalLine);
    end;

    local procedure VerifyParentAccountIsDefined(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine."Account No." = '' then
            Error(YouMustEnterAnAccountNoForInheritFromParentErr);
    end;

    var
        PostFromBatchErr: Label 'The general journal line that are using allocation accounts must be posted from a batch.';
        PostFromBatchFilterWasNotSetErr: Label 'The filter was not set when posting from batch. Aborting the post.';
        CannotSetTheAllocationAccountToBothErr: Label 'You cannot set Allocation account to both Account type and to Balancing account type.';
        CannotGetAllocationAccountFromLineErr: Label 'Cannot get allocation account from journal line %1.', Comment = '%1 - Line No., it is an integer that identifies the line e.g. 10000, 200000.';
        NoLinesGeneratedLbl: Label 'No allocation account lines were generated for journal line %1.', Comment = '%1 - Unique identification of the line.';
        ChangeDimensionsOnAllocationDistributionsQst: Label 'The line is connected to the Allocation Account. Any dimensions that you change through this action will be merged with dimensions that are defined on the Allocation Line. To change the final dimensions you should invoke the Redistribute Account Allocations action.\\Do you want to continue?';
        CannotUseBothAccountTypeAndBalancingAccountTypeAsAllocationAccountErr: Label 'You cannot use both account type and balancing account type as allocation accounts.';
        DeleteManualOverridesQst: Label 'Modifying the line will delete all manual overrides for allocation account.\\Do you want to continue?';
        YouMustEnterAnAccountNoForInheritFromParentErr: Label 'You must enter the account number if the allocation account with inherit from parent is used.';
        InvalidAccountTypeForInheritFromParentErr: Label 'Selected account type - %1 cannot be used for allocation accounts that have inherit from parent defined.', Comment = '%1 - Account type, e.g. G/L Account, Customer, Vendor, Bank Account, Fixed Asset, Item, Resource, Charge, Project, or Blank.';
        MustProvideAccountNoForInheritFromParentErr: Label 'You must provide an account number for allocation account with inherit from parent defined.';
        AllocationAccountsCannotBeUsedOnThisPageErr: Label 'Allocation accounts cannot be used on this page.';
        GenJnlLineCount: Integer;
        SumAmountLCY: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnLoadManualAllocationLinesOnBeforeInsertAllocationLine(var AllocAccManualOverride: Record "Alloc. Acc. Manual Override"; var AllocationLine: Record "Allocation Line")
    begin
    end;
}
