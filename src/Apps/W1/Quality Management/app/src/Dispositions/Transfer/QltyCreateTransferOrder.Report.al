// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Transfer;

using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Structure;

report 20410 "Qlty. Create Transfer Order"
{
    Caption = 'Quality Management - Create Transfer Order';
    ApplicationArea = QualityManagement;
    ProcessingOnly = true;
    UsageCategory = Tasks;
    AllowScheduling = false;
    ToolTip = 'Use this to transfer items to another location.';

    dataset
    {
        dataitem(CurrentInspection; "Qlty. Inspection Header")
        {
            RequestFilterFields = "No.", "Re-inspection No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Document No.", "Template Code";

            trigger OnAfterGetRecord()
            var
                QltyDispTransfer: Codeunit "Qlty. Disp. Transfer";
            begin
                QltyDispTransfer.PerformDisposition(CurrentInspection, SpecificQuantity, QltyQuantityBehavior, FilterOfSourceLocation, FilterOfSourceBin, Destination, InTransit);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Creating a Transfer';
        AboutText = 'Use this to transfer inventory from an inspectioning location to another location.';

        layout
        {
            area(Content)
            {
                group(Quantity)
                {
                    Caption = 'Quantity';
                    InstructionalText = 'The quantity of the item that will be transferred to another location.';

                    field(ChooseMoveTracked; MoveTracked)
                    {
                        ApplicationArea = All;
                        Caption = 'Entire Lot/Serial/Package';
                        ToolTip = 'Specifies to create a transfer using the entire lot/serial/package quantity.';

                        trigger OnValidate()
                        begin
                            if MoveTracked then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
                                MoveSpecific := false;
                                MoveSampleSize := false;
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
                                MoveSampleSize := false;
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
                            ToolTip = 'Specifies the specific quantity to use when creating the transfer.';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowMandatory = true;
                            Enabled = MoveSpecific;
                        }
                    }
                    field(ChooseMoveSampleSize; MoveSampleSize)
                    {
                        ApplicationArea = All;
                        Caption = 'Sample Quantity';
                        ToolTip = 'Specifies to use the sample size for the quantity.';

                        trigger OnValidate()
                        begin
                            if MoveSampleSize then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Sample Quantity";
                                MoveTracked := false;
                                MoveSpecific := false;
                                MovePassed := false;
                                MoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity" then
                                    MoveSampleSize := true;

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
                                MoveSampleSize := false;
                                MoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Passed Quantity" then
                                    MovePassed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseMoveSampleFail; MoveFailed)
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
                                MoveSampleSize := false;
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
                    InstructionalText = 'Optional filters that limit where the inventory is transferred from if the inspection covers more than one bin.';

                    field(ChooseSourceLocationFilter; FilterOfSourceLocation)
                    {
                        ApplicationArea = All;
                        TableRelation = Location.Code;
                        Caption = 'Location Filter';
                        ToolTip = 'Specifies to optionally restrict the location from which the inventory will be transferred.';
                    }
                    field(ChooseSourceBinFilter; FilterOfSourceBin)
                    {
                        ApplicationArea = All;
                        TableRelation = Bin.Code;
                        Caption = 'Bin Filter';
                        ToolTip = 'Specifies to optionally restrict the bin from which the inventory will be transferred.';
                    }
                }
                group(GroupDestination)
                {
                    Caption = 'Destination';
                    InstructionalText = 'The location where the inventory will be transferred.';

                    field(ChooseDestinationLocation; Destination)
                    {
                        ApplicationArea = All;
                        TableRelation = Location.Code;
                        Caption = 'Location';
                        ToolTip = 'Specifies the location where the inventory will be transferred.';
                        ShowMandatory = true;
                    }
                }
                group(Transfer)
                {
                    Caption = 'Transfer Details';
                    InstructionalText = 'If the in-transit code is blank and no Transfer Route between the locations has been defined, the transfer will be direct. If the in-transit code is blank and a Transfer Route is defined, the Transfer Route''s in-transit location will be used.';

                    field(ChooseDirectTransfer; DirectTransfer)
                    {
                        ApplicationArea = All;
                        Caption = 'Direct Transfer';
                        ToolTip = 'Specifies that the transfer does not use an in-transit location';

                        trigger OnValidate()
                        begin
                            if DirectTransfer then
                                InTransit := '';
                        end;
                    }
                    field(ChooseInTransitCode; InTransit)
                    {
                        ApplicationArea = All;
                        Caption = 'In-Transit Code';
                        ToolTip = 'Specifies the in-transit location. Leave blank for a direct transfer or to use the Transfer Route.';
                        TableRelation = Location.Code where("Use As In-Transit" = const(true));
                        Enabled = not DirectTransfer;
                    }
                }
            }
        }
    }

    var
        QltyQuantityBehavior: Enum "Qlty. Quantity Behavior";
        SpecificQuantity: Decimal;
        FilterOfSourceLocation: Code[100];
        FilterOfSourceBin: Code[100];
        MoveTracked: Boolean;
        MoveSpecific: Boolean;
        MoveSampleSize: Boolean;
        MovePassed: Boolean;
        MoveFailed: Boolean;
        Destination: Code[10];
        InTransit: Code[10];
        DirectTransfer: Boolean;

    trigger OnInitReport()
    begin
        MoveSpecific := true;
    end;
}
