// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Provides list view access to posted general journal batches for historical analysis and audit trail purposes.
/// Displays completed journal batch information including posting details, template references, and batch descriptions.
/// </summary>
/// <remarks>
/// Historical journal batch list for posted batch analysis and audit purposes. Provides read-only access to
/// batch-level posting information including template references, posting dates, and batch identification details.
/// Key features: Posted batch browsing, template and batch identification, posting history access, audit trail support.
/// Integration: Links to posted journal lines and G/L register entries for complete posting history analysis.
/// </remarks>
page 185 "Posted General Journal Batch"
{
    Caption = 'Posted General Journal Batch';
    PageType = List;
    SourceTable = "Posted Gen. Journal Batch";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Journal Template Name"; Rec."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}
