// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

page 50163 "BC14 Migration Error Overview"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "BC14 Migration Errors";
    Caption = 'BC14 Migration Errors';
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company where the error occurred.';
                    Editable = false;
                }

                field("Source Table Name"; Rec."Source Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source table name.';
                    Editable = false;
                }

                field("Source Record Key"; Rec."Source Record Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the key of the source record that failed.';
                    Editable = false;
                }

                field("Destination Table ID"; Rec."Destination Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the destination table where the error occurred.';
                    Editable = false;
                }

                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error message.';
                    Editable = false;
                }

                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error code.';
                    Editable = false;
                }

                field("Created On"; Rec."Created On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the error was logged.';
                    Editable = false;
                }

                field("Resolved"; Rec."Resolved")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the error has been resolved.';
                    Editable = false;
                }

                field("Resolved On"; Rec."Resolved On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the error was resolved.';
                    Editable = false;
                }

                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many times retry was attempted.';
                    Editable = false;
                }

                field("Resolution Notes"; Rec."Resolution Notes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies notes about how the error was resolved.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditSourceRecord)
            {
                ApplicationArea = All;
                Caption = 'Edit Source Record';
                ToolTip = 'Open the source buffer record to fix the data that caused the error.';
                Image = Edit;

                trigger OnAction()
                var
                    BC14HelperFunctions: Codeunit "BC14 Helper Functions";
                begin
                    if Rec."Source Table ID" = 0 then begin
                        Message(SourceRecordNotAvailableMsg, Rec."Source Table Name", Rec."Source Record Key");
                        exit;
                    end;

                    BC14HelperFunctions.OpenBufferRecord(Rec."Source Table ID", Rec."Record Id");
                    CurrPage.Update(false);
                end;
            }

            action(RetrySelected)
            {
                ApplicationArea = All;
                Caption = 'Retry';
                ToolTip = 'Retry migration for the selected error records. Fix the source data first using Edit.';
                Image = Refresh;

                trigger OnAction()
                var
                    SelectedErrors: Record "BC14 Migration Errors";
                    BC14CompanyAdditionalSettings: Record "BC14CompanyAdditionalSettings";
                    BC14MigrationRunner: Codeunit "BC14 Migration Runner";
                    RetryCount: Integer;
                    IsPaused: Boolean;
                    StopOnFirstError: Boolean;
                begin
                    CurrPage.SetSelectionFilter(SelectedErrors);
                    RetryCount := SelectedErrors.Count();

                    if RetryCount = 0 then begin
                        Message('No records selected.');
                        exit;
                    end;

                    BC14CompanyAdditionalSettings.GetSingleInstance();
                    IsPaused := BC14CompanyAdditionalSettings.IsMigrationPaused();
                    StopOnFirstError := BC14CompanyAdditionalSettings.GetStopOnFirstTransformationError();

                    if not Confirm(RetrySelectedQst, false, RetryCount) then
                        exit;

                    // Mark selected as scheduled for retry
                    SelectedErrors.ModifyAll("Scheduled For Retry", true);
                    Commit();

                    // Run retry for the selected records
                    BC14MigrationRunner.RetryFailedRecords();

                    // If in Stop On First Error mode and migration was paused, 
                    // automatically continue migration after retry
                    if StopOnFirstError and IsPaused then begin
                        // Check if the retried records were resolved
                        SelectedErrors.SetRange("Resolved", true);
                        if SelectedErrors.Count() = RetryCount then begin
                            // All selected records resolved - continue migration
                            if Confirm(RetrySuccessContinueQst) then
                                BC14MigrationRunner.ContinueMigration()
                            else
                                Message(RetrySuccessManualContinueMsg);
                        end else
                            Message(RetryPartialSuccessMsg);
                    end else
                        Message(RetryCompletedMsg);

                    CurrPage.Update(false);
                end;
            }

            action(DeleteAllErrors)
            {
                ApplicationArea = All;
                Caption = 'Delete All Errors';
                ToolTip = 'Delete all error records.';
                Image = Delete;

                trigger OnAction()
                var
                    BC14MigrationErrors: Record "BC14 Migration Errors";
                    DeletedCount: Integer;
                begin
                    if not Confirm(DeleteAllErrorsQst, false) then
                        exit;

                    DeletedCount := BC14MigrationErrors.Count();
                    BC14MigrationErrors.DeleteAll();
                    Message(ErrorsDeletedMsg, DeletedCount);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(EditSourceRecord_Promoted; EditSourceRecord)
                {
                }
                actionref(RetrySelected_Promoted; RetrySelected)
                {
                }
                actionref(DeleteAllErrors_Promoted; DeleteAllErrors)
                {
                }
            }
        }
    }

    var
        DeleteAllErrorsQst: Label 'Do you want to DELETE ALL error records? This cannot be undone.';
        RetrySelectedQst: Label 'Retry migration for %1 selected record(s)?', Comment = '%1 = Count';
        ErrorsDeletedMsg: Label '%1 error records have been deleted.', Comment = '%1 = Count';
        RetryCompletedMsg: Label 'Retry completed. Check the list - resolved records show Resolved = Yes.';
        RetrySuccessContinueQst: Label 'All selected records were migrated successfully.\Do you want to continue the migration now?';
        RetrySuccessManualContinueMsg: Label 'Retry successful. Use "Continue Migration" in BC14 Migration Configuration when ready to continue.';
        RetryPartialSuccessMsg: Label 'Retry completed but some records still have errors. Fix them and retry again.';
        SourceRecordNotAvailableMsg: Label 'Source record %2 in table %1 cannot be opened. The record reference is unavailable.', Comment = '%1 = Source Table Name, %2 = Source Record Key';
}
