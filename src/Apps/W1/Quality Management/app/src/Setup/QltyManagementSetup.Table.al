// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;
using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Assembly;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;
using System.Apps;
using System.Environment.Configuration;

table 20400 "Qlty. Management Setup"
{
    Caption = 'Quality Management Setup';
    DrillDownPageId = "Qlty. Management Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Quality Inspection Nos."; Code[20])
        {
            Caption = 'Quality Inspection Nos.';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the default number series for quality inspection documents.';
        }
        field(4; "Inspection Creation Option"; Enum "Qlty. Inspect. Creation Option")
        {
            Caption = 'Inspection Creation Option';
            ToolTip = 'Specifies whether and how a new quality inspection is created if existing inspections are found.';
        }
        field(5; "Inspection Search Criteria"; Enum "Qlty. Inspect. Search Criteria")
        {
            Caption = 'Inspection Search Criteria';
            ToolTip = 'Specifies the criteria the system uses to search for existing inspections.';
        }
        field(6; "Certificate Contact No."; Code[20])
        {
            Caption = 'Certificate of Analysis Contact';
            TableRelation = Contact."No.";
            ToolTip = 'Specifies the contact details that will appear on the Certificate of Analysis report when supplied.';
        }
        field(10; "Production Order Trigger"; Enum "Qlty. Production Order Trigger")
        {
            Caption = 'Production Order Trigger';
            ToolTip = 'Specifies a default production order related trigger value for Inspection Generation Rules to try and create an inspection.';

            trigger OnValidate()
            var
                QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
            begin
                if (Rec."Production Order Trigger" <> xRec."Production Order Trigger") and (xRec."Production Order Trigger" <> xRec."Production Order Trigger"::NoTrigger) then begin
                    QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Production);
                    QltyInspectionGenRule.SetRange("Production Order Trigger", xRec."Production Order Trigger");
                    if (not QltyInspectionGenRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInspectionGenRule.Count(), xRec."Production Order Trigger", Rec."Production Order Trigger")) then
                            QltyInspectionGenRule.ModifyAll("Production Order Trigger", Rec."Production Order Trigger", false);
                end;
            end;
        }
        field(11; "Production Update Control"; Enum "Qlty. Update Source Behavior")
        {
            InitValue = "Do not update";
            Caption = 'Production Update Control';
            ToolTip = 'Specifies whether to update when the source changes. Set to "Update when source changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do not update" to prevent updating the original source that created the inspection.';
        }
        field(24; "Item Tracking Before Finishing"; Enum "Qlty. Item Tracking Behavior")
        {
            Caption = 'Item Tracking Before Finishing';
            ToolTip = 'Specifies when item tracking is required for inspections, including whether missing values are allowed, only posted tracking is accepted, reserved (unposted) tracking is permitted, or any non-empty lot/serial/package value is valid.';
        }
        field(26; "Scheduler Template Code"; Code[20])
        {
            ToolTip = 'Specifies which specific template to use when using a specific template.';
            TableRelation = "Qlty. Inspection Template Hdr.".Code;
            Caption = 'Scheduler Template Code';
        }
        field(27; "Additional Picture Handling"; Enum "Qlty. Add. Picture Handling")
        {
            Caption = 'Additional Picture Handling';
            ToolTip = 'Specifies what to do with a picture after it has been taken.';

            trigger OnValidate()
            begin
                SanityCheckPictureAndCameraSettings();
            end;
        }
        field(28; "Inspection Selection Criteria"; Enum "Qlty. Insp. Selection Criteria")
        {
            Caption = 'Quality Inspection Selection Criteria';
            ToolTip = 'Specifies the checks the system uses to decide if a document-specific transaction should be blocked.';
        }
        field(29; "Warehouse Trigger"; Enum "Qlty. Warehouse Trigger")
        {
            Caption = 'Warehouse Trigger';
            ToolTip = 'Specifies a default warehousing related trigger value for Inspection Generation Rules to try and create an inspection.';

            trigger OnValidate()
            var
                QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
                QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
            begin
                if Rec."Warehouse Trigger" <> Rec."Warehouse Trigger"::NoTrigger then
                    QltyAutoConfigure.CreateDefaultWarehousingConfiguration();

                if (Rec."Warehouse Trigger" <> xRec."Warehouse Trigger") and (xRec."Warehouse Trigger" <> xRec."Warehouse Trigger"::NoTrigger) then begin
                    QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::"Warehouse Movement");
                    QltyInspectionGenRule.SetRange("Warehouse Movement Trigger", xRec."Warehouse Trigger");
                    if (not QltyInspectionGenRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInspectionGenRule.Count(), xRec."Warehouse Trigger", Rec."Warehouse Trigger")) then
                            QltyInspectionGenRule.ModifyAll("Warehouse Movement Trigger", Rec."Warehouse Trigger", false);
                end;
            end;
        }
        field(73; "Item Reclass. Batch Name"; Code[10])
        {
            Caption = 'Item Reclass. Batch Name';
            ToolTip = 'Specifies the item reclassification journal batch to use for bin movements and reclassifications for non-directed pick and put-away locations.';

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
                    Rec."Item Reclass. Batch Name" := ItemJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                ItemJournalBatch: Record "Item Journal Batch";
            begin
                if Rec."Item Reclass. Batch Name" <> '' then
                    ItemJournalBatch.Get(GetItemReclassJournalTemplate(), "Item Reclass. Batch Name");
            end;
        }
        field(74; "Whse. Reclass. Batch Name"; Code[10])
        {
            Caption = 'Whse. Reclass. Batch Name';
            ToolTip = 'Specifies the warehouse reclassification journal batch to use for bin movements and reclassifications for directed pick and put-away locations.';

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
                    "Whse. Reclass. Batch Name" := WhseWarehouseJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
            begin
                if "Whse. Reclass. Batch Name" <> '' then begin
                    WhseWarehouseJournalBatch.SetRange(Name, "Whse. Reclass. Batch Name");
                    if WhseWarehouseJournalBatch.IsEmpty() then
                        Error(BatchNotFoundErr, "Whse. Reclass. Batch Name");
                end;
            end;
        }
        field(91; "Max Rows Field Lookups"; Integer)
        {
            Caption = 'Maximum Rows To Fetch In Lookups';
            BlankZero = true;
            MinValue = 1;
            MaxValue = 1000;
            InitValue = 30;
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the maximum number of rows to fetch on data lookups. Keeping the number as low as possible will increase usability and performance. A larger number will reduce performance and reduce usability.';
        }
        field(92; "Prod. Trigger Output Condition"; Enum "Prod. Trigger Output Condition")
        {
            Caption = 'Prod. Trigger Output Condition';
            ToolTip = 'Specifies granular options for when an inspection should be created automatically during the production process.';
        }
        field(93; "Movement Worksheet Name"; Code[10])
        {
            Caption = 'Movement Worksheet Name';
            ToolTip = 'Specifies the movement worksheet name used for warehouse movements for directed pick and put-away locations.';

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
                    Rec."Movement Worksheet Name" := WhseWorksheetName.Name;
                end;
            end;

            trigger OnValidate()
            var
                WhseWorksheetName: Record "Whse. Worksheet Name";
            begin
                if Rec."Movement Worksheet Name" <> '' then begin
                    WhseWorksheetName.SetRange(Name, Rec."Movement Worksheet Name");
                    if WhseWorksheetName.IsEmpty() then
                        Error(WorksheetNameNotFoundErr, Rec."Movement Worksheet Name");
                end;
            end;
        }
        field(95; "Item Journal Batch Name"; Code[10])
        {
            Caption = 'Item Journal Batch Name';
            ToolTip = 'Specifies the item journal batch to use for negative inventory adjustments.';

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
                    Rec."Item Journal Batch Name" := ItemJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                ItemJournalBatch: Record "Item Journal Batch";
            begin
                if Rec."Item Journal Batch Name" <> '' then
                    ItemJournalBatch.Get(GetInventoryAdjustmentJournalTemplate(), Rec."Item Journal Batch Name");
            end;
        }
        field(96; "Whse. Item Journal Batch Name"; Code[10])
        {
            Caption = 'Whse. Item Journal Batch Name';
            ToolTip = 'Specifies the warehouse item journal batch to use for negative inventory adjustments.';

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
                    Rec."Whse. Item Journal Batch Name" := WhseWarehouseJournalBatch.Name;
                end;
            end;

            trigger OnValidate()
            var
                WhseWarehouseJournalBatch: Record "Warehouse Journal Batch";
            begin
                if Rec."Whse. Item Journal Batch Name" <> '' then begin
                    WhseWarehouseJournalBatch.SetRange(Name, Rec."Whse. Item Journal Batch Name");
                    if WhseWarehouseJournalBatch.IsEmpty() then
                        Error(BatchNotFoundErr, Rec."Whse. Item Journal Batch Name");
                end;
            end;
        }
        field(97; "Warehouse Receipt Trigger"; Enum "Qlty. Whse. Receipt Trigger")
        {
            Caption = 'Create Inspection On Warehouse Receipt Trigger';
            ToolTip = 'Specifies a default warehouse receipt trigger value for Inspection Generation Rules to create an inspection.';

            trigger OnValidate()
            var
                QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
            begin
                if (Rec."Warehouse Receipt Trigger" <> xRec."Warehouse Receipt Trigger") and (xRec."Warehouse Receipt Trigger" <> xRec."Warehouse Receipt Trigger"::NoTrigger) then begin
                    QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::"Warehouse Receipt");
                    QltyInspectionGenRule.SetRange("Warehouse Receipt Trigger", xRec."Warehouse Receipt Trigger");
                    if (not QltyInspectionGenRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInspectionGenRule.Count(), xRec."Warehouse Receipt Trigger", Rec."Warehouse Receipt Trigger")) then
                            QltyInspectionGenRule.ModifyAll("Warehouse Receipt Trigger", Rec."Warehouse Receipt Trigger", false);
                end;
            end;
        }
        field(98; "Purchase Order Trigger"; Enum "Qlty. Purchase Order Trigger")
        {
            Caption = 'Create Inspection On Purchase Order Trigger';
            ToolTip = 'Specifies a default purchase order trigger value for Inspection Generation Rules to create an inspection.';
            trigger OnValidate()
            var
                QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
            begin
                if (Rec."Purchase Order Trigger" <> xRec."Purchase Order Trigger") and (xRec."Purchase Order Trigger" <> xRec."Purchase Order Trigger"::NoTrigger) then begin
                    QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Purchase);
                    QltyInspectionGenRule.SetRange("Purchase Order Trigger", xRec."Purchase Order Trigger");
                    if (not QltyInspectionGenRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInspectionGenRule.Count(), xRec."Purchase Order Trigger", Rec."Purchase Order Trigger")) then
                            QltyInspectionGenRule.ModifyAll("Purchase Order Trigger", Rec."Purchase Order Trigger", false);
                end;
            end;
        }
        field(99; "Sales Return Trigger"; Enum "Qlty. Sales Return Trigger")
        {
            Caption = 'Create Inspection On Sales Return Trigger';
            ToolTip = 'Specifies a default sales return trigger value for Inspection Generation Rules to create an inspection.';

            trigger OnValidate()
            var
                QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
            begin
                if (Rec."Sales Return Trigger" <> xRec."Sales Return Trigger") and (xRec."Sales Return Trigger" <> xRec."Sales Return Trigger"::NoTrigger) then begin
                    QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::"Sales Return");
                    QltyInspectionGenRule.SetRange("Sales Return Trigger", xRec."Sales Return Trigger");
                    if (not QltyInspectionGenRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInspectionGenRule.Count(), xRec."Sales Return Trigger", Rec."Sales Return Trigger")) then
                            QltyInspectionGenRule.ModifyAll("Sales Return Trigger", Rec."Sales Return Trigger", false);
                end;
            end;
        }
        field(100; "Transfer Order Trigger"; Enum "Qlty. Transfer Order Trigger")
        {
            Caption = 'Create Inspection On Transfer Order Trigger';
            ToolTip = 'Specifies a default transfer order trigger value for Inspection Generation Rules to create an inspection.';

            trigger OnValidate()
            var
                QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
            begin
                if (Rec."Transfer Order Trigger" <> xRec."Transfer Order Trigger") and (xRec."Transfer Order Trigger" <> xRec."Transfer Order Trigger"::NoTrigger) then begin
                    QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Transfer);
                    QltyInspectionGenRule.SetRange("Transfer Order Trigger", xRec."Transfer Order Trigger");
                    if (not QltyInspectionGenRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInspectionGenRule.Count(), xRec."Transfer Order Trigger", Rec."Transfer Order Trigger")) then
                            QltyInspectionGenRule.ModifyAll("Transfer Order Trigger", Rec."Transfer Order Trigger", false);
                end;
            end;
        }
        field(101; "Assembly Trigger"; Enum "Qlty. Assembly Trigger")
        {
            Caption = 'Create Inspection On Assembly Trigger';
            ToolTip = 'Specifies when to create an inspection for assembly orders using inspection generation rules';

            trigger OnValidate()
            var
                QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
            begin
                if (Rec."Assembly Trigger" <> xRec."Assembly Trigger") and (xRec."Assembly Trigger" <> xRec."Assembly Trigger"::NoTrigger) then begin
                    QltyInspectionGenRule.SetRange(Intent, QltyInspectionGenRule.Intent::Assembly);
                    QltyInspectionGenRule.SetRange("Assembly Trigger", xRec."Assembly Trigger");
                    if (not QltyInspectionGenRule.IsEmpty()) and GuiAllowed() then
                        if Confirm(StrSubstNo(ConfirmExistingRulesQst, QltyInspectionGenRule.Count(), xRec."Assembly Trigger", Rec."Assembly Trigger")) then
                            QltyInspectionGenRule.ModifyAll("Assembly Trigger", Rec."Assembly Trigger", false);
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
        RecordHasBeenRead: Boolean;
        ConfirmExistingRulesQst: Label 'You have %1 existing generation rules that used the "%2" setting. Do you want to change those to be "%3"?', Comment = '%1=the count, %2=the old setting, %3=the new setting.';
        BatchNotFoundErr: Label 'The batch name "%1" was not found. Confirm that the batch name is correct.', Comment = '%1=the batch name';
        WorksheetNameNotFoundErr: Label 'The worksheet name "%1" was not found. Confirm that the worksheet name is correct.', Comment = '%1=the worksheet name';
        OneDriveIntegrationNotConfiguredErr: Label 'The Quality Management Setup has been configured to upload pictures to OneDrive, however you have not yet configured Business Central to work with . Please configure OneDrive setup with Business Central first before using this feature.';

    internal procedure SanityCheckPictureAndCameraSettings()
    var
        DocumentServiceManagement: Codeunit "Document Service Management";
    begin
        if Rec."Additional Picture Handling" <> Rec."Additional Picture Handling"::"Save as attachment and upload to OneDrive" then
            exit;

        if not DocumentServiceManagement.IsConfigured() then
            Error(OneDriveIntegrationNotConfiguredErr);
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
    /// Retrieves the Setup record from the database, caching the result to avoid repeated reads within the same session.
    /// </summary>
    internal procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;
}
