// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;

report 20412 "Qlty. Schedule Inspection"
{
    Caption = 'Quality Management - Schedule Inspection';
    AdditionalSearchTerms = 'Periodic inspections, scheduled inspections,schedule test,schedule inspection';
    Description = 'This report is intended to be scheduled in the job queue to allow the ability to schedule tests.';
    ProcessingOnly = true;
    ApplicationArea = QualityManagement;
    UsageCategory = Tasks;
    AllowScheduling = true;

    dataset
    {
        dataitem(CurrentInspectionGenerationRule; "Qlty. Inspection Gen. Rule")
        {
            RequestFilterFields = "Schedule Group", "Template Code", Description;
            DataItemTableView = where("Activation Trigger" = filter(<> Disabled), "Schedule Group" = filter(<> ''));

            trigger OnAfterGetRecord()
            begin
                CreateTestsThatMatchRule(CurrentInspectionGenerationRule);
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
                    Visible = ShowWarningIfCreateTest;
                    InstructionalText = 'On your Quality Management Setup page you have the Create Inspection Behavior set to a setting that will cause tests to be created whenever this report is run even if there are already tests for that item and lot. Make sure this is compatible with the scenario you are solving.';

                    field(ChooseOpenQualityManagementSetup; 'Click here to open the Quality Management Setup page.')
                    {
                        ShowCaption = false;
                        ApplicationArea = QualityManagement;

                        trigger OnDrillDown()
                        begin
                            QltyManagementSetup.Get();
                            Page.RunModal(Page::"Qlty. Management Setup", QltyManagementSetup, QltyManagementSetup.FieldNo("Create Inspection Behavior"));
                        end;
                    }
                }
            }
        }
    }

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        ShowWarningIfCreateTest: Boolean;
        CreatedQltyInspectionIds: List of [Code[20]];
        ZeroTestsCreatedMsg: Label 'No tests were created.';
        SomeTestsWereCreatedQst: Label '%1 tests were created. Do you want to see them?', Comment = '%1=the count of tests that were created.';
        ScheduleGroupIsMandatoryErr: Label 'It is mandatory to define a schedule group on the test generation rule(s), and then configure the schedule with the same group. This will help make sure that inadvertent configuration does not cause excessive test generation. ';

    trigger OnInitReport()
    begin
        QltyManagementSetup.Get();
        if QltyManagementSetup."Create Inspection Behavior" in [QltyManagementSetup."Create Inspection Behavior"::"Always create new inspection", QltyManagementSetup."Create Inspection Behavior"::"Always create retest"] then
            ShowWarningIfCreateTest := true;
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
                Message(ZeroTestsCreatedMsg)
            else
                if Confirm(StrSubstNo(SomeTestsWereCreatedQst, CreatedQltyInspectionIds.Count())) then
                    QltyInspectionCreate.DisplayTestsIfConfigured(true, CreatedQltyInspectionIds);
    end;

    /// <summary>
    /// This will use the generation rule, and create inspections that match the records found with that rule.
    /// </summary>
    /// <param name="QltyInspectionGenRule"></param>
    procedure CreateTestsThatMatchRule(QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        QltyJobQueueManagement: Codeunit "Qlty. Job Queue Management";
        SourceRecordRef: RecordRef;
    begin
        if QltyInspectionGenRule."Activation Trigger" = QltyInspectionGenRule."Activation Trigger"::Disabled then
            exit;

        if QltyInspectionGenRule."Schedule Group" = '' then
            exit;

        QltyJobQueueManagement.CheckIfGenerationRuleCanBeScheduled(QltyInspectionGenRule);

        SourceRecordRef.Open(QltyInspectionGenRule."Source Table No.");
        if QltyInspectionGenRule."Condition Filter" <> '' then
            SourceRecordRef.SetView(QltyInspectionGenRule."Condition Filter");

        QltyInspectionGenRule.SetRecFilter();
        QltyInspectionGenRule.SetRange("Schedule Group", QltyInspectionGenRule."Schedule Group");
        QltyInspectionGenRule.SetRange("Template Code", QltyInspectionGenRule."Template Code");
        if SourceRecordRef.FindSet() then
            QltyInspectionCreate.CreateMultipleTestsWithoutDisplaying(SourceRecordRef, GuiAllowed(), QltyInspectionGenRule, CreatedQltyInspectionIds);
    end;
}
