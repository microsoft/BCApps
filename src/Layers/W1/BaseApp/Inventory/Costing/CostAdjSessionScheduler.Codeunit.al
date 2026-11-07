// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using System.Text;

codeunit 5809 "Cost Adj. Session Scheduler"
{
    var
        RunForeground: Boolean;

    trigger OnRun()
    begin
        Code();
    end;

    procedure Code()
    var
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
    begin
        if CostAdjItemBucket.FindSet() then
            repeat
                if CostAdjItemBucket.Status = CostAdjItemBucket.Status::"Not started" then begin
                    CostAdjItemBucket.Status := CostAdjItemBucket.Status::Running;
                    CostAdjItemBucket."Starting Date-Time" := CurrentDateTime();
                    Clear(CostAdjItemBucket."Ending Date-Time");
                    Clear(CostAdjItemBucket."Last Error");
                    Clear(CostAdjItemBucket."Last Error Call Stack");
                    Clear(CostAdjItemBucket."Failed Item No.");
                    CostAdjItemBucket.Modify();
                    Commit();

                    RunCostAdjustment(CostAdjItemBucket);

                    CostAdjItemBucket.Get(CostAdjItemBucket."Line No.");
                    if CostAdjItemBucket.Status = CostAdjItemBucket.Status::Running then
                        CostAdjItemBucket.Status := CostAdjItemBucket.Status::"Timed out";
                    CostAdjItemBucket."Ending Date-Time" := CurrentDateTime();
                    CostAdjItemBucket.Modify();

                    if (CostAdjItemBucket.Status in [CostAdjItemBucket.Status::Failed, CostAdjItemBucket.Status::"Timed out"]) and
                       (CostAdjItemBucket."Reschedule Count" > 0) and not CostAdjItemBucket.Trace
                    then
                        Reschedule(CostAdjItemBucket);
                end;
            until CostAdjItemBucket.Next() = 0;
    end;

    local procedure RunCostAdjustment(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    var
        NewSessionId: Integer;
        Timeout: Duration;
    begin
        if RunForeground then begin
            Codeunit.Run(Codeunit::"Cost Adjustment Runner", CostAdjItemBucket);
            exit;
        end;

        NewSessionId := 0;
        Timeout := CostAdjItemBucket."Timeout (Minutes)" * 60 * 1000;
        if CostAdjItemBucket.Trace then
            Timeout := Timeout * 2; // to leave time for rollback

        StartSession(NewSessionId, Codeunit::"Cost Adjustment Runner", Timeout, CompanyName(), CostAdjItemBucket);

        while IsSessionActive(NewSessionId) do
            Sleep(1000);
    end;

    local procedure Reschedule(var CurrentCostAdjItemBucket: Record "Cost Adj. Item Bucket")
    var
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
        Item: Record Item;
        TempFirstHalfItem: Record Item temporary;
        TempSecondHalfItem: Record Item temporary;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RescheduleCount: Integer;
        NoOfItems: Integer;
        i: Integer;
    begin
        CostAdjItemBucket.Copy(CurrentCostAdjItemBucket);
        Item.SetFilter("No.", CostAdjItemBucket."Item Filter");
        Item.SetRange("Cost is Adjusted", false);
        NoOfItems := Item.Count();
        RescheduleCount := CostAdjItemBucket."Reschedule Count";

        case true of
            NoOfItems = 0:
                // nothing to adjust, stop
                exit;
            NoOfItems = 1:
                begin
                    // save the failed item and stop
                    Item.FindFirst();
                    CostAdjItemBucket."Line No." := CostAdjItemBucket.GetLastLineNo() + 10000;
                    CostAdjItemBucket."Item Filter" := Item."No.";
                    CostAdjItemBucket."Reschedule Count" := RescheduleCount - 1;
                    CostAdjItemBucket.Insert();
                end;
            CostAdjItemBucket."Failed Item No." <> '':
                begin
                    // split into two buckets: failed item and the rest
                    CostAdjItemBucket."Line No." := CostAdjItemBucket.GetLastLineNo() + 10000;
                    CostAdjItemBucket."Item Filter" := CostAdjItemBucket."Failed Item No.";
                    CostAdjItemBucket."Reschedule Count" := RescheduleCount - 1;
                    CostAdjItemBucket.Insert();

                    Item.FilterGroup := 2;
                    Item.SetFilter("No.", '<>%1', CostAdjItemBucket."Failed Item No.");
                    Item.FilterGroup := 0;
                    Item.SetRange("Cost is Adjusted");
                    InsertNotStartedCostAdjItemBucket(CostAdjItemBucket, SelectionFilterManagement.GetSelectionFilterForItem(Item), RescheduleCount - 1);
                end;
            else begin
                // split items into two even buckets
                Item.SetRange("Cost is Adjusted");
                Item.FindSet();
                for i := 1 to (NoOfItems div 2) do begin
                    TempFirstHalfItem := Item;
                    TempFirstHalfItem.Insert();
                    Item.Next();
                end;
                for i := NoOfItems div 2 + 1 to NoOfItems do begin
                    TempSecondHalfItem := Item;
                    TempSecondHalfItem.Insert();
                    Item.Next();
                end;
                InsertNotStartedCostAdjItemBucket(CostAdjItemBucket, SelectionFilterManagement.GetSelectionFilterForItem(TempFirstHalfItem), RescheduleCount - 1);
                InsertNotStartedCostAdjItemBucket(CostAdjItemBucket, SelectionFilterManagement.GetSelectionFilterForItem(TempSecondHalfItem), RescheduleCount - 1);
            end;
        end;
    end;

    local procedure InsertNotStartedCostAdjItemBucket(var CostAdjItemBucket: Record "Cost Adj. Item Bucket"; ItemFilter: Text; RescheduleCount: Integer)
    begin
        CostAdjItemBucket."Line No." := CostAdjItemBucket.GetLastLineNo() + 10000;
        CostAdjItemBucket."Item Filter" := CopyStr(ItemFilter, 1, MaxStrLen(CostAdjItemBucket."Item Filter"));
        CostAdjItemBucket.Status := CostAdjItemBucket.Status::"Not started";
        CostAdjItemBucket."Reschedule Count" := RescheduleCount;
        Clear(CostAdjItemBucket."Starting Date-Time");
        Clear(CostAdjItemBucket."Ending Date-Time");
        Clear(CostAdjItemBucket."Last Error");
        Clear(CostAdjItemBucket."Last Error Call Stack");
        Clear(CostAdjItemBucket."Failed Item No.");
        CostAdjItemBucket.Insert();
    end;

    procedure SetRunForeground(NeedRunForeground: Boolean)
    begin
        RunForeground := NeedRunForeground;
    end;
}
