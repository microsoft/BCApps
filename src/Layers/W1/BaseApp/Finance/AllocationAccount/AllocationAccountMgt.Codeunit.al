// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Central management for allocation account operations including line generation and validation.
/// Handles both fixed and variable allocation methods with dimension and currency support.
/// </summary>
codeunit 2675 "Allocation Account Mgt."
{
    /// <summary>
    /// Determines if allocation account fields should be used based on parent inheritance configuration.
    /// </summary>
    /// <returns>True if allocation accounts are configured to inherit from parent documents</returns>
    procedure UseAllocationAccountNoField(): Boolean
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution.ReadIsolation := IsolationLevel::ReadCommitted;
        AllocAccountDistribution.SetRange("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"Inherit from Parent");
        exit(not (AllocAccountDistribution.IsEmpty()));
    end;

    /// <summary>
    /// Generates allocation lines based on the allocation account configuration and distribution rules.
    /// </summary>
    /// <param name="AllocationAccount">Allocation account containing distribution configuration</param>
    /// <param name="AllocationLine">Allocation line record to populate with calculated distributions</param>
    /// <param name="AmountToDistribute">Total amount to be distributed across allocation rules</param>
    /// <param name="PostingDate">Date to use for variable allocation calculations</param>
    /// <param name="ExistingDimensionSetId">Dimension set ID to inherit or modify</param>
    /// <param name="CurrencyCode">Currency code for amount calculations</param>
    procedure GenerateAllocationLines(var AllocationAccount: Record "Allocation Account"; var AllocationLine: Record "Allocation Line"; AmountToDistribute: Decimal; PostingDate: Date; ExistingDimensionSetId: Integer; CurrencyCode: Code[10])
    begin
        if AllocationAccount."Account Type" = AllocationAccount."Account Type"::Fixed then
            GenerateFixedAllocationLines(AllocationAccount, AllocationLine, AmountToDistribute, ExistingDimensionSetId, CurrencyCode)
        else
            GenerateVariableAllocationLines(AllocationAccount, AllocationLine, AmountToDistribute, PostingDate, ExistingDimensionSetId, CurrencyCode);
    end;

    internal procedure GenerateVariableAllocationLines(var AllocationAccount: Record "Allocation Account"; var AllocationLine: Record "Allocation Line"; AmountToDistribute: Decimal; PostingDate: Date; ExistingDimensionSetId: Integer; CurrencyCode: Code[10])
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        VariableAllocationMgt: Codeunit "Variable Allocation Mgt.";
        ShareDistributions: Dictionary of [Guid, Decimal];
        AmountDistributions: Dictionary of [Guid, Decimal];
    begin
        OnBeforeGenerateVariableAllocationLines(AllocationAccount, AllocationLine, ExistingDimensionSetId);

        VariableAllocationMgt.CalculateAmountDistributions(AllocationAccount, AmountToDistribute, AmountDistributions, ShareDistributions, PostingDate, CurrencyCode);

        AllocAccountDistribution.ReadIsolation := IsolationLevel::ReadCommitted;
        AllocAccountDistribution.SetRange("Allocation Account No.", AllocationAccount."No.");
        if not AllocAccountDistribution.FindSet() then
            exit;

        repeat
            AllocationLine."Allocation Account No." := AllocAccountDistribution."Allocation Account No.";
            AllocationLine."Line No." += 10000;
            AllocationLine.Amount := AmountDistributions.Get(AllocAccountDistribution.SystemId);
            AllocationLine.Percentage := Round(AllocationLine.Amount / AmountToDistribute * 100, 0.00001);
            AllocationLine."Destination Account Type" := AllocAccountDistribution."Destination Account Type";
            AllocationLine."Destination Account Number" := AllocAccountDistribution."Destination Account Number";
            AllocationLine."Destination Account Name" := AllocAccountDistribution.LookupDistributionAccountName();
            AllocationLine."Breakdown Account Name" := AllocAccountDistribution.LookupBreakdownAccountName();
            AllocationLine."Breakdown Account Balance" := ShareDistributions.Get(AllocAccountDistribution.SystemId);
            AllocationLine."Breakdown Account Number" := AllocAccountDistribution."Breakdown Account Number";
            AllocationLine."Dimension Set ID" := AllocAccountDistribution."Dimension Set ID";
            AllocationLine."Global Dimension 1 Code" := AllocAccountDistribution."Global Dimension 1 Code";
            AllocationLine."Global Dimension 2 Code" := AllocAccountDistribution."Global Dimension 2 Code";
            CombineDimensionSetIds(ExistingDimensionSetId, AllocationLine);

            AllocationLine.Insert();
            OnGenerateVariableAllocationLinesOnAfterInsertAllocationLine(AllocationLine, AllocAccountDistribution);
        until AllocAccountDistribution.Next() = 0;

        OnAfterGenerateVariableAllocationLines(AllocationAccount, AllocationLine, ExistingDimensionSetId);
    end;

    internal procedure GenerateFixedAllocationLines(var AllocationAccount: Record "Allocation Account"; var AllocationLine: Record "Allocation Line"; AmountToDistribute: Decimal; ExistingDimensionSetId: Integer; CurrencyCode: Code[10])
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        AllocatedAmount: Decimal;
        AmountRoundingPrecision: Decimal;
    begin
        AllocAccountDistribution.ReadIsolation := IsolationLevel::ReadCommitted;
        AllocAccountDistribution.SetRange("Allocation Account No.", AllocationAccount."No.");
        if not AllocAccountDistribution.FindSet() then
            exit;

        AmountRoundingPrecision := GetCurrencyRoundingPrecision(CurrencyCode);

        repeat
            AllocationLine."Allocation Account No." := AllocAccountDistribution."Allocation Account No.";
            AllocationLine."Line No." += 10000;
            AllocationLine."Destination Account Type" := AllocAccountDistribution."Destination Account Type";
            AllocationLine."Destination Account Number" := AllocAccountDistribution."Destination Account Number";
            AllocationLine."Destination Account Name" := AllocAccountDistribution.LookupDistributionAccountName();
            AllocationLine.Percentage := AllocAccountDistribution.Percent;
            AllocationLine.Amount := Round(AllocationLine.Percentage * AmountToDistribute / 100, AmountRoundingPrecision);
            AllocatedAmount += AllocationLine.Amount;
            AllocationLine."Dimension Set ID" := AllocAccountDistribution."Dimension Set ID";
            AllocationLine."Global Dimension 1 Code" := AllocAccountDistribution."Global Dimension 1 Code";
            AllocationLine."Global Dimension 2 Code" := AllocAccountDistribution."Global Dimension 2 Code";
            CombineDimensionSetIds(ExistingDimensionSetId, AllocationLine);

            AllocationLine.Insert();
            OnGenerateFixedAllocationLinesOnAfterInsertAllocationLine(AllocationLine, AllocAccountDistribution);
        until AllocAccountDistribution.Next() = 0;

        if AllocatedAmount = AmountToDistribute then
            exit;

        AllocationLine.Amount += AmountToDistribute - AllocatedAmount;
        AllocationLine.Modify();
    end;

    /// <summary>
    /// Validates that allocation account does not use parent inheritance for standalone usage scenarios.
    /// </summary>
    /// <param name="AccountNo">Allocation account number to validate</param>
    procedure VerifyNoInheritFromParentUsed(AccountNo: Code[20])
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        AllocAccountDistribution.SetRange("Allocation Account No.", AccountNo);
        AllocAccountDistribution.SetRange("Destination Account Type", AllocAccountDistribution."Destination Account Type"::"Inherit from parent");
        if AllocAccountDistribution.IsEmpty() then
            exit;

        Error(CannotEnterAccountNumberIfInheritFromParentErr);
    end;

    internal procedure GetDefaultAmountForPreview(): Decimal
    begin
        exit(1000);
    end;

    local procedure CombineDimensionSetIds(ExistingSetID: Integer; var AllocationLine: Record "Allocation Line")
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        if AllocationLine."Dimension Set ID" = 0 then begin
            if ExistingSetID <> 0 then begin
                AllocationLine."Dimension Set ID" := ExistingSetID;
                DimensionManagement.UpdateGlobalDimFromDimSetID(
                  AllocationLine."Dimension Set ID", AllocationLine."Global Dimension 1 Code", AllocationLine."Global Dimension 2 Code");
            end;
            exit;
        end;

        if ExistingSetID = AllocationLine."Dimension Set ID" then
            exit;

        if ExistingSetID = 0 then
            exit;


        DimensionSetIDArr[1] := ExistingSetID;
        DimensionSetIDArr[2] := AllocationLine."Dimension Set ID";
        AllocationLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, AllocationLine."Global Dimension 1 Code", AllocationLine."Global Dimension 2 Code");
    end;

    internal procedure GetCurrencyRoundingPrecision(CurrencyCode: Code[10]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        AmountRoundingPrecision: Decimal;
    begin
        GeneralLedgerSetup.Get();
        AmountRoundingPrecision := GeneralLedgerSetup."Amount Rounding Precision";
        if CurrencyCode <> '' then
            if Currency.Get(CurrencyCode) then
                AmountRoundingPrecision := Currency."Amount Rounding Precision";
        exit(AmountRoundingPrecision);
    end;

    internal procedure GetCurrencyUnitAmountPrecision(CurrencyCode: Code[10]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        UnitAmountRoundingPrecision: Decimal;
    begin
        GeneralLedgerSetup.Get();
        UnitAmountRoundingPrecision := GeneralLedgerSetup."Unit-Amount Rounding Precision";
        if CurrencyCode <> '' then
            if Currency.Get(CurrencyCode) then
                UnitAmountRoundingPrecision := Currency."Unit-Amount Rounding Precision";
        exit(UnitAmountRoundingPrecision);
    end;

    internal procedure SplitQuantitiesIfNeeded(OriginalQuantity: Decimal; var AllocationLine: Record "Allocation Line"; var AllocationAccount: Record "Allocation Account")
    var
        QuantityAssigned: Decimal;
    begin
        if AllocationAccount."Document Lines Split" <> AllocationAccount."Document Lines Split"::"Split Quantity" then
            exit;

        AllocationLine.ReadIsolation := IsolationLevel::ReadCommitted;
        if not AllocationLine.FindSet() then
            exit;

        repeat
            AllocationLine.Quantity := Round(OriginalQuantity * AllocationLine.Percentage / 100, AllocationLine.GetQuantityPrecision());
            QuantityAssigned += AllocationLine.Quantity;
            AllocationLine.Modify();
        until AllocationLine.Next() = 0;

        if ((OriginalQuantity - QuantityAssigned) <> 0) then begin
            AllocationLine.Quantity += OriginalQuantity - QuantityAssigned;
            AllocationLine.Modify();
        end;
    end;

    var
        CannotEnterAccountNumberIfInheritFromParentErr: Label 'To use an Allocation Account with "Inherit from parent" you must set Account Type to G/L Account or Bank Account. To set the allocation account use the Allocation Account No. field on the line.';

    /// <summary>
    /// Integration event raised after inserting allocation line for fixed allocation methods.
    /// </summary>
    /// <param name="AllocationLine">Generated allocation line</param>
    /// <param name="AllocAccountDistibution">Source allocation account distribution record</param>
    [IntegrationEvent(false, false)]
    local procedure OnGenerateFixedAllocationLinesOnAfterInsertAllocationLine(var AllocationLine: Record "Allocation Line"; var AllocAccountDistibution: Record "Alloc. Account Distribution")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting allocation line for variable allocation methods.
    /// </summary>
    /// <param name="AllocationLine">Generated allocation line</param>
    /// <param name="AllocAccountDistibution">Source allocation account distribution record</param>
    [IntegrationEvent(false, false)]
    local procedure OnGenerateVariableAllocationLinesOnAfterInsertAllocationLine(var AllocationLine: Record "Allocation Line"; var AllocAccountDistibution: Record "Alloc. Account Distribution")
    begin
    end;

    /// <summary>
    /// Integration event raised before generating variable allocation lines for preprocessing.
    /// </summary>
    /// <param name="AllocationAccount">Allocation account configuration record</param>
    /// <param name="AllocationLine">Allocation line record to be generated</param>
    /// <param name="ExistingDimensionSetId">Existing dimension set ID for inheritance</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenerateVariableAllocationLines(var AllocationAccount: Record "Allocation Account"; var AllocationLine: Record "Allocation Line"; var ExistingDimensionSetId: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after generating variable allocation lines for postprocessing.
    /// </summary>
    /// <param name="AllocationAccount">Allocation account configuration record</param>
    /// <param name="AllocationLine">Generated allocation line record</param>
    /// <param name="ExistingDimensionSetId">Final dimension set ID used</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGenerateVariableAllocationLines(var AllocationAccount: Record "Allocation Account"; var AllocationLine: Record "Allocation Line"; var ExistingDimensionSetId: Integer)
    begin
    end;
}
