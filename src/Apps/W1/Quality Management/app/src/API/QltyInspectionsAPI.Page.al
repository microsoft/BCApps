// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.API;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Dispositions.InventoryAdjustment;
using Microsoft.QualityManagement.Dispositions.ItemTracking;
using Microsoft.QualityManagement.Dispositions.Move;
using Microsoft.QualityManagement.Dispositions.PutAway;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Power automate friendly web service for quality inspections.
/// </summary>
page 20414 "Qlty. Inspections API"
{
    APIVersion = 'v2.0';
    APIGroup = 'qualityinspection';
    APIPublisher = 'microsoft';
    Caption = 'qltyInspections', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'qltyInspection';
    EntitySetName = 'qltyInspections';
    EntityCaption = 'Quality Inspection';
    EntitySetCaption = 'Quality Inspections';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    RefreshOnActivate = true;
    SourceTable = "Qlty. Inspection Header";

    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(rptTests)
            {
                ShowCaption = false;
                field(qltySystemIDOfTest; Rec.SystemId)
                {
                    Caption = 'qltySystemIDOfTest', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the system id of the record this test refers to. The Quality inspection document no.';
                }
                field(qltyTestNo; Rec."No.")
                {
                    Caption = 'qltyTestNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quality inspection document no.';
                }
                field(qltyTestRetestNo; Rec."Re-inspection No.")
                {
                    Caption = 'qltyTestRetestNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies which retest this is for.';
                }
                field(qltyTemplate; Rec."Template Code")
                {
                    Caption = 'qltyTemplate', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies which template this test was created from.';
                }
                field(qltyDescription; Rec.Description)
                {
                    Caption = 'qltyDescription', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the test itself.';
                }
                field(qltyInspectionStatus; Rec.Status)
                {
                    Caption = 'qltyInspectionStatus', Locked = true;
                    ApplicationArea = All;

                    ToolTip = 'Specifies the status of the test. No additional changes can be made to a finished Quality Inspection.';
                }

                field(qltyResultCode; Rec."Result Code")
                {
                    Caption = 'qltyResultCode', Locked = true;
                    ApplicationArea = All;

                    ToolTip = 'Specifies the result is automatically determined based on the test value and result configuration.';
                }
                field(qltyResultDescription; Rec."Result Description")
                {
                    Caption = 'qltyResultDescription', Locked = true;
                    ApplicationArea = All;

                    ToolTip = 'Specifies the result description for this test result. The result is automatically determined based on the test value and result configuration.';
                }
                field(qltyFinishedDate; Rec."Finished Date")
                {
                    Caption = 'qltyFinishedDate', Locked = true;
                    ApplicationArea = All;

                    ToolTip = 'Specifies the date that the test was finished.';
                }
                field(qltyResultPriority; Rec."Evaluation Sequence")
                {
                    Caption = 'qltyResultPriority', Locked = true;
                    ApplicationArea = All;

                    ToolTip = 'Specifies the associated result priority for this test result. The result is automatically determined based on the test value and result configuration.';
                }
                field(qltySourceTableNo; Rec."Source Table No.")
                {
                    Caption = 'qltySourceTableNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies a reference to the table that the quality inspection is for. ';

                }
                field(qltySourceDocumentNo; Rec."Source Document No.")
                {
                    Caption = 'qltySourceDocumentNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies a reference to the source that this Quality Inspection is referring to. This typically refers to a production order document number.';

                }
                field(qltySourceDocumentLineNo; Rec."Source Document Line No.")
                {
                    Caption = 'qltySourceDocumentLineNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies a reference to the source line no. that this Quality Inspection is referring to. This typically refers to a production order line no.';

                }

                field(qltySourceItemNo; Rec."Source Item No.")
                {
                    Caption = 'qltySourceItemNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item that the Quality Inspection is for. When used with production orders this typically refers to the item being produced.';
                }
                field(qltySourceVariantCode; Rec."Source Variant Code")
                {
                    Caption = 'qltySourceVariantCode', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item variant that the Quality Inspection is for. When used with production orders this typically refers to the item being produced.';
                }

                field(qltySourceSerialNo; Rec."Source Serial No.")
                {
                    Caption = 'qltySourceSerialNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the serial number that the quality inspection is for. This is only used for serial tracked items.';
                }
                field(qltySourceLotNo; Rec."Source Lot No.")
                {
                    Caption = 'qltySourceLotNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the lot number that the quality inspection is for. This is only used for lot tracked items.';
                }
                field(qltySourcePackageNo; Rec."Source Package No.")
                {
                    Caption = 'qltySourcePackageNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the package number that the quality inspection is for. This is only used for package tracked items.';
                }
                field(qltySourceQuantity; Rec."Source Quantity (Base)")
                {
                    Caption = 'qltySourceQuantity', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Source Quantity when configured.';

                }
                field(qltySourceRecordID; Rec."Source RecordId")
                {
                    Caption = 'qltySourceRecordID', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Source record ID.';
                }
                field(qltySourceRecordTableNo; Rec."Source Record Table No.")
                {
                    Caption = 'qltySourceRecordTableNo', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Source record Table No.';
                }
                field(qltyAssignedUserID; Rec."Assigned User ID")
                {
                    Caption = 'qltyAssignedUserID', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user this test is assigned to.';
                }
                field(qltySystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'qltySystemCreatedAt', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date the test was created.';
                }
                field(qltySystemCreatedBy; Rec.SystemCreatedBy)
                {
                    Caption = 'qltySystemCreatedBy', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies which User ID made the test.';
                }
                field(qltySystemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'qltySystemModifiedAt', Locked = true;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last modified date of the test.';
                }
                field(qltySystemModifiedBy; Rec.SystemModifiedBy)
                {
                    Caption = 'qltySystemModifiedBy';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last Modified By User ID';
                }
            }
        }
    }
    var
        QltyBooleanParsing: Codeunit "Qlty. Boolean Parsing";
        CannotConvertDateErr: Label 'Could not convert date %1. Use ISO 8601 (YYYY-MM-DD) date format.', Comment = '%1=date';


    /// <summary>
    /// Use with web services and power automate to Finish the Inspection
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure FinishInspection(var ActionContext: WebServiceActionContext)
    begin
        Rec.FinishInspection();
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Creates a Reinspection.
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure CreateReinspection(var ActionContext: WebServiceActionContext)
    begin
        Rec.CreateReinspection();
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Reopens an inspection
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure ReopenInspection(var ActionContext: WebServiceActionContext)
    begin
        Rec.ReopenInspection();
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Sets a test value
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="testCode">Text. The field code to set.</param>
    /// <param name="testValue">Text. The field value to set.</param>
    [ServiceEnabled]
    procedure SetTestValue(var ActionContext: WebServiceActionContext; testCode: Text; testValue: Text)
    begin
        Rec.SetTestValue(testCode, testValue);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Assigns the test.
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="assignToUser">Text. The user id to assign the test to.</param>
    [ServiceEnabled]
    procedure AssignTo(var ActionContext: WebServiceActionContext; assignToUser: Text)
    begin
        Rec."Assigned User ID" := CopyStr(assignToUser, 1, MaxStrLen(Rec."Assigned User ID"));
        Rec.Modify(false);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Blocks the lot
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure BlockLot(var ActionContext: WebServiceActionContext)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetLotBlockState(Rec, true);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Un-Blocks the lot
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure UnBlockLot(var ActionContext: WebServiceActionContext)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetLotBlockState(Rec, false);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;


    /// <summary>
    /// Blocks the serial
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure BlockSerial(var ActionContext: WebServiceActionContext)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetSerialBlockState(Rec, true);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Un-Blocks the serial
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure UnBlockSerial(var ActionContext: WebServiceActionContext)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetSerialBlockState(Rec, false);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Blocks the serial
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure BlockPackage(var ActionContext: WebServiceActionContext)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetPackageBlockState(Rec, true);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Un-Blocks the serial
    /// </summary>
    /// <param name="ActionContext"></param>
    [ServiceEnabled]
    procedure UnBlockPackage(var ActionContext: WebServiceActionContext)
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        QltyItemTracking.SetPackageBlockState(Rec, false);
        ActionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    /// <summary>
    /// Uses an inventory movement to move inventory
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="optionalDestinationLocation"></param>
    /// <param name="binCode"></param>
    /// <param name="optionalSpecificQuantity"></param>
    /// <param name="moveEntireLot"></param>
    /// <param name="optionalSourceLocationFilter"></param>
    /// <param name="optionalSourceBinFilter"></param>
    [ServiceEnabled]
    procedure CreateMovement(var ActionContext: WebServiceActionContext; optionalDestinationLocation: Text; binCode: Text; optionalSpecificQuantity: Text; moveEntireLot: Text; optionalSourceLocationFilter: Text; optionalSourceBinFilter: Text) // Text to work around limitations in MS power automate integration as of 2023/April/17
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyDispInternalMove: Codeunit "Qlty. Disp. Internal Move";
    begin

        optionalSourceLocationFilter := DelChr(optionalSourceLocationFilter, '<>', ' ');
        optionalSourceBinFilter := DelChr(optionalSourceBinFilter, '<>', ' ');
        binCode := DelChr(binCode, '<>', ' ');
        optionalDestinationLocation := DelChr(optionalDestinationLocation, '<>', ' ');

        if QltyBooleanParsing.GetBooleanFor(moveEntireLot) then
            TempInstructionQltyDispositionBuffer."Quantity Behavior" := TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity";

        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Internal Movement";

        if optionalSpecificQuantity <> '' then
            Evaluate(TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)", optionalSpecificQuantity);

        TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(optionalSourceLocationFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
        TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(optionalSourceBinFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
        TempInstructionQltyDispositionBuffer."New Location Code" := CopyStr(optionalDestinationLocation, 1, 10);
        TempInstructionQltyDispositionBuffer."New Bin Code" := CopyStr(binCode, 1, 20);

        if QltyDispInternalMove.PerformDisposition(
            Rec,
            TempInstructionQltyDispositionBuffer
            ) then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;

    local procedure ConvertTextToQuantityBehaviorEnum(TextToConvert: Text) QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"
    var
        IndexOfText: Integer;
        OrdinalOfEnum: Integer;
    begin
        IndexOfText := QltyQuantityBehavior.Names.IndexOf(TextToConvert);
        if IndexOfText = 0 then
            QltyQuantityBehavior := QltyQuantityBehavior::"Specific Quantity"
        else begin
            OrdinalOfEnum := QltyQuantityBehavior.Ordinals.Get(IndexOfText);
            QltyQuantityBehavior := Enum::"Qlty. Quantity Behavior".FromInteger(OrdinalOfEnum);
        end;
    end;

    /// <summary>
    /// Creates a Warehouse Internal Put-away document.
    /// This feature can be used with directed pick and put locations with lot warehouse tracked items.
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="optionalSpecificQuantity">When non zero this indicates the quantity to move.</param>
    /// <param name="releaseImmediately">When set to TRUE, will release the internal put-away</param>
    /// <param name="optionalSourceLocationFilter">Optionally restrict the locations to move from. </param>
    /// <param name="optionalSourceBinFilter">Optionally restrict the specific bins to move from.</param>
    /// <param name="moveBehavior">Valid options are: SpecificQuantity (quantity defined in optionalSpecificQuantity), TrackedQuantity (quantity of lot/package/serial), SampleQuantity (sample size), FailQuantity (number of failed samples), PassQuantity (number of passed samples)</param>
    [ServiceEnabled]
    procedure CreateWarehouseInternalPutaway(var ActionContext: WebServiceActionContext; optionalSpecificQuantity: Text; releaseImmediately: Text; optionalSourceLocationFilter: Text; optionalSourceBinFilter: Text; moveBehavior: Text) // Text to work around limitations in MS power automate integration as of 2023/April/17
    var
        QltyDispInternalPutAway: Codeunit "Qlty. Disp. Internal Put-away";
        OverrideQuantity: Decimal;
        ShouldReleaseImmediately: Boolean;
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
    begin
        optionalSourceLocationFilter := DelChr(optionalSourceLocationFilter, '<>', ' ');
        optionalSourceBinFilter := DelChr(optionalSourceBinFilter, '<>', ' ');

        if optionalSpecificQuantity <> '' then
            Evaluate(OverrideQuantity, optionalSpecificQuantity);

        ShouldReleaseImmediately := QltyBooleanParsing.GetBooleanFor(releaseImmediately);
        QuantityBehavior := ConvertTextToQuantityBehaviorEnum(moveBehavior);

        if QltyDispInternalPutAway.PerformDisposition(
            Rec,
            OverrideQuantity,
            optionalSourceLocationFilter,
            optionalSourceBinFilter,
            ShouldReleaseImmediately,
            QuantityBehavior
            ) then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;

    /// <summary>
    /// Creates a Warehouse Put-away document.
    /// This feature can be used with directed pick and put locations with lot warehouse tracked items.
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="optionalSpecificQuantity">Quantity to move, if updating a specific quantity</param>
    /// <param name="optionalSourceLocationFilter">Optionally restrict the locations to move from. </param>
    /// <param name="optionalSourceBinFilter">Optionally restrict the specific bins to move from.</param>
    /// <param name="putawayBehavior">valid options are KEEPOPEN (create internal put-away), RELEASE (create and release internal put-away), or CREATEPUTAWAY (create and release internal put-away and create warehouse put-away) </param>
    /// <param name="moveBehavior">Valid options are: SpecificQuantity (quantity defined in optionalSpecificQuantity), TrackedQuantity (quantity of lot/package/serial), SampleQuantity (sample size), FailQuantity (number of failed samples), PassQuantity (number of passed samples)</param>
    [ServiceEnabled]
    procedure CreateWarehousePutAway(var ActionContext: WebServiceActionContext; optionalSpecificQuantity: Text; optionalSourceLocationFilter: Text; optionalSourceBinFilter: Text; putAwayBehavior: Text; moveBehavior: Text) // Text to work around limitations in MS power automate integration as of 2023/April/17
    var
        QltyDispInternalPutAway: Codeunit "Qlty. Disp. Internal Put-away";
        QltyDispWarehousePutAway: Codeunit "Qlty. Disp. Warehouse Put-away";
        OverrideQuantity: Decimal;
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
        Success: Boolean;
    begin
        optionalSourceLocationFilter := DelChr(optionalSourceLocationFilter, '<>', ' ');
        optionalSourceBinFilter := DelChr(optionalSourceBinFilter, '<>', ' ');
        putAwayBehavior := DelChr(putAwayBehavior, '<>', ' ').ToUpper();

        if optionalSpecificQuantity <> '' then
            Evaluate(OverrideQuantity, optionalSpecificQuantity);

        QuantityBehavior := ConvertTextToQuantityBehaviorEnum(moveBehavior);

        if putAwayBehavior.Contains('CREATEPUTAWAY') then
            Success := QltyDispWarehousePutAway.PerformDisposition(
                Rec,
                OverrideQuantity,
                optionalSourceLocationFilter,
                optionalSourceBinFilter,
                QuantityBehavior)
        else
            Success := QltyDispInternalPutAway.PerformDisposition(
                Rec,
                OverrideQuantity,
                optionalSourceLocationFilter,
                optionalSourceBinFilter,
                putAwayBehavior.Contains('RELEASE'),
                QuantityBehavior);

        if Success then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);
    end;

    /// <summary>
    /// Uses an item/warehouse reclassification journal or movement worksheet to move the inventory.
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="optionalDestinationLocation">When left blank this assumes the same location as the from location.</param>
    /// <param name="optionalDestinationBin">The target bin to move to.</param>
    /// <param name="optionalSpecificQuantity">Quantity to move, if updating a specific quantity</param>
    /// <param name="postImmediately">When set to TRUE this will post journals immediately or create the warehouse movement.  Verify you have sufficient licensing to use this flag.</param>
    /// <param name="optionalSourceLocationFilter">Optionally restrict the locations to move from. </param>
    /// <param name="optionalSourceBinFilter">Optionally restrict the specific bins to move from.</param>
    /// <param name="useMoveSheet">When set to TRUE, will use the Movement Worksheet instead of a reclassification journal.</param>
    /// <param name="moveBehavior">Valid options are: SpecificQuantity (quantity defined in optionalSpecificQuantity), TrackedQuantity (quantity of lot/package/serial) SampleQuantity (sample size), FailQuantity (number of failed samples), PassQuantity (number of passed samples)</param>
    [ServiceEnabled]
    procedure MoveInventory(var ActionContext: WebServiceActionContext; optionalDestinationLocation: Text; optionalDestinationBin: Text; optionalSpecificQuantity: Text; postImmediately: Text; optionalSourceLocationFilter: Text; optionalSourceBinFilter: Text; useMoveSheet: Text; moveBehavior: Text) // Text to work around limitations in MS power automate integration as of 2023/April/17
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        InventoryQltyDispMoveAutoChoose: Codeunit "Qlty. Disp. Move Auto Choose";
        UseMovement: Boolean;
    begin

        optionalDestinationBin := DelChr(optionalDestinationBin, '<>', ' ');
        optionalDestinationLocation := DelChr(optionalDestinationLocation, '<>', ' ');
        optionalSourceLocationFilter := DelChr(optionalSourceLocationFilter, '<>', ' ');
        optionalSourceBinFilter := DelChr(optionalSourceBinFilter, '<>', ' ');


        TempInstructionQltyDispositionBuffer."Quantity Behavior" := ConvertTextToQuantityBehaviorEnum(moveBehavior);

        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with automatic choice";

        if optionalSpecificQuantity <> '' then
            Evaluate(TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)", optionalSpecificQuantity);

        TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(optionalSourceLocationFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
        TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(optionalSourceBinFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
        if QltyBooleanParsing.GetBooleanFor(postImmediately) then
            TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        TempInstructionQltyDispositionBuffer."New Location Code" := CopyStr(optionalDestinationLocation, 1, 10);
        TempInstructionQltyDispositionBuffer."New Bin Code" := CopyStr(optionalDestinationBin, 1, 20);


        if InventoryQltyDispMoveAutoChoose.MoveInventory(
            Rec,
           TempInstructionQltyDispositionBuffer,
            UseMovement
            ) then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);

    end;

    /// <summary>
    /// Uses the information from a Quality Inspection to process a negative adjustment for the tested item.
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="optionalSourceLocationFilter">Optional additional location filter for item on test</param>
    /// <param name="optionalSourceBinFilter">Optional additional bin filter for item on test</param>
    /// <param name="optionalSpecificQuantity">Quantity to remove, if moving a specific quantity</param>
    /// <param name="optionalReasonCode">Optional Reason Code</param>
    /// <param name="adjustmentBehavior">Remove a specific quantity, tracked quantity, sample size, or sample pass/fail quantity</param>
    /// <param name="postingBehavior">Whether to create journal entries, register a warehouse item journal, or post an item journal</param>
    [ServiceEnabled]
    procedure CreateNegativeAdjustment(var ActionContext: WebServiceActionContext; optionalSourceLocationFilter: Text; optionalSourceBinFilter: Text; optionalSpecificQuantity: Text; optionalReasonCode: Text; adjustmentBehavior: Text; postingBehavior: Text) // Text to work around limitations in MS power automate integration as of 2023/April/17
    var
        QltyDispNegAdjustInv: Codeunit "Qlty. Disp. Neg. Adjust Inv.";
        SpecificQuantity: Decimal;
    begin
        optionalSourceLocationFilter := DelChr(optionalSourceLocationFilter, '<>', ' ');
        optionalSourceBinFilter := DelChr(optionalSourceBinFilter, '<>', ' ');

        if optionalSpecificQuantity <> '' then
            Evaluate(SpecificQuantity, optionalSpecificQuantity);

        if QltyDispNegAdjustInv.PerformDisposition(
            Rec,
            SpecificQuantity,
            ConvertTextToQuantityBehaviorEnum(adjustmentBehavior),
            optionalSourceLocationFilter,
            optionalSourceBinFilter,
            ConvertTextToItemAdjPostBehaviorEnum(postingBehavior),
            CopyStr(optionalReasonCode, 1, 10))
            then
            ActionContext.SetResultCode(WebServiceActionResultCode::Created)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);

    end;

    local procedure ConvertTextToItemAdjPostBehaviorEnum(InputText: Text) QltyItemAdjPostBehavior: Enum "Qlty. Item Adj. Post Behavior"
    var
        IndexOfText: Integer;
        OrdinalOfEnum: Integer;
    begin
        IndexOfText := QltyItemAdjPostBehavior.Names.IndexOf(InputText);
        if IndexOfText = 0 then
            QltyItemAdjPostBehavior := QltyItemAdjPostBehavior::"Prepare only"
        else begin
            OrdinalOfEnum := QltyItemAdjPostBehavior.Ordinals.Get(IndexOfText);
            QltyItemAdjPostBehavior := Enum::"Qlty. Item Adj. Post Behavior".FromInteger(OrdinalOfEnum);
        end;
    end;

    /// <summary>
    /// Uses the information from a Quality Inspection to update item tracking information for the tested item.
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="optionalSourceLocationFilter">Optional additional location filter for item on test</param>
    /// <param name="optionalSourceBinFilter">Optional additional bin filter for item on test</param>
    /// <param name="optionalSpecificQuantity">Quantity to update, if updating a specific quantity</param>
    /// <param name="quantityChoice">Valid options are: SpecificQuantity (quantity defined in optionalSpecificQuantity), TrackedQuantity (quantity of lot/package/serial)
    /// SampleQuantity (sample size), FailQuantity (number of failed samples), PassQuantity (number of passed samples)</param>
    /// <param name="postImmediately">Boolean value signifying whether to create the journal entry or create and post the journal</param>
    /// <param name="newLotNo">New lot no.</param>
    /// <param name="newSerialNo">New serial no.</param>
    /// <param name="newPackageNo">New package no.</param>
    /// <param name="newExpirationDate">New expiration date</param>
    [ServiceEnabled]
    procedure ChangeItemTracking(var ActionContext: WebServiceActionContext; optionalSourceLocationFilter: Text; optionalSourceBinFilter: Text; optionalSpecificQuantity: Text; quantityChoice: Text; postImmediately: Text;
                                    newLotNo: Text; newSerialNo: Text; newPackageNo: Text; newExpirationDate: Text) // Text to work around limitations in MS power automate integration as of 2023/April/17
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyDispChangeTracking: Codeunit "Qlty. Disp. Change Tracking";
        SpecificQuantity: Decimal;
        DesiredExpirationDate: Date;
    begin
        optionalSourceLocationFilter := DelChr(optionalSourceLocationFilter, '<>', ' ');
        optionalSourceBinFilter := DelChr(optionalSourceBinFilter, '<>', ' ');
        newExpirationDate := DelChr(newExpirationDate, '<>', ' ');

        if optionalSpecificQuantity <> '' then
            Evaluate(SpecificQuantity, optionalSpecificQuantity);
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := SpecificQuantity;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := ConvertTextToQuantityBehaviorEnum(quantityChoice);
        if QltyBooleanParsing.GetBooleanFor(postImmediately) then
            TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;

        TempInstructionQltyDispositionBuffer."New Lot No." := CopyStr(DelChr(newLotNo, '<>', ' '), 1, MaxStrLen(TempInstructionQltyDispositionBuffer."New Lot No."));
        TempInstructionQltyDispositionBuffer."New Serial No." := CopyStr(DelChr(newSerialNo, '<>', ' '), 1, MaxStrLen(TempInstructionQltyDispositionBuffer."New Serial No."));
        TempInstructionQltyDispositionBuffer."New Package No." := CopyStr(DelChr(newPackageNo, '<>', ' '), 1, MaxStrLen(TempInstructionQltyDispositionBuffer."New Package No."));
        if newExpirationDate <> '' then
            if not Evaluate(DesiredExpirationDate, Format(newExpirationDate, 0, 9)) then
                Error(CannotConvertDateErr, newExpirationDate);

        TempInstructionQltyDispositionBuffer."New Expiration Date" := DesiredExpirationDate;
        if QltyDispChangeTracking.PerformDisposition(Rec, TempInstructionQltyDispositionBuffer) then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);

    end;

    /// <summary>
    /// Uses the information from a Quality Inspection to create a transfer order for the tested item.
    /// </summary>
    /// <param name="ActionContext"></param>
    /// <param name="optionalSourceLocationFilter">Optional additional location filter for item on test</param>
    /// <param name="optionalSourceBinFilter">Optional additional bin filter for item on test</param>
    /// <param name="destinationLocation">Destination location for the transfer</param>
    /// <param name="optionalSpecificQuantity">Quantity to transfer, if using the specific quantity choice</param>
    /// <param name="quantityChoice">Transfer a specific quantity (SpecificQuantity), item tracked quantity (TrackedQuantity), sample size (SampleQuantity), or sample pass/fail quantity (PassQuantity or FailQuantity)</param>
    /// <param name="directTransfer">Boolean defining whether the transfer is direct</param>
    /// <param name="inTransitLocation">The in-transit location to use</param>
    [ServiceEnabled]
    procedure CreateTransferOrder(var ActionContext: WebServiceActionContext; optionalSourceLocationFilter: Text; optionalSourceBinFilter: Text; destinationLocation: Text; optionalSpecificQuantity: Text; quantityChoice: Text;
                                    directTransfer: Text; inTransitLocation: Text) // Text to work around limitations in MS power automate integration as of 2023/April/17
    var
        QltyDispTransfer: Codeunit "Qlty. Disp. Transfer";
        SpecificQuantity: Decimal;
        QuantityBehavior: Enum "Qlty. Quantity Behavior";
        IsDirectTransfer: Boolean;
        DestinationLocationCode: Code[10];
        InTransitLocationCode: Code[10];
    begin
        optionalSourceLocationFilter := DelChr(optionalSourceLocationFilter, '<>', ' ');
        optionalSourceBinFilter := DelChr(optionalSourceBinFilter, '<>', ' ');

        if optionalSpecificQuantity <> '' then
            Evaluate(SpecificQuantity, optionalSpecificQuantity);
        QuantityBehavior := ConvertTextToQuantityBehaviorEnum(quantityChoice);
        IsDirectTransfer := QltyBooleanParsing.GetBooleanFor(directTransfer);
        DestinationLocationCode := CopyStr(destinationLocation, 1, MaxStrLen(DestinationLocationCode));
        InTransitLocationCode := CopyStr(inTransitLocation, 1, MaxStrLen(InTransitLocationCode));
        if IsDirectTransfer then
            InTransitLocationCode := '';

        if QltyDispTransfer.PerformDisposition(
            Rec,
            SpecificQuantity,
            QuantityBehavior,
            optionalSourceLocationFilter,
            optionalSourceBinFilter,
            DestinationLocationCode,
            InTransitLocationCode
            )
        then
            ActionContext.SetResultCode(WebServiceActionResultCode::Updated)
        else
            ActionContext.SetResultCode(WebServiceActionResultCode::None);

    end;

}
