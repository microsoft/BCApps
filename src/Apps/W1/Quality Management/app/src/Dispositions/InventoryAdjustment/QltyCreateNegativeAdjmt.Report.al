// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.InventoryAdjustment;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Structure;

report 20408 "Qlty. Create Negative Adjmt."
{
    Caption = 'Quality Management - Create Negative Inventory Adjustment';
    ApplicationArea = QualityManagement;
    AdditionalSearchTerms = 'write-off, dispose';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    AllowScheduling = false;
    ToolTip = 'Use this to decrease inventory quantity, such as when disposing of samples after destructive testing or writing off stock due to damage or spoilage';

    dataset
    {
        dataitem(CurrentInspection; "Qlty. Inspection Header")
        {
            RequestFilterFields = "No.", "Re-inspection No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Document No.", "Template Code";

            trigger OnAfterGetRecord()
            var
                QltyDispNegAdjustInv: Codeunit "Qlty. Disp. Neg. Adjust Inv.";
                CurrentVariant: Text;
                LotNo, SerialNo, PackageNo : Text;
            begin
                if QltyDispNegAdjustInv.PerformDisposition(CurrentInspection, SpecificQuantity, QltyQuantityBehavior, FilterOfSourceLocation, FilterOfSourceBin, PostBehavior, ReasonCode) then
                    exit;

                if CurrentInspection."Source Variant Code" <> '' then
                    CurrentVariant := StrSubstNo(VariantLbl, CurrentInspection."Source Variant Code");

                if CurrentInspection."Source Lot No." <> '' then
                    LotNo := StrSubstNo(LotLbl, CurrentInspection."Source Lot No.");
                if CurrentInspection."Source Serial No." <> '' then
                    SerialNo := StrSubstNo(SerialLbl, CurrentInspection."Source Serial No.");
                if CurrentInspection."Source Package No." <> '' then
                    PackageNo := StrSubstNo(PackageLbl, CurrentInspection."Source Package No.");
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Creating a Negative Adjustment';
        AboutText = 'Use this to decrease inventory quantity, such as when disposing of samples after destructive testing or writing off stock due to damage or spoilage';

        layout
        {
            area(Content)
            {
                group(Quantity)
                {
                    Caption = 'Quantity';
                    InstructionalText = 'In destructive testing scenarios, the number of samples that were destroyed. For other scenarios, the quantity of the inspected item that will be written off.';

                    field(ChooseRemoveTracked; RemoveTracked)
                    {
                        ApplicationArea = All;
                        Caption = 'Entire Lot/Serial/Package';
                        ToolTip = 'Specifies that this will create a negative adjustment using the lot/serial/package quantity.';

                        trigger OnValidate()
                        begin
                            if RemoveTracked then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
                                RemoveSpecific := false;
                                RemoveSampleSize := false;
                                RemovePassed := false;
                                RemoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Item Tracked Quantity" then
                                    RemoveTracked := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseRemoveSpecificQuantity; RemoveSpecific)
                    {
                        ApplicationArea = All;
                        Caption = 'Specific Quantity';
                        ToolTip = 'Specifies a well known quantity to use.';

                        trigger OnValidate()
                        begin
                            if RemoveSpecific then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Specific Quantity";
                                RemoveTracked := false;
                                RemoveSampleSize := false;
                                RemovePassed := false;
                                RemoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity" then
                                    RemoveSpecific := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    group(SpecificQty)
                    {
                        ShowCaption = false;
                        Visible = RemoveSpecific;

                        field(ChooseQuantity; SpecificQuantity)
                        {
                            ApplicationArea = All;
                            Caption = 'Quantity to Handle';
                            ToolTip = 'Specifies the specific quantity to use when creating a negative adjustment.';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowMandatory = true;
                            Enabled = RemoveSpecific;
                        }
                    }
                    field(ChooseRemoveSampleSize; RemoveSampleSize)
                    {
                        ApplicationArea = All;
                        Caption = 'Sample Quantity';
                        ToolTip = 'Specifies to use the sample size for the quantity.';

                        trigger OnValidate()
                        begin
                            if RemoveSampleSize then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Sample Quantity";
                                RemoveTracked := false;
                                RemoveSpecific := false;
                                RemovePassed := false;
                                RemoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity" then
                                    RemoveSampleSize := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseRemoveSamplePass; RemovePassed)
                    {
                        ApplicationArea = All;
                        Caption = 'Passed Quantity';
                        ToolTip = 'Specifies to use the number of passed samples as the quantity. When transferring passed samples, all sampling measurements must pass for the sample to be accepted.';

                        trigger OnValidate()
                        begin
                            if RemovePassed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Passed Quantity";
                                RemoveTracked := false;
                                RemoveSpecific := false;
                                RemoveSampleSize := false;
                                RemoveFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Passed Quantity" then
                                    RemovePassed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseRemoveSampleFail; RemoveFailed)
                    {
                        ApplicationArea = All;
                        Caption = 'Failed Quantity';
                        ToolTip = 'Specifies to use the number of failed samples as the quantity. When using failed samples, at least one sampling measurement must have failed.';

                        trigger OnValidate()
                        begin
                            if RemoveFailed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Failed Quantity";
                                RemoveTracked := false;
                                RemoveSpecific := false;
                                RemoveSampleSize := false;
                                RemovePassed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Failed Quantity" then
                                    RemoveFailed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                }
                group(Reason)
                {
                    Caption = 'Reason (optional)';
                    InstructionalText = 'Optional reason for the negative adjustment.';

                    field(ChooseReasonCode; ReasonCode)
                    {
                        ApplicationArea = All;
                        TableRelation = "Reason Code".Code;
                        Caption = 'Reason';
                        Tooltip = 'Specifies an optional reason code to use.';
                    }
                }
                group(Source)
                {
                    Caption = 'Source (optional)';
                    InstructionalText = 'Optional filters that limit where the inventory is adjusted from if the inspection covers more than one bin.';

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
                group(PostingBehavior)
                {
                    Caption = 'Post Now or Later';

                    field(ChoosePostLater; PostLater)
                    {
                        ApplicationArea = All;
                        Caption = 'Just Create Entries';
                        ToolTip = 'Specifies to just create the journal entries.';

                        trigger OnValidate()
                        begin
                            if PostLater then begin
                                PostNow := false;
                                PostBehavior := PostBehavior::"Prepare only";
                            end;
                        end;
                    }
                    field(ChoosePostNow; PostNow)
                    {
                        ApplicationArea = All;
                        Caption = 'Post Immediately';
                        ToolTip = 'Specifies to post the journal immediately. For directed put-away and pick locations, this will also register the warehouse journal.';

                        trigger OnValidate()
                        begin
                            if PostNow then begin
                                PostLater := false;
                                PostBehavior := PostBehavior::Post;
                            end;
                        end;
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            QltyInspectionHeader: Record "Qlty. Inspection Header";
        begin
            QltyInspectionHeader.CopyFilters(CurrentInspection);
            if QltyInspectionHeader.Count() <> 1 then
                exit;

            QltyInspectionHeader.FindFirst();
            if (QltyInspectionHeader."Location Code" <> '') and (FilterOfSourceLocation = '') then
                FilterOfSourceLocation := QltyInspectionHeader."Location Code";
        end;
    }

    var
        QltyQuantityBehavior: Enum "Qlty. Quantity Behavior";
        SpecificQuantity: Decimal;
        FilterOfSourceLocation: Code[100];
        FilterOfSourceBin: Code[100];
        ReasonCode: Code[10];
        RemoveTracked: Boolean;
        RemoveSpecific: Boolean;
        RemoveSampleSize: Boolean;
        RemovePassed: Boolean;
        RemoveFailed: Boolean;
        PostNow: Boolean;
        PostLater: Boolean;
        PostBehavior: Enum "Qlty. Item Adj. Post Behavior";
        VariantLbl: Label ':%1 ', Comment = '%1=Variant';
        LotLbl: Label ' Lot %1', Comment = '%1= Item Lot';
        SerialLbl: Label ' Serial %1', Comment = '%1= Item Serial';
        PackageLbl: Label ' Package %1', Comment = '%1= Item Package';

    trigger OnInitReport()
    begin
        RemoveSpecific := true;
        PostLater := true;
        PostNow := false;
    end;
}
