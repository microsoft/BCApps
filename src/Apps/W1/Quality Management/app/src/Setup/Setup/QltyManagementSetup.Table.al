// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.Setup;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Assembly;
using Microsoft.QualityManagement.Integration.Inventory;
// TODO: Decouple Manufacturing dependency - FIXED
//using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;
using System.Apps;
using System.Environment.Configuration;

table 20400 "Qlty. Management Setup"
{
    Caption = 'Quality Management Setup';
    DrillDownPageID = "Qlty. Management Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Quality Inspection Test Nos."; Code[20])
        {
            Caption = 'Quality Inspection Test Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the default number series used for quality inspection test documents when there is not a no. series defined on a Quality Inspection Template. When a no. series is defined on a template, then that is used instead.';
        }
        field(3; "Show Test Behavior"; Enum "Qlty. Show Test Behavior")
        {
            Caption = 'Show Test Behavior';
            ToolTip = 'Specifies whether to show the Quality Inspection Test page after a test has been made.';
        }
        field(4; "Create Test Behavior"; Enum "Qlty. Create Test Behavior")
        {
            Caption = 'Create Test Behavior';
            ToolTip = 'Specifies the behavior of when to create a new Quality Inspection Test when existing tests occur.';
        }
        field(5; "Find Existing Behavior"; Enum "Qlty. Find Existing Behavior")
        {
            Caption = 'Find Existing Behavior';
            Description = 'When looking for existing tests, this defines what it looks for.';
            ToolTip = 'Specifies what criteria the system looks for when searching for existing tests.';
        }
        field(6; "CoA Contact No."; Code[20])
        {
            Caption = 'CoA Contact No.';
            Description = 'When supplied, these contact details will appear on the CoA report.';
            TableRelation = Contact."No.";
            ToolTip = 'Specifies the contact details that will appear on the Certificate of Analysis report when supplied.';
        }
        // TODO: Decouple Manufacturing dependency - FIXED
        /*        field(10; "Production Trigger"; Enum "Qlty. Production Trigger")
                {
                    Description = 'Optionally choose a production related trigger to try and create a test.';
                    Caption = 'Production Trigger';
                    ToolTip = 'Specifies a default production-related trigger value for Test Generation Rules to try and create a test.';

                    trigger OnValidate()
                    var
                        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
                    begin
                        if (Rec."Production Trigger" <> xRec."Production Trigger") and (xRec."Production Trigger" <> xRec."Production Trigger"::NoTrigger) then begin
                            QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Production);
                            QltyInTestGenerationRule.SetRange("Production Trigger", xRec."Production Trigger");
                            if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                                if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInTestGenerationRule.Count(), xRec."Production Trigger", Rec."Production Trigger")) then
                                    QltyInTestGenerationRule.ModifyAll("Production Trigger", Rec."Production Trigger", false);
                        end;
                    end;
                }
                field(11; "Production Update Control"; Enum "Qlty. Update Source Behavior")
                {
                    Description = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
                    InitValue = "Do not update";
                    Caption = 'Production Update Control';
                    ToolTip = 'Specifies whether to update when the source changes. Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
                }*/
        field(21; "Receive Update Control"; Enum "Qlty. Update Source Behavior")
        {
            Description = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
            Caption = 'Receive Update Control';
            ToolTip = 'Specifies whether to update when the source changes. Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Purchase Order is posted). Set to "Do Not Update" to prevent updating the original source that created the test.';
        }
        field(24; "Item Tracking Before Finishing"; Enum "Qlty. Item Tracking Behavior")
        {
            Description = 'Whether to require item tracking before finishing a test.';
            Caption = 'Item Tracking Before Finishing';
            ToolTip = 'Specifies whether to require item tracking before finishing a test.';
        }
        field(26; "Scheduler Template Code"; Code[20])
        {
            Description = 'When using a specific template, which specific template.';
            TableRelation = "Qlty. Inspection Template Hdr.".Code;
            Caption = 'Scheduler Template Code';
        }
        field(27; "Picture Upload Behavior"; Enum "Qlty. Picture Upload Behavior")
        {
            Description = 'When a picture has been taken, this field defines what to do with that picture.';
            Caption = 'Picture Upload Behavior';
            ToolTip = 'Specifies what to do with a picture after it has been taken.';

            trigger OnValidate()
            begin
                SanityCheckPictureAndCameraSettings();
            end;
        }
        field(28; "Conditional Lot Find Behavior"; Enum "Qlty. Test Find Behavior")
        {
            Description = 'When evaluating if a document specific transactions are blocked, this determines which test(s) are considered.';
            Caption = 'Conditional Lot Find Behavior';
            ToolTip = 'Specifies which test(s) are considered when evaluating if a document-specific transaction is blocked.';
        }
        field(29; "Warehouse Trigger"; Enum "Qlty. Warehouse Trigger")
        {
            Description = 'Optionally choose a warehouse related trigger to try and create a test.';
            Caption = 'Warehouse Trigger';
            ToolTip = 'Specifies a default warehousing related trigger value for Test Generation Rules to try and create a test.';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
                QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
            begin
                if Rec."Warehouse Trigger" <> Rec."Warehouse Trigger"::NoTrigger then
                    QltyAutoConfigure.CreateDefaultWarehousingConfiguration();

                if (Rec."Warehouse Trigger" <> xRec."Warehouse Trigger") and (xRec."Warehouse Trigger" <> xRec."Warehouse Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::"Warehouse Movement");
                    QltyInTestGenerationRule.SetRange("Warehouse Movement Trigger", xRec."Warehouse Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInTestGenerationRule.Count(), xRec."Warehouse Trigger", Rec."Warehouse Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Warehouse Movement Trigger", Rec."Warehouse Trigger", false);
                end;
            end;
        }
        field(30; "Whse. Move Related Triggers"; Integer)
        {
            CalcFormula = count("Qlty. In. Test Generation Rule" where(Intent = const("Warehouse Movement")));
            Caption = 'Whse. Move Related Triggers';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the Test Generation Rules that are warehouse movement related.';
        }
        field(60; "Brick Top Left Expression"; Text[200])
        {
            Caption = 'Brick Top Left Expression';
            ToolTip = 'Specifies the top left expression. Appears in small font in its own row of the tile.';
        }
        field(61; "Brick Middle Left Expression"; Text[200])
        {
            Caption = 'Brick Middle Left Expression';
            ToolTip = 'Specifies the middle left expression. Appears in a tile large font, with a link style lookup.';
        }
        field(62; "Brick Middle Right Expression"; Text[200])
        {
            Caption = 'Brick Middle Right Expression';
            ToolTip = 'Specifies the middle right expression. Appears in a tile with a large font and no link, right-aligned.';
        }
        field(63; "Brick Bottom Left Expression"; Text[200])
        {
            Caption = 'Brick Bottom Left Expression';
            ToolTip = 'Specifies the bottom left expression. Appears in a tile with a small font, not as small as Brick Top Left Expression (the first field).';
        }
        field(64; "Brick Bottom Right Expression"; Text[200])
        {
            Caption = 'Brick Bottom Right Expression';
            ToolTip = 'Specifies the bottom right expression. Appears in a tile with a small font, not as small as Brick Top Left Expression (the first field).';
        }
        field(65; "Brick Top Left Header"; Text[30])
        {
            Description = 'Appears in small font in its own row of the tile';
            Caption = 'Brick Top Left Header';
            ToolTip = 'Specifies a field header for the Brick Top Left Expression.';
        }
        field(66; "Brick Middle Left Header"; Text[30])
        {
            Description = 'Appears in a tile large font, with a link style lookup';
            Caption = 'Brick Middle Left Header';
            ToolTip = 'Specifies the middle left header. Field header for the Brick Middle Left Expression.';
        }
        field(67; "Brick Middle Right Header"; Text[30])
        {
            Description = 'Appears in a tile with a large font and no link, right-aligned.';
            Caption = 'Brick Middle Right Header';
            ToolTip = 'Specifies the middle right header. Field header for the Brick Middle Right Expression.';
        }
        field(68; "Brick Bottom Left Header"; Text[30])
        {
            Description = 'Appears in a tile with a small font, not as small as field 1.';
            Caption = 'Brick Bottom Left Header';
            ToolTip = 'Specifies the bottom left header. Field header for the Brick Bottom Left Expression.';
        }
        field(69; "Brick Bottom Right Header"; Text[30])
        {
            Description = 'Appears in a tile with a small font, not as small as field 1.';
            Caption = 'Brick Bottom Right Header';
            ToolTip = 'Specifies the bottom right field header for the Brick Bottom Right Expression.';
        }
        field(70; "Visibility"; Enum "Qlty. Management Visibility")
        {
            Description = 'Assists with toggling the application area that shows or hides the Quality Management.';
            DataClassification = SystemMetadata;
            Caption = 'Visibility';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if Rec.Visibility <> Rec.Visibility::Hide then
                    exit;

                QltyInTestGenerationRule.SetFilter("Activation Trigger", '<>%1', QltyInTestGenerationRule."Activation Trigger"::Disabled);
                if QltyInTestGenerationRule.IsEmpty() then
                    exit;

                if not GuiAllowed() then
                    exit;

                if Confirm(ShouldDisableTestGenerationRulesQst) then begin
                    QltyInTestGenerationRule.ModifyAll("Activation Trigger", QltyInTestGenerationRule."Activation Trigger"::Disabled);
                    Message(TestGenerationRulesHaveBeenDisabledMsg);
                end;
            end;
        }
        field(72; "Workflow Integration Enabled"; Boolean)
        {
            Description = 'When enabled, provides events and responses for working with Business Central workflows and approvals.';
            DataClassification = SystemMetadata;
            Caption = 'Workflow Integration Enabled';
            ToolTip = 'Specifies whether to enable events and responses for workflows.';
        }
        field(73; "Bin Move Batch Name"; Code[10])
        {
            Caption = 'Bin Move Batch Name';
            ToolTip = 'Specifies the batch to use for bin movements and reclassifications for non-directed pick and put-away locations.';

            trigger OnLookup()
            var
                ItemJournalBatch: Record "Item Journal Batch";
                ItemJournalBatches: Page "Item Journal Batches";
            begin
                ItemJournalBatch.SetRange("Journal Template Name", GetItemReclassJournalTemplate());
                ItemJournalBatches.SetTableView(ItemJournalBatch);
                ItemJournalBatches.LookupMode(true);

                if ItemJournalBatches.RunModal() = Action::LookupOK then begin
                    ItemJournalBatches.GetRecord(ItemJournalBatch);
                    Rec."Bin Move Batch Name" := ItemJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                ItemJournalBatch: Record "Item Journal Batch";
            begin
                if Rec."Bin Move Batch Name" <> '' then
                    ItemJournalBatch.Get(GetItemReclassJournalTemplate(), "Bin Move Batch Name");
            end;
        }
        field(74; "Bin Whse. Move Batch Name"; Code[10])
        {
            Caption = 'Bin Whse. Move Batch Name';
            Description = 'The batch to use for bin movements for directed pick and put-away locations';
            ToolTip = 'Specifies the batch to use for bin movements and reclassifications for directed pick and put-away locations.';

            trigger OnLookup()
            var
                WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
                JnlWhseJournalBatches: Page "Whse. Journal Batches";
            begin
                WhseWarehouseJournalBatch.SetRange("Journal Template Name", GetWarehouseReclassificationJournalTemplate());
                JnlWhseJournalBatches.SetTableView(WhseWarehouseJournalBatch);
                JnlWhseJournalBatches.LookupMode(true);

                if JnlWhseJournalBatches.RunModal() = Action::LookupOK then begin
                    JnlWhseJournalBatches.GetRecord(WhseWarehouseJournalBatch);
                    "Bin Whse. Move Batch Name" := WhseWarehouseJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
            begin
                if "Bin Whse. Move Batch Name" <> '' then begin
                    WhseWarehouseJournalBatch.SetRange(Name, "Bin Whse. Move Batch Name");
                    if WhseWarehouseJournalBatch.IsEmpty() then
                        Error(BatchNotFoundErr, "Bin Whse. Move Batch Name");
                end;
            end;
        }
        field(91; "Max Rows Field Lookups"; Integer)
        {
            Caption = 'Maximum Rows To Fetch on Field Lookups';
            BlankZero = true;
            MinValue = 1;
            MaxValue = 1000;
            InitValue = 30;
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the maximum number of rows to fetch on data lookups. Keeping the number as low as possible will increase usability and performance. A larger number will reduce performance and reduce usability.';
        }
        // TODO: Decouple Manufacturing dependency - FIXED
        /*        field(92; "Auto Output Configuration"; Enum "Qlty. Auto. Production Trigger")
                {
                    Caption = 'Auto Output Configuration';
                    ToolTip = 'Specifies granular options for when a test should be created automatically during the production process.';
                }*/
        field(93; "Whse. Wksh. Name"; Code[10])
        {
            Caption = 'Warehouse Worksheet Name';
            ToolTip = 'Specifies the worksheet used for warehouse movements for directed pick and put-away locations.';

            trigger OnLookup()
            var
                WhseWorksheetName: Record "Whse. Worksheet Name";
                NameWhseWorksheetNames: Page "Whse. Worksheet Names";
            begin
                WhseWorksheetName.SetRange("Worksheet Template Name", GetMovementWorksheetTemplateName());
                NameWhseWorksheetNames.SetTableView(WhseWorksheetName);
                NameWhseWorksheetNames.LookupMode(true);

                if NameWhseWorksheetNames.RunModal() = Action::LookupOK then begin
                    NameWhseWorksheetNames.GetRecord(WhseWorksheetName);
                    Rec."Whse. Wksh. Name" := WhseWorksheetName.Name;
                end;
            end;

            trigger OnValidate()
            var
                WhseWorksheetName: Record "Whse. Worksheet Name";
            begin
                if Rec."Whse. Wksh. Name" <> '' then begin
                    WhseWorksheetName.SetRange(Name, Rec."Whse. Wksh. Name");
                    if WhseWorksheetName.IsEmpty() then
                        Error(WorksheetNameNotFoundErr, Rec."Whse. Wksh. Name");
                end;
            end;
        }
        field(95; "Adjustment Batch Name"; Code[10])
        {
            Caption = 'Adjustment Batch Name';
            ToolTip = 'Specifies the batch to use for negative inventory adjustment item journals.';

            trigger OnLookup()
            var
                ItemJournalBatch: Record "Item Journal Batch";
                ItemJournalBatches: Page "Item Journal Batches";
            begin
                ItemJournalBatch.SetRange("Journal Template Name", GetInventoryAdjustmentJournalTemplate());
                ItemJournalBatches.SetTableView(ItemJournalBatch);
                ItemJournalBatches.LookupMode(true);

                if ItemJournalBatches.RunModal() = Action::LookupOK then begin
                    ItemJournalBatches.GetRecord(ItemJournalBatch);
                    Rec."Adjustment Batch Name" := ItemJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                ItemJournalBatch: Record "Item Journal Batch";
            begin
                if Rec."Adjustment Batch Name" <> '' then
                    ItemJournalBatch.Get(GetInventoryAdjustmentJournalTemplate(), Rec."Adjustment Batch Name");
            end;
        }
        field(96; "Whse. Adjustment Batch Name"; Code[10])
        {
            Caption = 'Whse. Adjustment Batch Name';
            ToolTip = 'Specifies the batch to use for negative inventory adjustment warehouse item journals.';

            trigger OnLookup()
            var
                WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
                JnlWhseJournalBatches: Page "Whse. Journal Batches";
            begin
                WhseWarehouseJournalBatch.SetRange("Journal Template Name", GetWarehouseInventoryAdjustmentJournalTemplate());
                JnlWhseJournalBatches.SetTableView(WhseWarehouseJournalBatch);
                JnlWhseJournalBatches.LookupMode(true);

                if JnlWhseJournalBatches.RunModal() = Action::LookupOK then begin
                    JnlWhseJournalBatches.GetRecord(WhseWarehouseJournalBatch);
                    Rec."Whse. Adjustment Batch Name" := WhseWarehouseJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
            begin
                if Rec."Whse. Adjustment Batch Name" <> '' then begin
                    WhseWarehouseJournalBatch.SetRange(Name, Rec."Whse. Adjustment Batch Name");
                    if WhseWarehouseJournalBatch.IsEmpty() then
                        Error(BatchNotFoundErr, Rec."Whse. Adjustment Batch Name");
                end;
            end;
        }
        field(97; "Warehouse Receive Trigger"; Enum "Qlty. Whse. Receive Trigger")
        {
            Caption = 'Create Test On Warehouse Receive Trigger';
            Description = 'Provides automation to create a test when a warehouse receipt is created.';
            ToolTip = 'Specifies a default warehouse receipt trigger value for Test Generation Rules to create a test.';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                SanityCheckReceiveSettings();

                if (Rec."Warehouse Receive Trigger" <> xRec."Warehouse Receive Trigger") and (xRec."Warehouse Receive Trigger" <> xRec."Warehouse Receive Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::"Warehouse Receipt");
                    QltyInTestGenerationRule.SetRange("Warehouse Receive Trigger", xRec."Warehouse Receive Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInTestGenerationRule.Count(), xRec."Warehouse Receive Trigger", Rec."Warehouse Receive Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Warehouse Receive Trigger", Rec."Warehouse Receive Trigger", false);
                end;
            end;
        }
        field(98; "Purchase Trigger"; Enum "Qlty. Purchase Trigger")
        {
            Caption = 'Create Test On Purchase Trigger';
            Description = 'Provides automation to create a test when a purchase is received.';
            ToolTip = 'Specifies a default purchase trigger value for Test Generation Rules to create a test.';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if (Rec."Purchase Trigger" <> xRec."Purchase Trigger") and (xRec."Purchase Trigger" <> xRec."Purchase Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Purchase);
                    QltyInTestGenerationRule.SetRange("Purchase Trigger", xRec."Purchase Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInTestGenerationRule.Count(), xRec."Purchase Trigger", Rec."Purchase Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Purchase Trigger", Rec."Purchase Trigger", false);
                end;
            end;
        }
        field(99; "Sales Return Trigger"; Enum "Qlty. Sales Return Trigger")
        {
            Caption = 'Create Test On Sales Return Trigger';
            Description = 'Provides automation to create a test when a sales return is received.';
            ToolTip = 'Specifies a default sales return trigger value for Test Generation Rules to create a test.';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if (Rec."Sales Return Trigger" <> xRec."Sales Return Trigger") and (xRec."Sales Return Trigger" <> xRec."Sales Return Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::"Sales Return");
                    QltyInTestGenerationRule.SetRange("Sales Return Trigger", xRec."Sales Return Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInTestGenerationRule.Count(), xRec."Sales Return Trigger", Rec."Sales Return Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Sales Return Trigger", Rec."Sales Return Trigger", false);
                end;
            end;
        }
        field(100; "Transfer Trigger"; Enum "Qlty. Transfer Trigger")
        {
            Caption = 'Create Test On Transfer Trigger';
            Description = 'Provides automation to create a test when a transfer order is received.';
            ToolTip = 'Specifies a default transfer trigger value for Test Generation Rules to create a test.';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if (Rec."Transfer Trigger" <> xRec."Transfer Trigger") and (xRec."Transfer Trigger" <> xRec."Transfer Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Transfer);
                    QltyInTestGenerationRule.SetRange("Transfer Trigger", xRec."Transfer Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInTestGenerationRule.Count(), xRec."Transfer Trigger", Rec."Transfer Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Transfer Trigger", Rec."Transfer Trigger", false);
                end;
            end;
        }
        field(101; "Assembly Trigger"; Enum "Qlty. Assembly Trigger")
        {
            Caption = 'Create Test On Assembly Trigger';
            Description = 'Provides automation to create a test when an assembly order creates output.';
            ToolTip = 'Specifies a default assembly-related trigger value for Test Generation Rules to try and create a test.';

            trigger OnValidate()
            var
                QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
            begin
                if (Rec."Assembly Trigger" <> xRec."Assembly Trigger") and (xRec."Assembly Trigger" <> xRec."Assembly Trigger"::NoTrigger) then begin
                    QltyInTestGenerationRule.SetRange(Intent, QltyInTestGenerationRule.Intent::Assembly);
                    QltyInTestGenerationRule.SetRange("Assembly Trigger", xRec."Assembly Trigger");
                    if (not QltyInTestGenerationRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInTestGenerationRule.Count(), xRec."Assembly Trigger", Rec."Assembly Trigger")) then
                            QltyInTestGenerationRule.ModifyAll("Assembly Trigger", Rec."Assembly Trigger", false);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        ShouldDisableTestGenerationRulesQst: Label 'Changing the visibility to be off should be accompanied by disabling the test generation rules. Do you want to disable your current enabled generation rules?';
        TestGenerationRulesHaveBeenDisabledMsg: Label 'All test generation rules have been disabled.';
        ConfirmExistingRulesQst: Label 'You have %1 existing generation rules that used the "%2" setting. Do you want to change those to be "%3"?', Comment = '%1=the count, %2=the old setting, %3=the new setting.';
        BatchNotFoundErr: Label 'The batch name "%1" was not found. Confirm that the batch name is correct.', Comment = '%1=the batch name';
        WorksheetNameNotFoundErr: Label 'The worksheet name "%1" was not found. Confirm that the worksheet name is correct.', Comment = '%1=the worksheet name';
        OneDriveIntegrationNotConfiguredErr: Label 'The Quality Management Setup has been configured to upload pictures to OneDrive, however you have not yet configured Business Central to work with . Please configure OneDrive setup with Business Central first before using this feature.';
        DefaultTopLeftExpressionTxt: Label '[No.] [Retest No.]', Locked = true;
        DefaultMiddleLeftExpressionTxt: Label '[Grade Description]', Locked = true;
        DefaultMiddleRightExpressionTxt: Label '[Description] [Source Item No.] [Source Lot No.]  [Source Serial No.]', Locked = true;
        DefaultBottomLeftExpressionTxt: Label '[Source Document No.]', Locked = true;
        DefaultBottomRightExpressionTxt: Label '[Status] [Finished Date]', Locked = true;
        DefaultTopLeftLbl: Label 'Test', Locked = true;
        DefaultMiddleLeftLbl: Label 'Grade', Locked = true;
        DefaultMiddleRightLbl: Label 'Details', Locked = true;
        DefaultBottomLeftLbl: Label 'Document', Locked = true;
        DefaultBottomRightLabelLbl: Label 'Status', Locked = true;
        ExcludeBrickFieldTok: Label '<>Brick*', Locked = true;
        MobileFieldsHaveBeenUpdatedForAllExistingTestsMsg: Label 'The mobile fields have been updated for all existing tests.';

    trigger OnInsert()
    begin
        Rec.GetBrickHeaders(Rec."Brick Top Left Header", Rec."Brick Middle Left Header", Rec."Brick Middle Right Header", Rec."Brick Bottom Left Header", Rec."Brick Bottom Right Header");

        Rec.GetBrickExpressions(Rec."Brick Top Left Expression", Rec."Brick Middle Left Expression", Rec."Brick Middle Right Expression", Rec."Brick Bottom Left Expression", Rec."Brick Bottom Right Expression");
    end;

    trigger OnModify()
    begin
        Rec.GetBrickHeaders(Rec."Brick Top Left Header", Rec."Brick Middle Left Header", Rec."Brick Middle Right Header", Rec."Brick Bottom Left Header", Rec."Brick Bottom Right Header");

        Rec.GetBrickExpressions(Rec."Brick Top Left Expression", Rec."Brick Middle Left Expression", Rec."Brick Middle Right Expression", Rec."Brick Bottom Left Expression", Rec."Brick Bottom Right Expression");
    end;

    internal procedure SanityCheckReceiveSettings()
    var
        Handled: Boolean;
    begin
        OnBeforeValidateQualityManagementSettings(xRec, Rec, Handled);
        if Handled then
            exit;
    end;

    internal procedure SanityCheckPictureAndCameraSettings()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        if Rec."Picture Upload Behavior" <> Rec."Picture Upload Behavior"::"Attach and upload to OneDrive" then
            exit;

        if not DocumentServiceManagement.IsConfigured() then
            Error(OneDriveIntegrationNotConfiguredErr);
    end;

    internal procedure GetBrickExpressions(var TopLeft: Text[200]; var MiddleLeft: Text[200]; var MiddleRight: Text[200]; var BottomLeft: Text[200]; var BottomRight: Text[200])
    begin
        TopLeft := DefaultTopLeftExpressionTxt;
        MiddleLeft := DefaultMiddleLeftExpressionTxt;
        MiddleRight := DefaultMiddleRightExpressionTxt;
        BottomLeft := DefaultBottomLeftExpressionTxt;
        BottomRight := DefaultBottomRightExpressionTxt;

        if Rec."Brick Top Left Expression" <> '' then
            TopLeft := Rec."Brick Top Left Expression";

        if Rec."Brick Middle Left Expression" <> '' then
            MiddleLeft := Rec."Brick Middle Left Expression";

        if Rec."Brick Middle Right Expression" <> '' then
            MiddleRight := Rec."Brick Middle Right Expression";

        if Rec."Brick Bottom Left Expression" <> '' then
            BottomLeft := Rec."Brick Bottom Left Expression";

        if Rec."Brick Bottom Right Expression" <> '' then
            BottomRight := Rec."Brick Bottom Right Expression";
    end;

    internal procedure GetBrickHeaders(var TopLeft: Text[30]; var MiddleLeft: Text[30]; var MiddleRight: Text[30]; var BottomLeft: Text[30]; var BottomRight: Text[30])
    begin
        TopLeft := DefaultTopLeftLbl;
        MiddleLeft := DefaultMiddleLeftLbl;
        MiddleRight := DefaultMiddleRightLbl;
        BottomLeft := DefaultBottomLeftLbl;
        BottomRight := DefaultBottomRightLabelLbl;

        if Rec."Brick Top Left Header" <> '' then
            TopLeft := Rec."Brick Top Left Header";

        if Rec."Brick Middle Left Header" <> '' then
            MiddleLeft := Rec."Brick Middle Left Header";

        if Rec."Brick Middle Right Header" <> '' then
            MiddleRight := Rec."Brick Middle Right Header";

        if Rec."Brick Bottom Left Header" <> '' then
            BottomLeft := Rec."Brick Bottom Left Header";

        if Rec."Brick Bottom Right Header" <> '' then
            BottomRight := Rec."Brick Bottom Right Header";
    end;

    internal procedure AssistEditBrickField(FieldNo: Integer)
    var
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        TestRecordRef: RecordRef;
        TestFieldRef: FieldRef;
        Template: Text;
    begin
        TestRecordRef := Rec.RecordId().GetRecord();
        TestRecordRef.SetRecFilter();
        TestRecordRef.FindFirst();
        TestFieldRef := TestRecordRef.Field(FieldNo);
        Template := TestFieldRef.Value();
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", ExcludeBrickFieldTok, Template) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            TestFieldRef.Validate(CopyStr(Template, 1, TestFieldRef.Length));
            TestRecordRef.Modify();
        end;
    end;

    /// <summary>
    /// UpdateBrickFieldsOnAllExistingTests will update the brick fields on all existing tests.
    /// Use this if you need to adjust the brick summary on all tests.
    /// </summary>
    procedure UpdateBrickFieldsOnAllExistingTests()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        if QltyInspectionTestHeader.FindSet(true) then
            repeat
                QltyInspectionTestHeader.UpdateBrickFields();
#pragma warning disable AA0214
                QltyInspectionTestHeader.Modify(false);
#pragma warning restore AA0214
            until QltyInspectionTestHeader.Next() = 0;

        Message(MobileFieldsHaveBeenUpdatedForAllExistingTestsMsg);
    end;

    internal procedure GetAppGuid(): Guid
    begin
        exit('bc7b3891-f61b-4883-bbb3-384cdef88bec');
    end;

    internal procedure GetVersion() VersionText: Text
    var
        NAVAppInstalledApp: Record "NAV App Installed App";
    begin
        NAVAppInstalledApp.SetRange("App ID", Rec.GetAppGuid());
        if NAVAppInstalledApp.FindFirst() then
            VersionText := Format(NAVAppInstalledApp."Version Major") + '.' + Format(NAVAppInstalledApp."Version Minor");
    end;

    internal procedure GetIsCompanyPremiumEnabled(): Boolean
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        exit(ApplicationAreaMgmtFacade.IsPremiumExperienceEnabled());
    end;

    internal procedure GetSetupVideoLink(): Text
    begin
        exit('');
    end;

    procedure GetInventoryAdjustmentJournalTemplate(): Code[10]
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlManagement: Codeunit ItemJnlManagement;
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        JournalSelected: Boolean;
    begin
        BindSubscription(QltyItemTrackingMgmt);
        ItemJnlManagement.TemplateSelection(Page::"Item Journal", 0, false, ItemJournalLine, JournalSelected);
        ItemJournalLine.FilterGroup(2);
        UnbindSubscription(QltyItemTrackingMgmt);
        exit(ItemJournalLine.GetRangeMin("Journal Template Name"));
    end;

    procedure GetWarehouseInventoryAdjustmentJournalTemplate(): Code[10]
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        WhseJnlTemplateType: Enum "Warehouse Journal Template Type";
    begin
        BindSubscription(QltyItemTrackingMgmt);
        WarehouseJournalLine.TemplateSelection(Page::"Whse. Item Journal", WhseJnlTemplateType::Item, WarehouseJournalLine);
        WarehouseJournalLine.FilterGroup(2);
        UnbindSubscription(QltyItemTrackingMgmt);
        exit(WarehouseJournalLine.GetRangeMin("Journal Template Name"));
    end;

    procedure GetWarehouseReclassificationJournalTemplate(): Code[10]
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        WhseJnlTemplateType: Enum "Warehouse Journal Template Type";
    begin
        BindSubscription(QltyItemTrackingMgmt);
        WarehouseJournalLine.TemplateSelection(Page::"Whse. Reclassification Journal", WhseJnlTemplateType::Reclassification, WarehouseJournalLine);
        WarehouseJournalLine.FilterGroup(2);
        UnbindSubscription(QltyItemTrackingMgmt);
        exit(WarehouseJournalLine.GetRangeMin("Journal Template Name"));
    end;

    /// <summary>
    /// Gets the first page template for the supplied page.
    /// </summary>
    /// <param name="piPageID"></param>
    /// <returns></returns>
    procedure GetItemReclassJournalTemplate(): Code[10]
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlManagement: Codeunit ItemJnlManagement;
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        JournalSelected: Boolean;
    begin
        BindSubscription(QltyItemTrackingMgmt);
        ItemJnlManagement.TemplateSelection(Page::"Item Reclass. Journal", 1, false, ItemJournalLine, JournalSelected);
        ItemJournalLine.FilterGroup(2);
        UnbindSubscription(QltyItemTrackingMgmt);
        exit(ItemJournalLine.GetRangeMin("Journal Template Name"));
    end;

    /// <summary>
    /// Gets the first movement worksheet template name.
    /// </summary>
    /// <returns></returns>
    procedure GetMovementWorksheetTemplateName(): Code[10]
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        JournalSelected: Boolean;
    begin
        WhseWorksheetLine.TemplateSelection(Page::"Movement Worksheet", 2, WhseWorksheetLine, JournalSelected);
        WhseWorksheetLine.FilterGroup(2);
        exit(WhseWorksheetLine.GetRangeMin("Worksheet Template Name"));
    end;

    internal procedure GetSetupRecord(): Boolean
    begin
        if not Rec.ReadPermission() then
            exit(false);

        exit(Rec.Get());
    end;

    /// <summary>
    /// Occurs when changing settings on the quality inspector setup page.
    /// </summary>
    /// <param name="XOldQltyManagementSetup"></param>
    /// <param name="NewQltyManagementSetup"></param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQualityManagementSettings(var XOldQltyManagementSetup: Record "Qlty. Management Setup"; var NewQltyManagementSetup: Record "Qlty. Management Setup"; var Handled: Boolean)
    begin
    end;
}
