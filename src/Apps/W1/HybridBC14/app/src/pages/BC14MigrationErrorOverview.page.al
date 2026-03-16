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

                field("Scheduled For Retry"; Rec."Scheduled For Retry")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this record is scheduled for retry.';
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
            action(MarkAsResolved)
            {
                ApplicationArea = All;
                Caption = 'Mark as Resolved';
                ToolTip = 'Mark the selected error as resolved.';
                Image = Approve;

                trigger OnAction()
                var
                    ResolutionNote: Text[500];
                begin
                    ResolutionNote := '';
                    if Page.RunModal(Page::"BC14 Resolution Notes Dialog", Rec) = Action::OK then begin
                        Rec.MarkAsResolved(Rec."Resolution Notes");
                        CurrPage.Update(false);
                    end;
                end;
            }

            action(ResolveAllErrors)
            {
                ApplicationArea = All;
                Caption = 'Resolve All Errors';
                ToolTip = 'Mark all unresolved errors as resolved.';
                Image = ApplyEntries;

                trigger OnAction()
                var
                    BC14MigrationErrors: Record "BC14 Migration Errors";
                    ResolvedCount: Integer;
                begin
                    if not Confirm(ResolveAllErrorsQst, false) then
                        exit;

                    BC14MigrationErrors.SetRange("Resolved", false);
                    if BC14MigrationErrors.FindSet() then
                        repeat
                            BC14MigrationErrors.MarkAsResolved(BulkResolvedLbl);
                            ResolvedCount += 1;
                        until BC14MigrationErrors.Next() = 0;

                    Message(ErrorsResolvedMsg, ResolvedCount);
                    CurrPage.Update(false);
                end;
            }

            action(DeleteAllErrors)
            {
                ApplicationArea = All;
                Caption = 'Delete All Errors';
                ToolTip = 'Delete all error records (resolved and unresolved).';
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

            action(ScheduleForRetry)
            {
                ApplicationArea = All;
                Caption = 'Schedule for Retry';
                ToolTip = 'Schedule the selected record for retry during next migration run.';
                Image = Refresh;

                trigger OnAction()
                begin
                    Rec.ScheduleForRetry();
                    CurrPage.Update(false);
                end;
            }

            action(UnblockForManualFix)
            {
                ApplicationArea = All;
                Caption = 'Unblock Record';
                ToolTip = 'Unblock the selected failed record and schedule it for retry.';
                Image = ReOpen;

                trigger OnAction()
                begin
                    Rec.UnblockForRetry(ManuallyUnblockedLbl);
                    Message(RecordUnblockedMsg, Rec."Source Record Key");
                    CurrPage.Update(false);
                end;
            }

            action(OpenSourceBufferRecord)
            {
                ApplicationArea = All;
                Caption = 'Open Source Buffer Record';
                ToolTip = 'Open the failed source record for manual edits.';
                Image = EditLines;

                trigger OnAction()
                var
                    BC14BufferTableHelper: Codeunit "BC14 Buffer Table Helper";
                begin
                    if Rec."Source Table ID" = 0 then begin
                        Message(SourceRecordNotAvailableMsg, Rec."Source Table Name", Rec."Source Record Key");
                        exit;
                    end;

                    BC14BufferTableHelper.OpenBufferRecord(Rec."Source Table ID", Rec."Record Id");
                    CurrPage.Update(false);
                end;
            }

            action(UnblockAndEditSourceRecord)
            {
                ApplicationArea = All;
                Caption = 'Unblock and Edit Source Record';
                ToolTip = 'Unblock the failed record and open the source buffer record for manual correction.';
                Image = Edit;

                trigger OnAction()
                var
                    BC14BufferTableHelper: Codeunit "BC14 Buffer Table Helper";
                begin
                    if Rec."Source Table ID" = 0 then begin
                        Message(SourceRecordNotAvailableMsg, Rec."Source Table Name", Rec."Source Record Key");
                        exit;
                    end;

                    Rec.UnblockForRetry(ManuallyUnblockedForEditLbl);
                    BC14BufferTableHelper.OpenBufferRecord(Rec."Source Table ID", Rec."Record Id");
                    CurrPage.Update(false);
                end;
            }

            action(RetrySelectedRecords)
            {
                ApplicationArea = All;
                Caption = 'Retry Selected Records';
                ToolTip = 'Retry migration for selected records now.';
                Image = Start;

                trigger OnAction()
                var
                    BC14MigrationRunner: Codeunit "BC14 Migration Runner";
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    Rec.ModifyAll("Scheduled For Retry", true);
                    BC14MigrationRunner.RetryFailedRecords();
                    CurrPage.Update(false);
                end;
            }

            action(ShowUnresolvedOnly)
            {
                ApplicationArea = All;
                Caption = 'Show Unresolved Only';
                ToolTip = 'Filter to show only unresolved errors.';
                Image = FilterLines;

                trigger OnAction()
                begin
                    Rec.SetRange("Resolved", false);
                    CurrPage.Update(false);
                end;
            }

            action(ShowAll)
            {
                ApplicationArea = All;
                Caption = 'Show All';
                ToolTip = 'Show all errors including resolved ones.';
                Image = ShowList;

                trigger OnAction()
                begin
                    Rec.SetRange("Resolved");
                    CurrPage.Update(false);
                end;
            }

            action(ClearResolvedErrors)
            {
                ApplicationArea = All;
                Caption = 'Clear Resolved Errors';
                ToolTip = 'Delete all resolved error records.';
                Image = ClearLog;

                trigger OnAction()
                var
                    BC14MigrationErrors: Record "BC14 Migration Errors";
                begin
                    if Confirm(DeleteResolvedErrorsQst, false) then begin
                        BC14MigrationErrors.SetRange("Resolved", true);
                        BC14MigrationErrors.DeleteAll();
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(MarkAsResolved_Promoted; MarkAsResolved)
                {
                }
                actionref(ResolveAllErrors_Promoted; ResolveAllErrors)
                {
                }
                actionref(DeleteAllErrors_Promoted; DeleteAllErrors)
                {
                }
                actionref(ScheduleForRetry_Promoted; ScheduleForRetry)
                {
                }
                actionref(UnblockForManualFix_Promoted; UnblockForManualFix)
                {
                }
                actionref(OpenSourceBufferRecord_Promoted; OpenSourceBufferRecord)
                {
                }
                actionref(UnblockAndEditSourceRecord_Promoted; UnblockAndEditSourceRecord)
                {
                }
                actionref(RetrySelectedRecords_Promoted; RetrySelectedRecords)
                {
                }
            }
        }
    }

    var
        ResolveAllErrorsQst: Label 'Do you want to mark ALL unresolved errors as resolved?';
        DeleteAllErrorsQst: Label 'Do you want to DELETE ALL error records? This cannot be undone.';
        DeleteResolvedErrorsQst: Label 'Do you want to delete all resolved error records?';
        ErrorsResolvedMsg: Label '%1 errors have been marked as resolved.', Comment = '%1 = Count';
        ErrorsDeletedMsg: Label '%1 error records have been deleted.', Comment = '%1 = Count';
        BulkResolvedLbl: Label 'Bulk resolved';
        ManuallyUnblockedLbl: Label 'Manually unblocked by user';
        ManuallyUnblockedForEditLbl: Label 'Manually unblocked for source record correction';
        RecordUnblockedMsg: Label 'Record %1 has been unblocked and scheduled for retry.', Comment = '%1 = Source Record Key';
        SourceRecordNotAvailableMsg: Label 'Source record %2 in table %1 cannot be opened. The record reference is unavailable.', Comment = '%1 = Source Table Name, %2 = Source Record Key';
}
