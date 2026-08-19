// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Read-only worksheet page for viewing archived deferral schedules.
/// Displays historical deferral schedule information from archived documents.
/// </summary>
page 1706 "Deferral Schedule Archive"
{
    Caption = 'Deferral Schedule Archive';
    DataCaptionFields = "Schedule Description";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    ShowFilter = false;
    SourceTable = "Deferral Header Archive";

    layout
    {
        area(content)
        {
            part("<Deferral Sched. Arch. Subform>"; "Deferral Sched. Arch. Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Deferral Doc. Type" = field("Deferral Doc. Type"),
                              "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No."),
                              "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                              "Version No." = field("Version No.");
            }
        }
    }

    actions
    {
    }
}

