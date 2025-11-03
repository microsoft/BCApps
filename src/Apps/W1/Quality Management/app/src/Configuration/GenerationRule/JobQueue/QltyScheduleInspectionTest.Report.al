// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule.JobQueue;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;

report 20412 "Qlty. Schedule Inspection Test"
{
    Caption = 'Quality Management - Schedule Inspection Test';
    AdditionalSearchTerms = 'Periodic inspections, scheduled inspections,schedule test,schedule inspection';
    Description = 'This report is intended to be scheduled in the job queue to allow the ability to schedule tests.';
    ProcessingOnly = true;
    ApplicationArea = QualityManagement;
    UsageCategory = Tasks;
    AllowScheduling = true;

    dataset
    {
        dataitem(CurrentTestGenerationRule; "Qlty. In. Test Generation Rule")
        {
            RequestFilterFields = "Schedule Group", "Template Code", Description;
            DataItemTableView = where("Activation Trigger" = filter(<> Disabled));

            trigger OnAfterGetRecord()
            begin
                CreateTestsThatMatchRule(CurrentTestGenerationRule);
            end;

            trigger OnPreDataItem()
            begin
                if CurrentTestGenerationRule.GetFilter("Schedule Group") = '' then
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
                    InstructionalText = 'On your Quality Management Setup page you have the Create Test Behavior set to a setting that will cause tests to be created whenever this report is run even if there are already tests for that item and lot. Make sure this is compatible with the scenario you are solving.';

                    field(ChooseOpenQualityManagementSetup; 'Click here to open the Quality Management Setup page.')
                    {
                        ShowCaption = false;
                        ApplicationArea = QualityManagement;

                        trigger OnDrillDown()
                        begin
                            QltyManagementSetup.Get();
                            Page.RunModal(Page::"Qlty. Management Setup", QltyManagementSetup, QltyManagementSetup.FieldNo("Create Test Behavior"));
                        end;
                    }
                }
            }
        }
    }

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ShowWarningIfCreateTest: Boolean;
        ScheduleGroupIsMandatoryErr: Label 'It is mandatory to define a schedule group on the test generation rule(s), and then configure the schedule with the same group. This will help make sure that inadvertent configuration does not cause excessive test generation. ';

    trigger OnInitReport()
    begin
        QltyManagementSetup.Get();
        if QltyManagementSetup."Create Test Behavior" in [QltyManagementSetup."Create Test Behavior"::"Always create new test", QltyManagementSetup."Create Test Behavior"::"Always create retest"] then
            ShowWarningIfCreateTest := true;
    end;

    /// <summary>
    /// This will use the generation rule, and create tests that match the records found with that rule.
    /// </summary>
    /// <param name="QltyInTestGenerationRule"></param>
    procedure CreateTestsThatMatchRule(QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule")
    var
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        QltyJobQueueManagement: Codeunit "Qlty. Job Queue Management";
        SourceRecordRef: RecordRef;
    begin
        if QltyInTestGenerationRule."Activation Trigger" = QltyInTestGenerationRule."Activation Trigger"::Disabled then
            exit;

        QltyJobQueueManagement.TestIfGenerationRuleCanBeScheduled(QltyInTestGenerationRule);

        SourceRecordRef.Open(QltyInTestGenerationRule."Source Table No.");
        if QltyInTestGenerationRule."Condition Filter" <> '' then
            SourceRecordRef.SetView(QltyInTestGenerationRule."Condition Filter");

        QltyInTestGenerationRule.SetRecFilter();
        if SourceRecordRef.FindSet() then
            QltyInspectionTestCreate.CreateMultipleTestsForMultipleRecords(SourceRecordRef, GuiAllowed(), QltyInTestGenerationRule);
    end;
}
