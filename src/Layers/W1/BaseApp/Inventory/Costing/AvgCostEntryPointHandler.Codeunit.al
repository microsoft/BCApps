// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;
using System.Utilities;

codeunit 5849 "Avg. Cost Entry Point Handler"
{
    var
        AverageCostEntryPoint: Interface "Average Cost Entry Point";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        IsHandled: Boolean;
    begin
        if IsInitialized then
            exit;

        IsHandled := false;
        OnBeforeInitialize(AverageCostEntryPoint, IsHandled);
        if not IsHandled then
            AverageCostEntryPoint := "Average Cost Entry Point Impl."::"Default Implementation";

        IsInitialized := true;
    end;

    procedure GetMaxValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"): Date
    begin
        Initialize();
        exit(AverageCostEntryPoint.GetMaxValuationDate(ItemLedgerEntry, ValueEntry));
    end;

    procedure GetValuationPeriod(var CalendarPeriod: Record Date; PostingDate: Date)
    begin
        Initialize();
        AverageCostEntryPoint.GetValuationPeriod(CalendarPeriod, PostingDate);
    end;

    procedure LockBuffer()
    begin
        Initialize();
        AverageCostEntryPoint.LockBuffer();
    end;

    procedure UpdateValuationDate(ValueEntry: Record "Value Entry")
    begin
        Initialize();
        AverageCostEntryPoint.UpdateValuationDate(ValueEntry);
    end;

    procedure IsEntriesAdjusted(itemNo: Code[20]; EndingDate: Date): Boolean
    begin
        Initialize();
        exit(AverageCostEntryPoint.IsEntriesAdjusted(ItemNo, EndingDate));
    end;

    procedure DeleteBuffer(ItemNo: Code[20]; FromValuationDate: Date)
    begin
        Initialize();
        AverageCostEntryPoint.DeleteBuffer(ItemNo, FromValuationDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var AverageCostEntryPoint: Interface "Average Cost Entry Point"; var IsHandled: Boolean)
    begin
    end;
}
