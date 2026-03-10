// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Move;

using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Structure;

report 20404 "Qlty. Move Inventory"
{
    Caption = 'Quality Management - Move Inventory';
    AdditionalSearchTerms = 'Quarantine';
    ProcessingOnly = true;
    ApplicationArea = QualityManagement;
    UsageCategory = Tasks;
    AllowScheduling = false;

    dataset
    {
        dataitem(CurrentInspection; "Qlty. Inspection Header")
        {
            RequestFilterFields = "No.", "Re-inspection No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Document No.", "Template Code";

            trigger OnAfterGetRecord()
            var
                TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
                InventoryQltyDispMoveAutoChoose: Codeunit "Qlty. Disp. Move Auto Choose";
            begin
                if (SpecificQuantity = 0) and (QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity") then begin
                    SpecificQuantity := CurrentInspection."Source Quantity (Base)";
                    if SpecificQuantity = 0 then
                        Error(InventoryNeedsQuantityErr);
                end;

                if (QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity") and (CurrentInspection."Sample Size" <= 0) then
                    Error(SampleMoveErr);

                TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with automatic choice";
                TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := SpecificQuantity;
                TempInstructionQltyDispositionBuffer."Quantity Behavior" := QltyQuantityBehavior;
                TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(FilterOfSourceLocationCode, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
                TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(FilterOfSourceBinCode, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
                if ShouldPostImmediately then
                    TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

                TempInstructionQltyDispositionBuffer."New Location Code" := DestinationLocationCode;
                TempInstructionQltyDispositionBuffer."New Bin Code" := DestinationBinCode;

                InventoryQltyDispMoveAutoChoose.MoveInventory(CurrentInspection, TempInstructionQltyDispositionBuffer, UseMovement);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(MovementMethod)
                {
                    Caption = 'Movement Method';

                    field(ChooseUseReclass; UseReclass)
                    {
                        ApplicationArea = All;
                        Caption = 'Use a Reclassification Journal';
                        ToolTip = 'Specifies that this will use an Item or Warehouse Reclassification Journal to process the movement.';

                        trigger OnValidate()
                        begin
                            UseMovement := not UseReclass;
                        end;
                    }
                    field(ChooseUseWorksheet; UseMovement)
                    {
                        ApplicationArea = All;
                        Caption = 'Use the Movement Worksheet (directed put-away and pick) or an Internal Movement';
                        ToolTip = 'Specifies that this will use the Movement Worksheet (directed put-away and pick) or an Internal Movement to process the movement.';

                        trigger OnValidate()
                        begin
                            UseReclass := not UseMovement;
                        end;
                    }
                }
                group(Quantity)
                {
                    Caption = 'Quantity';
                    InstructionalText = 'In most scenarios you will want to move the entire lot/serial/package if it is being quarantined. If you want a specific amount you can define it here. If this value is zero and also you are not moving the entire amount then the journal entry will use the Quantity defined on the inspection itself.';

                    field(ChooseMoveAllInventory; IsMoveTracked)
                    {
                        ApplicationArea = All;
                        Caption = 'Entire Lot/Serial/Package';
                        ToolTip = 'Specifies that this will move the entire lot/serial/package.';

                        trigger OnValidate()
                        begin
                            if IsMoveTracked then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
                                IsMoveSpecific := false;
                                ShouldMoveSampleTotal := false;
                                IsMovePassed := false;
                                IsMoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Item Tracked Quantity" then
                                    IsMoveTracked := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseMoveSpecificQuantity; IsMoveSpecific)
                    {
                        ApplicationArea = All;
                        Caption = 'Specific Quantity';
                        ToolTip = 'Specifies a well known quantity to use.';

                        trigger OnValidate()
                        begin
                            if IsMoveSpecific then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Specific Quantity";
                                IsMoveTracked := false;
                                ShouldMoveSampleTotal := false;
                                IsMovePassed := false;
                                IsMoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity" then
                                    IsMoveSpecific := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    group(SpecificQty)
                    {
                        ShowCaption = false;
                        Visible = IsMoveSpecific;

                        field(ChooseQuantity; SpecificQuantity)
                        {
                            ApplicationArea = All;
                            Caption = 'Quantity to Handle';
                            ToolTip = 'Specifies the specific quantity to move.';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowMandatory = true;
                            Enabled = IsMoveSpecific;
                        }
                    }
                    field(ChooseMoveSampleTotal; ShouldMoveSampleTotal)
                    {
                        ApplicationArea = All;
                        Caption = 'Sample Quantity';
                        ToolTip = 'Specifies to use the sample size for the quantity.';

                        trigger OnValidate()
                        begin
                            if ShouldMoveSampleTotal then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Sample Quantity";
                                IsMoveTracked := false;
                                IsMoveSpecific := false;
                                IsMovePassed := false;
                                IsMoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity" then
                                    ShouldMoveSampleTotal := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseMoveSamplePass; IsMovePassed)
                    {
                        ApplicationArea = All;
                        Caption = 'Passed Quantity';
                        ToolTip = 'Specifies to use the number of passed samples as the quantity. When transferring passed samples, all sampling measurements must pass for the sample to be accepted.';

                        trigger OnValidate()
                        begin
                            if IsMovePassed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Passed Quantity";
                                IsMoveTracked := false;
                                IsMoveSpecific := false;
                                ShouldMoveSampleTotal := false;
                                IsMoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Passed Quantity" then
                                    IsMovePassed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseMoveSampleFail; IsMoveFailed)
                    {
                        ApplicationArea = All;
                        Caption = 'Failed Quantity';
                        ToolTip = 'Specifies to use the number of failed samples as the quantity. When using failed samples, at least one sampling measurement must have failed.';

                        trigger OnValidate()
                        begin
                            if IsMoveFailed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Failed Quantity";
                                IsMoveTracked := false;
                                IsMoveSpecific := false;
                                ShouldMoveSampleTotal := false;
                                IsMovePassed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Failed Quantity" then
                                    IsMoveFailed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                }
                group(Source)
                {
                    Caption = 'Source (optional)';
                    InstructionalText = 'Optional filters that limit where the inventory is moved from. When left blank then the current location/bin that the lot/serial/package resides in will be used. When this section is filled in then this will limit the from location to only the locations and filters specified. When you are quarantining entire item tracking combinations you can leave this blank to move all existing inventory regardless of where it currently is.';

                    field(ChooseSourceLocationFilter; FilterOfSourceLocationCode)
                    {
                        ApplicationArea = All;
                        TableRelation = Location.Code;
                        Caption = 'Location Filter';
                        ToolTip = 'Specifies to optionally limit which locations will be used to pull the inventory from.';
                    }

                    field(ChooseSourceBinFilter; FilterOfSourceBinCode)
                    {
                        ApplicationArea = All;
                        TableRelation = Bin.Code;
                        Caption = 'Bin Filter';
                        ToolTip = 'Specifies to optionally limit which bins will be used to pull the inventory from.';

                    }
                }

                group(Destination)
                {
                    Caption = 'Destination';
                    InstructionalText = 'Where the inventory should be moved to.';

                    field(ChooseDestinationLocation; DestinationLocationCode)
                    {
                        ApplicationArea = All;
                        TableRelation = Location.Code;
                        Caption = 'Location';
                        ToolTip = 'Specifies the destination location to move the inventory to.';
                        ShowMandatory = true;

                        trigger OnValidate()
                        var
                            DestinationLocation: Record Location;
                        begin
                            ShowBinCode := true;
                            if DestinationLocation.Get(DestinationLocationCode) then
                                ShowBinCode := DestinationLocation."Bin Mandatory";
                        end;
                    }

                    field(ChooseDestinationBin; DestinationBinCode)
                    {
                        ApplicationArea = All;
                        TableRelation = Bin.Code;
                        Caption = 'Bin';
                        ToolTip = 'Specifies the destination bin to move the inventory to.';
                        ShowMandatory = true;
                        Enabled = ShowBinCode;
                    }
                }
                group(PostImmediately)
                {
                    Caption = 'Post Now or Later';

                    field(ChoosePostNow; ShouldPostImmediately)
                    {
                        ApplicationArea = All;
                        Caption = 'Post Immediately';
                        ToolTip = 'Specifies to post the journal or create the movement document immediately.';

                        trigger OnValidate()
                        begin
                            ShouldPostLater := not ShouldPostImmediately;
                        end;
                    }
                    field(ChoosePostLater; ShouldPostLater)
                    {
                        ApplicationArea = All;
                        Caption = 'Just Create Entries';
                        ToolTip = 'Specifies to just create the journal or movement entries.';

                        trigger OnValidate()
                        begin
                            ShouldPostImmediately := not ShouldPostLater;
                        end;
                    }
                }
            }
        }
    }

    var
        QltyQuantityBehavior: Enum "Qlty. Quantity Behavior";
        FilterOfSourceLocationCode: Code[100];
        FilterOfSourceBinCode: Code[100];
        DestinationLocationCode: Code[10];
        DestinationBinCode: Code[20];
        SpecificQuantity: Decimal;
        IsMoveTracked: Boolean;
        ShouldPostImmediately: Boolean;
        ShouldPostLater: Boolean;
        ShowBinCode: Boolean;
        UseMovement: Boolean;
        UseReclass: Boolean;
        IsMoveSpecific: Boolean;
        ShouldMoveSampleTotal: Boolean;
        IsMovePassed: Boolean;
        IsMoveFailed: Boolean;
        InventoryNeedsQuantityErr: Label 'Please enter a quantity to use.';
        SampleMoveErr: Label 'No samples to move. Sample size is zero.', Locked = true;

    trigger OnInitReport()
    begin
        ShouldPostLater := not ShouldPostImmediately;
        UseReclass := not UseMovement;
        IsMoveSpecific := true;
    end;
}
