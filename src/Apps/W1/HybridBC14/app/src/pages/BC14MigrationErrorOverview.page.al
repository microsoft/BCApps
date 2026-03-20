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
    SourceTableView = sorting(Id) order(descending);
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

                    BC14HelperFunctions.OpenBufferRecord(Rec."Source Table ID", Rec."Record Id", Rec."Company Name");
                    CurrPage.Update(false);
                end;
            }

            action(RetrySelected)
            {
                ApplicationArea = All;
                Caption = 'Rerun Migration';
                ToolTip = 'Rerun migration to retry all unresolved errors. Records that already succeeded will be skipped automatically.';
                Image = Refresh;

                trigger OnAction()
                var
                    BC14MigrationErrors: Record "BC14 Migration Errors";
                    BC14MigrationRunner: Codeunit "BC14 Migration Runner";
                    UnresolvedCount: Integer;
                begin
                    // Rerun only works for errors in the current company context.
                    // The Runner executes in CompanyName(), so cross-company retry is not possible from here.
                    BC14MigrationErrors.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
                    BC14MigrationErrors.SetRange("Resolved", false);
                    UnresolvedCount := BC14MigrationErrors.Count();

                    if UnresolvedCount = 0 then begin
                        Message(NoUnresolvedErrorsForCurrentCompanyMsg);
                        exit;
                    end;

                    if not Confirm(RerunMigrationQst, false, UnresolvedCount, CompanyName()) then
                        exit;

                    // Mark all unresolved as scheduled for retry
                    BC14MigrationErrors.ModifyAll("Scheduled For Retry", true);
                    Commit();

                    // Run retry - this reruns migration, skipping already-succeeded records
                    BC14MigrationRunner.RetryFailedRecords();

                    // Report results
                    BC14MigrationErrors.Reset();
                    BC14MigrationErrors.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
                    BC14MigrationErrors.SetRange("Resolved", false);
                    if BC14MigrationErrors.IsEmpty() then
                        Message(RerunAllResolvedMsg)
                    else
                        Message(RerunPartialSuccessMsg, BC14MigrationErrors.Count());

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

                    BC14MigrationErrors.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
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
        RerunMigrationQst: Label 'There are %1 unresolved error(s) for company %2. Rerun migration to retry them?\Already succeeded records will be skipped.\Note: This only retries errors for the current company. For other companies, switch to that company or use the Cloud Migration Management page.', Comment = '%1 = Count, %2 = Company Name';
        ErrorsDeletedMsg: Label '%1 error records have been deleted.', Comment = '%1 = Count';
        RerunAllResolvedMsg: Label 'Rerun completed successfully. All errors have been resolved.';
        RerunPartialSuccessMsg: Label 'Rerun completed. %1 error(s) still unresolved - review and fix the source data, then rerun again.', Comment = '%1 = Count';
        NoUnresolvedErrorsForCurrentCompanyMsg: Label 'There are no unresolved errors for the current company. If you see errors for other companies, switch to that company or use the Cloud Migration Management page to rerun the upgrade.';
        SourceRecordNotAvailableMsg: Label 'Source record %2 in table %1 cannot be opened. The record reference is unavailable.', Comment = '%1 = Source Table Name, %2 = Source Record Key';
}
