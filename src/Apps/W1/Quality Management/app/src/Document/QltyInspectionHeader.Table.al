// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Integration.Inventory.Transfer;
using Microsoft.QualityManagement.Reports;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.QualityManagement.Workflow;
using System.Device;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Utilities;

table 20405 "Qlty. Inspection Header"
{
    Caption = 'Quality Inspection Header';
    DrillDownPageId = "Qlty. Inspection List";
    LookupPageId = "Qlty. Inspection List";
    DataClassification = CustomerContent;
    Permissions = tabledata "Qlty. Inspection Line" = d;

    fields
    {
        field(1; "No."; Code[20])
        {
            OptimizeForTextSearch = true;
            Caption = 'No.';
            ToolTip = 'Specifies the quality inspection document number.';
        }
        field(2; "Re-inspection No."; Integer)
        {
            Caption = 'Re-inspection No.';
            ToolTip = 'Specifies the re-inspection counter.';
            BlankZero = true;
        }
        field(4; "Most Recent Re-inspection"; Boolean)
        {
            Caption = 'Most Recent Re-inspection';
            Editable = false;
            ToolTip = 'Specifies if this is the most recent re-inspection for the same inspection.';
        }
        field(5; "Template Code"; Code[20])
        {
            Caption = 'Template Code';
            NotBlank = true;
            TableRelation = "Qlty. Inspection Template Hdr.";
            ToolTip = 'Specifies which template this inspection was created from.';

            trigger OnValidate()
            begin
                InitInspectionNumber();
            end;
        }
        field(6; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the Quality Inspection itself.';
        }
        field(8; "Status"; Enum "Qlty. Inspection Status")
        {
            Caption = 'Status';
            Editable = false;
            ToolTip = 'Specifies the status of the inspection. No additional changes can be made to a finished Quality Inspection.';

            trigger OnValidate()
            begin
                if Rec.Status = Rec.Status::Finished then
                    ProcessFinishInspection()
                else
                    ProcessReopenInspection();
            end;
        }
        field(11; "Source Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            ToolTip = 'Specifies a reference to the quantity involved.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if not Rec.IsTemporary() then
                    if not GetIsCreating() then
                        QltyPermissionMgmt.VerifyCanChangeSourceQuantity();

                if Rec."Source Quantity (Base)" < 0 then
                    Rec."Source Quantity (Base)" := Abs(Rec."Source Quantity (Base)");

                VerifyPassAndFailQuantities();
                UpdateSampleSize();
            end;
        }
        field(13; "Pass Quantity"; Decimal)
        {
            Caption = 'Pass Quantity';
            AutoFormatType = 0;
            ToolTip = 'Specifies the quantity that passed inspection. A manually entered quantity for non-sampling inspections, or derived from the quantity of passed sampling lines for sampling inspections.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Rec.IsTemporary() then
                    exit;

                if not Rec.GetIsCreating() then
                    QltyPermissionMgmt.VerifyCanChangeSourceQuantity();

                VerifyPassAndFailQuantities();
            end;
        }
        field(15; "Fail Quantity"; Decimal)
        {
            Caption = 'Fail Quantity';
            AutoFormatType = 0;
            ToolTip = 'Specifies the quantity that failed inspection. A manually entered quantity for non-sampling inspections, or derived from the quantity of failed sampling lines for sampling inspections.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Rec.IsTemporary() then
                    exit;
                if not Rec.GetIsCreating() then
                    QltyPermissionMgmt.VerifyCanChangeSourceQuantity();

                VerifyPassAndFailQuantities();
            end;
        }
        field(17; "Sample Size"; Integer)
        {
            Caption = 'Sample Size';
            ToolTip = 'Specifies the number of units that must be inspected. This will be used to fill out the sample size field on a Quality Inspection when possible based on the other characteristics that were applied.';

            trigger OnValidate()
            var
                Math: Codeunit Math;
            begin
                if (Rec."Sample Size" > Rec."Source Quantity (Base)") and (Rec."Source Quantity (Base)" > 0) then begin
                    if GuiAllowed() and not Rec.GetIsCreating() and (not Rec.IsTemporary()) then
                        Message(SampleSizeInvalidMsg, Rec."Sample Size", Rec."No.", Rec."Source Quantity (Base)");

                    Rec."Sample Size" := Math.Truncate(Rec."Source Quantity (Base)");
                end;
            end;
        }
        field(21; "Assigned User ID"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            Caption = 'Assigned User ID';
            ToolTip = 'Specifies the user this inspection is assigned to.';

            trigger OnValidate()
            var
                CanChangeAssignmentWithoutPermission: Boolean;
            begin
                CanChangeAssignmentWithoutPermission := false;

                if ((xRec."Assigned User ID" = UserId()) and (Rec."Assigned User ID" = '')) or (((xRec."Assigned User ID" = '') and (Rec."Assigned User ID" = UserId()))) then
                    CanChangeAssignmentWithoutPermission := true
                else
                    CanChangeAssignmentWithoutPermission := QltyPermissionMgmt.CanChangeOtherInspections();

                if not CanChangeAssignmentWithoutPermission then
                    Error(YouCannotChangeTheAssignmentOfTheInspectionErr, UserId(), Rec."No.", Rec."Re-inspection No.");
            end;
        }
        field(23; "Planned Start Date"; DateTime)
        {
            Editable = false;
            Caption = 'Planned Start Date';
            ToolTip = 'Specifies the last planned start time of the inspection.';
        }
        field(25; "Finished Date"; DateTime)
        {
            Editable = false;
            Caption = 'Finished Date';
            ToolTip = 'Specifies the date that the inspection was finished.';
        }
        field(26; "Finished By User ID"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            Caption = 'Finished By User ID';
            ToolTip = 'Specifies the user that finished the inspection.';
        }
        field(31; "Result Code"; Code[20])
        {
            Editable = false;
            TableRelation = "Qlty. Inspection Result".Code;
            Caption = 'Result Code';
            ToolTip = 'Specifies the result is automatically determined based on the test value and result configuration.';

            trigger OnValidate()
            var
                QltyInspectionResult: Record "Qlty. Inspection Result";
            begin
                if Rec."Result Code" = '' then
                    Rec."Evaluation Sequence" := 0
                else begin
                    QltyInspectionResult.Get("Result Code");
                    Rec."Evaluation Sequence" := "Evaluation Sequence";
                end;
                Rec.CalcFields("Result Description");
            end;
        }
        field(32; "Result Description"; Text[100])
        {
            Caption = 'Result';
            Editable = false;
            ToolTip = 'Specifies the result description for this test result. The result is automatically determined based on the test value and result configuration.';
            FieldClass = FlowField;
            CalcFormula = lookup("Qlty. Inspection Result"."Description" where("Code" = field("Result Code")));
        }
        field(33; "Evaluation Sequence"; Integer)
        {
            Caption = 'Evaluation Sequence';
            Editable = false;
            ToolTip = 'Specifies the associated evaluation sequence for this test result. The result is automatically determined based on the test value and result configuration.';
        }
        field(35; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location.Code;
            ToolTip = 'Specifies the location of the inspection.';
        }
        field(41; "Most Recent Picture"; Media)
        {
            Caption = 'Most Recent Picture';
            ToolTip = 'Specifies the most recent picture. Additionally, pictures can be uploaded to document attachments and OneDrive automatically.';
        }
        field(45; "Existing Inspections This Rec."; Integer)
        {
            Caption = 'Existing Inspections (this record)';
            Editable = false;
            ToolTip = 'Specifies whether or not there are existing quality inspections for this same record.';
            FieldClass = FlowField;
            CalcFormula = count("Qlty. Inspection Header" where("Source Table No." = field("Source Table No."),
                                                                "Source Type" = field("Source Type"),
                                                                "Source Sub Type" = field("Source Sub Type"),
                                                                "Source Document No." = field("Source Document No."),
                                                                "Source Document Line No." = field("Source Document Line No."),
                                                                "Source Lot No." = field("Source Lot No."),
                                                                "Source Serial No." = field("Source Serial No."),
                                                                "Source Package No." = field("Source Package No.")));
        }
        field(46; "Existing Inspections This Item"; Integer)
        {
            Caption = 'Existing Inspections (this item)';
            Editable = false;
            ToolTip = 'Specifies whether or not there are existing existing inspections for this same item.';
            FieldClass = FlowField;
            CalcFormula = count("Qlty. Inspection Header" where("Source Item No." = field("Source Item No."),
                                                                "Source Variant Code" = field("Source Variant Code"),
                                                                "Source Lot No." = field("Source Lot No."),
                                                                "Source Serial No." = field("Source Serial No."),
                                                                "Source Package No." = field("Source Package No.")));
        }
        field(51; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            BlankZero = true;
            Editable = false;
            ToolTip = 'Specifies a reference to the table that the quality inspection is for.';
        }
        field(52; "Source Table Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                          "Object ID" = field("Source Table No.")));
            Caption = 'Source Table Name';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the target table. If a table is referenced, the name of the table.';
        }
        field(53; "Source Type"; Integer)
        {
            BlankZero = true;
            Caption = 'Source Type';
            ToolTip = 'Specifies an optional field used to track the source type for the source record.';
        }
        field(54; "Source Sub Type"; Integer)
        {
            BlankZero = true;
            Caption = 'Source Sub Type';
            ToolTip = 'Specifies an optional field used to track the source sub type for the source record.';
        }
        field(55; "Source Document No."; Code[20])
        {
            Caption = 'Document No.';
            NotBlank = true;
            Editable = false;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies a reference to the document that this Quality Inspection is referring to. This typically refers to a production order document number.';
        }
        field(56; "Source Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
            Editable = false;
            ToolTip = 'Specifies a reference to the source document line no. that this Quality Inspection is referring to. This typically refers to a production order line no.';
        }
        field(58; "Source Task No."; Code[20])
        {
            Caption = 'Task No.';
            ToolTip = 'Specifies a reference to the source task no. that this Quality Inspection is referring to. This typically refers to an operation.';
        }
        field(61; "Source Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item."No.";
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the item that the Quality Inspection is for. When used with production orders this typically refers to the item being produced.';
        }
        field(62; "Source Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant"."Code" where("Item No." = field("Source Item No."));
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the item variant that the Quality Inspection is for. When used with production orders this typically refers to the item being produced.';
        }
        field(65; "Source Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the serial number that the quality inspection is for. This is only used for serial tracked items.';

            trigger OnValidate()
            begin
                if (Rec.Status = Rec.Status::Finished) and (Rec."Source Serial No." <> xRec."Source Serial No.") then
                    Error(TrackingCannotChangeForFinishedInspectionErr, Rec."No.", Rec."Re-inspection No.");

                if not GetIsCreating() then
                    QltyPermissionMgmt.VerifyCanChangeItemTracking();
            end;
        }
        field(66; "Source Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the lot number that the quality inspection is for. This is only used for lot tracked items.';

            trigger OnValidate()
            begin
                if (Rec.Status = Rec.Status::Finished) and (Rec."Source Lot No." <> xRec."Source Lot No.") then
                    Error(TrackingCannotChangeForFinishedInspectionErr, Rec."No.", Rec."Re-inspection No.");

                if not GetIsCreating() then
                    QltyPermissionMgmt.VerifyCanChangeItemTracking();
            end;
        }
        field(67; "Source Package No."; Code[50])
        {
            Caption = 'Package No.';
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies the package number that the quality inspection is for. This is only used for package tracked items.';

            trigger OnValidate()
            begin
                if (Rec.Status = Rec.Status::Finished) and (Rec."Source Package No." <> xRec."Source Package No.") then
                    Error(TrackingCannotChangeForFinishedInspectionErr, Rec."No.", Rec."Re-inspection No.");

                if not GetIsCreating() then
                    QltyPermissionMgmt.VerifyCanChangeItemTracking();
            end;
        }
        field(71; "Trigger Record Table No."; Integer)
        {
            Caption = 'Trigger Record Table No.';
            ToolTip = 'Specifies the table no. of the triggering record that caused this Quality Inspection to be created.';
            NotBlank = true;
        }
        field(72; "Trigger RecordId"; RecordId)
        {
            Caption = 'Trigger Record';
            ToolTip = 'Specifies the triggering record that caused this Quality Inspection to be created.';
            NotBlank = true;
        }
        field(75; "Source Record Table No."; Integer)
        {
            Caption = 'Source Record Table No.';
            ToolTip = 'Specifies the table no. of the source record this Quality Inspection is for.';
            NotBlank = true;
        }
        field(76; "Source RecordId"; RecordId)
        {
            Caption = 'Source Record';
            ToolTip = 'Specifies the source record this Quality Inspection is for.';
            NotBlank = true;
        }
        field(78; "Source RecordId 2"; RecordId)
        {
            Caption = 'Source Record 2';
            ToolTip = 'Specifies the secondary source record this Quality Inspection is for.';
            NotBlank = true;
        }
        field(79; "Source RecordId 3"; RecordId)
        {
            Caption = 'Source Record 3';
            ToolTip = 'Specifies the tertiary source record this Quality Inspection is for.';
            NotBlank = true;
        }
        field(80; "Source RecordId 4"; RecordId)
        {
            Caption = 'Source Record 4';
            ToolTip = 'Specifies the fourth source record this Quality Inspection is for.';
            NotBlank = true;
        }
        field(90; "Source Custom 1"; Text[60])
        {
            Caption = 'Source Custom 1';
            Editable = false;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(91; "Source Custom 2"; Text[60])
        {
            Caption = 'Source Custom 2';
            Editable = false;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(92; "Source Custom 3"; Text[60])
        {
            Caption = 'Source Custom 3';
            Editable = false;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(93; "Source Custom 4"; Text[60])
        {
            Caption = 'Source Custom 4';
            Editable = false;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(94; "Source Custom 5"; Text[60])
        {
            Caption = 'Source Custom 5';
            Editable = false;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(95; "Source Custom 6"; Text[60])
        {
            Caption = 'Source Custom 6';
            Editable = false;
            OptimizeForTextSearch = true;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(96; "Source Custom 7"; Integer)
        {
            Caption = 'Source Custom 7';
            Editable = false;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(97; "Source Custom 8"; Integer)
        {
            Caption = 'Source Custom 8';
            Editable = false;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(98; "Source Custom 9"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Source Custom 9';
            Editable = false;
            ToolTip = 'Specifies additional information from a source record.';
        }
        field(99; "Source Custom 10"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Source Custom 10';
            Editable = false;
            ToolTip = 'Specifies additional information from a source record.';
        }
    }

    keys
    {
        key(Key1; "No.", "Re-inspection No.")
        {
            Clustered = true;
        }
        key(bySource; "Template Code", "Source Table No.", "Source Type", "Source Sub Type", "Source Document No.", "Source Document Line No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Task No.")
        {
        }
        key(byCustomSource; "Template Code", "Source Custom 1", "Source Custom 2", "Source Custom 3", "Source Custom 4", "Source Custom 5", "Source Custom 6", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.")
        {
        }
        key(byAllSource; "Template Code", "Source Table No.", "Source Type", "Source Sub Type", "Source Document No.", "Source Document Line No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Task No.", "Source Custom 1", "Source Custom 2", "Source Custom 3", "Source Custom 4", "Source Custom 5", "Source Custom 6")
        {
        }
        key(byItemTracking; "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Template Code")
        {
        }
        key(byRecord; "Source Record Table No.", "Source RecordId", "Trigger Record Table No.", "Trigger RecordId")
        {
        }
        key(byTemplateAndRecord; "Template Code", "Source RecordId", "Source Record Table No.")
        {
        }
        key(byUser; SystemCreatedBy, SystemCreatedAt, "Template Code")
        {
        }
        key(byDocumentAndItemNo; "Source Document No.", "Source Document Line No.", "Source Item No.", "Source Variant Code")
        {
        }
        key(byDateAndTracking; SystemModifiedAt, SystemCreatedAt, SystemModifiedBy, SystemCreatedBy, "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.")
        {
        }
        key(StatusKey; Status, "Assigned User ID", "Planned Start Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Template Code")
        {
        }
        fieldgroup(Brick; "No.", Description, Status, "Source Item No.", "Source Document No.", "Most Recent Picture", "Result Description")
        {
        }
    }

    trigger OnDelete()
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        case Rec.Status of
            Rec.Status::Open:
                QltyPermissionMgmt.VerifyCanDeleteOpenInspection();
            Rec.Status::Finished:
                QltyPermissionMgmt.VerifyCanDeleteFinishedInspection();
        end;

        QltyInspectionLine.SetRange("Inspection No.", Rec."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", Rec."Re-inspection No.");
        QltyInspectionLine.DeleteAll();

        QltyIResultConditConf.SetRange("Condition Type", QltyIResultConditConf."Condition Type"::Inspection);
        QltyIResultConditConf.SetRange("Target Code", Rec."No.");
        QltyIResultConditConf.SetRange("Target Re-inspection No.", Rec."Re-inspection No.");
        QltyIResultConditConf.DeleteAll();
    end;

    trigger OnInsert()
    var
    begin
        InitInspectionNumber();

        UpdateMostRecentReinspection();
    end;

    trigger OnModify()
    var
        QltyStartWorkflow: Codeunit "Qlty. Start Workflow";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        PromptToAssignIfPossible: Boolean;
        UserFieldWasChanged: Boolean;
        ShouldTryAndChangePrompt: Boolean;
        ShouldPreventAutoAssignment: Boolean;
    begin
        if not IsChangingStatus then
            TestStatusOpen();

        ShouldPreventAutoAssignment := Rec.GetPreventAutoAssignment();

        if not ShouldPreventAutoAssignment then begin
            UserFieldWasChanged := xRec."Assigned User ID" <> Rec."Assigned User ID";
            case true of
                (xRec."Assigned User ID" = '') and (not UserFieldWasChanged):
                    ShouldTryAndChangePrompt := true;
                (xRec."Assigned User ID" = UserId()) and (not UserFieldWasChanged):
                    ShouldTryAndChangePrompt := false;
                (xRec."Assigned User ID" <> '') and (Rec."Assigned User ID" <> UserId()) and (not UserFieldWasChanged):
                    ShouldTryAndChangePrompt := true;
                UserFieldWasChanged:
                    ShouldTryAndChangePrompt := false;
            end;
            if ShouldTryAndChangePrompt then
                if QltyPermissionMgmt.GetShouldAutoAssign(PromptToAssignIfPossible) then
                    if PromptToAssignIfPossible and GuiAllowed() then
                        QltyNotificationMgmt.NotifyDoYouWantToAssignToYourself(Rec)
                    else
                        Rec.AssignToSelf();
        end;

        Rec.UpdateResultFromLines();

        if Rec."Planned Start Date" = 0DT then
            Rec."Planned Start Date" := CurrentDateTime();

        QltyStartWorkflow.StartWorkflowInspectionChanged(Rec, xRec);
        IsChangingStatus := false;
    end;

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        QltyTraversal: Codeunit "Qlty. Traversal";
        QltySessionHelper: Codeunit "Qlty. Session Helper";
        IsChangingStatus: Boolean;
        TrackingCannotChangeForFinishedInspectionErr: Label 'You cannot change item tracking on a finished inspection. %1-%2 is finished. Reopen this inspection to change the tracking.', Comment = '%1=Quality Inspection No., %2=Re-inspection No.';
        SampleSizeInvalidMsg: Label 'The sample size %1 is not valid on the inspection %2 because it exceeds the Source Quantity of %3. The sample size will be changed on this inspection to be the source quantity.', Comment = '%1=original sample size, %2=the inspection, %3=the source quantity';
        YouCannotChangeTheAssignmentOfTheInspectionErr: Label '%1 does not have permission to change the assigned user field on %2-%3. Permissions can be altered on the Quality Inspection function permissions.', Comment = '%1=the user, %2=the inspection no, %3=the re-inspection';
        UnableToSetTestValueErr: Label 'Unable to set the test field [%1] on the inspection [%2], there should be one matching inspection line, there are %3', Comment = '%1=the field being set, %2=the record id of the inspection, %3=the count.';
        ItemIsTrackingErr: Label 'The item [%1] is %2 tracked. Please define a %2 number before finishing the inspection. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=the item number. %2=Item tracking token';
        ItemInsufficientPostedErr: Label 'The item [%1] is %2 tracked and requires posted inventory before it can be finished. The %2 %3 has inventory of %4. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=Item number. %2=Item tracking token, %3=the Item tracking, %4=';
        ItemInsufficientPostedOrUnpostedErr: Label 'The item [%1] is %2 tracked and requires either posted inventory or a reservation entry for it before it can be finished. The %2 %3 has inventory of %4. You can change whether this is required on the Quality Management Setup card.', Comment = '%1=Item number. %2=Item tracking token, %3=Item tracking, %4=';
        LotLbl: Label 'lot', Locked = true;
        SerialLbl: Label 'serial', Locked = true;
        PackageLbl: Label 'package', Locked = true;
        ReopenInspectionQst: Label 'Are you sure you want to Reopen the inspection %1 on %2?', Comment = '%1=the inspection details, %2=the source details.';
        MoreRecentReinspectionErr: Label 'This inspection cannot be Reopened because there is a more recent Re-inspection. Please work with the most recent Re-inspection instead.';
        CreateReinspectionQst: Label 'Are you sure you want to create a Re-inspection?';
        FinishBeforeReinspectionErr: Label 'An inspection must be finished before a Re-inspection can be made. This is done automatically, but you do not have permission to finish an inspection. Ask your administrator to add the ability to finish an inspection in the Quality Inspection Permissions page.';
        PictureNameTok: Label '%1_%2_%3', Locked = true;
        FileExtensionTok: Label 'jpeg', Locked = true;
        CameraNotAvailableErr: Label 'The camera is not available. Make sure to use this with a device that has a camera supported by Business Central.';
        UnableToSavePictureErr: Label 'Unable to take or save a picture. Make sure to use this with a device that has a camera supported by Business Central.';
        UnableToFindRecordErr: Label 'Unable to show inspections with the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheItemErr: Label 'Unable to identify the item for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheTrackingErr: Label 'Unable to identify the tracking for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        UnableToIdentifyTheDocumentErr: Label 'Unable to identify the document for the supplied record. [%1]', Comment = '%1=the record being supplied.';
        ThereIsNoAttributeByTheNameOfNoItemErr: Label 'There is no item attribute by the name of [%1]', Comment = '%1=the name of the item attribute';
        KeyIsCreatingTok: Label 'IsCreating-%1', Locked = true, Comment = '%1=the record';
        AreYouSureFinishInspectionQst: Label 'Are you sure you want to Finish the inspection %1 on %2?', Comment = '%1=the inspection details, %2=the source details.';
        AutoAssignmentDecisionTok: Label 'PreventAutoAssign-%1', Locked = true, Comment = '%1=the record id to prevent auto assignment on';
        InspectionLbl: Label '%1,%2', Comment = '%1=the inspection no., %2=the re-inspection no.';
        NoItemErr: Label 'There is no source item specified for inspection %1-%2', Comment = '%1=the item, %2=the re-inspection.';
        NotLotTrackedErr: Label 'The item %1 does not appear to be lot tracked.', Comment = '%1=Item No.';
        NotSerialTrackedErr: Label 'The item %1 does not appear to be serial tracked.', Comment = '%1=Item No.';
        NotPackageTrackedErr: Label 'The item %1 does not appear to be package tracked.', Comment = '%1=Item No.';
        CannotFinishInspectionBecauseTheInspectionIsInResultErr: Label 'Cannot finish the inspection %1 because the inspection currently has the result %2, which is configured to disallow finishing.', Comment = '%1=the inspection, %2=the result code.';
        MimeTypeTok: Label 'image/jpeg', Locked = true;
        AttachmentNameTok: Label '%1.%2', Locked = true, Comment = '%1=name,%2=extension';
        PictureFileFilterTok: Label 'Pictures |*.jpg;*.png;*.jpeg;*.bmp', Locked = true;
        ImageTok: Label 'Image', Locked = true;
        PassFailQuantityInvalidErr: Label 'The %1 and %2 cannot exceed the %3. The %3 is currently exceeded by %4.', Comment = '%1=the passed quantity caption, %2=the failed quantity caption, %3=the source quantity caption, %4=the quantity exceeded';

    local procedure UpdateMostRecentReinspection()
    begin
        Rec."Most Recent Re-inspection" := true;

        ClearMostRecentReinspectionForPrecedingInspections();
    end;

    local procedure ClearMostRecentReinspectionForPrecedingInspections()
    var
        PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        if Rec."Re-inspection No." = 0 then
            exit;

        PrecedingQltyInspectionHeader.SetRange("No.", Rec."No.");
        PrecedingQltyInspectionHeader.SetFilter("Re-inspection No.", '<%1', Rec."Re-inspection No.");
        PrecedingQltyInspectionHeader.SetRange("Most Recent Re-inspection", true);
        PrecedingQltyInspectionHeader.ModifyAll("Most Recent Re-inspection", false);
    end;

    /// <summary>
    /// Helper function to set an inspection line value.
    /// </summary>
    /// <param name="NumberOrNameOfTestCode"></param>
    /// <param name="NumberOrNameOfTestValue"></param>
    procedure SetTestValue(NumberOrNameOfTestCode: Text; NumberOrNameOfTestValue: Text)
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        QltyInspectionLine.SetRange("Inspection No.", Rec."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", Rec."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", CopyStr(NumberOrNameOfTestCode, 1, MaxStrLen(QltyInspectionLine."Test Code")));
        if QltyInspectionLine.Count() <> 1 then
            Error(UnableToSetTestValueErr, NumberOrNameOfTestCode, Rec.GetFriendlyIdentifier(), QltyInspectionLine.Count);
        QltyInspectionLine.FindFirst();
        QltyInspectionLine.Validate("Test Value", CopyStr(NumberOrNameOfTestValue, 1, MaxStrLen(QltyInspectionLine."Test Value")));
        QltyInspectionLine.Modify(true);
    end;

    /// <summary>
    /// Use this to invoke the assist-edit for the given measurement test on the inspection.
    /// This presumes that the given measurement test is only used once on the inspection.
    /// </summary>
    /// <param name="NumberOrNameOfTestCode"></param>
    procedure AssistEditTest(NumberOrNameOfTestCode: Text)
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        QltyInspectionLine.SetRange("Inspection No.", Rec."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", Rec."Re-inspection No.");
        QltyInspectionLine.SetRange("Test Code", CopyStr(NumberOrNameOfTestCode, 1, MaxStrLen(QltyInspectionLine."Test Code")));
        if QltyInspectionLine.Count() <> 1 then
            Error(UnableToSetTestValueErr, NumberOrNameOfTestCode, Rec.GetFriendlyIdentifier(), QltyInspectionLine.Count);
        QltyInspectionLine.SetAutoCalcFields("Test Value Type");
        QltyInspectionLine.FindFirst();
        if QltyInspectionTemplateLine.Get(QltyInspectionLine."Template Code", QltyInspectionLine."Template Line No.") then;

        QltyInspectionLine.AssistEditTestValue();
        QltyInspectionLine.Modify(true);
    end;

    /// <summary>
    /// This will upresult the result on the test based on the results from the line.
    /// </summary>
    procedure UpdateResultFromLines()
    var
        QltyInspectionLine: Record "Qlty. Inspection Line";
        IsHandled: Boolean;
    begin
        QltyInspectionLine.SetRange("Inspection No.", Rec."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", Rec."Re-inspection No.");
        QltyInspectionLine.SetFilter("Test Value Type", '<>%1', QltyInspectionLine."Test Value Type"::"Value Type Label");
        QltyInspectionLine.SetCurrentKey("Evaluation Sequence");
        OnBeforeFindLineUpdateResultFromLines(Rec, QltyInspectionLine, IsHandled);
        if IsHandled then
            exit;

        QltyInspectionLine.SetRange("Failure State", QltyInspectionLine."Failure State"::"Failed from Acceptable Quality Level");
        if not QltyInspectionLine.FindFirst() then
            QltyInspectionLine.SetRange("Failure State");

        if QltyInspectionLine.FindFirst() then
            Rec.Validate("Result Code", QltyInspectionLine."Result Code")
        else
            Rec."Result Code" := '';

        OnAfterFindLineUpdateResultFromLines(Rec, QltyInspectionLine);
    end;

    /// <summary>
    /// InitInspectionNumber will initialize the document no. on the Quality Inspection if it's needed. If it's already set then this will not be altered.
    /// </summary>
    internal procedure InitInspectionNumber()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if Rec."No." <> '' then
            exit;

        QltyManagementSetup.GetRecordOnce();
        QltyManagementSetup.TestField("Quality Inspection Nos.");
        Rec."No." := NoSeries.GetNextNo(QltyManagementSetup."Quality Inspection Nos.", WorkDate(), true);
    end;

    /// <summary>
    /// Simple flag to let us know whether we are in-progress of creating this inspection.
    /// Decision decision: because we're passing this around as a recordref everywhere and we need that flag, we're storing in the session state instead.
    /// </summary>
    /// <param name="IsCreating"></param>
    internal procedure SetIsCreating(IsCreating: Boolean)
    begin
        QltySessionHelper.SetSessionValue(GetIsCreatingKey(), Format(IsCreating));
    end;

    /// <summary>
    /// Returns true if this record is in the middle of being created.
    /// </summary>
    /// <returns></returns>
    internal procedure GetIsCreating(): Boolean
    begin
        exit(QltySessionHelper.GetSessionValue(GetIsCreatingKey()) = Format(true));
    end;

    local procedure GetIsCreatingKey(): Text
    begin
        exit(StrSubstNo(KeyIsCreatingTok, Rec.RecordId()));
    end;

    /// <summary>
    /// Assigns the inspection to the current user.
    /// </summary>
    procedure AssignToSelf()
    begin
        if Rec."Assigned User ID" = '' then
            Rec."Assigned User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."Assigned User ID"))
        else
            if Rec."Assigned User ID" <> UserId() then begin
                QltyPermissionMgmt.VerifyCanChangeOtherInspections();
                Rec."Assigned User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."Assigned User ID"));
            end;
    end;

    /// <summary>
    /// Reopens an inspection
    /// </summary>
    procedure ReopenInspection()
    var
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        Proceed: Boolean;
        IsHandled: Boolean;
    begin
        QltyPermissionMgmt.VerifyCanReopenInspection();
        if HasMoreRecentReinspection() then
            Error(MoreRecentReinspectionErr);

        if Rec.Status = Rec.Status::Finished then begin
            if GuiAllowed() then
                Proceed := Confirm(StrSubstNo(ReopenInspectionQst, Rec.GetFriendlyIdentifier(), QltyNotificationMgmt.GetSourceSummaryText(Rec)))
            else
                Proceed := true;

            if Proceed then begin
                IsChangingStatus := true;
                OnBeforeReopenInspection(Rec, IsHandled);
                if IsHandled then
                    exit;

                Rec.Validate(Status, Rec.Status::Open);
                Rec.Modify(true);
            end;
        end;
        IsChangingStatus := false;
    end;

    /// <summary>
    /// Finishes the inspection.
    /// </summary>
    procedure FinishInspection()
    begin
        FinishInspectionAndPrompt(true);
    end;

    /// <summary>
    /// Finishes the inspection.
    /// </summary>
    local procedure FinishInspectionAndPrompt(ShowConfirmationIfInteractive: Boolean)
    var
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        Proceed: Boolean;
        IsHandled: Boolean;
        SourceDetails: Text;
    begin
        QltyPermissionMgmt.VerifyCanFinishInspection();
        SourceDetails := QltyNotificationMgmt.GetSourceSummaryText(Rec);

        VerifyTrackingBeforeFinish();

        if Rec.Status = Rec.Status::Open then begin
            if GuiAllowed() and ShowConfirmationIfInteractive then
                Proceed := Confirm(StrSubstNo(AreYouSureFinishInspectionQst, Rec.GetFriendlyIdentifier(), QltyNotificationMgmt.GetSourceSummaryText(Rec)))
            else
                Proceed := true;

            if Proceed then begin
                IsChangingStatus := true;
                OnBeforeFinishInspection(Rec, IsHandled);
                if IsHandled then
                    exit;

                Rec.Validate(Status, Rec.Status::Finished);
                Rec.Get(Rec.RecordId());

                Rec.Modify(true);
            end;
        end;
        IsChangingStatus := false;
    end;

    internal procedure VerifyTrackingBeforeFinish()
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        PostedQuantity: Decimal;
        ReservedQuantity: Decimal;
    begin
        QltyManagementSetup.Get();
        if QltyManagementSetup."Item Tracking Before Finishing" = QltyManagementSetup."Item Tracking Before Finishing"::"Allow without Item Tracking" then
            exit;

        TempItemTrackingSetup."Lot No. Required" := true;
        TempItemTrackingSetup."Serial No. Required" := true;
        TempItemTrackingSetup."Package No. Required" := true;
        Rec.IsItemTrackingUsed(TempItemTrackingSetup);
        if (not TempItemTrackingSetup."Lot No. Required") and (not TempItemTrackingSetup."Serial No. Required") and (not TempItemTrackingSetup."Package No. Required") then
            exit;

        if TempItemTrackingSetup."Lot No. Required" and (Rec."Source Lot No." = '') then
            Error(ItemIsTrackingErr, Rec."Source Item No.", LotLbl);

        if TempItemTrackingSetup."Serial No. Required" and (Rec."Source Serial No." = '') then
            Error(ItemIsTrackingErr, Rec."Source Item No.", SerialLbl);

        if TempItemTrackingSetup."Package No. Required" and (Rec."Source Package No." = '') then
            Error(ItemIsTrackingErr, Rec."Source Item No.", PackageLbl);

        PostedQuantity := Rec.GetPostedInventory();
        case QltyManagementSetup."Item Tracking Before Finishing" of
            QltyManagementSetup."Item Tracking Before Finishing"::"Allow only posted Item Tracking":
                if PostedQuantity = 0 then
                    case true of
                        TempItemTrackingSetup."Serial No. Required":
                            Error(ItemInsufficientPostedErr, Rec."Source Item No.", SerialLbl, Rec."Source Serial No.", PostedQuantity);
                        TempItemTrackingSetup."Lot No. Required":
                            Error(ItemInsufficientPostedErr, Rec."Source Item No.", LotLbl, Rec."Source Lot No.", PostedQuantity);
                        TempItemTrackingSetup."Package No. Required":
                            Error(ItemInsufficientPostedErr, Rec."Source Item No.", PackageLbl, Rec."Source Package No.", PostedQuantity);
                    end;
            QltyManagementSetup."Item Tracking Before Finishing"::"Allow reserved or posted Item Tracking":
                begin
                    if PostedQuantity <= 0 then
                        ReservedQuantity := Rec.GetReservedInventory();

                    if (PostedQuantity = 0) and (ReservedQuantity = 0) then
                        case true of
                            TempItemTrackingSetup."Serial No. Required":
                                Error(ItemInsufficientPostedOrUnpostedErr, Rec."Source Item No.", SerialLbl, Rec."Source Serial No.", PostedQuantity);
                            TempItemTrackingSetup."Lot No. Required":
                                Error(ItemInsufficientPostedOrUnpostedErr, Rec."Source Item No.", LotLbl, Rec."Source Lot No.", PostedQuantity);
                            TempItemTrackingSetup."Package No. Required":
                                Error(ItemInsufficientPostedOrUnpostedErr, Rec."Source Item No.", PackageLbl, Rec."Source Package No.", PostedQuantity);
                        end;
                end;
        end;
    end;

    /// <summary>
    /// Returns the posted inventory for the item/variant
    /// </summary>
    /// <returns></returns>
    internal procedure GetPostedInventory() PostedInventory: Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        TempItemTrackingSetup."Lot No. Required" := true;
        TempItemTrackingSetup."Serial No. Required" := true;
        TempItemTrackingSetup."Package No. Required" := true;
        Rec.IsItemTrackingUsed(TempItemTrackingSetup);

        ItemLedgerEntry.SetRange("Item No.", Rec."Source Item No.");
        ItemLedgerEntry.SetRange("Variant Code", Rec."Source Variant Code");
        if TempItemTrackingSetup."Lot No. Required" then
            ItemLedgerEntry.SetRange("Lot No.", Rec."Source Lot No.");
        if TempItemTrackingSetup."Serial No. Required" then
            ItemLedgerEntry.SetRange("Serial No.", Rec."Source Serial No.");
        if TempItemTrackingSetup."Package No. Required" then
            ItemLedgerEntry.SetRange("Package No.", Rec."Source Package No.");

        ItemLedgerEntry.CalcSums(Quantity);
        PostedInventory := ItemLedgerEntry.Quantity;
    end;

    internal procedure GetReservedInventory() ReservedInventory: Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        TempItemTrackingSetup."Lot No. Required" := true;
        TempItemTrackingSetup."Serial No. Required" := true;
        TempItemTrackingSetup."Package No. Required" := true;
        Rec.IsItemTrackingUsed(TempItemTrackingSetup);

        ReservationEntry.SetRange("Item No.", Rec."Source Item No.");
        ReservationEntry.SetRange("Variant Code", Rec."Source Variant Code");
        if TempItemTrackingSetup."Lot No. Required" then
            ReservationEntry.SetRange("Lot No.", Rec."Source Lot No.");
        if TempItemTrackingSetup."Serial No. Required" then
            ReservationEntry.SetRange("Serial No.", Rec."Source Serial No.");
        if TempItemTrackingSetup."Package No. Required" then
            ReservationEntry.SetRange("Package No.", Rec."Source Package No.");

        ReservationEntry.CalcSums("Quantity (Base)");
        ReservedInventory := ReservationEntry."Quantity (Base)";
    end;

    /// <summary>
    /// Creates a Re-inspection
    /// </summary>
    procedure CreateReinspection()
    var
        NewlyCreatedReQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        Proceed: Boolean;
    begin
        QltyPermissionMgmt.VerifyCanCreateReinspection();

        if Rec.Status = Rec.Status::Open then begin
            if not QltyPermissionMgmt.CanFinishInspection() then
                Error(FinishBeforeReinspectionErr);
            FinishInspectionAndPrompt(false);
        end;

        if GuiAllowed() then
            Proceed := Confirm(CreateReinspectionQst)
        else
            Proceed := true;
        if Proceed then
            QltyInspectionCreate.CreateReinspection(Rec, NewlyCreatedReQltyInspectionHeader);
    end;

    /// <summary>
    /// Returns true if there is a more recent re-inspection than the current inspection.
    /// </summary>
    /// <returns></returns>
    internal procedure HasMoreRecentReinspection(): Boolean
    var
        SucceedingQltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        SucceedingQltyInspectionHeader.SetRange("No.", Rec."No.");
        SucceedingQltyInspectionHeader.SetFilter("Re-inspection No.", '>%1', Rec."Re-inspection No.");
        exit(not SucceedingQltyInspectionHeader.IsEmpty());
    end;

    internal procedure IsItemTrackingUsed(): Boolean
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        exit(QltyItemTracking.IsItemTrackingUsed(Rec."Source Item No."));
    end;

    /// <summary>
    /// If this inspection is associated with an item that requires item tracking of any type.
    /// </summary>
    /// <returns></returns>
    internal procedure IsItemTrackingUsed(var TempItemTrackingSetup: Record "Item Tracking Setup" temporary): Boolean
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
    begin
        exit(QltyItemTracking.IsItemTrackingUsed(Rec."Source Item No.", TempItemTrackingSetup));
    end;

    internal procedure GetControlCaptionClass(Input: Text): Text
    begin
        exit(QltyTraversal.GetControlCaptionClass(Rec, Input));
    end;

    internal procedure GetControlVisibleState(Input: Text) Visible: Boolean;
    begin
        Visible := QltyTraversal.GetControlVisibleState(Rec, Input);
    end;

    internal procedure DetermineControlInformation(Input: Text)
    begin
        QltyTraversal.DetermineControlInformation(Rec, Input);
    end;

    procedure AssistEditLotNo();
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        LoopAgainBecauseSpecialFlag: Boolean;
        OnlyForTheDocument: Boolean;
    begin
        if Rec."Source Item No." = '' then
            Error(NoItemErr, Rec."No.", Rec."Re-inspection No.");

        TempItemTrackingSetup."Lot No. Required" := true;
        QltyItemTracking.IsItemTrackingUsed(Rec."Source Item No.", TempItemTrackingSetup);
        if not TempItemTrackingSetup."Lot No. Required" then
            Error(NotLotTrackedErr, Rec."Source Item No.");

        QltyPermissionMgmt.VerifyCanChangeItemTracking();

        OnlyForTheDocument := true;

        repeat
            Clear(TempTrackingSpecification);
            Clear(ItemTrackingDataCollection);
            LoopAgainBecauseSpecialFlag := false;
            QltySessionHelper.SetTrackingFormModeFlag('');
            TempTrackingSpecification."Item No." := Rec."Source Item No.";
            TempTrackingSpecification."Variant Code" := CopyStr(Rec."Source Variant Code", 1, MaxStrLen(TempTrackingSpecification."Variant Code"));
            TempTrackingSpecification."Lot No." := Rec."Source Lot No.";
            TempTrackingSpecification."Source Type" := Database::"Qlty. Inspection Header";
            if OnlyForTheDocument then begin
                if Rec."Source Document No." <> '' then begin
                    TempTrackingSpecification."Source ID" := Rec."Source Document No.";
                    TempTrackingSpecification."Source Ref. No." := Rec."Source Document Line No.";
                end;
            end else begin
                TempTrackingSpecification."Source ID" := '';
                TempTrackingSpecification."Source Ref. No." := 0;
            end;

            QltySessionHelper.SetStartingFromQualityManagementFlag();

            QltySessionHelper.SetTrackingFormModeFlag('');
            ItemTrackingDataCollection.AssistEditTrackingNo(TempTrackingSpecification, true, 1, "Item Tracking Type"::"Lot No.", 0);
            case QltySessionHelper.GetTrackingFormModeFlag() of
                QltySessionHelper.GetTrackingFormFlagValueAllDocs():
                    begin
                        LoopAgainBecauseSpecialFlag := true;
                        OnlyForTheDocument := false;
                        TempTrackingSpecification."Source ID" := '';
                        TempTrackingSpecification."Source Ref. No." := 0;
                    end;
                QltySessionHelper.GetTrackingFormFlagValueSourceDoc():
                    begin
                        LoopAgainBecauseSpecialFlag := true;
                        OnlyForTheDocument := true;
                        TempTrackingSpecification."Source ID" := '';
                        TempTrackingSpecification."Source Ref. No." := 0;
                    end;
            end;
            QltySessionHelper.SetTrackingFormModeFlag('');
        until (not LoopAgainBecauseSpecialFlag);

        if TempTrackingSpecification."Lot No." <> Rec."Source Lot No." then begin
            Rec."Source Lot No." := TempTrackingSpecification."Lot No.";
            if not Rec.IsTemporary() then
                Rec.Modify();
        end;
    end;

    procedure AssistEditPackageNo()
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        LoopAgainBecauseSpecialFlag: Boolean;
        OnlyForTheDocument: Boolean;
    begin
        if Rec."Source Item No." = '' then
            Error(NoItemErr, Rec."No.", Rec."Re-inspection No.");

        TempItemTrackingSetup."Package No. Required" := true;
        QltyItemTracking.IsItemTrackingUsed(Rec."Source Item No.", TempItemTrackingSetup);
        if not TempItemTrackingSetup."Package No. Required" then
            Error(NotPackageTrackedErr, Rec."Source Item No.");

        QltyPermissionMgmt.VerifyCanChangeItemTracking();

        OnlyForTheDocument := true;

        repeat
            Clear(TempTrackingSpecification);
            Clear(ItemTrackingDataCollection);
            LoopAgainBecauseSpecialFlag := false;
            QltySessionHelper.SetTrackingFormModeFlag('');
            TempTrackingSpecification."Item No." := Rec."Source Item No.";
            TempTrackingSpecification."Variant Code" := CopyStr(Rec."Source Variant Code", 1, MaxStrLen(TempTrackingSpecification."Variant Code"));
            TempTrackingSpecification."Package No." := Rec."Source Package No.";
            TempTrackingSpecification."Source Type" := Database::"Qlty. Inspection Header";
            if OnlyForTheDocument then begin
                if Rec."Source Document No." <> '' then begin
                    TempTrackingSpecification."Source ID" := Rec."Source Document No.";
                    TempTrackingSpecification."Source Ref. No." := Rec."Source Document Line No.";
                end;
            end else begin
                TempTrackingSpecification."Source ID" := '';
                TempTrackingSpecification."Source Ref. No." := 0;
            end;
            QltySessionHelper.SetStartingFromQualityManagementFlag();
            QltySessionHelper.SetTrackingFormModeFlag('');
            ItemTrackingDataCollection.AssistEditTrackingNo(TempTrackingSpecification, true, 1, "Item Tracking Type"::"Package No.", 0);
            case QltySessionHelper.GetTrackingFormModeFlag() of
                QltySessionHelper.GetTrackingFormFlagValueAllDocs():
                    begin
                        LoopAgainBecauseSpecialFlag := true;
                        OnlyForTheDocument := false;
                        TempTrackingSpecification."Source ID" := '';
                        TempTrackingSpecification."Source Ref. No." := 0;
                    end;
                QltySessionHelper.GetTrackingFormFlagValueSourceDoc():
                    begin
                        LoopAgainBecauseSpecialFlag := true;
                        OnlyForTheDocument := true;
                        TempTrackingSpecification."Source ID" := '';
                        TempTrackingSpecification."Source Ref. No." := 0;
                    end;
            end;
            QltySessionHelper.SetTrackingFormModeFlag('');
        until (not LoopAgainBecauseSpecialFlag);

        if TempTrackingSpecification."Package No." <> Rec."Source Package No." then begin
            Rec."Source Package No." := TempTrackingSpecification."Package No.";
            if not Rec.IsTemporary() then
                Rec.Modify();
        end;
    end;

    procedure AssistEditSerialNo();
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        LoopAgainBecauseSpecialFlag: Boolean;
        OnlyForTheDocument: Boolean;
    begin
        if Rec."Source Item No." = '' then
            Error(NoItemErr, Rec."No.", Rec."Re-inspection No.");

        TempItemTrackingSetup."Serial No. Required" := true;
        QltyItemTracking.IsItemTrackingUsed(Rec."Source Item No.", TempItemTrackingSetup);
        if not TempItemTrackingSetup."Serial No. Required" then
            Error(NotSerialTrackedErr, Rec."Source Item No.");

        QltyPermissionMgmt.VerifyCanChangeItemTracking();

        OnlyForTheDocument := true;

        repeat
            Clear(TempTrackingSpecification);
            Clear(ItemTrackingDataCollection);
            LoopAgainBecauseSpecialFlag := false;
            QltySessionHelper.SetTrackingFormModeFlag('');
            TempTrackingSpecification."Item No." := Rec."Source Item No.";
            TempTrackingSpecification."Variant Code" := CopyStr(Rec."Source Variant Code", 1, MaxStrLen(TempTrackingSpecification."Variant Code"));
            TempTrackingSpecification."Serial No." := Rec."Source Serial No.";
            TempTrackingSpecification."Source Type" := Database::"Qlty. Inspection Header";
            if OnlyForTheDocument then begin
                if Rec."Source Document No." <> '' then
                    TempTrackingSpecification."Source ID" := Rec."Source Document No.";
            end else
                TempTrackingSpecification."Source ID" := '';

            QltySessionHelper.SetStartingFromQualityManagementFlag();

            QltySessionHelper.SetTrackingFormModeFlag('');
            ItemTrackingDataCollection.AssistEditTrackingNo(TempTrackingSpecification, true, 1, "Item Tracking Type"::"Serial No.", 0);
            case QltySessionHelper.GetTrackingFormModeFlag() of
                QltySessionHelper.GetTrackingFormFlagValueAllDocs():
                    begin
                        LoopAgainBecauseSpecialFlag := true;
                        OnlyForTheDocument := false;
                        TempTrackingSpecification."Source ID" := '';
                    end;
                QltySessionHelper.GetTrackingFormFlagValueSourceDoc():
                    begin
                        LoopAgainBecauseSpecialFlag := true;
                        OnlyForTheDocument := true;
                        TempTrackingSpecification."Source ID" := '';
                    end;
            end;
            QltySessionHelper.SetTrackingFormModeFlag('');
        until (not LoopAgainBecauseSpecialFlag);

        if TempTrackingSpecification."Serial No." <> Rec."Source Serial No." then begin
            Rec."Source Serial No." := TempTrackingSpecification."Serial No.";
            if not Rec.IsTemporary() then
                Rec.Modify();
        end;
    end;

    local procedure TestStatusOpen()
    begin
        Rec.TestField(Status, Rec.Status::Open);
    end;

    local procedure ProcessFinishInspection()
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyStartWorkflow: Codeunit "Qlty. Start Workflow";
    begin
        if Rec.Status <> Rec.Status::Finished then
            exit;

        if QltyInspectionResult.Get(Rec."Result Code") then
            if QltyInspectionResult."Finish Allowed" <> QltyInspectionResult."Finish Allowed"::"Allow Finish" then
                Error(CannotFinishInspectionBecauseTheInspectionIsInResultErr, Rec."No.", QltyInspectionResult.Code);

        Rec."Finished By User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."Finished By User ID"));
        Rec."Finished Date" := CurrentDateTime();
        Rec.Modify(false);

        OnInspectionFinished(Rec);

        QltyStartWorkflow.StartWorkflowInspectionFinished(Rec);
    end;

    local procedure ProcessReopenInspection()
    var
        QltyStartWorkflow: Codeunit "Qlty. Start Workflow";
    begin
        if xRec.Status <> xRec.Status::Finished then
            exit;
        if Rec.Status <> Rec.Status::Open then
            exit;

        Rec.Modify(false);

        OnInspectionReopen(Rec);

        QltyStartWorkflow.StartWorkflowInspectionReopens(Rec);
    end;

    /// <summary>
    /// Sets record filters based on the supplied variant and flags on whether it should be finding related inspections for the item, document, or something else.
    /// </summary>
    /// <param name="ErrorIfMissingFilter"></param>
    /// <param name="RecordVariant"></param>
    /// <param name="UseItem"></param>
    /// <param name="UseTracking"></param>
    /// <param name="UseDocument"></param>
    procedure SetRecordFiltersToFindInspectionFor(ErrorIfMissingFilter: Boolean; RecordVariant: Variant; UseItem: Boolean; UseTracking: Boolean; UseDocument: Boolean)
    var
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        TargetRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        OnBeforeSetRecordFiltersToFindInspectionFor(Rec, ErrorIfMissingFilter, RecordVariant, UseItem, UseTracking, UseDocument, IsHandled);
        if IsHandled then
            exit;

        if not QltyMiscHelpers.GetRecordRefFromVariant(RecordVariant, TargetRecordRef) then
            Error(UnableToFindRecordErr, RecordVariant);

        if not QltyTraversal.ApplySourceFields(TargetRecordRef, TempQltyInspectionHeader, true, false) then
            Error(UnableToFindRecordErr, TargetRecordRef.RecordId());
        TempQltyInspectionHeader.SetRecFilter();
        if UseItem then begin
            if (TempQltyInspectionHeader."Source Item No." = '') and ErrorIfMissingFilter then
                Error(UnableToIdentifyTheItemErr, TargetRecordRef.RecordId());

            if TempQltyInspectionHeader."Source Item No." <> '' then
                Rec.SetRange("Source Item No.", TempQltyInspectionHeader."Source Item No.");

            if TempQltyInspectionHeader."Source Variant Code" <> '' then
                Rec.SetRange("Source Variant Code", TempQltyInspectionHeader."Source Variant Code");
        end;
        if UseTracking then begin
            if (TempQltyInspectionHeader."Source Lot No." = '') and (TempQltyInspectionHeader."Source Serial No." = '') and (TempQltyInspectionHeader."Source Package No." = '') and ErrorIfMissingFilter then
                Error(UnableToIdentifyTheTrackingErr, TargetRecordRef.RecordId());
            if TempQltyInspectionHeader."Source Lot No." <> '' then
                Rec.SetRange("Source Lot No.", TempQltyInspectionHeader."Source Lot No.");
            if TempQltyInspectionHeader."Source Serial No." <> '' then
                Rec.SetRange("Source Serial No.", TempQltyInspectionHeader."Source Serial No.");
            if TempQltyInspectionHeader."Source Package No." <> '' then
                Rec.SetRange("Source Package No.", TempQltyInspectionHeader."Source Package No.");
        end;
        if UseDocument then begin
            if (TempQltyInspectionHeader."Source Document No." = '') and ErrorIfMissingFilter then
                Error(UnableToIdentifyTheDocumentErr, TargetRecordRef.RecordId());

            if TempQltyInspectionHeader."Source Document No." <> '' then
                Rec.SetRange("Source Document No.", TempQltyInspectionHeader."Source Document No.");
        end;

        OnAfterSetRecordFiltersToFindInspectionFor(Rec, ErrorIfMissingFilter, RecordVariant, UseItem, UseTracking, UseDocument);
    end;

    internal procedure GetMostRecentInspectionFor(RecordVariant: Variant) Success: Boolean
    begin
        Rec.SetRecordFiltersToFindInspectionFor(false, RecordVariant, true, true, true);
        Rec.SetCurrentKey("No.", "Re-inspection No.");
        Rec.Ascending(false);
        Success := Rec.FindFirst();
    end;

    internal procedure PrintCertificateOfAnalysis()
    var
        QltyReportMgmt: Codeunit "Qlty. Report Mgmt.";
    begin
        QltyReportMgmt.PrintCertificateOfAnalysis(Rec);
    end;

    internal procedure PrintNonConformance()
    var
        QltyReportMgmt: Codeunit "Qlty. Report Mgmt.";
    begin
        QltyReportMgmt.PrintNonConformance(Rec);
    end;

    internal procedure PrintGeneralPurposeInspection()
    var
        QltyReportMgmt: Codeunit "Qlty. Report Mgmt.";
    begin
        QltyReportMgmt.PrintGeneralPurposeInspection(Rec);
    end;

    /// <summary>
    /// Intended for use with PowerAutomate and Dataverse.
    /// It will return the 'best' reference in the order of preference of:
    ///  -- triggering record
    ///  -- otherwise primary source record
    ///  -- otherwise secondary source record
    ///  -- otherwise tertiary source record.
    ///  -- otherwise fourth source record.
    ///  -- otherwise a null guid.
    /// </summary>
    /// <returns></returns>
    internal procedure GetReferenceRecordId(): Guid
    var
        RelatedSourceRecordRef: RecordRef;
        NullForComparison: RecordId;
    begin
        if Rec."Trigger RecordId" <> NullForComparison then
            if Rec."Trigger RecordId".TableNo() <> 0 then begin
                RelatedSourceRecordRef.Open(Rec."Trigger RecordId".TableNo());
                if RelatedSourceRecordRef.Get(Rec."Trigger RecordId") then
                    if RelatedSourceRecordRef.SystemIdNo() > 0 then
                        exit(RelatedSourceRecordRef.Field(RelatedSourceRecordRef.SystemIdNo()).Value());
                RelatedSourceRecordRef.Close();
            end;

        if Rec."Source RecordId" <> NullForComparison then
            if Rec."Source RecordId".TableNo() <> 0 then begin
                RelatedSourceRecordRef.Open(Rec."Source RecordId".TableNo());
                if RelatedSourceRecordRef.Get(Rec."Source RecordId") then
                    if RelatedSourceRecordRef.SystemIdNo() > 0 then
                        exit(RelatedSourceRecordRef.Field(RelatedSourceRecordRef.SystemIdNo()).Value());
                RelatedSourceRecordRef.Close();
            end;

        if Rec."Source RecordId 2" <> NullForComparison then
            if Rec."Source RecordId 2".TableNo() <> 0 then begin
                RelatedSourceRecordRef.Open(Rec."Source RecordId 2".TableNo());
                if RelatedSourceRecordRef.Get(Rec."Source RecordId 2") then
                    if RelatedSourceRecordRef.SystemIdNo() > 0 then
                        exit(RelatedSourceRecordRef.Field(RelatedSourceRecordRef.SystemIdNo()).Value());
                RelatedSourceRecordRef.Close();
            end;

        if Rec."Source RecordId 3" <> NullForComparison then
            if Rec."Source RecordId 3".TableNo() <> 0 then begin
                RelatedSourceRecordRef.Open(Rec."Source RecordId 3".TableNo());
                if RelatedSourceRecordRef.Get(Rec."Source RecordId 3") then
                    if RelatedSourceRecordRef.SystemIdNo() > 0 then
                        exit(RelatedSourceRecordRef.Field(RelatedSourceRecordRef.SystemIdNo()).Value());
                RelatedSourceRecordRef.Close();
            end;

        if Rec."Source RecordId 4" <> NullForComparison then
            if Rec."Source RecordId 4".TableNo() <> 0 then begin
                RelatedSourceRecordRef.Open(Rec."Source RecordId 4".TableNo());
                if RelatedSourceRecordRef.Get(Rec."Source RecordId 4") then
                    if RelatedSourceRecordRef.SystemIdNo() > 0 then
                        exit(RelatedSourceRecordRef.Field(RelatedSourceRecordRef.SystemIdNo()).Value());
                RelatedSourceRecordRef.Close();
            end;
    end;

    /// <summary>
    /// Use SetPreventAutoAssignment to set whether or not we should prevent auto-assignment for this inspection
    /// </summary>
    /// <param name="ShouldPrevent"></param>
    internal procedure SetPreventAutoAssignment(ShouldPrevent: Boolean)
    begin
        QltySessionHelper.SetSessionValue(GetPreventAutoAssignmentKey(), Format(ShouldPrevent));
    end;

    /// <summary>
    /// Use GetPreventAutoAssignment to determine if you should prevent automatically assigning.
    /// </summary>
    /// <returns></returns>
    procedure GetPreventAutoAssignment() Result: Boolean
    var
        TempValue: Text;
    begin
        TempValue := QltySessionHelper.GetSessionValue(GetPreventAutoAssignmentKey());
        if TempValue <> '' then
            if Evaluate(Result, TempValue) then;
    end;

    local procedure GetPreventAutoAssignmentKey(): Text
    begin
        exit(StrSubstNo(AutoAssignmentDecisionTok, Rec.RecordId()));
    end;

    local procedure UpdateSampleSize()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        if not QltyInspectionTemplateHdr.Get(Rec."Template Code") then
            exit;

        case QltyInspectionTemplateHdr."Sample Source" of
            QltyInspectionTemplateHdr."Sample Source"::"Fixed Quantity":
                Rec.Validate("Sample Size", QltyInspectionTemplateHdr."Sample Fixed Amount");
            QltyInspectionTemplateHdr."Sample Source"::"Percent of Quantity":
                Rec.Validate("Sample Size", Round(Rec."Source Quantity (Base)" * QltyInspectionTemplateHdr."Sample Percentage" / 100.0, 1, '>'));
        end;
    end;

    /// <summary>
    /// Gets the related item
    /// </summary>
    /// <param name="Item"></param>
    /// <returns></returns>
    procedure GetRelatedItem(var Item: Record Item): Boolean
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        TriggerAsRecordRef: RecordRef;
        NullForComparison: RecordId;
    begin
        if Rec."Source Item No." <> '' then
            exit(Item.Get(Rec."Source Item No."));

        if NullForComparison = Rec."Trigger RecordId" then
            exit(false);

        if not QltyMiscHelpers.GetRecordRefFromVariant(Rec."Trigger RecordId", TriggerAsRecordRef) then
            exit(false);

        exit(QltyTraversal.FindRelatedItem(Item, TriggerAsRecordRef, Rec."Source RecordId", Rec."Source RecordId 2", Rec."Source RecordId 3", Rec."Source RecordId 4"));
    end;

    /// <summary>
    /// Gets an item attribute value by the specified item attribute name.
    /// </summary>
    /// <param name="ItemAttributeName"></param>
    /// <returns></returns>
    procedure GetItemAttributeValue(ItemAttributeName: Text) FoundItemAttributeValue: Text
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttribute.SetRange(Name, CopyStr(ItemAttributeName, 1, MaxStrLen(ItemAttribute.Name)));
        if not ItemAttribute.FindFirst() then
            Error(ThereIsNoAttributeByTheNameOfNoItemErr, ItemAttributeName);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ItemAttribute.ID);
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", Rec."Source Item No.");
        if ItemAttributeValueMapping.FindFirst() then begin
            ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
            ItemAttributeValue.SetRange(ID, ItemAttributeValueMapping."Item Attribute Value ID");
            if ItemAttributeValue.FindFirst() then
                FoundItemAttributeValue := ItemAttributeValue.Value;
        end;
    end;

    /// <summary>
    ///Returns the quantity of samples with acceptable measures for all sampling fields.
    ///If no sampling fields, will return the sample size if all measures are acceptable.
    /// </summary>
    /// <returns>Quantity of samples</returns>
    internal procedure GetPassSampleQuantity() PassQuantity: Decimal
    begin
    end;

    /// <summary>
    ///Returns the quantity of samples with any not acceptable measure for all sampling fields.
    ///If no sampling fields, will return the sample size if any measures are not acceptable.
    /// </summary>
    /// <returns>Quantity of samples</returns>
    internal procedure GetFailedSampleQuantity() FailQuantity: Decimal
    begin
    end;

    /// <summary>
    /// Initializes the Qlty. Related Transfers page with the Quality Inspection record and runs it
    /// </summary>
    internal procedure RunModalRelatedTransfers()
    var
        QltyRelatedTransferOrders: Page "Qlty. Related Transfer Orders";
    begin
        QltyRelatedTransferOrders.InitializeWithInspection(Rec);
        QltyRelatedTransferOrders.RunModal();
    end;

    /// <summary>
    /// Returns the Inspection No. and Re-inspection No. (if not 0) in the format No.,Re-inspection No.
    /// </summary>
    /// <returns>Text of No.,Re-inspection No.</returns>
    procedure GetFriendlyIdentifier(): Text
    begin
        exit((Rec."Re-inspection No." = 0) ? Rec."No." : StrSubstNo(InspectionLbl, Rec."No.", Rec."Re-inspection No."));
    end;

    local procedure VerifyPassAndFailQuantities()
    var
        DifferenceInPassFailQuantity: Decimal;
    begin
        if (Rec."Pass Quantity" + Rec."Fail Quantity") > Rec."Source Quantity (Base)" then begin
            DifferenceInPassFailQuantity := Rec."Pass Quantity" + Rec."Fail Quantity" - Rec."Source Quantity (Base)";
            Error(PassFailQuantityInvalidErr, Rec.FieldCaption("Pass Quantity"), Rec.FieldCaption("Fail Quantity"), Rec.FieldCaption("Source Quantity (Base)"), DifferenceInPassFailQuantity);
        end;
    end;

    #region Most Recent Picture Management
    /// <summary>
    /// This will use the camera to take a picture and add it to the Inspection document.
    /// </summary>
    /// <returns></returns>
    internal procedure TakeNewMostRecentPicture()
    var
        Camera: Codeunit Camera;
        PictureInStream: InStream;
        PictureName, FullFileNameWithExtension : Text;
    begin
        TestStatusOpen();

        QltyManagementSetup.GetRecordOnce();
        QltyManagementSetup.SanityCheckPictureAndCameraSettings();

        if not Camera.IsAvailable() then
            Error(CameraNotAvailableErr);

        if not Camera.GetPicture(PictureInStream, PictureName) then
            Error(UnableToSavePictureErr);

        PictureName := StrSubstNo(PictureNameTok, Rec."No.", Rec."Re-inspection No.", CurrentDateTime());
        PictureName := DelChr(PictureName, '=', ' ><{}.@!`~''"|\/?&*():');

        FullFileNameWithExtension := PictureName;
        if not FullFileNameWithExtension.Contains('.') then
            FullFileNameWithExtension := StrSubstNo(AttachmentNameTok, FullFileNameWithExtension, FileExtensionTok);

        AddMostRecentPicture(PictureInStream, PictureName, MimeTypeTok);
        ProcessAdditionalPictureHandling(PictureInStream, PictureName, FileExtensionTok, FullFileNameWithExtension);
    end;

    internal procedure ImportMostRecentPicture()
    var
        FileManagement: Codeunit "File Management";
        QltyFileImport: Codeunit "Qlty. File Import";
        PictureInStream: InStream;
        PictureName, FileExtension, FullFileNameWithExtension : Text;
    begin
        TestStatusOpen();

        if not QltyFileImport.PromptAndImportIntoInStream(PictureFileFilterTok, PictureInStream, FullFileNameWithExtension) then
            exit;

        if not FullFileNameWithExtension.Contains('.') then begin
            PictureName := FileManagement.GetFileName(FullFileNameWithExtension);
            FileExtension := FileExtensionTok;
            FullFileNameWithExtension := StrSubstNo(AttachmentNameTok, FullFileNameWithExtension, FileExtensionTok);
        end else begin
            PictureName := FileManagement.GetFileName(FullFileNameWithExtension);
            FileExtension := FileManagement.GetExtension(FullFileNameWithExtension);
        end;

        AddMostRecentPicture(PictureInStream, ImageTok, '');
        ProcessAdditionalPictureHandling(PictureInStream, PictureName, FileExtension, FullFileNameWithExtension);
    end;

    internal procedure DeleteMostRecentPicture()
    begin
        Clear(Rec."Most Recent Picture");
        Rec.Modify(true);
    end;

    /// <summary>
    /// Adds the supplied InStream to the Inspection document as "Most Recent Picture".
    /// </summary>
    /// <param name="PictureInStream"></param>
    /// <param name="PictureName"></param>
    /// <param name="MimeType"></param>
    /// <returns></returns>
    local procedure AddMostRecentPicture(var PictureInStream: InStream; PictureName: Text; MimeType: Text)
    begin
        Clear(Rec."Most Recent Picture");
        if MimeType <> '' then
            Rec."Most Recent Picture".ImportStream(PictureInStream, PictureName, MimeType)
        else
            Rec."Most Recent Picture".ImportStream(PictureInStream, PictureName);
        Rec.Modify();
    end;

    local procedure ProcessAdditionalPictureHandling(var PictureInStream: InStream; PictureName: Text; FileExtension: Text; FullFileNameWithExtension: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentServiceManagement: Codeunit "Document Service Management";
        RecordRefToQltyInspectionHeader: RecordRef;
    begin
        QltyManagementSetup.GetRecordOnce();
        if QltyManagementSetup."Additional Picture Handling" in [QltyManagementSetup."Additional Picture Handling"::"Save as attachment", QltyManagementSetup."Additional Picture Handling"::"Save as attachment and upload to OneDrive"] then begin
            RecordRefToQltyInspectionHeader.GetTable(Rec);
            DocumentAttachment.SaveAttachmentFromStream(PictureInStream, RecordRefToQltyInspectionHeader, FullFileNameWithExtension);
        end;

        if QltyManagementSetup."Additional Picture Handling" = QltyManagementSetup."Additional Picture Handling"::"Save as attachment and upload to OneDrive" then
            if DocumentServiceManagement.IsConfigured() then
                DocumentServiceManagement.ShareWithOneDrive(PictureName, FileExtension, PictureInStream);
    end;
    #endregion Most Recent Picture Management

    /// <summary>
    /// Use to supplement or replace default system behavior of finding related inspections.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="ErrorIfMissingFilter"></param>
    /// <param name="RecordVariant"></param>
    /// <param name="UseItem"></param>
    /// <param name="UseTracking"></param>
    /// <param name="UseDocument"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetRecordFiltersToFindInspectionFor(var QltyInspectionHeader: Record "Qlty. Inspection Header"; ErrorIfMissingFilter: Boolean; RecordVariant: Variant; UseItem: Boolean; UseTracking: Boolean; var UseDocument: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Use to supplement existing behavior of finding related inspections.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="ErrorIfMissingFilter"></param>
    /// <param name="RecordVariant"></param>
    /// <param name="UseItem"></param>
    /// <param name="UseTracking"></param>
    /// <param name="UseDocument"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRecordFiltersToFindInspectionFor(var QltyInspectionHeader: Record "Qlty. Inspection Header"; ErrorIfMissingFilter: Boolean; RecordVariant: Variant; UseItem: Boolean; UseTracking: Boolean; var UseDocument: Boolean)
    begin
    end;

    /// <summary>
    /// Triggers when the inspection has finished.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    [IntegrationEvent(false, false)]
    local procedure OnInspectionFinished(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
    end;

    /// <summary>
    /// Triggers when an inspection re-opens.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    [IntegrationEvent(false, false)]
    local procedure OnInspectionReopen(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
    end;

    /// <summary>
    /// OnBeforeReopenInspection is called before an inspection is Reopened.
    /// </summary>
    /// <param name="QltyInspectionHeader">The quality Inspection involved</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenInspection(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// OnBeforeFinishInspection is called before an inspection is finished.
    /// </summary>
    /// <param name="QltyInspectionHeader">The quality Inspection involved</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinishInspection(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// This is called when the Quality Inspection header is being updated automatically based on the inspection lines.
    /// Use this to inspect or adjust the result that the system automatically chose.
    /// </summary>
    /// <param name="QltyInspectionHeader">The quality Inspection involved</param>
    /// <param name="QltyInspectionLine"></param>

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindLineUpdateResultFromLines(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionLine: Record "Qlty. Inspection Line")
    begin
    end;

    /// <summary>
    /// This is called when the Quality Inspection header is being updated automatically based on the inspection lines.
    /// Use this to optionally alter the filters on the inspection line before the inspection has been found.
    /// This can be used to influence how the inspection header automatically changes.
    /// You can also avoid the inspection header changing by implementing this and just setting Handled to 'true'
    /// causing it to exit immediately.
    /// </summary>
    /// <param name="QltyInspectionHeader">The quality Inspection involved</param>
    /// <param name="QltyInspectionLine"></param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLineUpdateResultFromLines(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var QltyInspectionLine: Record "Qlty. Inspection Line"; var IsHandled: Boolean)
    begin
    end;
}
