// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

codeunit 5808 "Cost Adjustment Runner"
{
    TableNo = "Cost Adj. Item Bucket";

    trigger OnRun()
    var
        CostAdjItemBucket: Record "Cost Adj. Item Bucket";
        CostAdjustmentBucketRunner: Codeunit "Cost Adjustment Bucket Runner";
        CostAdjustmentSubscribers: Codeunit "Cost Adjustment Subscribers";
    begin
        BindSubscription(CostAdjustmentSubscribers);
        OnBeforeRunCostAdjustment(Rec);

        CostAdjItemBucket.Copy(Rec);
        if CostAdjustmentBucketRunner.Run(CostAdjItemBucket) then
            RegisterSuccess(CostAdjItemBucket)
        else
            RegisterFailure(CostAdjItemBucket);
        CostAdjItemBucket.Modify();

        OnAfterRunCostAdjustment(CostAdjItemBucket);
    end;

    local procedure RegisterSuccess(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
        CostAdjItemBucket.Status := CostAdjItemBucket.Status::Success;
        OnRegisterSuccess(CostAdjItemBucket);
    end;

    local procedure RegisterFailure(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
        CostAdjItemBucket.Status := CostAdjItemBucket.Status::Failed;
        CostAdjItemBucket."Last Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(CostAdjItemBucket."Last Error"));
        CostAdjItemBucket."Last Error Call Stack" := CopyStr(GetLastErrorCallStack(), 1, MaxStrLen(CostAdjItemBucket."Last Error Call Stack"));
        OnRegisterFailure(CostAdjItemBucket);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCostAdjustment(CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCostAdjustment(CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterSuccess(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterFailure(var CostAdjItemBucket: Record "Cost Adj. Item Bucket")
    begin
    end;
}
