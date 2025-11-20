// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount.Purchase;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Posting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using System.Automation;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 2679 "Purchase Alloc. Acc. Mgt."
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
        PurchaseLine: Record "Purchase Line";
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        PurchaseLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        PurchaseLine.GetBySystemId(ParentSystemId);
        AmountToAllocate := PurchaseLine.Amount;

        PostingDate := PurchaseLine.GetPurchHeader()."Posting Date";

        if PurchaseLine."Alloc. Acc. Modified by User" then
            LoadManualAllocationLines(PurchaseLine, AllocationLine)
        else begin
            GetAllocationAccount(PurchaseLine, AllocationAccount);
            AllocationAccountMgt.GenerateAllocationLines(AllocationAccount, AllocationLine, PurchaseLine.Amount, PostingDate, PurchaseLine."Dimension Set ID", PurchaseLine."Currency Code");
            AllocationAccountMgt.SplitQuantitiesIfNeeded(PurchaseLine.Quantity, AllocationLine, AllocationAccount);
            ReplaceInheritFromParent(AllocationLine, PurchaseLine);
        end;
    end;

    internal procedure LoadManualAllocationLines(var PurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", PurchaseLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Purchase Line");
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
            AllocationLine."Dimension Set ID" := AllocAccManualOverride."Dimension Set ID";
            AllocationLine.Amount := AllocAccManualOverride.Amount;
            AllocationLine.Quantity := AllocAccManualOverride.Quantity;
            OnLoadManualAllocationLinesOnBeforeInsertAllocationLine(AllocAccManualOverride, AllocationLine);
            AllocationLine.Insert();
        until AllocAccManualOverride.Next() = 0;
    end;

    local procedure ReplaceInheritFromParent(var AllocationLine: Record "Allocation Line"; var PurchaseLine: Record "Purchase Line")
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

        if PurchaseLine."No." = '' then
            Error(MustProvideAccountNoForInheritFromParentErr);

        AllocationLine.ModifyAll("Destination Account Number", PurchaseLine."No.");

        case PurchaseLine.Type of
            PurchaseLine.Type::"G/L Account":
                AllocationLine.ModifyAll("Destination Account Type", AllocationLine."Destination Account Type"::"G/L Account");
            else
                Error(InvalidAccountTypeForInheritFromParentErr, PurchaseLine.Type);
        end;

        IsInheritFromParent := true;
        AllocationLine.Reset();
        AllocationLine.SetView(CurrentFilters);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure HandlePostDocument(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var IsHandled: Boolean)
    var
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
        ContainsAllocationLines: Boolean;
    begin
        VerifyLinesFromDocument(PurchaseHeader, ContainsAllocationLines);
        if not ContainsAllocationLines then
            exit;

        AllocAccTelemetry.LogPurchaseInvoicePostingUsage();
        CreateLinesFromDocument(PurchaseHeader)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeShowDimensions', '', false, false)]
    local procedure HandleShowDimensions(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        if (PurchaseLine."Type" <> PurchaseLine."Type"::"Allocation Account") then
            exit;

        if GuiAllowed() then
            if not Confirm(ChangeDimensionsOnAllocationDistributionsQst) then
                Error('');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnAfterCheckPurchaseApprovalPossible', '', false, false)]
    local procedure HandleAfterCheckSalesApprovalPossible(var PurchaseHeader: Record "Purchase Header")
    var
        ContainsAllocationLines: Boolean;
    begin
        VerifyLinesFromDocument(PurchaseHeader, ContainsAllocationLines);
        if not ContainsAllocationLines then
            exit;

        if not GuiAllowed() then
            Error(ReplaceAllocationLinesBeforeSendingToApprovalErr);

        if not Confirm(ReplaceAllocationLinesBeforeSendingToApprovalQst) then
            Error(ReplaceAllocationLinesBeforeSendingToApprovalErr);

        CreateLinesFromDocument(PurchaseHeader);
        Commit();
        if PurchaseHeader.Find() then;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckBeforeModifyLine(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        VerifyPurchaseLine(Rec);
        DeleteManualDistributionsIfLineChanged(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeValidateNo', '', false, false)]
    local procedure HandleValidateLineNo(CurrentFieldNo: Integer; var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if IsHandled then
            exit;

        if PurchaseLine."Type" <> PurchaseLine."Type"::"Allocation Account" then
            exit;

        IsHandled := true;

        VerifyPurchaseLine(PurchaseLine);
        if PurchaseLine.Description <> '' then
            exit;

        AllocationAccount.Get(PurchaseLine."No.");
        PurchaseLine.Description := AllocationAccount.Name;
    end;

    local procedure DeleteManualDistributionsIfLineChanged(var PurchaseLine: Record "Purchase Line")
    var
        PreviousPurchaseLine: Record "Purchase Line";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        DeleteAllocAccManualOverrideNeeded: Boolean;
    begin
        if PurchaseLine.IsTemporary() then
            exit;

        if (not AllocationAccountUsed(PurchaseLine)) then
            exit;

        PreviousPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not PreviousPurchaseLine.GetBySystemId(PurchaseLine.SystemId) then
            exit;

        AllocAccManualOverride.SetRange("Parent System Id", PurchaseLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Purchase Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocAccManualOverride.IsEmpty() then
            exit;

        DeleteAllocAccManualOverrideNeeded := (PurchaseLine."Type" <> PreviousPurchaseLine."Type") or
                                              (PurchaseLine."No." <> PreviousPurchaseLine."No.") or
                                                 (PurchaseLine."Line Amount" <> PreviousPurchaseLine."Line Amount");

        if not DeleteAllocAccManualOverrideNeeded then
            exit;

        if GuiAllowed() then
            if not Confirm(DeleteManualOverridesQst) then
                Error('');

        AllocAccManualOverride.DeleteAll();
    end;

    local procedure AllocationAccountUsed(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit((PurchaseLine.Type = PurchaseLine.Type::"Allocation Account") or (PurchaseLine."Selected Alloc. Account No." <> ''));
    end;

    local procedure CreateLinesFromDocument(var PurchaseHeader: Record "Purchase Header")
    var
        AllocationPurchaseLine: Record "Purchase Line";
        IsReopen: Boolean;
    begin
        CheckPurchaseReleaseStatus(PurchaseHeader, IsReopen);

        AllocationPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationPurchaseLine.SetRange("Type", AllocationPurchaseLine."Type"::"Allocation Account");
        CreateLines(AllocationPurchaseLine);
        AllocationPurchaseLine.DeleteAll();

        AllocationPurchaseLine.Reset();
        AllocationPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationPurchaseLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        CreateLines(AllocationPurchaseLine);
        AllocationPurchaseLine.DeleteAll();

        CheckPurchaseReleaseStatus(PurchaseHeader, IsReopen);
    end;

    local procedure CreateLines(var AllocationPurchaseLine: Record "Purchase Line")
    begin
        AllocationPurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if AllocationPurchaseLine.IsEmpty() then
            exit;

        AllocationPurchaseLine.ReadIsolation := IsolationLevel::UpdLock;
        AllocationPurchaseLine.FindSet();
        repeat
            CreateLinesFromAllocationAccountLine(AllocationPurchaseLine);
        until AllocationPurchaseLine.Next() = 0;
    end;

    procedure CreateLinesFromAllocationAccountLine(var AllocationAccountPurchaseLine: Record "Purchase Line")
    var
        ExistingAccountPurchaseLine: Record "Purchase Line";
        AllocationLine: Record "Allocation Line";
        AllocationAccount: Record "Allocation Account";
        DescriptionChanged: Boolean;
        NextLineNo: Integer;
        LastLineNo: Integer;
        Increment: Integer;
        CreatedLines: List of [Guid];
    begin
        if not GetAllocationAccount(AllocationAccountPurchaseLine, AllocationAccount) then
            Error(CannotGetAllocationAccountFromLineErr, AllocationAccountPurchaseLine."Line No.");

        VerifyAllocationAccount(AllocationAccount);

        GetOrGenerateAllocationLines(AllocationLine, AllocationAccountPurchaseLine.SystemId);
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        if AllocationLine.Count = 0 then
            Error(NoLinesGeneratedLbl, AllocationAccountPurchaseLine.RecordId);

        NextLineNo := GetNextLine(AllocationAccountPurchaseLine);
        LastLineNo := AllocationAccountPurchaseLine."Line No.";

        Increment := GetLineIncrement(AllocationAccountPurchaseLine."Line No.", NextLineNo, AllocationLine.Count);
        if Increment < -1 then begin
            Increment := 10000;
            LastLineNo := GetLastLine(AllocationAccountPurchaseLine)
        end;

        AllocationLine.Reset();
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        AllocationLine.FindSet();
        ExistingAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        ExistingAccountPurchaseLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        ExistingAccountPurchaseLine.GetBySystemId(AllocationAccountPurchaseLine.SystemId);
        DescriptionChanged := GetDescriptionChanged(ExistingAccountPurchaseLine.Description, ExistingAccountPurchaseLine.Type, ExistingAccountPurchaseLine."No.");

        repeat
            CreatedLines.Add(CreatePurchaseLine(ExistingAccountPurchaseLine, AllocationLine, LastLineNo, Increment, AllocationAccount, DescriptionChanged));
        until AllocationLine.Next() = 0;

        FixQuantityRounding(CreatedLines, ExistingAccountPurchaseLine, AllocationAccount);
        DeleteManualOverrides(AllocationAccountPurchaseLine);
    end;

    local procedure DeleteManualOverrides(var PurchaseLine: Record "Purchase Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", PurchaseLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Purchase Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.IsEmpty() then
            AllocAccManualOverride.DeleteAll();
    end;

    local procedure VerifyLinesFromDocument(var PurchaseHeader: Record "Purchase Header"; var ContainsAllocationLines: Boolean)
    var
        AllocationAccountPurchaseLine: Record "Purchase Line";
    begin
        AllocationAccountPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationAccountPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationAccountPurchaseLine.SetRange("Type", AllocationAccountPurchaseLine."Type"::"Allocation Account");
        AllocationAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocationAccountPurchaseLine.FindSet() then begin
            ContainsAllocationLines := true;
            repeat
                VerifyPurchaseLines(AllocationAccountPurchaseLine);
            until AllocationAccountPurchaseLine.Next() = 0;
        end;

        AllocationAccountPurchaseLine.Reset();
        AllocationAccountPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        AllocationAccountPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        AllocationAccountPurchaseLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        AllocationAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocationAccountPurchaseLine.FindSet() then begin
            ContainsAllocationLines := true;
            repeat
                VerifyPurchaseLines(AllocationAccountPurchaseLine);
            until AllocationAccountPurchaseLine.Next() = 0;
        end;
    end;

    local procedure CreatePurchaseLine(var AllocationPurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line"; var LastLineNo: Integer; Increment: Integer; var AllocationAccount: Record "Allocation Account"; var DescriptionChanged: Boolean): Guid
    var
        PurchaseLine: Record "Purchase Line";
        AllocAccHandleDocPost: Codeunit "Alloc. Acc. Handle Doc. Post";
    begin
        PurchaseLine.TransferFields(AllocationPurchaseLine, true);
        PurchaseLine."Line No." := LastLineNo + Increment;
        PurchaseLine."Type" := PurchaseLine."Type"::"G/L Account";
        if AllocationPurchaseLine."VAT Bus. Posting Group" <> '' then
            AllocAccHandleDocPost.SetVATBusPostingGroupCode(AllocationPurchaseLine."VAT Bus. Posting Group");

        if AllocationPurchaseLine."VAT Prod. Posting Group" <> '' then
            AllocAccHandleDocPost.SetVATProdPostingGroupCode(AllocationPurchaseLine."VAT Prod. Posting Group");

        BindSubscription(AllocAccHandleDocPost);
        PurchaseLine.Validate("No.", AllocationLine."Destination Account Number");
        if AllocationPurchaseLine."Tax Group Code" <> '' then
            PurchaseLine.Validate("Tax Group Code", AllocationPurchaseLine."Tax Group Code");
        UnbindSubscription(AllocAccHandleDocPost);

        if DescriptionChanged then begin
            if AllocationPurchaseLine.Description <> '' then
                PurchaseLine.Description := AllocationPurchaseLine.Description;
            if AllocationPurchaseLine."Description 2" <> '' then
                PurchaseLine."Description 2" := AllocationPurchaseLine."Description 2";
        end;

        MoveAmounts(PurchaseLine, AllocationPurchaseLine, AllocationLine, AllocationAccount);
        MoveQuantities(PurchaseLine, AllocationPurchaseLine);

        PurchaseLine."VAT Difference" := AllocationLine.Percentage * AllocationPurchaseLine."VAT Difference" / 100;
        PurchaseLine."Deferral Code" := AllocationPurchaseLine."Deferral Code";
        CopyDeferralSchedule(PurchaseLine, AllocationPurchaseLine);
        TransferDimensionSetID(PurchaseLine, AllocationLine, AllocationPurchaseLine."Alloc. Acc. Modified by User");
        PurchaseLine."Allocation Account No." := AllocationLine."Allocation Account No.";
        PurchaseLine."Selected Alloc. Account No." := '';
        PurchaseLine."Alloc. Purch. Line SystemId" := AllocationPurchaseLine.SystemId;
        OnBeforeCreatePurchaseLine(PurchaseLine, AllocationLine, AllocationPurchaseLine);
        BindSubscription(AllocAccHandleDocPost);
        PurchaseLine.Insert(true);
        UnbindSubscription(AllocAccHandleDocPost);
        LastLineNo := PurchaseLine."Line No.";
        RedistributeQuantitiesIfNeededMoveQuantities(PurchaseLine, AllocationPurchaseLine, AllocationLine, AllocationAccount);
        exit(PurchaseLine.SystemId);
    end;

    local procedure CopyDeferralSchedule(PurchaseLine: Record "Purchase Line"; AllocationPurchaseLine: Record "Purchase Line")
    var
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        if PurchaseLine."Deferral Code" = '' then
            exit;

        if not DeferralTemplate.Get(PurchaseLine."Deferral Code") then
            exit;

        if DeferralTemplate."Calc. Method" <> DeferralTemplate."Calc. Method"::"User-Defined" then
            exit;

        if not DeferralHeader.Get("Deferral Document Type"::Purchase, '', '', PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", AllocationPurchaseLine."Line No.") then
            exit;

        DeferralUtilities.CreateCopyOfDeferralSchedule(DeferralHeader, PurchaseLine."Line No.");
    end;

    local procedure MoveQuantities(var PurchaseLine: Record "Purchase Line"; var AllocationPurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Quantity := AllocationPurchaseLine.Quantity;
        PurchaseLine."Outstanding Quantity" := AllocationPurchaseLine."Outstanding Quantity";
        PurchaseLine."Quantity Received" := AllocationPurchaseLine."Quantity Received";
        PurchaseLine."Quantity Invoiced" := AllocationPurchaseLine."Quantity Invoiced";
        PurchaseLine."Qty. to Invoice" := AllocationPurchaseLine."Qty. to Invoice";
        PurchaseLine."Qty. to Receive" := AllocationPurchaseLine."Qty. to Receive";
        PurchaseLine."Quantity (Base)" := AllocationPurchaseLine."Quantity (Base)";
        PurchaseLine."Outstanding Qty. (Base)" := AllocationPurchaseLine."Outstanding Qty. (Base)";
        PurchaseLine."Qty. to Receive (Base)" := AllocationPurchaseLine."Qty. to Receive (Base)";
        PurchaseLine."Return Qty. to Ship" := AllocationPurchaseLine."Return Qty. to Ship";
        PurchaseLine."Return Qty. to Ship (Base)" := AllocationPurchaseLine."Return Qty. to Ship (Base)";
    end;

    local procedure RedistributeQuantitiesIfNeededMoveQuantities(var PurchaseLine: Record "Purchase Line"; var AllocationPurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line"; var AllocationAccount: Record "Allocation Account")
    var
        LinePercentage: Decimal;
    begin
        if AllocationAccount."Document Lines Split" <> AllocationAccount."Document Lines Split"::"Split Quantity" then
            exit;

        if AllocationLine.Percentage <> 0 then
            LinePercentage := AllocationLine.Percentage
        else
            LinePercentage := Round(AllocationLine.Quantity / AllocationPurchaseLine.Quantity * 100, AllocationLine.GetQuantityPrecision());

        PurchaseLine.Quantity := 0;
        if PurchaseLine.IsInvoiceDocType() then
            PurchaseLine.Validate(Quantity, Round(AllocationPurchaseLine.Quantity * LinePercentage / 100, AllocationLine.GetQuantityPrecision()))
        else
            PurchaseLine.Validate(Quantity, AllocationLine.Quantity);
        PurchaseLine."Outstanding Quantity" := Round(AllocationPurchaseLine."Outstanding Quantity" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Quantity Received" := Round(AllocationPurchaseLine."Quantity Received" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Quantity Invoiced" := Round(AllocationPurchaseLine."Quantity Invoiced" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Qty. to Invoice" := Round(AllocationPurchaseLine."Qty. to Invoice" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Qty. to Receive" := Round(AllocationPurchaseLine."Qty. to Receive" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Quantity (Base)" := Round(AllocationPurchaseLine."Quantity (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Outstanding Qty. (Base)" := Round(AllocationPurchaseLine."Outstanding Qty. (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Qty. to Receive (Base)" := Round(AllocationPurchaseLine."Qty. to Receive (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Return Qty. to Ship" := Round(AllocationPurchaseLine."Return Qty. to Ship" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine."Return Qty. to Ship (Base)" := Round(AllocationPurchaseLine."Return Qty. to Ship (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        PurchaseLine.Modify();
    end;

    local procedure FixQuantityRounding(CreatedLines: List of [Guid]; var ExistingAccountPurchaseLine: Record "Purchase Line"; var AllocationAccount: Record "Allocation Account")
    var
        PurchaseLine: Record "Purchase Line";
        LastLine: Record "Purchase Line";
        CreatedLineSystemID: Guid;
        ModifyLine: Boolean;
    begin
        if AllocationAccount."Document Lines Split" <> AllocationAccount."Document Lines Split"::"Split Quantity" then
            exit;

        PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        foreach CreatedLineSystemID in CreatedLines do begin
            PurchaseLine.GetBySystemId(CreatedLineSystemID);
            PurchaseLine.Mark(true);
        end;

        PurchaseLine.MarkedOnly(true);
        if not PurchaseLine.FindLast() then
            exit;

        LastLine.Copy(PurchaseLine);

        PurchaseLine.CalcSums("Outstanding Quantity", "Quantity Received", "Quantity Invoiced", "Qty. to Invoice", "Qty. to Receive", "Quantity (Base)", "Outstanding Qty. (Base)", "Qty. to Receive (Base)", "Return Qty. to Ship", "Return Qty. to Ship (Base)");

        if ExistingAccountPurchaseLine."Outstanding Quantity" - PurchaseLine."Outstanding Quantity" > 0 then begin
            LastLine."Outstanding Quantity" += ExistingAccountPurchaseLine."Outstanding Quantity" - PurchaseLine."Outstanding Quantity";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Quantity Received" - PurchaseLine."Quantity Received" > 0 then begin
            LastLine."Quantity Received" += ExistingAccountPurchaseLine."Quantity Received" - PurchaseLine."Quantity Received";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Quantity Invoiced" - PurchaseLine."Quantity Invoiced" > 0 then begin
            LastLine."Quantity Invoiced" += ExistingAccountPurchaseLine."Quantity Invoiced" - PurchaseLine."Quantity Invoiced";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Qty. to Invoice" - PurchaseLine."Qty. to Invoice" > 0 then begin
            LastLine."Qty. to Invoice" += ExistingAccountPurchaseLine."Qty. to Invoice" - PurchaseLine."Qty. to Invoice";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Qty. to Receive" - PurchaseLine."Qty. to Receive" > 0 then begin
            LastLine."Qty. to Receive" += ExistingAccountPurchaseLine."Qty. to Receive" - PurchaseLine."Qty. to Receive";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Quantity (Base)" - PurchaseLine."Quantity (Base)" > 0 then begin
            LastLine."Quantity (Base)" += ExistingAccountPurchaseLine."Quantity (Base)" - PurchaseLine."Quantity (Base)";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Outstanding Qty. (Base)" - PurchaseLine."Outstanding Qty. (Base)" > 0 then begin
            LastLine."Outstanding Qty. (Base)" += ExistingAccountPurchaseLine."Outstanding Qty. (Base)" - PurchaseLine."Outstanding Qty. (Base)";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Qty. to Receive (Base)" - PurchaseLine."Qty. to Receive (Base)" > 0 then begin
            LastLine."Qty. to Receive (Base)" += ExistingAccountPurchaseLine."Qty. to Receive (Base)" - PurchaseLine."Qty. to Receive (Base)";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Return Qty. to Ship" - PurchaseLine."Return Qty. to Ship" > 0 then begin
            LastLine."Return Qty. to Ship" += ExistingAccountPurchaseLine."Return Qty. to Ship" - PurchaseLine."Return Qty. to Ship";
            ModifyLine := true;
        end;

        if ExistingAccountPurchaseLine."Return Qty. to Ship (Base)" - PurchaseLine."Return Qty. to Ship (Base)" > 0 then begin
            LastLine."Return Qty. to Ship (Base)" += ExistingAccountPurchaseLine."Return Qty. to Ship (Base)" - PurchaseLine."Return Qty. to Ship (Base)";
            ModifyLine := true;
        end;

        if ModifyLine then
            LastLine.Modify();
    end;

    local procedure MoveAmounts(var PurchaseLine: Record "Purchase Line"; var AllocationPurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line"; var AllocationAccount: Record "Allocation Account")
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        AmountRoundingPrecision: Decimal;
    begin
        PurchaseLine."Unit Cost" := AllocationPurchaseLine."Unit Cost";

        if AllocationAccount."Document Lines Split" = AllocationAccount."Document Lines Split"::"Split Amount" then begin
            if IsInheritFromParent then begin
                PurchaseLine.Validate("Direct Unit Cost", GetUnitPrice(PurchaseLine, AllocationLine.Amount));
                PurchaseLine."Line Amount" := AllocationLine.Amount;
            end else begin
                AmountRoundingPrecision := AllocationAccountMgt.GetCurrencyRoundingPrecision(PurchaseLine."Currency Code");
                PurchaseLine.Validate("Direct Unit Cost", Round(AllocationLine.Amount / PurchaseLine.Quantity, AmountRoundingPrecision));
                PurchaseLine.Validate("Line Amount", AllocationLine.Amount);
            end;
        end else begin
            PurchaseLine.Validate("Direct Unit Cost", AllocationPurchaseLine."Direct Unit Cost");
            PurchaseLine."Line Amount" := AllocationPurchaseLine."Line Amount";
        end;
    end;

    local procedure GetUnitPrice(var PurchaseLine: Record "Purchase Line"; AllocationLineAmount: Decimal): Decimal
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        AmountRoundingPrecision: Decimal;
    begin
        if PurchaseLine.GetPurchHeader()."Prices Including VAT" then begin
            AllocationLineAmount += AllocationLineAmount * PurchaseLine."VAT %" / 100;
            AmountRoundingPrecision := AllocationAccountMgt.GetCurrencyRoundingPrecision(PurchaseLine."Currency Code");
            exit(Round(AllocationLineAmount / PurchaseLine.Quantity, AmountRoundingPrecision));
        end;

        exit(AllocationLineAmount / PurchaseLine.Quantity);
    end;

    local procedure GetNextLine(var AllocationPurchaseLine: Record "Purchase Line"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", AllocationPurchaseLine."Document No.");
        PurchaseLine.SetRange("Document Type", AllocationPurchaseLine."Document Type");
        PurchaseLine.SetFilter("Line No.", '>%1', AllocationPurchaseLine."Line No.");
        PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if PurchaseLine.FindFirst() then
            exit(PurchaseLine."Line No.");

        exit(AllocationPurchaseLine."Line No." + 10000);
    end;

    local procedure GetLastLine(var AllocationPurchaseLine: Record "Purchase Line"): Integer
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", AllocationPurchaseLine."Document No.");
        PurchaseLine.SetRange("Document Type", AllocationPurchaseLine."Document Type");
        PurchaseLine.SetFilter("Line No.", '>%1', AllocationPurchaseLine."Line No.");
        PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if PurchaseLine.FindLast() then
            exit(PurchaseLine."Line No.");

        exit(AllocationPurchaseLine."Line No.");
    end;


    local procedure GetLineIncrement(CurrentLineNo: Integer; NextLineNo: Integer; LinesToInsert: Integer): Integer
    var
        Increment: Integer;
    begin
        Increment := Round((NextLineNo - CurrentLineNo) / LinesToInsert, 1);
        if Increment < LinesToInsert then
            exit(-1);

        if Increment >= 1000 then
            exit(1000);

        if Increment >= 100 then
            exit(100);

        if Increment >= 10 then
            exit(10);

        exit(Increment);
    end;

    local procedure GetAllocationAccount(var AllocationAccountPurchaseLine: Record "Purchase Line"; var AllocationAccount: Record "Allocation Account"): Boolean
    begin
        if AllocationAccountPurchaseLine."Selected Alloc. Account No." <> '' then
            exit(AllocationAccount.Get(AllocationAccountPurchaseLine."Selected Alloc. Account No."));

        if AllocationAccountPurchaseLine."Type" = AllocationAccountPurchaseLine."Type"::"Allocation Account" then
            exit(AllocationAccount.Get(AllocationAccountPurchaseLine."No."));

        exit(false);
    end;

    internal procedure VerifyAllocationAccount(var AllocationAccount: Record "Allocation Account")
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution.SetRange("Allocation Account No.", AllocationAccount."No.");
        AllocAccountDistribution.SetFilter("Destination Account Type", '<>%1&<>%2', AllocAccountDistribution."Destination Account Type"::"G/L Account", AllocAccountDistribution."Destination Account Type"::"Inherit from Parent");
        if not AllocAccountDistribution.IsEmpty() then
            Error(AllocationAccountMustOnlyDistributeToGLAccountsErr);
    end;

    procedure TransferDimensionSetID(var PurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line"; ModifiedByUser: Boolean)
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        if AllocationLine."Dimension Set ID" = 0 then
            exit;

        if PurchaseLine."Dimension Set ID" = AllocationLine."Dimension Set ID" then
            exit;

        if (PurchaseLine."Dimension Set ID" = 0) or ModifiedByUser then begin
            PurchaseLine."Dimension Set ID" := AllocationLine."Dimension Set ID";
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              PurchaseLine."Dimension Set ID", PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");

            exit;
        end;

        DimensionSetIDArr[1] := PurchaseLine."Dimension Set ID";
        DimensionSetIDArr[2] := AllocationLine."Dimension Set ID";
        PurchaseLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");
    end;

    local procedure VerifyPurchaseLines(var AllocationAccountPurchaseLine: Record "Purchase Line")
    begin
        AllocationAccountPurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if not AllocationAccountPurchaseLine.FindSet() then
            exit;

        repeat
            VerifyPurchaseLine(AllocationAccountPurchaseLine);
        until AllocationAccountPurchaseLine.Next() = 0;
    end;

    procedure VerifySelectedAllocationAccountNo(var PurchaseLine: Record "Purchase Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if PurchaseLine."Selected Alloc. Account No." = '' then
            exit;

        if not (PurchaseLine.Type = PurchaseLine.Type::"G/L Account") then
            Error(InvalidAccountTypeForInheritFromParentErr, PurchaseLine.Type);

        AllocationAccount.Get(PurchaseLine."Selected Alloc. Account No.");
        VerifyAllocationAccount(AllocationAccount);
    end;

    local procedure GetDescriptionChanged(ExistingDescription: Text; AccountType: Enum "Purchase Line Type"; AccountValue: Code[20]): Boolean
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

    local procedure VerifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        if not AllocationAccountUsed(PurchaseLine) then
            exit;

        OnBeforeVerifyPurchaseLine(PurchaseLine);
        if PurchaseLine."Selected Alloc. Account No." <> '' then
            VerifySelectedAllocationAccountNo(PurchaseLine)
        else begin
            if PurchaseLine."No." = '' then
                exit;

            AllocationAccount.Get(PurchaseLine."No.");
            VerifyAllocationAccount(AllocationAccount);
            AllocationAccountMgt.VerifyNoInheritFromParentUsed(AllocationAccount."No.");
        end;
    end;

    local procedure CheckPurchaseReleaseStatus(var PurchaseHeader: Record "Purchase Header"; var IsReopen: Boolean)
    var
        PurchaseRelease: Codeunit "Release Purchase Document";
    begin
        if IsReopen then begin
            PurchaseRelease.Run(PurchaseHeader);
            PurchaseHeader.Modify();
            exit;
        end;

        if PurchaseHeader.Status <> PurchaseHeader.Status::Released then
            exit;

        PurchaseRelease.Reopen(PurchaseHeader);
        IsReopen := true;
        PurchaseRelease.SetSkipCheckReleaseRestrictions();
        PurchaseHeader.SetHideValidationDialog(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; var AllocationLine: Record "Allocation Line"; var AllocationPurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadManualAllocationLinesOnBeforeInsertAllocationLine(var AllocAccManualOverride: Record "Alloc. Acc. Manual Override"; var AllocationLine: Record "Allocation Line")
    begin
    end;

    var
        IsInheritFromParent: Boolean;
        AllocationAccountMustOnlyDistributeToGLAccountsErr: Label 'The allocation account must contain G/L accounts as distribution accounts.';
        CannotGetAllocationAccountFromLineErr: Label 'Cannot get allocation account from Purchase line %1.', Comment = '%1 - Line No., it is an integer that identifies the line e.g. 10000, 200000.';
        NoLinesGeneratedLbl: Label 'No allocation account lines were generated for Purchase line %1.', Comment = '%1 - Unique identification of the line.';
        ChangeDimensionsOnAllocationDistributionsQst: Label 'The line is connected to the Allocation Account. Any dimensions that you change through this action will be merged with dimensions that are defined on the Allocation Line. To change the final dimensions you should invoke the Redistribute Account Allocations action.\\Do you want to continue?';
        DeleteManualOverridesQst: Label 'Modifying the line will delete all manual overrides for allocation account.\\Do you want to continue?';
        InvalidAccountTypeForInheritFromParentErr: Label 'Selected account type - %1 cannot be used for allocation accounts that have inherit from parent defined.', Comment = '%1 - Account type, e.g. G/L Account, Customer, Vendor, Bank Account, Fixed Asset, Item, Resource, Charge, Project, or Blank.';
        MustProvideAccountNoForInheritFromParentErr: Label 'You must provide an account number for allocation account with inherit from parent defined.';
        ReplaceAllocationLinesBeforeSendingToApprovalErr: Label 'You must replace allocation lines before sending the document to approval.';
        ReplaceAllocationLinesBeforeSendingToApprovalQst: Label 'Document contains allocation lines.\\Do you want to replace them before sending the document to approval?';
}
