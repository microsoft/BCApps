// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.AuditCodes;

/// <summary>
/// Reason codes supplement the source codes and are used to indicate why an entry was created.
/// </summary>
page 259 "Reason Codes"
{
    ApplicationArea = All;
    Caption = 'Reason Codes';
    PageType = List;
    SourceTable = "Reason Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                /// <summary>
                /// Specifies a reason code to attach to the entry.
                /// </summary>
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a reason code to attach to the entry.';
                }
                /// <summary>
                /// Specifies a description of what the code stands for.
                /// </summary>
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of what the code stands for.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

