// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Card page displaying detailed information for individual consolidation log entries.
/// Provides read-only view of consolidation process log details and execution information.
/// </summary>
/// <remarks>
/// Card page for viewing detailed consolidation log entry information including process details and status.
/// Read-only interface for examining individual consolidation operation logs and troubleshooting.
/// Supports consolidation audit trails and process monitoring through detailed log entry examination.
/// </remarks>
page 1836 "Consolidation Log Entry"
{
    Caption = 'Consolidation Log Entry';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Consolidation Log Entry";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Entry No."; Rec."Entry No.")
            {
                ApplicationArea = All;
            }
            field("Created at"; Rec.SystemCreatedAt)
            {
                ApplicationArea = All;
                ToolTip = 'The date and time when the log entry was created.';
            }
            field("Status Code"; Rec."Status Code")
            {
                ApplicationArea = All;
            }
            field(Request; Rec.GetRequestAsText())
            {
                ApplicationArea = All;
                Caption = 'Request';
                MultiLine = true;
                ToolTip = 'The request that was sent to the API of the business unit.';
            }
            field(Response; Rec.GetResponseAsText())
            {
                ApplicationArea = All;
                Caption = 'Response';
                MultiLine = true;
                ToolTip = 'The response that was received from the API for this request.';
            }
        }
    }
}
