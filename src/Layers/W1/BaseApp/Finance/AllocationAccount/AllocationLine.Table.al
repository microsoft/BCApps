// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.AllocationAccount.Purchase;
using Microsoft.Finance.AllocationAccount.Sales;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

table 2672 "Allocation Line"
{
    DataClassification = SystemMetadata;
    Caption = 'Allocation Line';
    TableType = Temporary;

    fields
    {
        field(1; "Allocation Account No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Allocation Account No.';
            TableRelation = "Allocation Account"."No.";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(3; "Destination Account Type"; Enum "Destination Account Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Destination Account Type';
        }
        field(4; "Destination Account Number"; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Destination Account Number';
            TableRelation = if ("Destination Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting), "Direct Posting" = const(true))
            else
            if ("Destination Account Type" = const("Bank Account")) "Bank Account";
        }
        field(5; "Destination Account Name"; Text[2048])
        {
            DataClassification = SystemMetadata;
            Caption = 'Destination Account Name';
        }
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
            Caption = 'Amount';
        }
        field(10; "Breakdown Account Number"; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Breakdown Account Number';
        }
        field(11; "Breakdown Account Balance"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            DataClassification = SystemMetadata;
            Caption = 'Breakdown Account Balance';
        }
        field(12; "Breakdown Account Name"; Text[2048])
        {
            DataClassification = SystemMetadata;
            Caption = 'Breakdown Account Name';
        }
        field(13; Percentage; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = SystemMetadata;
            Caption = 'Percentage';
        }
        field(20; Quantity; Decimal)
        {
            AutoFormatType = 0;
            DataClassification = SystemMetadata;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));
        }
        field(38; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Allocation Account No.", "Line No.")
        {
            Clustered = true;
        }
    }

    internal procedure GetQuantityVisible(var AllocationLine: Record "Allocation Line"): Boolean
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if not AllocationAccount.Get(AllocationLine."Allocation Account No.") then
            exit(false);

        exit(AllocationAccount."Document Lines Split" = AllocationAccount."Document Lines Split"::"Split Quantity");
    end;

    internal procedure GetQuantityDataForRedistributePage(var AllocationLine: Record "Allocation Line"; ParentSystemId: Guid; ParentTableId: Integer; var AmountPerQuantity: Decimal; var QuantityToDistribute: Decimal)
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        case ParentTableId of
            Database::"Sales Line":
                begin
                    SalesLine.GetBySystemId(ParentSystemId);
                    AmountPerQuantity := SalesLine."Unit Price";
                    QuantityToDistribute := SalesLine.Quantity;
                end;
            Database::"Purchase Line":
                begin
                    PurchaseLine.GetBySystemId(ParentSystemId);
                    AmountPerQuantity := PurchaseLine."Unit Cost";
                    QuantityToDistribute := PurchaseLine.Quantity;
                end;
            else
                exit;
        end;
    end;

    internal procedure GetOrGenerateAllocationLines(var AllocationLine: Record "Allocation Line"; ParentSystemId: Guid; ParentTableId: Integer; var AmountToAllocate: Decimal; var PostingDate: Date)
    var
        GenJournalAllocAccMgt: Codeunit "Gen. Journal Alloc. Acc. Mgt.";
        SalesAllocAccMgt: Codeunit "Sales Alloc. Acc. Mgt.";
        PurchaseAllocAccMgt: Codeunit "Purchase Alloc. Acc. Mgt.";
    begin
        VerifyParentInformationProvided(ParentSystemId, ParentTableId);

        case ParentTableId of
            database::"Gen. Journal Line":
                GenJournalAllocAccMgt.GetOrGenerateAllocationLines(AllocationLine, ParentSystemId, AmountToAllocate, PostingDate);
            database::"Sales Line":
                SalesAllocAccMgt.GetOrGenerateAllocationLines(AllocationLine, ParentSystemId, AmountToAllocate, PostingDate);
            database::"Purchase Line":
                PurchaseAllocAccMgt.GetOrGenerateAllocationLines(AllocationLine, ParentSystemId, AmountToAllocate, PostingDate);
            else
                OnGetOrGenerateAllocationLines(ParentTableId, ParentSystemId, AllocationLine, AmountToAllocate, PostingDate);
        end;
    end;

    internal procedure SaveChangesToAllocationLines(var AllocationLine: Record "Allocation Line"; ParentSystemId: Guid; ParentTableId: Integer; AmountToAllocate: Decimal)
    var
        ExistingAllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        NewAllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        AllocAccTelemetry: Codeunit "Alloc. Acc. Telemetry";
    begin
        VerifyParentInformationProvided(ParentSystemId, ParentTableId);

        ExistingAllocAccManualOverride.SetRange("Parent System Id", ParentSystemId);
        ExistingAllocAccManualOverride.SetRange("Parent Table Id", ParentTableId);
        ExistingAllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not ExistingAllocAccManualOverride.IsEmpty() then
            ExistingAllocAccManualOverride.DeleteAll();

        AllocationLine.Reset();
        if not AllocationLine.FindSet() then
            exit;

        AllocAccTelemetry.LogDefinedOverride();
        repeat
            Clear(AllocAccManualOverride);
            AllocAccManualOverride."Parent System Id" := ParentSystemId;
            AllocAccManualOverride."Parent Table Id" := ParentTableId;
            AllocAccManualOverride.Amount := AllocationLine.Amount;
            AllocAccManualOverride."Line No." := AllocationLine."Line No.";
            AllocAccManualOverride."Allocation Account No." := AllocationLine."Allocation Account No.";
            AllocAccManualOverride."Destination Account Number" := AllocationLine."Destination Account Number";
            AllocAccManualOverride."Destination Account Type" := AllocationLine."Destination Account Type";
            AllocAccManualOverride."Dimension Set ID" := AllocationLine."Dimension Set ID";
            AllocAccManualOverride."Global Dimension 1 Code" := AllocationLine."Global Dimension 1 Code";
            AllocAccManualOverride."Global Dimension 2 Code" := AllocationLine."Global Dimension 2 Code";
            AllocAccManualOverride.Quantity := AllocationLine.Quantity;
            OnSaveChangesToAllocationLinesOnBeforeAllocAccManualOverrideInsert(AllocAccManualOverride, AllocationLine);
            AllocAccManualOverride.Insert();
        until AllocationLine.Next() = 0;

        NewAllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        NewAllocAccManualOverride.SetRange("Parent System Id", ParentSystemId);
        NewAllocAccManualOverride.SetRange("Parent Table Id", ParentTableId);
        NewAllocAccManualOverride.CalcSums(Amount);
        if AmountToAllocate <> NewAllocAccManualOverride.Amount then
            Error(AllocAccManualOverrideAmountDoesNotMatchErr, NewAllocAccManualOverride.Amount - AmountToAllocate);
    end;

    internal procedure ResetToDefault(var AllocationLine: Record "Allocation Line"; ParentSystemId: Guid; ParentTableId: Integer)
    var
        AllocAccManualOverride: Record "Alloc. Acc. Manual Override";
        AmountToAllocate: Decimal;
        PostingDate: Date;
    begin
        VerifyParentInformationProvided(ParentSystemId, ParentTableId);
        AllocationLine.Reset();
        AllocationLine.DeleteAll();

        AllocAccManualOverride.SetRange("Parent System Id", ParentSystemId);
        AllocAccManualOverride.SetRange("Parent Table Id", ParentTableId);
        AllocAccManualOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not AllocAccManualOverride.IsEmpty() then
            AllocAccManualOverride.DeleteAll();

        GetOrGenerateAllocationLines(AllocationLine, ParentSystemId, ParentTableId, AmountToAllocate, PostingDate);
    end;

    local procedure VerifyParentInformationProvided(ParentSystemId: Guid; ParentTableId: Integer)
    begin
        if IsNullGuid(ParentSystemId) then
            Error(ParentSystemIdIsNotProvidedErr);

        if ParentTableId = 0 then
            Error(ParenTableIsNotProvidedErr);
    end;

    internal procedure ShowDimensions()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        "Dimension Set ID" :=
          DimensionManagement.EditDimensionSet("Dimension Set ID", StrSubstNo(DimensionPageCaptionLbl, Rec.TableCaption(), Rec."Allocation Account No.", Rec."Line No."));
        DimensionManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    internal procedure GetQuantityPrecision(): Decimal
    begin
        exit(0.00001);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOrGenerateAllocationLines(ParentTableId: Integer; ParentSystemId: Guid; var AllocationLine: Record "Allocation Line"; var AmountToAllocate: Decimal; var PostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveChangesToAllocationLinesOnBeforeAllocAccManualOverrideInsert(var AllocAccManualOverride: Record "Alloc. Acc. Manual Override"; var AllocationLine: Record "Allocation Line")
    begin
    end;

    var
        ParentSystemIdIsNotProvidedErr: Label 'Parent System Id is not provided';
        ParenTableIsNotProvidedErr: Label 'Parent Table Id is not provided';
        AllocAccManualOverrideAmountDoesNotMatchErr: Label 'The sum of the allocation lines does not match the amount to allocate. Difference is %1.', Comment = '%1 Amount e.g. 1231.71';
        DimensionPageCaptionLbl: Label '%1 %2 %3', Locked = true;
}
