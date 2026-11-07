// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Read-only worksheet page for viewing posted deferral schedules.
/// Displays historical deferral schedule information after posting has occurred.
/// </summary>
page 1704 "Deferral Schedule View"
{
    Caption = 'Deferral Schedule View';
    DataCaptionFields = "Start Date";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    ShowFilter = false;
    SourceTable = "Posted Deferral Header";

    layout
    {
        area(content)
        {
            part("<Deferral Shedule View Subform>"; "Deferral Schedule View Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Deferral Doc. Type" = field("Deferral Doc. Type"),
                              "Gen. Jnl. Document No." = field("Gen. Jnl. Document No."),
                              "Account No." = field("Account No."),
                              "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
            }
        }
    }

    actions
    {
    }
}

