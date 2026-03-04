// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Structure;
using System.Automation;

/// <summary>
/// Extend workflow response options to allow configuration of Quality Inspection Actions.
/// </summary>
pageextension 20403 "Qlty. Workflow Resp. Options" extends "Workflow Response Options"
{
    layout
    {
        addlast(content)
        {
            group(Qlty_MoveInventory_Group)
            {
                Visible = QltyShouldShowInventory;
                ShowCaption = false;

                group(Qlty_MoveType)
                {
                    Visible = QltyShouldShowGrpMoveType;
                    Caption = 'Movement Method';
                    InstructionalText = 'Whether to use a reclassification journal or movement worksheet to process the movement.';

                    field(Qlty_UseReclass; QltyUseReclass)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Use a Reclassification Journal';
                        ToolTip = 'Specifies that this will use an Item or Warehouse Reclassification Journal to process the movement.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyUseMoveSheet := not QltyUseReclass;
                            QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownUseMoveSheet(), QltyUseMoveSheet);
                            CurrPage.Update(true);
                        end;
                    }
                    field(Qlty_UseMoveSheet; QltyUseMoveSheet)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Use the Movement Worksheet (directed put-away and pick) or an Internal Movement';
                        ToolTip = 'Specifies that this will use the Movement Worksheet (directed put-away and pick) or an Internal Movement to process the movement.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyUseReclass := not QltyUseMoveSheet;
                            QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownUseMoveSheet(), QltyUseMoveSheet);
                            CurrPage.Update(true);
                        end;
                    }
                }
                group(Qlty_Quantity_Group)
                {
                    Visible = QltyShouldShowGrpQuantity;
                    Caption = 'Quantity';
                    InstructionalText = 'In most scenarios you will want to use the entire lot/serial/package if it is being quarantined. If you want a specific amount you can define it here. If this value is zero and also you are not moving the entire amount then the journal entry will use the Quantity defined on the inspection itself.';

                    field(Qlty_QuantityMoveAll; QltyMoveAll)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Entire Lot/Serial/Package';
                        ToolTip = 'Specifies that this will use the entire lot/serial/package.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(Rec, QltyWorkflowResponse.GetWellKnownMoveAll(), QltyQuantityBehavior::"Item Tracked Quantity");
                            if QltyMoveAll then begin
                                QltyMoveSpecific := false;
                                QltyUsePassed := false;
                                QltyUseFailed := false;
                                QltyUseTotalSample := false;
                                QuantityToHandle := 0;
                                QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(Rec, QltyWorkflowResponse.GetWellKnownKeyQuantity(), QuantityToHandle);
                            end;
                            CurrPage.Update(true);
                        end;
                    }
                    field(Qlty_MoveSpecific; QltyMoveSpecific)
                    {
                        ApplicationArea = All;
                        Caption = 'Specific Quantity';
                        ToolTip = 'Specifies a well known quantity to use.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(Rec, QltyWorkflowResponse.GetWellKnownMoveAll(), QltyQuantityBehavior::"Specific Quantity");
                            if QltyMoveSpecific then begin
                                QltyMoveAll := false;
                                QltyUsePassed := false;
                                QltyUseFailed := false;
                                QltyUseTotalSample := false;
                            end;
                            CurrPage.Update(true);
                        end;
                    }
                    group(Qlty_SpecificQty_Group)
                    {
                        ShowCaption = false;
                        Visible = QltyMoveSpecific;

                        field(Qlty_QuantityToHandle; QuantityToHandle)
                        {
                            ApplicationArea = QualityManagement;
                            Caption = 'Quantity to Handle';
                            ToolTip = 'Specifies the specific quantity to use.';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowMandatory = true;
                            Enabled = QltyMoveSpecific;

                            trigger OnValidate()
                            var
                                QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            begin
                                QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(Rec, QltyWorkflowResponse.GetWellKnownKeyQuantity(), QuantityToHandle);
                            end;
                        }
                    }
                    group(Qlty_Sample_Group)
                    {
                        ShowCaption = false;
                        field(Qlty_UseTotalSample; QltyUseTotalSample)
                        {
                            ApplicationArea = All;
                            Caption = 'Sample Quantity';
                            ToolTip = 'Specifies to use the sample size for the quantity.';

                            trigger OnValidate()
                            var
                                QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            begin
                                QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(Rec, QltyWorkflowResponse.GetWellKnownMoveAll(), QltyQuantityBehavior::"Sample Quantity");
                                if QltyUseTotalSample then begin
                                    QltyMoveAll := false;
                                    QltyUsePassed := false;
                                    QltyUseFailed := false;
                                    QltyMoveSpecific := false;
                                    QuantityToHandle := 0;
                                    QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(Rec, QltyWorkflowResponse.GetWellKnownKeyQuantity(), QuantityToHandle);
                                end;
                                CurrPage.Update(true);
                            end;
                        }
                        field(Qlty_UsePassed; QltyUsePassed)
                        {
                            ApplicationArea = All;
                            Caption = 'Passed Quantity';
                            ToolTip = 'Specifies to use the number of passed samples as the quantity. When transferring passed samples, all sampling measurements must pass for the sample to be accepted.';

                            trigger OnValidate()
                            var
                                QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            begin
                                QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(Rec, QltyWorkflowResponse.GetWellKnownMoveAll(), QltyQuantityBehavior::"Passed Quantity");
                                if QltyUsePassed then begin
                                    QltyMoveAll := false;
                                    QltyUseTotalSample := false;
                                    QltyUseFailed := false;
                                    QltyMoveSpecific := false;
                                    QuantityToHandle := 0;
                                    QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(Rec, QltyWorkflowResponse.GetWellKnownKeyQuantity(), QuantityToHandle);
                                end;
                                CurrPage.Update(true);
                            end;
                        }
                        field(Qlty_UseFailed; QltyUseFailed)
                        {
                            ApplicationArea = All;
                            Caption = 'Failed Quantity';
                            ToolTip = 'Specifies to use the number of failed samples as the quantity. When using failed samples, at least one sampling measurement must have failed.';

                            trigger OnValidate()
                            var
                                QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            begin
                                QltyWorkflowResponse.SetStepConfigurationValueAsQuantityBehaviorEnum(Rec, QltyWorkflowResponse.GetWellKnownMoveAll(), QltyQuantityBehavior::"Failed Quantity");
                                if QltyUseFailed then begin
                                    QltyMoveAll := false;
                                    QltyUseTotalSample := false;
                                    QltyUsePassed := false;
                                    QltyMoveSpecific := false;
                                    QuantityToHandle := 0;
                                    QltyWorkflowResponse.SetStepConfigurationValueAsDecimal(Rec, QltyWorkflowResponse.GetWellKnownKeyQuantity(), QuantityToHandle);
                                end;
                                CurrPage.Update(true);
                            end;
                        }
                    }
                }
                group(Qlty_ItemTrackingChange)
                {
                    Visible = QltyShouldShowGrpItemTrackingChange;
                    Caption = 'New Item Tracking';
                    InstructionalText = 'Use this to change the inspected item''s tracking information, such as updating the lot no. or expiry date.';

                    field(Qlty_NewLotNo; NewLotNoExpression)
                    {
                        ApplicationArea = All;
                        Caption = 'New Lot No.';
                        ToolTip = 'Specifies the new lot no. to use.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewLotNo(), NewLotNoExpression);
                        end;

                        trigger OnAssistEdit()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
                            Expression: Text;
                        begin
                            Expression := NewLotNoExpression;
                            if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
                                NewLotNoExpression := Expression;
                                QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewLotNo(), NewLotNoExpression);
                            end;

                            CurrPage.Update(true);
                        end;
                    }
                    field(Qlty_NewSerialNo; NewSerialNoExpression)
                    {
                        ApplicationArea = All;
                        Caption = 'New Serial No.';
                        ToolTip = 'Specifies the new serial no. to use.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewSerialNo(), NewSerialNoExpression);
                        end;

                        trigger OnAssistEdit()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
                            Expression: Text;
                        begin
                            Expression := NewSerialNoExpression;
                            if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
                                NewSerialNoExpression := Expression;
                                QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewSerialNo(), NewSerialNoExpression);
                            end;

                            CurrPage.Update(true);
                        end;
                    }
                    field(Qlty_NewPackageNo; NewPackageNoExpression)
                    {
                        ApplicationArea = All;
                        Caption = 'New Package No.';
                        ToolTip = 'Specifies the new package no. to use.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewPackageNo(), NewPackageNoExpression);
                        end;

                        trigger OnAssistEdit()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
                            Expression: Text;
                        begin
                            Expression := NewPackageNoExpression;
                            if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
                                NewPackageNoExpression := Expression;
                                QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewPackageNo(), NewPackageNoExpression);
                            end;

                            CurrPage.Update(true);
                        end;
                    }
                    field(Qlty_NewExpirationDate; NewExpirationDate)
                    {
                        ApplicationArea = All;
                        Caption = 'New Expiration Date';
                        ToolTip = 'Specifies the new expiration date to use.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValueAsDate(Rec, QltyWorkflowResponse.GetWellKnownNewExpDate(), NewExpirationDate);
                        end;
                    }
                }
                group(Qlty_Reason_Group)
                {
                    Visible = QltyShouldShowReasonCode;
                    Caption = 'Reason';
                    InstructionalText = 'Optional reason for the change.';
                    field(Qlty_ReasonCode; QltyReasonCode)
                    {
                        ApplicationArea = QualityManagement;
                        TableRelation = "Reason Code".Code;
                        Caption = 'Reason';
                        ToolTip = 'Specifies the optional reason for the change.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownReasonCode(), QltyReasonCode);
                        end;
                    }
                }
                group(Qlty_Source_Group)
                {
                    Visible = QltyShouldShowGrpSource;
                    Caption = 'Source (optional)';
                    InstructionalText = 'Optional filters that limit the inventory source. When left blank then the current location/bin that the lot/serial/package resides in will be used. When this section is filled in then this will limit the from location to only the locations and filters specified. When you are quarantining entire item tracking combinations you can leave this blank to move all existing inventory regardless of where it currently is.';

                    field(Qlty_SourceLocationCodeFilter; OptionalSourceLocationCodeFilter)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Location Filter';
                        ToolTip = 'Specifies to optionally limit which locations will be used as the inventory source.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownSourceLocationFilter(), OptionalSourceLocationCodeFilter);
                        end;
                    }
                    field(Qlty_SourceBinCodeFilter; OptionalSourceBinCodeFilter)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Bin Filter';
                        ToolTip = 'Specifies to optionally limit which bins will be used as the inventory source.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownSourceBinFilter(), OptionalSourceBinCodeFilter);
                        end;
                    }
                }
                group(Qlty_Destination_Group)
                {
                    Visible = QltyShouldShowGrpDestination;
                    Caption = 'Destination';

                    field(Qlty_LocationCode; QltyLocationCode)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Location';
                        ToolTip = 'Specifies the destination location to use.';
                        ShowMandatory = true;
                        TableRelation = Location.Code;

                        trigger OnValidate()
                        var
                            DestinationLocation: Record Location;
                            DestinationBin: Record Bin;
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyLocation(), QltyLocationCode);
                            if not QltyShouldShowGrpTransfer then begin
                                QltyShowBinCode := true;
                                if DestinationLocation.Get(QltyLocationCode) then begin
                                    QltyShowBinCode := DestinationLocation."Bin Mandatory";
                                    if QltyBinCode <> '' then
                                        if not DestinationBin.Get(QltyLocationCode, QltyBinCode) then
                                            QltyBinCode := '';
                                end;
                            end;
                        end;
                    }
                    field(Qlty_BinCode; QltyBinCode)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Bin';
                        ToolTip = 'Specifies the destination bin to use.';
                        ShowMandatory = true;
                        Enabled = QltyShowBinCode;
                        AssistEdit = true;

                        trigger OnAssistEdit()
                        var
                            Bin: Record Bin;
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            BinList: Page "Bin List";
                        begin
                            if QltyLocationCode <> '' then
                                Bin.SetRange("Location Code", QltyLocationCode);
                            BinList.SetTableView(Bin);
                            BinList.LookupMode(true);
                            if BinList.RunModal() in [Action::LookupOK] then begin
                                BinList.GetRecord(Bin);
                                QltyBinCode := Bin.Code;
                                QltyWorkflowResponse.SetStepConfigurationValue(
                                    Rec,
                                    QltyWorkflowResponse.GetWellKnownKeyBin(),
                                    QltyBinCode);
                            end;
                        end;

                        trigger OnValidate()
                        var
                            Bin: Record Bin;
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            // After the table relation is removed to change from a drop-down to an assist-edit
                            // to allow the bins to be filtered by the location code, there needs to be an ability
                            // to validate the bin is still valid.  We do this by fetching the record and 
                            // letting it fail if it doesn't exist.
                            Bin.Get(QltyLocationCode, QltyBinCode);
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyBin(), QltyBinCode);
                        end;
                    }
                }
                group(Qlty_TransferDetails_Group)
                {
                    Visible = QltyShouldShowGrpTransfer;
                    Caption = 'Transfer Details';
                    InstructionalText = 'If the in-transit code is blank and no Transfer Route between the locations has been defined, the transfer will be direct. If the in-transit code is blank and a Transfer Route is defined, the Transfer Route''s in-transit location will be used.';

                    field(Qlty_DirectTransfer; QltyDirectTransfer)
                    {
                        ApplicationArea = All;
                        Caption = 'Direct Transfer';
                        ToolTip = 'Specifies that the transfer does not use an in-transit location';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownDirectTransfer(), QltyDirectTransfer);

                            if QltyDirectTransfer then begin
                                QltyInTransitLocationCode := '';
                                QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownInTransit(), QltyInTransitLocationCode);
                            end;
                        end;
                    }
                    field(Qlty_InTransitLocationCode; QltyInTransitLocationCode)
                    {
                        ApplicationArea = All;
                        Caption = 'In-Transit Code';
                        ToolTip = 'Specifies the in-transit location. Leave blank for a direct transfer or to use the Transfer Route.';
                        TableRelation = Location.Code where("Use As In-Transit" = const(true));
                        Enabled = not QltyDirectTransfer;

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownInTransit(), QltyInTransitLocationCode);
                        end;
                    }
                }
                group(Qlty_ReturnReason_Group)
                {
                    Visible = QltyShouldShowGrpReturnReason;
                    Caption = 'Return Reason (optional)';
                    field(Qlty_ReturnReasonCode; QltyReturnReasonCode)
                    {
                        ApplicationArea = QualityManagement;
                        TableRelation = "Return Reason".Code;
                        Caption = 'Return Reason';
                        ToolTip = 'Specifies the optional reason for the return.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownReasonCode(), QltyReturnReasonCode);
                        end;
                    }
                }
                group(Qlty_ExternalDocumentNo_Group)
                {
                    Visible = QltyShouldShowGrpExternalDocNo;
                    Caption = 'External Document';
                    ShowCaption = false;

                    field(ExternalDocumentNo; ExternalDocumentNo)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Vendor Credit Memo No.';
                        ToolTip = 'Specifies the optional Vendor Credit Memo No.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownExternalDocNo(), ExternalDocumentNo);
                        end;
                    }
                }
                group(Qlty_PostImmediately_Group)
                {
                    Visible = QltyShouldShowGrpPosting;
                    Caption = 'Post/Release Now or Later';
                    InstructionalText = 'Posting immediately can impact the Business Central licensing requirements.';

                    group(Qlty_CreatePutAway_Group)
                    {
                        ShowCaption = false;
                        Visible = QltyShouldShowCreatePutaway;
                        field(Qlty_CreatePutAway; QltyCreatePutAway)
                        {
                            ApplicationArea = QualityManagement;
                            Caption = 'Create the Put-away';
                            ToolTip = 'Specifies to automatically create the Put-away from the Internal Put-away. Use the Just Create Entries option to only create the Internal Put-away.';

                            trigger OnValidate()
                            var
                                QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                            begin
                                if QltyCreatePutAway then begin
                                    QltyPostImmediately := false;
                                    QltyPostLater := false;
                                end;

                                if QltyShouldShowCreatePutaway and not QltyPostImmediately and not QltyPostLater then
                                    QltyCreatePutAway := true;
                                QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownCreatePutAway(), QltyCreatePutAway);
                                QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownPostImmediately(), QltyPostImmediately);
                            end;
                        }
                    }
                    field(Qlty_PostNow; QltyPostImmediately)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Post Immediately';
                        ToolTip = 'Specifies to post the journal or create the movement document immediately.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            if QltyPostImmediately then begin
                                QltyCreatePutAway := false;
                                QltyPostLater := false;
                                QltyItemAdjPostBehavior := QltyItemAdjPostBehavior::Post;
                            end;

                            if QltyItemAdjPostBehavior = QltyItemAdjPostBehavior::Post then
                                QltyPostImmediately := true;

                            QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownPostImmediately(), QltyPostImmediately);
                            QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownCreatePutAway(), QltyCreatePutAway);
                            QltyWorkflowResponse.SetStepConfigurationValueAsAdjPostingEnum(Rec, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior(), QltyItemAdjPostBehavior);
                        end;
                    }
                    field(Qlty_PostLater; QltyPostLater)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Just Create Entries';
                        ToolTip = 'Specifies to just create the journal or movement entries.';

                        trigger OnValidate()
                        var
                            QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
                        begin
                            if QltyPostLater then begin
                                QltyCreatePutAway := false;
                                QltyPostImmediately := false;
                                QltyItemAdjPostBehavior := QltyItemAdjPostBehavior::"Prepare only";
                            end;

                            if QltyItemAdjPostBehavior = QltyItemAdjPostBehavior::"Prepare only" then
                                QltyPostLater := true;

                            QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownPostImmediately(), QltyPostImmediately);
                            QltyWorkflowResponse.SetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownCreatePutAway(), QltyCreatePutAway);
                            QltyWorkflowResponse.SetStepConfigurationValueAsAdjPostingEnum(Rec, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior(), QltyItemAdjPostBehavior);
                        end;
                    }
                }
            }
            group(Qlty_SetDatabaseValue_Group)
            {
                ShowCaption = false;
                Visible = QltyShouldShowSetDatabaseValue;
                InstructionalText = 'Set a field value in a table.';

                group(Qlty_SetDatabaseValue_Examples_Group)
                {
                    Caption = 'Examples:';
                    field(Qlty_SetDatabaseTable_Helper1; 'Block purchase on item card.')
                    {
                        ApplicationArea = QualityManagement;
                        ShowCaption = false;
                        Editable = false;
                        Caption = ' ';
                        Tooltip = ' ';

                        trigger OnDrillDown()
                        var
                            Item: Record Item;
                        begin
                            DatabaseTableName := Item.TableName();
                            DatabaseTableFilter := 'WHERE(No.=FILTER([Item:No.]))';
                            TestFieldToSet := Item.FieldName("Purchasing Blocked");
                            TestValueExpressionToSet := 'All';
                            Qlty_SetCommonDatabaseVariables();
                        end;
                    }
                    field(Qlty_SetDatabaseTable_Helper2; 'Block vendor.')
                    {
                        ApplicationArea = QualityManagement;
                        ShowCaption = false;
                        Editable = false;
                        Caption = ' ';
                        Tooltip = ' ';

                        trigger OnDrillDown()
                        var
                            Vendor: Record Vendor;
                        begin
                            DatabaseTableName := Vendor.TableName();
                            DatabaseTableFilter := 'WHERE(No.=FILTER([Vendor:No.]))';
                            TestFieldToSet := Vendor.FieldName("Blocked");
                            TestValueExpressionToSet := 'true';
                            Qlty_SetCommonDatabaseVariables();
                        end;
                    }
                    field(Qlty_SetDatabaseTable_Helper3; 'Flag BOM as under development.')
                    {
                        ApplicationArea = Manufacturing;
                        ShowCaption = false;
                        Editable = false;
                        Caption = ' ';
                        Tooltip = ' ';

                        trigger OnDrillDown()
                        var
                            ProductionBOMHeader: Record "Production BOM Header";
                        begin
                            DatabaseTableName := ProductionBOMHeader.TableName();
                            DatabaseTableFilter := 'WHERE(No.=FILTER([BOM:No.]))';
                            TestFieldToSet := ProductionBOMHeader.FieldName("Status");
                            TestValueExpressionToSet := UnderDevelopmentTxt;
                            Qlty_SetCommonDatabaseVariables();
                        end;
                    }
                }
                group(Qlty_SetDatabaseConfiguration_Group)
                {
                    Caption = 'Configuration:';

                    field(Qlty_SetDatabaseTable; DatabaseTableName)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Table';
                        Tooltip = 'Specifies which table to set?';

                        trigger OnValidate()
                        var
                            QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                            CurrentTable: Integer;
                        begin
                            if DatabaseTableName <> '' then begin
                                CurrentTable := QltyFilterHelpers.IdentifyTableIDFromText(DatabaseTableName);
                                if CurrentTable = 0 then
                                    QltyFilterHelpers.RunModalLookupTableFromText(DatabaseTableName);
                            end;
                            Qlty_SetCommonDatabaseVariables();
                            CurrPage.Update(true);
                        end;

                        trigger OnAssistEdit()
                        var
                            QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                        begin
                            QltyFilterHelpers.RunModalLookupTableFromText(DatabaseTableName);
                            Qlty_SetCommonDatabaseVariables();
                            CurrPage.Update(true);
                        end;
                    }
                    field(Qlty_SetDatabaseFilter; DatabaseTableFilter)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Filter';
                        Tooltip = 'Specifies what filter to use to find the record.';

                        trigger OnValidate()
                        begin
                            Qlty_SetCommonDatabaseVariables();
                            CurrPage.Update(true);
                        end;

                        trigger OnAssistEdit()
                        var
                            QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                            CurrentTable: Integer;
                        begin
                            CurrentTable := QltyFilterHelpers.IdentifyTableIDFromText(DatabaseTableName);
                            if CurrentTable = 0 then
                                Error(QltyChooseTableFirstErr);
                            QltyFilterHelpers.BuildFilter(CurrentTable, true, DatabaseTableFilter);
                            Qlty_SetCommonDatabaseVariables();
                            CurrPage.Update(true);
                        end;

                    }
                    field(Qlty_SetDatabaseField; TestFieldToSet)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Field';
                        Tooltip = 'Specifies which field on the table to set? [QltyInspectionField] nomenclature can be used to help find record based on another value in the quality inspection.';
                        InstructionalText = '[QltyInspectionField] nomenclature can be used to help find record based on another value in the quality inspection.';

                        trigger OnValidate()
                        var
                            QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                            CurrentField: Integer;
                            CurrentTable: Integer;
                        begin
                            if TestFieldToSet <> '' then begin
                                CurrentTable := QltyFilterHelpers.IdentifyTableIDFromText(DatabaseTableName);
                                if CurrentTable = 0 then
                                    Error(QltyChooseTableFirstErr);
                                CurrentField := QltyFilterHelpers.IdentifyFieldIDFromText(CurrentTable, TestFieldToSet);
                                if CurrentField = 0 then
                                    QltyFilterHelpers.RunModalLookupFieldFromText(DatabaseTableName, TestFieldToSet);
                            end;

                            Qlty_SetCommonDatabaseVariables();
                            CurrPage.Update(true);
                        end;

                        trigger OnAssistEdit()
                        var
                            QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                        begin
                            QltyFilterHelpers.RunModalLookupFieldFromText(DatabaseTableName, TestFieldToSet);
                            Qlty_SetCommonDatabaseVariables();
                            CurrPage.Update(true);
                        end;
                    }
                    field(Qlty_SetDatabaseValue; TestValueExpressionToSet)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Value to Set';
                        Tooltip = 'Specifies what value do you want to set? [QltyInspectionField] nomenclature can be used to use a field on the quality inspection while setting the value.';
                        InstructionalText = '[QltyInspectionField] nomenclature can be used to use a field on the quality inspection while setting the value.';

                        trigger OnValidate()
                        begin
                            Qlty_SetCommonDatabaseVariables();
                            CurrPage.Update(true);
                        end;

                        trigger OnAssistEdit()
                        var
                            QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
                            Expression: Text;
                        begin
                            Expression := TestValueExpressionToSet;
                            if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
                                TestValueExpressionToSet := Expression;
                                Qlty_SetCommonDatabaseVariables();
                            end;

                            CurrPage.Update(true);
                        end;
                    }
                }
            }
        }
    }

    var
        QltyShouldShowSetDatabaseValue: Boolean;
        QltyLocationCode: Code[10];
        QltyBinCode: Code[20];
        QltyMoveAll: Boolean;
        QltyPostImmediately: Boolean;
        QltyPostLater: Boolean;
        QltyShowBinCode: Boolean;
        QltyCreatePutAway: Boolean;
        QuantityToHandle: Decimal;
        OptionalSourceLocationCodeFilter: Text;
        OptionalSourceBinCodeFilter: Text;
        QltyUseReclass: Boolean;
        QltyUseMoveSheet: Boolean;
        TestFieldToSet: Text;
        TestValueExpressionToSet: Text;
        DatabaseTableName: Text;
        DatabaseTableFilter: Text;
        QltyUseTotalSample: Boolean;
        QltyUseFailed: Boolean;
        QltyUsePassed: Boolean;
        QltyMoveSpecific: Boolean;
        QltyQuantityBehavior: Enum "Qlty. Quantity Behavior";
        QltyShouldShowCreatePutaway: Boolean;
        QltyShouldShowInventory: Boolean;
        QltyShouldShowGrpMoveType: Boolean;
        QltyShouldShowGrpQuantity: Boolean;
        QltyShouldShowGrpSource: Boolean;
        QltyShouldShowGrpDestination: Boolean;
        QltyShouldShowGrpPosting: Boolean;
        QltyShouldShowGrpRegWhseJrnl: Boolean;
        QltyShouldShowReasonCode: Boolean;
        QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior";
        QltyShouldShowGrpItemTrackingChange: Boolean;
        NewLotNoExpression, NewSerialNoExpression, NewPackageNoExpression : Text;
        NewExpirationDate: Date;
        QltyReasonCode: Code[10];
        QltyReturnReasonCode: Code[10];
        QltyDirectTransfer: Boolean;
        QltyInTransitLocationCode: Code[10];
        QltyShouldShowGrpTransfer: Boolean;
        ExternalDocumentNo: Text;
        QltyShouldShowGrpReturnReason: Boolean;
        QltyShouldShowGrpExternalDocNo: Boolean;
        QltyChooseTableFirstErr: Label 'Please choose a valid table first.';
        UnderDevelopmentTxt: Label 'Under Development', Comment = 'Text value to set a Production BOM Header to Under Development status.';

    trigger OnAfterGetRecord()
    begin
        Qlty_SetGroupVisibility();
        Qlty_SetFields();
    end;

    local procedure Qlty_SetCommonDatabaseVariables()
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyDatabaseTable(), DatabaseTableName);

        QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyDatabaseTableFilter(), DatabaseTableFilter);

        QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyField(), TestFieldToSet);
        QltyWorkflowResponse.SetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyValueExpression(), TestValueExpressionToSet);
    end;

    local procedure Qlty_SetMoveBehaviorBools()
    begin
        QltyMoveSpecific := false;
        QltyMoveAll := false;
        QltyUseTotalSample := false;
        QltyUsePassed := false;
        QltyUseFailed := false;

        case QltyQuantityBehavior of
            QltyQuantityBehavior::"Specific Quantity":
                QltyMoveSpecific := true;
            QltyQuantityBehavior::"Item Tracked Quantity":
                QltyMoveAll := true;
            QltyQuantityBehavior::"Sample Quantity":
                QltyUseTotalSample := true;
            QltyQuantityBehavior::"Passed Quantity":
                QltyUsePassed := true;
            QltyQuantityBehavior::"Failed Quantity":
                QltyUseFailed := true;
        end;
    end;

    local procedure Qlty_SetGroupVisibility()
    var
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";
    begin
        QltyShouldShowInventory := false;
        QltyShouldShowGrpMoveType := false;
        QltyShouldShowGrpQuantity := false;
        QltyShouldShowGrpSource := false;
        QltyShouldShowGrpDestination := false;
        QltyShouldShowGrpPosting := false;
        QltyShouldShowCreatePutaway := false;
        QltyShouldShowSetDatabaseValue := false;
        QltyShouldShowGrpRegWhseJrnl := false;
        QltyShouldShowGrpItemTrackingChange := false;
        QltyShouldShowReasonCode := false;
        QltyShouldShowGrpTransfer := false;
        QltyShowBinCode := false;

        case Rec."Response Function Name" of
            QltyWorkflowSetup.GetWorkflowResponseMoveInventory():
                begin
                    QltyShouldShowInventory := true;
                    QltyShouldShowGrpMoveType := true;
                    QltyShouldShowGrpQuantity := true;
                    QltyShouldShowGrpSource := true;
                    QltyShouldShowGrpDestination := true;
                    QltyShouldShowGrpPosting := true;
                end;
            QltyWorkflowSetup.GetWorkflowResponseInternalPutAway():
                begin
                    QltyShouldShowInventory := true;
                    QltyShouldShowGrpQuantity := true;
                    QltyShouldShowGrpSource := true;
                    QltyShouldShowGrpPosting := true;
                    QltyShouldShowCreatePutaway := true;
                end;
            QltyWorkflowSetup.GetWorkflowResponseSetDatabaseValue():
                QltyShouldShowSetDatabaseValue := true;
            QltyWorkflowSetup.GetWorkflowResponseInventoryAdjustment():
                begin
                    QltyShouldShowInventory := true;
                    QltyShouldShowGrpQuantity := true;
                    QltyShouldShowReasonCode := true;
                    QltyShouldShowGrpSource := true;
                    QltyShouldShowGrpPosting := true;
                    QltyShouldShowGrpRegWhseJrnl := true;
                end;
            QltyWorkflowSetup.GetWorkflowResponseChangeItemTracking():
                begin
                    QltyShouldShowInventory := true;
                    QltyShouldShowGrpQuantity := true;
                    QltyShouldShowGrpSource := true;
                    QltyShouldShowGrpPosting := true;
                    QltyShouldShowGrpItemTrackingChange := true;
                end;
            QltyWorkflowSetup.GetWorkflowResponseCreateTransfer():
                begin
                    QltyShouldShowInventory := true;
                    QltyShouldShowGrpQuantity := true;
                    QltyShouldShowGrpSource := true;
                    QltyShouldShowGrpDestination := true;
                    QltyShouldShowGrpTransfer := true;
                end;
            QltyWorkflowSetup.GetWorkflowResponseCreatePurchaseReturn():
                begin
                    QltyShouldShowInventory := true;
                    QltyShouldShowGrpQuantity := true;
                    QltyShouldShowGrpSource := true;
                    QltyShouldShowGrpReturnReason := true;
                    QltyShouldShowGrpExternalDocNo := true;
                end;
        end;
    end;

    local procedure Qlty_SetFields()
    var
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        if QltyShouldShowInventory then begin
            if QltyShouldShowGrpMoveType then begin
                QltyUseMoveSheet := QltyWorkflowResponse.GetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownUseMoveSheet());
                QltyUseReclass := not QltyUseMoveSheet;
            end;

            if QltyShouldShowGrpQuantity then begin
                QuantityToHandle := QltyWorkflowResponse.GetStepConfigurationValueAsDecimal(Rec, QltyWorkflowResponse.GetWellKnownKeyQuantity());
                QltyQuantityBehavior := QltyWorkflowResponse.GetStepConfigurationValueAsQuantityBehaviorEnum(Rec, QltyWorkflowResponse.GetWellKnownMoveAll());
                Qlty_SetMoveBehaviorBools();
            end;

            if QltyShouldShowGrpSource then begin
                OptionalSourceLocationCodeFilter := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownSourceLocationFilter());
                OptionalSourceBinCodeFilter := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownSourceBinFilter());
            end;

            if QltyShouldShowGrpDestination then
                SetLocationAndBinCode();

            if QltyShouldShowGrpPosting then begin
                QltyCreatePutAway := QltyWorkflowResponse.GetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownCreatePutAway());
                QltyPostImmediately := QltyWorkflowResponse.GetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownPostImmediately());
                if not QltyCreatePutAway and not QltyPostImmediately then
                    QltyPostLater := true;
                if not QltyCreatePutAway and QltyPostImmediately then
                    QltyPostLater := false;
            end;
        end;

        if QltyShouldShowSetDatabaseValue then begin
            TestFieldToSet := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyField());
            TestValueExpressionToSet := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyValueExpression());
        end;

        if QltyShouldShowSetDatabaseValue then begin
            DatabaseTableName := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyDatabaseTable());
            DatabaseTableFilter := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownKeyDatabaseTableFilter());
        end;

        if QltyShouldShowGrpRegWhseJrnl then begin
            QltyItemAdjPostBehavior := QltyWorkflowResponse.GetStepConfigurationValueAsAdjPostingEnum(Rec, QltyWorkflowResponse.GetWellKnownAdjPostingBehavior());
            case QltyItemAdjPostBehavior of
                QltyItemAdjPostBehavior::"Prepare only":
                    begin
                        QltyPostLater := true;
                        QltyPostImmediately := false;
                    end;
                QltyItemAdjPostBehavior::Post:
                    begin
                        QltyPostImmediately := true;
                        QltyPostLater := false;
                    end;
            end;
        end;
        if QltyShouldShowGrpItemTrackingChange then begin
            NewLotNoExpression := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewLotNo());
            NewSerialNoExpression := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewSerialNo());
            NewPackageNoExpression := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownNewPackageNo());
            NewExpirationDate := QltyWorkflowResponse.GetStepConfigurationValueAsDate(Rec, QltyWorkflowResponse.GetWellKnownNewExpDate());
        end;

        if QltyShouldShowReasonCode then
            QltyReasonCode := QltyWorkflowResponse.GetStepConfigurationValueAsCode10(Rec, QltyWorkflowResponse.GetWellKnownReasonCode());

        if QltyShouldShowGrpReturnReason then
            QltyReturnReasonCode := QltyWorkflowResponse.GetStepConfigurationValueAsCode10(Rec, QltyWorkflowResponse.GetWellKnownReasonCode());

        if QltyShouldShowGrpExternalDocNo then
            ExternalDocumentNo := QltyWorkflowResponse.GetStepConfigurationValue(Rec, QltyWorkflowResponse.GetWellKnownExternalDocNo());

        if QltyShouldShowGrpTransfer then begin
            QltyDirectTransfer := QltyWorkflowResponse.GetStepConfigurationValueAsBoolean(Rec, QltyWorkflowResponse.GetWellKnownDirectTransfer());
            QltyInTransitLocationCode := QltyWorkflowResponse.GetStepConfigurationValueAsCode10(Rec, QltyWorkflowResponse.GetWellKnownInTransit());
        end;
    end;

    local procedure SetLocationAndBinCode()
    var
        Location: Record Location;
        QltyWorkflowResponse: Codeunit "Qlty. Workflow Response";
    begin
        QltyLocationCode := QltyWorkflowResponse.GetStepConfigurationValueAsCode10(Rec, QltyWorkflowResponse.GetWellKnownKeyLocation());
        QltyBinCode := QltyWorkflowResponse.GetStepConfigurationValueAsCode20(Rec, QltyWorkflowResponse.GetWellKnownKeyBin());

        if not QltyShouldShowGrpTransfer then begin
            QltyShowBinCode := true;
            if Location.Get(QltyLocationCode) then;
            QltyShowBinCode := Location."Bin Mandatory";
        end;
    end;
}
