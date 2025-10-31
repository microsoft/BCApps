﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Purchase;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Location;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Structure;

report 20411 "Qlty. Create Purchase Return"
{
    ApplicationArea = PurchReturnOrder;
    Caption = 'Quality Management - Create Purchase Return Order';
    AdditionalSearchTerms = 'purchase return order, vendor return, damaged item, defective';
    UsageCategory = Tasks;
    ProcessingOnly = true;
    AllowScheduling = false;
    Description = 'Use this to create a Purchase Return Order from a Quality Inspection Test.';

    dataset
    {
        dataitem(CurrentTest; "Qlty. Inspection Test Header")
        {
            RequestFilterFields = "No.", "Retest No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Document No.", "Template Code";

            trigger OnAfterGetRecord()
            var
                ReactionRetQltyDispPurchaseReturn: Codeunit "Qlty. Disp. Purchase Return";
            begin
                ReactionRetQltyDispPurchaseReturn.PerformDisposition(CurrentTest, QltyQuantityBehavior, SpecificQuantity, FilterOfSourceLocation, FilterOfSourceBin, ReasonCode, OptionalVendorCreditMemoNo);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Creating a Purchase Return Order';
        AboutText = 'Use this to create a Purchase Return Order from a Quality Inspection Test.';

        layout
        {
            area(Content)
            {
                group(SettingsForQuantity)
                {
                    Caption = 'Quantity';
                    InstructionalText = 'The quantity of the tested item that will be returned.';

                    field(ChooseReturnTracked; ReturnTracked)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Entire Lot/Serial/Package';
                        ToolTip = 'Specifies that this will create a Purchase Return Order using the lot/serial/package quantity.';

                        trigger OnValidate()
                        begin
                            if ReturnTracked then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Item Tracked Quantity";
                                ReturnSpecific := false;
                                ReturnSampleSize := false;
                                ReturnPassed := false;
                                ReturnFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Item Tracked Quantity" then
                                    ReturnTracked := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseReturnSpecificQuantity; ReturnSpecific)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Specific Quantity';
                        ToolTip = 'Specifies a well known quantity to use.';

                        trigger OnValidate()
                        begin
                            if ReturnSpecific then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Specific Quantity";
                                ReturnTracked := false;
                                ReturnSampleSize := false;
                                ReturnPassed := false;
                                ReturnFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Specific Quantity" then
                                    ReturnSpecific := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    group(SettingsForSpecificQty)
                    {
                        ShowCaption = false;
                        Visible = ReturnSpecific;

                        field(ChooseQuantity; SpecificQuantity)
                        {
                            ApplicationArea = QualityManagement;
                            Caption = 'Quantity to Handle';
                            ToolTip = 'Specifies the specific quantity to use when creating a Purchase Return Order.';
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            Enabled = ReturnSpecific;
                        }
                    }
                    field(ChooseReturnSampleSize; ReturnSampleSize)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Sample Quantity';
                        ToolTip = 'Specifies to use the sample size for the quantity.';

                        trigger OnValidate()
                        begin
                            if ReturnSampleSize then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Sample Quantity";
                                ReturnTracked := false;
                                ReturnSpecific := false;
                                ReturnPassed := false;
                                ReturnFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Sample Quantity" then
                                    ReturnSampleSize := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseReturnSamplePass; ReturnPassed)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Passed Quantity';
                        ToolTip = 'Specifies to use the number of passed samples as the quantity. When transferring passed samples, all sampling measurements must pass for the sample to be accepted.';

                        trigger OnValidate()
                        begin
                            if ReturnPassed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Passed Quantity";
                                ReturnTracked := false;
                                ReturnSpecific := false;
                                ReturnSampleSize := false;
                                ReturnFailed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Passed Quantity" then
                                    ReturnPassed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                    field(ChooseReturnSampleFail; ReturnFailed)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Failed Quantity';
                        ToolTip = 'Specifies to use the number of failed samples as the quantity. When using failed samples, at least one sampling measurement must have failed.';

                        trigger OnValidate()
                        begin
                            if ReturnFailed then begin
                                QltyQuantityBehavior := QltyQuantityBehavior::"Failed Quantity";
                                ReturnTracked := false;
                                ReturnSpecific := false;
                                ReturnSampleSize := false;
                                ReturnPassed := false;
                            end else
                                if QltyQuantityBehavior = QltyQuantityBehavior::"Failed Quantity" then
                                    ReturnFailed := true;

                            CurrReport.RequestOptionsPage.Update(true);
                        end;
                    }
                }
                group(SettingsForReason)
                {
                    Caption = 'Reason (optional)';
                    InstructionalText = 'Optional return reason for the Purchase Return Order.';

                    field(ChooseReturnReasonCode; ReasonCode)
                    {
                        ApplicationArea = PurchReturnOrder;
                        TableRelation = "Return Reason".Code;
                        Caption = 'Return Reason';
                        Tooltip = 'Specifies an optional reason code to use.';
                    }
                }
                group(SettingsForSource)
                {
                    Caption = 'Source (optional)';
                    InstructionalText = 'Optional filters that limit where the inventory is adjusted from if the test covers more than one bin.';

                    field(ChooseSourceLocationFilter; FilterOfSourceLocation)
                    {
                        ApplicationArea = Location;
                        TableRelation = Location.Code;
                        Caption = 'Location Filter';
                        ToolTip = 'Specifies to optionally limit which locations will be used to pull the inventory from.';
                    }
                    field(ChooseSourceBinFilter; FilterOfSourceBin)
                    {
                        ApplicationArea = Warehouse;
                        TableRelation = Bin.Code;
                        Caption = 'Bin Filter';
                        ToolTip = 'Specifies to optionally limit which bins will be used to pull the inventory from.';
                    }
                }
                group(SettingsForCreditMemo)
                {
                    Caption = 'Vendor Credit Memo No. (optional)';

                    field(ChooseVendorCreditMemoNo; OptionalVendorCreditMemoNo)
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Vendor Credit Memo No. (Optional)';
                        ToolTip = 'Specifies the number that the vendor uses for the credit memo you are creating in this purchase return order.';
                    }
                }
            }
        }

    }

    trigger OnInitReport()
    begin
        ReturnSpecific := true;
    end;

    var
        QltyQuantityBehavior: Enum "Qlty. Quantity Behavior";
        ReturnTracked: Boolean;
        ReturnSpecific: Boolean;
        ReturnSampleSize: Boolean;
        ReturnPassed: Boolean;
        ReturnFailed: Boolean;
        FilterOfSourceLocation: Code[100];
        FilterOfSourceBin: Code[100];
        ReasonCode: Code[10];
        SpecificQuantity: Decimal;
        OptionalVendorCreditMemoNo: Code[35];
}
