// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Displays validation errors encountered during VAT report processing and submission.
/// Provides read-only view of error log entries for troubleshooting VAT report issues.
/// </summary>
page 745 "VAT Report Error Log"
{
    Caption = 'VAT Report Error Log';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Error Log";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

