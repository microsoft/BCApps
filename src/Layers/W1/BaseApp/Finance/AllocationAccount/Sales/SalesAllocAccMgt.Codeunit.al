// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount.Sales;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Dimension;
using System.Automation;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Account;

codeunit 2678 "Sales Alloc. Acc. Mgt."
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
        SalesLine: Record "Sales Line";
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        SalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        SalesLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        SalesLine.GetBySystemId(ParentSystemId);
        AmountToAllocate := SalesLine.Amount;

        PostingDate := SalesLine.GetSalesHeader()."Posting Date";

        if SalesLine."Alloc. Acc. Modified by User" then
            LoadManualAllocationLines(SalesLine, AllocationLine)
        else begin
            GetAllocationAccount(SalesLine, AllocationAccount);
            AllocationAccountMgt.GenerateAllocationLines(AllocationAccount, AllocationLine, SalesLine.Amount, PostingDate, SalesLine."Dimension Set ID", SalesLine."Currency Code");
            AllocationAccountMgt.SplitQuantitiesIfNeeded(SalesLine.Quantity, AllocationLine, AllocationAccount);
            ReplaceInheritFromParent(AllocationLine, SalesLine);
        end;
    end;

    internal procedure LoadManualAllocationLines(var SalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", SalesLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Sales Line");
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

    local procedure ReplaceInheritFromParent(var AllocationLine: Record "Allocation Line"; var SalesLine: Record "Sales Line")
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

        if SalesLine."No." = '' then
            Error(MustProvideAccountNoForInheritFromParentErr);

        AllocationLine.ModifyAll("Destination Account Number", SalesLine."No.");

        case SalesLine.Type of
            SalesLine.Type::"G/L Account":
                AllocationLine.ModifyAll("Destination Account Type", AllocationLine."Destination Account Type"::"G/L Account");
            else
                Error(InvalidAccountTypeForInheritFromParentErr, SalesLine.Type);
        end;

        AllocationLine.Reset();
        AllocationLine.SetView(CurrentFilters);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure HandlePostDocument(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean; var IsHandled: Boolean)
    var
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
        ContainsAllocationLines: Boolean;
    begin
        VerifyLinesFromDocument(SalesHeader, ContainsAllocationLines);
        if not ContainsAllocationLines then
            exit;

        AllocAccTelemetry.LogSalesInvoicePostingUsage();
        CreateLinesFromDocument(SalesHeader)
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeShowDimensions', '', false, false)]
    local procedure HandleShowDimensions(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsChanged: Boolean; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;

        if (SalesLine."Type" <> SalesLine."Type"::"Allocation Account") then
            exit;

        if GuiAllowed() then
            if not Confirm(ChangeDimensionsOnAllocationDistributionsQst) then
                Error('');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnAfterCheckSalesApprovalPossible', '', false, false)]
    local procedure HandleAfterCheckSalesApprovalPossible(var SalesHeader: Record "Sales Header")
    var
        ContainsAllocationLines: Boolean;
    begin
        VerifyLinesFromDocument(SalesHeader, ContainsAllocationLines);
        if not ContainsAllocationLines then
            exit;

        if not GuiAllowed() then
            Error(ReplaceAllocationLinesBeforeSendingToApprovalErr);

        if not Confirm(ReplaceAllocationLinesBeforeSendingToApprovalQst) then
            Error(ReplaceAllocationLinesBeforeSendingToApprovalErr);

        CreateLinesFromDocument(SalesHeader);
        Commit();
        if SalesHeader.Find() then;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckBeforeModifyLine(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        VerifySalesLine(Rec);
        DeleteManualDistributionsIfLineChanged(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeValidateNo', '', false, false)]
    local procedure HandleValidateLineNo(CurrentFieldNo: Integer; var IsHandled: Boolean; var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if IsHandled then
            exit;

        if SalesLine."Type" <> SalesLine."Type"::"Allocation Account" then
            exit;

        IsHandled := true;

        VerifySalesLine(SalesLine);
        if SalesLine.Description <> '' then
            exit;

        AllocationAccount.Get(SalesLine."No.");
        SalesLine.Description := AllocationAccount.Name;
    end;

    local procedure DeleteManualDistributionsIfLineChanged(var SalesLine: Record "Sales Line")
    var
        PreviousSalesLine: Record "Sales Line";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        DeleteAllocAccManualOverrideNeeded: Boolean;
    begin
        if SalesLine.IsTemporary() then
            exit;

        if (not AllocationAccountUsed(SalesLine)) then
            exit;

        PreviousSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not PreviousSalesLine.GetBySystemId(SalesLine.SystemId) then
            exit;

        AllocAccManualOverride.SetRange("Parent System Id", SalesLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Sales Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocAccManualOverride.IsEmpty() then
            exit;

        DeleteAllocAccManualOverrideNeeded := (SalesLine."Type" <> PreviousSalesLine."Type") or
                                              (SalesLine."No." <> PreviousSalesLine."No.") or
                                                 (SalesLine."Line Amount" <> PreviousSalesLine."Line Amount");

        if not DeleteAllocAccManualOverrideNeeded then
            exit;

        if GuiAllowed() then
            if not Confirm(DeleteManualOverridesQst) then
                Error('');

        AllocAccManualOverride.DeleteAll();
    end;

    local procedure AllocationAccountUsed(var SalesLine: Record "Sales Line"): Boolean
    begin
        exit((SalesLine.Type = SalesLine.Type::"Allocation Account") or (SalesLine."Selected Alloc. Account No." <> ''));
    end;

    local procedure CreateLinesFromDocument(var SalesHeader: Record "Sales Header")
    var
        AllocationSalesLine: Record "Sales Line";
    begin
        AllocationSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationSalesLine.SetRange("Type", AllocationSalesLine."Type"::"Allocation Account");
        CreateLines(AllocationSalesLine);
        AllocationSalesLine.DeleteAll();

        AllocationSalesLine.Reset();
        AllocationSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationSalesLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        CreateLines(AllocationSalesLine);
        AllocationSalesLine.DeleteAll();
    end;

    local procedure CreateLines(var AllocationSalesLine: Record "Sales Line")
    begin
        AllocationSalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if AllocationSalesLine.IsEmpty() then
            exit;

        AllocationSalesLine.ReadIsolation := IsolationLevel::UpdLock;
        AllocationSalesLine.FindSet();
        repeat
            CreateLinesFromAllocationAccountLine(AllocationSalesLine);
        until AllocationSalesLine.Next() = 0;
    end;

    procedure CreateLinesFromAllocationAccountLine(var AllocationAccountSalesLine: Record "Sales Line")
    var
        ExistingAccountSalesLine: Record "Sales Line";
        AllocationLine: Record "Allocation Line";
        AllocationAccount: Record "Allocation Account";
        DescriptionChanged: Boolean;
        NextLineNo: Integer;
        LastLineNo: Integer;
        Increment: Integer;
        CreatedLines: List of [Guid];
    begin
        if not GetAllocationAccount(AllocationAccountSalesLine, AllocationAccount) then
            Error(CannotGetAllocationAccountFromLineErr, AllocationAccountSalesLine."Line No.");

        VerifyAllocationAccount(AllocationAccount);

        GetOrGenerateAllocationLines(AllocationLine, AllocationAccountSalesLine.SystemId);
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        if AllocationLine.Count = 0 then
            Error(NoLinesGeneratedLbl, AllocationAccountSalesLine.RecordId);

        NextLineNo := GetNextLine(AllocationAccountSalesLine);
        LastLineNo := AllocationAccountSalesLine."Line No.";

        Increment := GetLineIncrement(AllocationAccountSalesLine."Line No.", NextLineNo, AllocationLine.Count);
        if Increment < -1 then begin
            Increment := 10000;
            LastLineNo := GetLastLine(AllocationAccountSalesLine)
        end;

        AllocationLine.Reset();
#pragma warning disable AA0210
        AllocationLine.SetFilter(Amount, '<>%1', 0);
#pragma warning restore AA0210

        AllocationLine.FindSet();
        ExistingAccountSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        ExistingAccountSalesLine.SetAutoCalcFields("Alloc. Acc. Modified by User");
        ExistingAccountSalesLine.GetBySystemId(AllocationAccountSalesLine.SystemId);
        DescriptionChanged := GetDescriptionChanged(ExistingAccountSalesLine.Description, ExistingAccountSalesLine.Type, ExistingAccountSalesLine."No.");

        repeat
            CreatedLines.Add(CreateSalesLine(ExistingAccountSalesLine, AllocationLine, LastLineNo, Increment, AllocationAccount, DescriptionChanged));
        until AllocationLine.Next() = 0;

        FixQuantityRounding(CreatedLines, ExistingAccountSalesLine, AllocationAccount);
        DeleteManualOverrides(AllocationAccountSalesLine);
    end;

    local procedure DeleteManualOverrides(var SalesLine: Record "Sales Line")
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
    begin
        AllocAccManualOverride.SetRange("Parent System Id", SalesLine.SystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", Database::"Sales Line");
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.IsEmpty() then
            AllocAccManualOverride.DeleteAll();
    end;

    local procedure VerifyLinesFromDocument(var SalesHeader: Record "Sales Header"; var ContainsAllocationLines: Boolean)
    var
        AllocationAccountSalesLine: Record "Sales Line";
    begin
        AllocationAccountSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationAccountSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationAccountSalesLine.SetRange("Type", AllocationAccountSalesLine."Type"::"Allocation Account");
        AllocationAccountSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocationAccountSalesLine.FindSet() then begin
            ContainsAllocationLines := true;
            repeat
                VerifySalesLines(AllocationAccountSalesLine);
            until AllocationAccountSalesLine.Next() = 0;
        end;

        AllocationAccountSalesLine.Reset();
        AllocationAccountSalesLine.SetRange("Document No.", SalesHeader."No.");
        AllocationAccountSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        AllocationAccountSalesLine.SetFilter("Selected Alloc. Account No.", '<>%1', '');
        AllocationAccountSalesLine.ReadIsolation := IsolationLevel::ReadUncommitted;
        if AllocationAccountSalesLine.FindSet() then begin
            ContainsAllocationLines := true;
            repeat
                VerifySalesLines(AllocationAccountSalesLine);
            until AllocationAccountSalesLine.Next() = 0;
        end;
    end;

    local procedure CreateSalesLine(var AllocationSalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line"; var LastLineNo: Integer; Increment: Integer; var AllocationAccount: Record "Allocation Account"; var DescriptionChanged: Boolean): Guid
    var
        SalesLine: Record "Sales Line";
        AllocAccHandleDocPost: Codeunit "Alloc. Acc. Handle Doc. Post";
    begin
        SalesLine.TransferFields(AllocationSalesLine, true);
        SalesLine."Line No." := LastLineNo + Increment;
        SalesLine."Type" := SalesLine."Type"::"G/L Account";
        if AllocationSalesLine."VAT Bus. Posting Group" <> '' then
            AllocAccHandleDocPost.SetVATBusPostingGroupCode(AllocationSalesLine."VAT Bus. Posting Group");

        if AllocationSalesLine."VAT Prod. Posting Group" <> '' then
            AllocAccHandleDocPost.SetVATProdPostingGroupCode(AllocationSalesLine."VAT Prod. Posting Group");

        BindSubscription(AllocAccHandleDocPost);
        SalesLine.Validate("No.", AllocationLine."Destination Account Number");
        UnbindSubscription(AllocAccHandleDocPost);

        if DescriptionChanged then begin
            if AllocationSalesLine.Description <> '' then
                SalesLine.Description := AllocationSalesLine.Description;
            if AllocationSalesLine."Description 2" <> '' then
                SalesLine."Description 2" := AllocationSalesLine."Description 2";
        end;

        MoveAmounts(SalesLine, AllocationSalesLine, AllocationLine, AllocationAccount);
        MoveQuantities(SalesLine, AllocationSalesLine);

        SalesLine."Deferral Code" := AllocationSalesLine."Deferral Code";
        CopyDeferralSchedule(SalesLine, AllocationSalesLine);
        TransferDimensionSetID(SalesLine, AllocationLine, AllocationSalesLine."Alloc. Acc. Modified by User");
        SalesLine."Allocation Account No." := AllocationLine."Allocation Account No.";
        SalesLine."Selected Alloc. Account No." := '';
        SalesLine."Alloc. Sales Line SystemId" := AllocationSalesLine.SystemId;
        OnBeforeCreateSalesLine(SalesLine, AllocationLine, AllocationSalesLine);
        BindSubscription(AllocAccHandleDocPost);
        SalesLine.Insert(true);
        UnbindSubscription(AllocAccHandleDocPost);
        LastLineNo := SalesLine."Line No.";
        RedistributeQuantitiesIfNeededMoveQuantities(SalesLine, AllocationSalesLine, AllocationLine, AllocationAccount);
        exit(SalesLine.SystemId);
    end;

    local procedure CopyDeferralSchedule(SalesLine: Record "Sales Line"; AllocationSalesLine: Record "Sales Line")
    var
        DeferralHeader: Record "Deferral Header";
        DeferralTemplate: Record "Deferral Template";
        DeferralUtilities: Codeunit "Deferral Utilities";
    begin
        if SalesLine."Deferral Code" = '' then
            exit;

        if not DeferralTemplate.Get(SalesLine."Deferral Code") then
            exit;

        if DeferralTemplate."Calc. Method" <> DeferralTemplate."Calc. Method"::"User-Defined" then
            exit;

        if not DeferralHeader.Get("Deferral Document Type"::Sales, '', '', SalesLine."Document Type".AsInteger(), SalesLine."Document No.", AllocationSalesLine."Line No.") then
            exit;

        DeferralUtilities.CreateCopyOfDeferralSchedule(DeferralHeader, SalesLine."Line No.");
    end;

    local procedure MoveQuantities(var SalesLine: Record "Sales Line"; var AllocationSalesLine: Record "Sales Line")
    begin
        SalesLine.Quantity := AllocationSalesLine.Quantity;
        SalesLine."Outstanding Quantity" := AllocationSalesLine."Outstanding Quantity";
        SalesLine."Quantity Shipped" := AllocationSalesLine."Quantity Shipped";
        SalesLine."Quantity Invoiced" := AllocationSalesLine."Quantity Invoiced";
        SalesLine."Qty. to Invoice" := AllocationSalesLine."Qty. to Invoice";
        SalesLine."Qty. to Ship" := AllocationSalesLine."Qty. to Ship";
        SalesLine."Quantity (Base)" := AllocationSalesLine."Quantity (Base)";
        SalesLine."Outstanding Qty. (Base)" := AllocationSalesLine."Outstanding Qty. (Base)";
        SalesLine."Qty. to Ship (Base)" := AllocationSalesLine."Qty. to Ship (Base)";
        SalesLine."Return Qty. to Receive" := AllocationSalesLine."Return Qty. to Receive";
        SalesLine."Return Qty. to Receive (Base)" := AllocationSalesLine."Return Qty. to Receive (Base)";
    end;

    local procedure RedistributeQuantitiesIfNeededMoveQuantities(var SalesLine: Record "Sales Line"; var AllocationSalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line"; var AllocationAccount: Record "Allocation Account")
    var
        LinePercentage: Decimal;
    begin
        if AllocationAccount."Document Lines Split" <> AllocationAccount."Document Lines Split"::"Split Quantity" then
            exit;

        if AllocationLine.Percentage <> 0 then
            LinePercentage := AllocationLine.Percentage
        else
            LinePercentage := Round(AllocationLine.Quantity / AllocationSalesLine.Quantity * 100, AllocationLine.GetQuantityPrecision());

        SalesLine.Quantity := 0;
        SalesLine.Validate(Quantity, AllocationLine.Quantity);
        SalesLine."Outstanding Quantity" := Round(AllocationSalesLine."Outstanding Quantity" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Quantity Shipped" := Round(AllocationSalesLine."Quantity Shipped" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Quantity Invoiced" := Round(AllocationSalesLine."Quantity Invoiced" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Qty. to Invoice" := Round(AllocationSalesLine."Qty. to Invoice" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Qty. to Ship" := Round(AllocationSalesLine."Qty. to Ship" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Quantity (Base)" := Round(AllocationSalesLine."Quantity (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Outstanding Qty. (Base)" := Round(AllocationSalesLine."Outstanding Qty. (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Qty. to Ship (Base)" := Round(AllocationSalesLine."Qty. to Ship (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Return Qty. to Receive" := Round(AllocationSalesLine."Return Qty. to Receive" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine."Return Qty. to Receive (Base)" := Round(AllocationSalesLine."Return Qty. to Receive (Base)" * LinePercentage / 100, AllocationLine.GetQuantityPrecision());
        SalesLine.Modify();
    end;

    local procedure FixQuantityRounding(CreatedLines: List of [Guid]; var ExistingAccountSalesLine: Record "Sales Line"; var AllocationAccount: Record "Allocation Account")
    var
        SalesLine: Record "Sales Line";
        LastLine: Record "Sales Line";
        CreatedLineSystemID: Guid;
        ModifyLine: Boolean;
    begin
        if AllocationAccount."Document Lines Split" <> AllocationAccount."Document Lines Split"::"Split Quantity" then
            exit;

        SalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        foreach CreatedLineSystemID in CreatedLines do begin
            SalesLine.GetBySystemId(CreatedLineSystemID);
            SalesLine.Mark(true);
        end;

        SalesLine.MarkedOnly(true);
        if not SalesLine.FindLast() then
            exit;

        LastLine.Copy(SalesLine);

        SalesLine.CalcSums("Outstanding Quantity", "Quantity Shipped", "Quantity Invoiced", "Qty. to Invoice", "Qty. to Ship", "Quantity (Base)", "Outstanding Qty. (Base)", "Qty. to Ship (Base)", "Return Qty. to Receive", "Return Qty. to Receive (Base)");

        if ExistingAccountSalesLine."Outstanding Quantity" - SalesLine."Outstanding Quantity" > 0 then begin
            LastLine."Outstanding Quantity" += ExistingAccountSalesLine."Outstanding Quantity" - SalesLine."Outstanding Quantity";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Quantity Shipped" - SalesLine."Quantity Shipped" > 0 then begin
            LastLine."Quantity Shipped" += ExistingAccountSalesLine."Quantity Shipped" - SalesLine."Quantity Shipped";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Quantity Invoiced" - SalesLine."Quantity Invoiced" > 0 then begin
            LastLine."Quantity Invoiced" += ExistingAccountSalesLine."Quantity Invoiced" - SalesLine."Quantity Invoiced";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Qty. to Invoice" - SalesLine."Qty. to Invoice" > 0 then begin
            LastLine."Qty. to Invoice" += ExistingAccountSalesLine."Qty. to Invoice" - SalesLine."Qty. to Invoice";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Qty. to Ship" - SalesLine."Qty. to Ship" > 0 then begin
            LastLine."Qty. to Ship" += ExistingAccountSalesLine."Qty. to Ship" - SalesLine."Qty. to Ship";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Quantity (Base)" - SalesLine."Quantity (Base)" > 0 then begin
            LastLine."Quantity (Base)" += ExistingAccountSalesLine."Quantity (Base)" - SalesLine."Quantity (Base)";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Outstanding Qty. (Base)" - SalesLine."Outstanding Qty. (Base)" > 0 then begin
            LastLine."Outstanding Qty. (Base)" += ExistingAccountSalesLine."Outstanding Qty. (Base)" - SalesLine."Outstanding Qty. (Base)";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Qty. to Ship (Base)" - SalesLine."Qty. to Ship (Base)" > 0 then begin
            LastLine."Qty. to Ship (Base)" += ExistingAccountSalesLine."Qty. to Ship (Base)" - SalesLine."Qty. to Ship (Base)";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Return Qty. to Receive" - SalesLine."Return Qty. to Receive" > 0 then begin
            LastLine."Return Qty. to Receive" += ExistingAccountSalesLine."Return Qty. to Receive" - SalesLine."Return Qty. to Receive";
            ModifyLine := true;
        end;

        if ExistingAccountSalesLine."Return Qty. to Receive (Base)" - SalesLine."Return Qty. to Receive (Base)" > 0 then begin
            LastLine."Return Qty. to Receive (Base)" += ExistingAccountSalesLine."Return Qty. to Receive (Base)" - SalesLine."Return Qty. to Receive (Base)";
            ModifyLine := true;
        end;

        if ModifyLine then
            LastLine.Modify();
    end;

    local procedure MoveAmounts(var SalesLine: Record "Sales Line"; var AllocationSalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line"; var AllocationAccount: Record "Allocation Account")
    begin
        SalesLine."Unit Cost" := AllocationSalesLine."Unit Cost";

        if AllocationAccount."Document Lines Split" = AllocationAccount."Document Lines Split"::"Split Amount" then begin
            SalesLine.Validate("Unit Price", GetUnitPrice(SalesLine, AllocationLine.Amount));
            SalesLine."Line Amount" := AllocationLine.Amount;
        end else begin
            SalesLine.Validate("Unit Price", AllocationSalesLine."Unit Price");
            SalesLine."Line Amount" := AllocationSalesLine."Line Amount";
        end;
    end;

    local procedure GetUnitPrice(var SalesLine: Record "Sales Line"; AllocationLineAmount: Decimal): Decimal
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        AmountRoundingPrecision: Decimal;
    begin
        if SalesLine.GetSalesHeader()."Prices Including VAT" then
            AllocationLineAmount += AllocationLineAmount * SalesLine."VAT %" / 100;

        AmountRoundingPrecision := AllocationAccountMgt.GetCurrencyRoundingPrecision(SalesLine."Currency Code");
        exit(Round(AllocationLineAmount / SalesLine.Quantity, AmountRoundingPrecision));
    end;

    local procedure GetNextLine(var AllocationSalesLine: Record "Sales Line"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", AllocationSalesLine."Document No.");
        SalesLine.SetRange("Document Type", AllocationSalesLine."Document Type");
        SalesLine.SetFilter("Line No.", '>%1', AllocationSalesLine."Line No.");
        SalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if SalesLine.FindFirst() then
            exit(SalesLine."Line No.");

        exit(AllocationSalesLine."Line No." + 10000);
    end;

    local procedure GetLastLine(var AllocationSalesLine: Record "Sales Line"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", AllocationSalesLine."Document No.");
        SalesLine.SetRange("Document Type", AllocationSalesLine."Document Type");
        SalesLine.SetFilter("Line No.", '>%1', AllocationSalesLine."Line No.");
        SalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if SalesLine.FindLast() then
            exit(SalesLine."Line No.");

        exit(AllocationSalesLine."Line No.");
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

    local procedure GetAllocationAccount(var AllocationAccountSalesLine: Record "Sales Line"; var AllocationAccount: Record "Allocation Account"): Boolean
    begin
        if AllocationAccountSalesLine."Selected Alloc. Account No." <> '' then
            exit(AllocationAccount.Get(AllocationAccountSalesLine."Selected Alloc. Account No."));

        if AllocationAccountSalesLine."Type" = AllocationAccountSalesLine."Type"::"Allocation Account" then
            exit(AllocationAccount.Get(AllocationAccountSalesLine."No."));

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

    local procedure TransferDimensionSetID(var SalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line"; ModifiedByUser: Boolean)
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        if AllocationLine."Dimension Set ID" = 0 then
            exit;

        if SalesLine."Dimension Set ID" = AllocationLine."Dimension Set ID" then
            exit;

        if (SalesLine."Dimension Set ID" = 0) or ModifiedByUser then begin
            SalesLine."Dimension Set ID" := AllocationLine."Dimension Set ID";
            DimensionManagement.UpdateGlobalDimFromDimSetID(
              SalesLine."Dimension Set ID", SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");

            exit;
        end;

        DimensionSetIDArr[1] := SalesLine."Dimension Set ID";
        DimensionSetIDArr[2] := AllocationLine."Dimension Set ID";
        SalesLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, SalesLine."Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 2 Code");
    end;

    local procedure VerifySalesLines(var AllocationAccountSalesLine: Record "Sales Line")
    begin
        AllocationAccountSalesLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if not AllocationAccountSalesLine.FindSet() then
            exit;

        repeat
            VerifySalesLine(AllocationAccountSalesLine);
        until AllocationAccountSalesLine.Next() = 0;
    end;

    procedure VerifySelectedAllocationAccountNo(var SalesLine: Record "Sales Line")
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if SalesLine."Selected Alloc. Account No." = '' then
            exit;

        if not (SalesLine.Type = SalesLine.Type::"G/L Account") then
            Error(InvalidAccountTypeForInheritFromParentErr, SalesLine.Type);

        AllocationAccount.Get(SalesLine."Selected Alloc. Account No.");
        VerifyAllocationAccount(AllocationAccount);
    end;

    local procedure GetDescriptionChanged(ExistingDescription: Text; AccountType: Enum "Sales Line Type"; AccountValue: Code[20]): Boolean
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

    local procedure VerifySalesLine(var SalesLine: Record "Sales Line")
    var
        AllocationAccount: Record "Allocation Account";
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        if not AllocationAccountUsed(SalesLine) then
            exit;

        OnBeforeVerifySalesLine(SalesLine);
        if SalesLine."Selected Alloc. Account No." <> '' then
            VerifySelectedAllocationAccountNo(SalesLine)
        else begin
            if SalesLine."No." = '' then
                exit;

            AllocationAccount.Get(SalesLine."No.");
            VerifyAllocationAccount(AllocationAccount);
            AllocationAccountMgt.VerifyNoInheritFromParentUsed(AllocationAccount."No.");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesLine(var SalesLine: Record "Sales Line"; var AllocationLine: Record "Allocation Line"; var AllocationSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifySalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadManualAllocationLinesOnBeforeInsertAllocationLine(var AllocAccManualOverride: Record "Alloc. Acc. Manual Override"; var AllocationLine: Record "Allocation Line")
    begin
    end;

    var
        AllocationAccountMustOnlyDistributeToGLAccountsErr: Label 'The allocation account must contain G/L accounts as distribution accounts.';
        CannotGetAllocationAccountFromLineErr: Label 'Cannot get allocation account from sales line %1.', Comment = '%1 - Line No., it is an integer that identifies the line e.g. 10000, 200000.';
        NoLinesGeneratedLbl: Label 'No allocation account lines were generated for sales line %1.', Comment = '%1 - Unique identification of the line.';
        ChangeDimensionsOnAllocationDistributionsQst: Label 'The line is connected to the Allocation Account. Any dimensions that you change through this action will be merged with dimensions that are defined on the Allocation Line. To change the final dimensions you should invoke the Redistribute Account Allocations action.\\Do you want to continue?';
        DeleteManualOverridesQst: Label 'Modifying the line will delete all manual overrides for allocation account.\\Do you want to continue?';
        InvalidAccountTypeForInheritFromParentErr: Label 'Selected account type - %1 cannot be used for allocation accounts that have inherit from parent defined.', Comment = '%1 - Account type, e.g. G/L Account, Customer, Vendor, Bank Account, Fixed Asset, Item, Resource, Charge, Project, or Blank.';
        MustProvideAccountNoForInheritFromParentErr: Label 'You must provide an account number for allocation account with inherit from parent defined.';
        ReplaceAllocationLinesBeforeSendingToApprovalErr: Label 'You must replace allocation lines before sending the document to approval.';
        ReplaceAllocationLinesBeforeSendingToApprovalQst: Label 'Document contains allocation lines.\\Do you want to replace them before sending the document to approval?';
}
