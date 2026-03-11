// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.ItemTracking;

using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Structure;

/// <summary>
/// Use this to update item tracking information.
/// </summary>
report 20409 "Qlty. Change Item Tracking"
{
    Caption = 'Quality Management - Change Item Tracking';
    ApplicationArea = QualityManagement;
    ProcessingOnly = true;
    UsageCategory = Tasks;
    AllowScheduling = false;
    Extensible = true;
    AdditionalSearchTerms = 'Change lot number, Change serial number, Change package number, Change Expiration Date';
    ToolTip = 'Use this to update item tracking information.';

    dataset
    {
        dataitem(CurrentInspection; "Qlty. Inspection Header")
        {
            RequestFilterFields = "No.", "Re-inspection No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Document No.", "Template Code";

            trigger OnAfterGetRecord()
            var
                TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
                ReactionTrkngQltyDispChangeTracking: Codeunit "Qlty. Disp. Change Tracking";
            begin
                TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := SpecificQuantity;
                TempInstructionQltyDispositionBuffer."Quantity Behavior" := QltyQuantityBehavior;
                TempInstructionQltyDispositionBuffer."Location Filter" := FilterOfSourceLocationCode;
                TempInstructionQltyDispositionBuffer."Bin Filter" := FilterOfSourceBinCode;
                if ShouldPostNow then
                    TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

                TempInstructionQltyDispositionBuffer."New Lot No." := NewLotNo;
                TempInstructionQltyDispositionBuffer."New Serial No." := NewSerialNo;
                TempInstructionQltyDispositionBuffer."New Package No." := NewPackageNo;
                TempInstructionQltyDispositionBuffer."New Expiration Date" := NewExpirationDate;

                ReactionTrkngQltyDispChangeTracking.PerformDisposition(CurrentInspection, TempInstructionQltyDispositionBuffer);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Changing Item Tracking';
        AboutText = 'Use this to change the inspected item''s tracking information, such as updating the lot no. or expiry date.';

        layout
        {
            area(Content)
            {
                group(Quantity)
                {
                    Caption = 'Quantity';
                    InstructionalText = 'The quantity of the item to be reclassified.';

                    field(ChooseReclassTracked; IsReclassTracked)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Entire Lot/Serial/Package';
                        ToolTip = 'Specifies that this will change the item tracking using the quantity of the entire lot/serial/package.';

                        trigger OnValidate()
                        begin
                            if IsReclassTracked then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
                                IsReclassSpecific := false;
                                IsReclassSampleSize := false;
                                IsReclassPassed := false;
                                IsReclassFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Item Tracked Quantity" then
                                    IsReclassTracked := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseReclassSpecificQuantity; IsReclassSpecific)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Specific Quantity';
                        ToolTip = 'Specifies a well known quantity to use.';

                        trigger OnValidate()
                        begin
                            if IsReclassSpecific then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Specific Quantity";
                                IsReclassTracked := false;
                                IsReclassSampleSize := false;
                                IsReclassPassed := false;
                                IsReclassFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity" then
                                    IsReclassSpecific := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    group(SpecificQty)
                    {
                        ShowCaption = false;
                        Visible = IsReclassSpecific;

                        field(ChooseQuantity; SpecificQuantity)
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Quantity to Handle';
                            ToolTip = 'Specifies the specific quantity to use when changing the item tracking.';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            Enabled = IsReclassSpecific;
                        }
                    }
                    field(ChooseReclassSampleSize; IsReclassSampleSize)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Sample Quantity';
                        ToolTip = 'Specifies to use the sample size for the quantity.';

                        trigger OnValidate()
                        begin
                            if IsReclassSampleSize then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Sample Quantity";
                                IsReclassTracked := false;
                                IsReclassSpecific := false;
                                IsReclassPassed := false;
                                IsReclassFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity" then
                                    IsReclassSampleSize := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseReclassSamplePass; IsReclassPassed)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Passed Quantity';
                        ToolTip = 'Specifies to use the number of passed samples as the quantity. When transferring passed samples, all sampling measurements must pass for the sample to be accepted.';

                        trigger OnValidate()
                        begin
                            if IsReclassPassed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Passed Quantity";
                                IsReclassTracked := false;
                                IsReclassSpecific := false;
                                IsReclassSampleSize := false;
                                IsReclassFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Passed Quantity" then
                                    IsReclassPassed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseReclassSampleFail; IsReclassFailed)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Failed Quantity';
                        ToolTip = 'Specifies to use the number of failed samples as the quantity. When using failed samples, at least one sampling measurement must have failed.';

                        trigger OnValidate()
                        begin
                            if IsReclassFailed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Failed Quantity";
                                IsReclassTracked := false;
                                IsReclassSpecific := false;
                                IsReclassSampleSize := false;
                                IsReclassPassed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Failed Quantity" then
                                    IsReclassFailed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                }
                group(ReclassType)
                {
                    Caption = 'Item Tracking';

                    field(ChooseNewLotNo; NewLotNo)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'New Lot No.';
                        ToolTip = 'Specifies the new lot no. to use.';
                    }
                    field(ChooseNewSerialNo; NewSerialNo)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'New Serial No.';
                        ToolTip = 'Specifies the new serial no. to use.';
                    }
                    field(ChooseNewPackageNo; NewPackageNo)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'New Package No.';
                        ToolTip = 'Specifies the new package no. to use.';
                    }
                    field(ChooseNewExpiration; NewExpirationDate)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'New Expiration Date';
                        ToolTip = 'Specifies the new expiration date to use.';
                    }
                }
                group(Source)
                {
                    Caption = 'Source (optional)';
                    InstructionalText = 'Optional filters that limit which inventory is updated if the inspected item is in more than one location or bin.';

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
                group(PostImmediately)
                {
                    Caption = 'Post Now or Later';

                    field(ChoosePostNow; ShouldPostNow)
                    {
                        ApplicationArea = All;
                        Caption = 'Post Immediately';
                        ToolTip = 'Specifies to post the journal immediately.';

                        trigger OnValidate()
                        begin
                            ShouldPostLater := not ShouldPostNow;
                        end;
                    }
                    field(ChoosePostLater; ShouldPostLater)
                    {
                        ApplicationArea = All;
                        Caption = 'Just Create Entries';
                        ToolTip = 'Specifies to just create the journal entries.';

                        trigger OnValidate()
                        begin
                            ShouldPostNow := not ShouldPostLater;
                        end;
                    }
                }
            }
        }
    }

    var
        QltyQuantityBehavior: Enum "Qlty. Quantity Behavior";
        NewLotNo, NewSerialNo, NewPackageNo : Code[50];
        NewExpirationDate: Date;
        SpecificQuantity: Decimal;
        FilterOfSourceLocationCode: Code[100];
        FilterOfSourceBinCode: Code[100];
        IsReclassTracked: Boolean;
        IsReclassSpecific: Boolean;
        IsReclassSampleSize: Boolean;
        IsReclassPassed: Boolean;
        IsReclassFailed: Boolean;
        ShouldPostNow: Boolean;
        ShouldPostLater: Boolean;
        NoItemTrackingChangesErr: Label 'No new item tracking information provided.';

    trigger OnInitReport()
    begin
        IsReclassSpecific := true;
        ShouldPostLater := true;
        ShouldPostNow := false;
    end;

    trigger OnPreReport()
    begin
        if (NewLotNo = '') and (NewSerialNo = '') and (NewPackageNo = '') and (NewExpirationDate = 0D) then
            Error(NoItemTrackingChangesErr);
    end;
}
