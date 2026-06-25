// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.ExternalResults;

/// <summary>
/// Lists the externally imported quality result log entries.
/// </summary>
page 20586 "Qlty. Import Log"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Qlty. Import Log Entry";
    Caption = 'Quality Import Log';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the number of the import log entry.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                }
                field("Customer Name"; Rec."Customer Name")
                {
                }
                field("Contact Email"; Rec."Contact Email")
                {
                }
                field("Result Value"; Rec."Result Value")
                {
                    ToolTip = 'Specifies the measured result value.';
                }
                field("Imported At"; Rec."Imported At")
                {
                }
            }
        }
    }
}
