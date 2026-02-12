// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.PutAway;

using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Structure;

report 20406 "Qlty. Create Internal Put-away"
{
    Caption = 'Quality Management - Create Internal Put-away';
    ProcessingOnly = true;
    ApplicationArea = Warehouse;
    UsageCategory = Tasks;
    AllowScheduling = false;

    dataset
    {
        dataitem(CurrentInspection; "Qlty. Inspection Header")
        {
            RequestFilterFields = "No.", "Re-inspection No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Document No.", "Template Code";

            trigger OnAfterGetRecord()
            var
                QltyDispInternalPutAway: Codeunit "Qlty. Disp. Internal Put-away";
                QltyDispWarehousePutAway: Codeunit "Qlty. Disp. Warehouse Put-away";
            begin
                if (SpecificQuantity = 0) and (QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity") then begin
                    SpecificQuantity := CurrentInspection."Source Quantity (Base)";
                    if SpecificQuantity = 0 then
                        Error(InventoryNeedsQuantityErr);
                end;

                if (QltyQuantityBehavior in [QltyQuantityBehavior::"Sample Quantity", QltyQuantityBehavior::"Failed Quantity", QltyQuantityBehavior::"Passed Quantity"]) and (CurrentInspection."Sample Size" <= 0) then
                    Error(SampleMoveErr);

                if CreateWarehousePutAwayFromInternalPutAway then
                    QltyDispWarehousePutAway.PerformDisposition(CurrentInspection, SpecificQuantity, FilterOfSourceLocation, FilterOfSourceBin, QltyQuantityBehavior)
                else
                    QltyDispInternalPutAway.PerformDisposition(CurrentInspection, SpecificQuantity, FilterOfSourceLocation, FilterOfSourceBin, ReleaseImmediately, QltyQuantityBehavior);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Quantity)
                {
                    Caption = 'Quantity';
                    InstructionalText = 'In most scenarios you will want to move the entire lot/serial/package if it is being quarantined. If you want a specific amount you can define it here. If this value is zero and also you are not moving the entire amount then the journal entry will use the Quantity defined on the inspection itself.';

                    field(ChooseMoveAllInventory; MoveTracked)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Entire Lot/Serial/Package';
                        ToolTip = 'Specifies that when checked this will move the entire lot/serial/package.';

                        trigger OnValidate()
                        begin
                            if MoveTracked then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
                                MoveSpecific := false;
                                MoveSampleTotal := false;
                                MovePassed := false;
                                MoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Item Tracked Quantity" then
                                    MoveTracked := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseMoveSpecificQuantity; MoveSpecific)
                    {
                        ApplicationArea = All;
                        Caption = 'Specific Quantity';
                        ToolTip = 'Specifies a well known quantity to use.';

                        trigger OnValidate()
                        begin
                            if MoveSpecific then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Specific Quantity";
                                MoveTracked := false;
                                MoveSampleTotal := false;
                                MovePassed := false;
                                MoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity" then
                                    MoveSpecific := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    group(SpecificQty)
                    {
                        ShowCaption = false;
                        Visible = MoveSpecific;

                        field(ChooseQuantity; SpecificQuantity)
                        {
                            ApplicationArea = All;
                            Caption = 'Quantity to Handle';
                            ToolTip = 'Specifies the specific quantity to move. If zero, the quantity defined on the inspection will be used.';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowMandatory = true;
                            Enabled = MoveSpecific;
                        }
                    }
                    field(ChooseMoveSampleTotal; MoveSampleTotal)
                    {
                        ApplicationArea = All;
                        Caption = 'Sample Quantity';
                        ToolTip = 'Specifies to use the sample size for the quantity.';

                        trigger OnValidate()
                        begin
                            if MoveSampleTotal then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Sample Quantity";
                                MoveTracked := false;
                                MoveSpecific := false;
                                MovePassed := false;
                                MoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity" then
                                    MoveSampleTotal := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseMoveSamplePass; MovePassed)
                    {
                        ApplicationArea = All;
                        Caption = 'Passed Quantity';
                        ToolTip = 'Specifies to use the number of passed samples as the quantity. When transferring passed samples, all sampling measurements must pass for the sample to be accepted.';

                        trigger OnValidate()
                        begin
                            if MovePassed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Passed Quantity";
                                MoveTracked := false;
                                MoveSpecific := false;
                                MoveSampleTotal := false;
                                MoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Passed Quantity" then
                                    MovePassed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseMoveSampleReject; MoveFailed)
                    {
                        ApplicationArea = All;
                        Caption = 'Failed Quantity';
                        ToolTip = 'Specifies to use the number of failed samples as the quantity. When using failed samples, at least one sampling measurement must have failed.';

                        trigger OnValidate()
                        begin
                            if MoveFailed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Failed Quantity";
                                MoveTracked := false;
                                MoveSpecific := false;
                                MoveSampleTotal := false;
                                MovePassed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Failed Quantity" then
                                    MoveFailed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                }
                group(Source)
                {
                    Caption = 'Source (optional)';
                    InstructionalText = 'Optional filters that limit where the inventory is moved from. When left blank then the current location/bin that the lot/serial/package resides in will be used. When this section is filled in then this will limit the from location to only the locations and filters specified. When you are quarantining entire item tracking combinations you can leave this blank to move all existing inventory regardless of where it currently is.';

                    field(ChooseSourceLocationFilter; FilterOfSourceLocation)
                    {
                        ApplicationArea = All;
                        TableRelation = Location.Code;
                        Caption = 'Location Filter';
                        ToolTip = 'Specifies to optionally limit which locations will be used to pull the inventory from.';
                    }
                    field(ChooseSourceBinFilter; FilterOfSourceBin)
                    {
                        ApplicationArea = All;
                        TableRelation = Bin.Code;
                        Caption = 'Bin Filter';
                        ToolTip = 'Specifies to optionally limit which bins will be used to pull the inventory from.';
                    }
                }
                group(ReleaseOptions)
                {
                    Caption = 'Release Now or Later';

                    field(ChooseCreatePutAway; CreateWarehousePutAwayFromInternalPutAway)
                    {
                        ApplicationArea = All;
                        Caption = 'Release and Create Put-away';
                        ToolTip = 'Specifies to release the Internal Put-away and create the Put-away from the Internal Put-away.';

                        trigger OnValidate()
                        begin
                            if CreateWarehousePutAwayFromInternalPutAway then begin
                                ReleaseImmediately := false;
                                KeepOpen := false;
                            end;
                        end;
                    }
                    field(ChooseReleaseNow; ReleaseImmediately)
                    {
                        ApplicationArea = All;
                        Caption = 'Release Immediately';
                        ToolTip = 'Specifies to release the Internal Put-away immediately.';
                        Editable = not CreateWarehousePutAwayFromInternalPutAway;

                        trigger OnValidate()
                        begin
                            if ReleaseImmediately then begin
                                CreateWarehousePutAwayFromInternalPutAway := false;
                                KeepOpen := false;
                            end;
                        end;
                    }
                    field(ChooseKeepOpen; KeepOpen)
                    {
                        ApplicationArea = All;
                        Caption = 'Keep Open';
                        ToolTip = 'Specifies to just create the Internal Put-away.';
                        Editable = not CreateWarehousePutAwayFromInternalPutAway;

                        trigger OnValidate()
                        begin
                            if KeepOpen then begin
                                CreateWarehousePutAwayFromInternalPutAway := false;
                                ReleaseImmediately := false;
                            end;
                        end;
                    }
                }
            }
        }
    }

    var
        QltyQuantityBehavior: Enum "Qlty. Quantity Behavior";
        FilterOfSourceLocation: Code[100];
        FilterOfSourceBin: Code[100];
        SpecificQuantity: Decimal;
        MoveTracked: Boolean;
        ReleaseImmediately: Boolean;
        KeepOpen: Boolean;
        CreateWarehousePutAwayFromInternalPutAway: Boolean;
        MoveSpecific: Boolean;
        MoveSampleTotal: Boolean;
        MovePassed: Boolean;
        MoveFailed: Boolean;
        InventoryNeedsQuantityErr: Label 'Please enter a quantity to use.';
        SampleMoveErr: Label 'No samples to move. Sample size is zero.', Locked = true;

    trigger OnInitReport()
    begin
        KeepOpen := not ReleaseImmediately;
        MoveSpecific := true;
    end;
}
