// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Automation;
using System.Utilities;

/// <summary>
/// Stores the configuration settings for an automated send reminders action including email and filter options.
/// </summary>
table 6755 "Send Reminders Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique code identifying this send reminders setup.
        /// </summary>
        field(1; Code; Code[50])
        {
            ToolTip = 'Specifies a code for the reminder setup';
        }
        /// <summary>
        /// Specifies the reminder action group to which this setup belongs.
        /// </summary>
        field(2; "Action Group Code"; Code[50])
        {
        }
        /// <summary>
        /// Specifies a description of this send reminders setup.
        /// </summary>
        field(3; Description; Text[50])
        {
            ToolTip = 'Specifies a description for the reminder setup';
        }
        /// <summary>
        /// Indicates whether reminders should be sent by email.
        /// </summary>
        field(10; "Send by Email"; Boolean)
        {
            ToolTip = 'Specifies whether to send reminders by email';
            InitValue = true;
        }
        /// <summary>
        /// Indicates whether reminders should be printed.
        /// </summary>
        field(11; Print; Boolean)
        {
            ToolTip = 'Specifies whether to print reminders';
        }
        /// <summary>
        /// Indicates whether the customer's document sending profile should be used.
        /// </summary>
        field(12; "Use Document Sending Profile"; Boolean)
        {
            ToolTip = 'Specifies whether to use a document sending profile when sending reminders by email';
        }
        /// <summary>
        /// Indicates whether sending the reminder should be logged as an interaction.
        /// </summary>
        field(13; "Log Interaction"; Boolean)
        {
            ToolTip = 'Specifies whether to log an interaction when a reminder is sent';
        }
        /// <summary>
        /// Indicates whether amounts not yet due should be shown on the reminder.
        /// </summary>
        field(14; "Show Amounts Not Due"; Boolean)
        {
            ToolTip = 'Specifies whether to show amounts that are not due on the reminder';
        }
        /// <summary>
        /// Indicates whether detailed information about multiple interest rates should be shown.
        /// </summary>
        field(15; "Show Multiple Interest Rates"; Boolean)
        {
            ToolTip = 'Specifies whether to show multiple interest rates on the reminder';
        }
        /// <summary>
        /// Specifies whether and which invoice documents should be attached to the reminder email.
        /// </summary>
        field(16; "Attach Invoice Documents"; Option)
        {
            OptionCaption = 'No, Overdue only, All';
            ToolTip = 'Specifies whether to attach all invoice documents to the reminder email';
            OptionMembers = No,"Overdue only",All;
        }
        /// <summary>
        /// Indicates whether reminders can be sent multiple times for the same reminder level.
        /// </summary>
        field(17; "Send Multiple Times Per Level"; Boolean)
        {
            ToolTip = 'Specifies whether to send multiple reminders to the same customer';
        }
        /// <summary>
        /// Specifies the minimum time interval that must pass between sending reminders to the same customer.
        /// </summary>
        field(18; "Minimum Time Between Sending"; Duration)
        {
            ToolTip = 'Specifies the minimum number of days between sending reminder to the same customer';
        }
        /// <summary>
        /// Stores the filter criteria for selecting issued reminders to send.
        /// </summary>
        field(20; "Reminder Filter"; Blob)
        {
        }
    }
    keys
    {
        key(Key1; Code, "Action Group Code")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Opens a filter page to allow the user to set the issued reminder selection filter for sending.
    /// </summary>
    procedure SetReminderSelectionFilter()
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        TempBlob: Codeunit "Temp Blob";
        IssuedReminderHeaderRecordRef: RecordRef;
        SelectionFilterOutStream: OutStream;
        SelectionFilterInStream: InStream;
        ExistingFilters: Text;
    begin
        IssuedReminderHeaderRecordRef.Open(Database::"Issued Reminder Header");
        ExistingFilters := GetReminderSelectionFilter();

        TempBlob.CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        if not RequestPageParametersHelper.OpenPageToGetFilter(IssuedReminderHeaderRecordRef, SelectionFilterOutStream, ExistingFilters) then
            exit;

        Clear(Rec."Reminder Filter");
        TempBlob.CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        Rec."Reminder Filter".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        CopyStream(SelectionFilterOutStream, SelectionFilterInStream);

        Rec.Modify();
        Rec.CalcFields("Reminder Filter");
    end;

    /// <summary>
    /// Gets the display text for the issued reminder selection filter.
    /// </summary>
    /// <returns>A formatted display text showing the filter criteria.</returns>
    procedure GetReminderSelectionDisplayText(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterDisplayText(Rec, Database::"Issued Reminder Header", Rec.FieldNo("Reminder Filter")));
    end;

    /// <summary>
    /// Gets the view filter for the issued reminder selection that can be applied to a record.
    /// </summary>
    /// <returns>The view filter string for issued reminder header records.</returns>
    procedure GetReminderSelectionFilterView(): Text
    var
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
    begin
        exit(RequestPageParametersHelper.GetFilterViewFilters(Rec, Database::"Issued Reminder Header", Rec.FieldNo("Reminder Filter")));
    end;

    local procedure GetReminderSelectionFilter(): Text
    var
        SelectionFilterInStream: InStream;
        SelectionFilterText: Text;
    begin
        Clear(SelectionFilterText);
        Rec.CalcFields("Reminder Filter");
        Rec."Reminder Filter".CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        if not Rec."Reminder Filter".HasValue() then
            exit;

        SelectionFilterInStream.ReadText(SelectionFilterText);
        exit(SelectionFilterText);
    end;
}