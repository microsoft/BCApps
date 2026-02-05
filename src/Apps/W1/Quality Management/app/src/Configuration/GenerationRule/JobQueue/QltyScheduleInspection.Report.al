// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;

report 20412 "Qlty. Schedule Inspection"
{
    Caption = 'Quality Management - Schedule Inspection';
    AdditionalSearchTerms = 'Periodic inspections';
    ToolTip = 'This report is intended to be scheduled in the job queue to allow the ability to schedule inspections.';
    ProcessingOnly = true;
    ApplicationArea = QualityManagement;
    UsageCategory = Tasks;
    AllowScheduling = true;

    dataset
    {
        dataitem(CurrentInspectionGenerationRule; "Qlty. Inspect. Creation Rule")
        {
            RequestFilterFields = "Schedule Group", "Template Code", Description;
            DataItemTableView = where("Activation Trigger" = filter(<> Disabled), "Schedule Group" = filter(<> ''));

            trigger OnAfterGetRecord()
            begin
                CreateInspectionsThatMatchRule(CurrentInspectionGenerationRule);
            end;

            trigger OnPreDataItem()
            begin
                if CurrentInspectionGenerationRule.GetFilter("Schedule Group") = '' then
                    Error(ScheduleGroupIsMandatoryErr);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(SettingsForWarning)
                {
                    Caption = 'Warning';
                    Visible = ShowWarningIfCreateInspection;
                    InstructionalText = 'On your Quality Management Setup page you have the Inspection Creation Option set to a setting that will cause inspections to be created whenever this report is run even if there are already inspections for that item and lot. Make sure this is compatible with the scenario you are solving.';

                    field(ChooseOpenQualityManagementSetup; 'Click here to open the Quality Management Setup page.')
                    {
                        ShowCaption = false;
                        ApplicationArea = QualityManagement;

                        trigger OnDrillDown()
                        begin
                            QltyManagementSetup.Get();
                            Page.RunModal(Page::"Qlty. Management Setup", QltyManagementSetup, QltyManagementSetup.FieldNo("Inspection Creation Option"));
                        end;
                    }
                }
            }
        }
    }

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        ShowWarningIfCreateInspection: Boolean;
        CreatedQltyInspectionIds: List of [Code[20]];
        ZeroInspectionsCreatedMsg: Label 'No inspections were created.';
        SomeInspectionsWereCreatedQst: Label '%1 inspections were created. Do you want to see them?', Comment = '%1=the count of inspections that were created.';
        ScheduleGroupIsMandatoryErr: Label 'It is mandatory to define a schedule group on the inspection generation rule(s), and then configure the schedule with the same group. This will help make sure that inadvertent configuration does not cause excessive inspection generation.';

    trigger OnInitReport()
    begin
        QltyManagementSetup.Get();
        if QltyManagementSetup."Inspection Creation Option" in [QltyManagementSetup."Inspection Creation Option"::"Always create new inspection", QltyManagementSetup."Inspection Creation Option"::"Always create re-inspection"] then
            ShowWarningIfCreateInspection := true;
    end;

    trigger OnPreReport()
    begin
        Clear(QltyInspectionCreate);
        Clear(CreatedQltyInspectionIds);
    end;

    trigger OnPostReport()
    begin
        if GuiAllowed() then
            if CreatedQltyInspectionIds.Count() = 0 then
                Message(ZeroInspectionsCreatedMsg)
            else
                if Confirm(StrSubstNo(SomeInspectionsWereCreatedQst, CreatedQltyInspectionIds.Count())) then
                    QltyInspectionCreate.DisplayInspectionsIfConfigured(true, CreatedQltyInspectionIds);
    end;

    /// <summary>
    /// This will use the creation rule, and create inspections that match the records found with that rule.
    /// </summary>
    /// <param name="QltyInspectCreationRule"></param>
    procedure CreateInspectionsThatMatchRule(QltyInspectCreationRule: Record "Qlty. Inspect. Creation Rule")
    var
        QltyJobQueueManagement: Codeunit "Qlty. Job Queue Management";
        SourceRecordRef: RecordRef;
    begin
        if QltyInspectCreationRule."Activation Trigger" = QltyInspectCreationRule."Activation Trigger"::Disabled then
            exit;

        if QltyInspectCreationRule."Schedule Group" = '' then
            exit;

        QltyJobQueueManagement.CheckIfGenerationRuleCanBeScheduled(QltyInspectCreationRule);

        SourceRecordRef.Open(QltyInspectCreationRule."Source Table No.");
        if QltyInspectCreationRule."Condition Filter" <> '' then
            SourceRecordRef.SetView(QltyInspectCreationRule."Condition Filter");

        QltyInspectCreationRule.SetRecFilter();
        QltyInspectCreationRule.SetRange("Schedule Group", QltyInspectCreationRule."Schedule Group");
        QltyInspectCreationRule.SetRange("Template Code", QltyInspectCreationRule."Template Code");
        if SourceRecordRef.FindSet() then
            QltyInspectionCreate.CreateMultipleInspectionsWithoutDisplaying(SourceRecordRef, GuiAllowed(), QltyInspectCreationRule, CreatedQltyInspectionIds);
    end;
}