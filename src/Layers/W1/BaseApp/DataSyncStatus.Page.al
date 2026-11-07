// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Integration;

page 6250 "Data Sync Status"
{
    ApplicationArea = All;
    Caption = 'Data Sync Status';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            part("Data Migration Status"; "Data Migration Overview Part")
            {
                ApplicationArea = All;
                Visible = ShowMigrationErrors;
            }
            part("Migration Errors"; "Data Migration Error Part")
            {
                ApplicationArea = All;
                Caption = 'Migration Errors';
                SubPageView = where("Destination Table ID" = filter(> 0));
                Visible = ShowMigrationErrors;
            }
            part("Posting Errors"; "Data Migration Error Part")
            {
                ApplicationArea = All;
                Caption = 'Posting Errors';
                SubPageView = where("Destination Table ID" = filter(= 0));
                Visible = not ShowMigrationErrors;
            }
        }
    }

    actions
    {
    }

    var
        GenJournalLine: Record "Gen. Journal Line";
        GPBatchTxt: Label 'GP*', Locked = true;
        CustomerBatchTxt: Label 'GPCUST', Locked = true;
        VendorBatchTxt: Label 'GPVEND', Locked = true;
        JnlTemplateNameTxt: Label 'GENERAL', Locked = true;
        ShowMigrationErrors: Boolean;

    local procedure PostingErrors(JournalBatchName: Text)
    var
        SkipPostingErrors: Boolean;
    begin
        OnSkipPostingErrors(SkipPostingErrors, JournalBatchName);
        if SkipPostingErrors then
            exit;

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", JnlTemplateNameTxt);
        GenJournalLine.SetFilter("Journal Batch Name", JournalBatchName);
        if GenJournalLine.FindSet() then
            REPORT.Run(REPORT::"Auto Posting Errors", false, false, GenJournalLine);
    end;

    procedure ParsePosting()
    var
        DataMigrationStatus: Record "Data Migration Status";
    begin
        DataMigrationStatus.Reset();
        if not DataMigrationStatus.IsEmpty() then begin
            PostingErrors(GPBatchTxt);
            PostingErrors(VendorBatchTxt);
            PostingErrors(CustomerBatchTxt);
        end;
    end;

    procedure SetMigrationVisibility(IsMigration: Boolean)
    begin
        ShowMigrationErrors := IsMigration;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSkipPostingErrors(var SkipPostingErrors: Boolean; JournalBatchName: Text)
    begin
    end;
}

