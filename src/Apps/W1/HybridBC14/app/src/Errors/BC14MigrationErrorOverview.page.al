// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using System.Integration;

page 46863 "BC14 Migration Error Overview"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Data Migration Error";
    SourceTableTemporary = true;
    SourceTableView = sorting("Created On") order(descending);
    Caption = 'Migration Errors';
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

                field("Error Dismissed"; Rec."Error Dismissed")
                {
                    ApplicationArea = All;
                    Caption = 'Resolved';
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
                    BC14ErrorFilter: Record "Data Migration Error";
                    BC14ErroredBufferRecords: Page "BC14 Errored Buffer Records";
                begin
                    if Rec."Source Table ID" = 0 then begin
                        Message(SourceRecordNotAvailableMsg, Rec."Source Table Name", Rec."Source Record Key");
                        exit;
                    end;

                    if Rec."Source Record Key" = '' then begin
                        Message(BulkErrorNoSourceRecordMsg, Rec."Source Table Name");
                        exit;
                    end;

                    BC14ErrorFilter.SetRange("Source Table ID", Rec."Source Table ID");
                    BC14ErrorFilter.SetRange("Company Name", Rec."Company Name");
                    BC14ErroredBufferRecords.SetTableView(BC14ErrorFilter);
                    BC14ErroredBufferRecords.Run();
                end;
            }

            action(ContinueMigration)
            {
                ApplicationArea = All;
                Caption = 'Continue migration';
                ToolTip = 'Continue migration for the company of the selected error record. Records that already succeeded will be skipped automatically.';
                Image = Refresh;
                trigger OnAction()
                var
                    DataMigrationError: Record "Data Migration Error";
                    BC14MigrationRunner: Codeunit "BC14 Migration Runner";
                    TargetCompany: Text[30];
                    UnresolvedCount: Integer;
                begin
                    TargetCompany := Rec."Company Name";
                    if TargetCompany = '' then begin
                        Message(NoCompanySelectedMsg);
                        exit;
                    end;

                    DataMigrationError.ChangeCompany(TargetCompany);
                    DataMigrationError.SetRange("Error Dismissed", false);
                    UnresolvedCount := DataMigrationError.Count();

                    if UnresolvedCount > 0 then begin
                        if not Confirm(UnresolvedErrorsWarningQst, false, UnresolvedCount, TargetCompany) then
                            exit;
                    end else
                        if not Confirm(ContinueMigrationQst, false, TargetCompany) then
                            exit;

                    BC14MigrationRunner.ContinueMigrationForCompany(TargetCompany);

                    Message(ContinueMigrationScheduledMsg, TargetCompany);

                    LoadErrorsFromAllCompanies();
                    CurrPage.Update(false);
                end;
            }

            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Reload errors from every Business Central 14 migration company.';
                Image = Refresh;
                trigger OnAction()
                begin
                    LoadErrorsFromAllCompanies();
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
                actionref(ContinueMigration_Promoted; ContinueMigration)
                {
                }
                actionref(Refresh_Promoted; Refresh)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadErrorsFromAllCompanies();
    end;

    local procedure LoadErrorsFromAllCompanies()
    var
        HybridCompany: Record "Hybrid Company";
        SourceError: Record "Data Migration Error";
        SourceCompanyName: Text[30];
        SyntheticId: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if not HybridCompany.FindSet() then
            exit;

        SyntheticId := 0;
        repeat
            SourceCompanyName := CopyStr(HybridCompany.Name, 1, MaxStrLen(SourceCompanyName));
            SourceError.Reset();
            SourceError.ChangeCompany(SourceCompanyName);
            if SourceError.FindSet() then
                repeat
                    Rec.Init();
                    Rec.TransferFields(SourceError, true);
                    // Override Id with a synthetic per-page key. The platform Id is per-company
                    // autoincrement and would collide across companies inside this temp aggregator.
                    SyntheticId += 1;
                    Rec.Id := SyntheticId;
                    Rec."Company Name" := SourceCompanyName;
                    if Rec.Insert(false) then;
                until SourceError.Next() = 0;
        until HybridCompany.Next() = 0;
    end;

    var
        ContinueMigrationQst: Label 'Continue migration for company %1?', Comment = '%1 = Company Name';
        UnresolvedErrorsWarningQst: Label 'There are still %1 unresolved errors for company %2. Continue migration anyway?', Comment = '%1 = Number of unresolved errors, %2 = Company Name';
        NoCompanySelectedMsg: Label 'Please select an error record first.';
        ContinueMigrationScheduledMsg: Label 'Migration has been scheduled to continue for company %1. Check Cloud Migration Management for progress.', Comment = '%1 = Company Name';
        SourceRecordNotAvailableMsg: Label 'Source record %2 in table %1 cannot be opened. The record reference is unavailable.', Comment = '%1 = Source Table Name, %2 = Source Record Key';
        BulkErrorNoSourceRecordMsg: Label 'This error was reported by a bulk transfer of table %1, so there is no individual source record to edit. Use Continue migration to retry the transfer.', Comment = '%1 = Source Table Name';
}
