// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

page 2592 "Dimension Corrections"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Dimension Corrections';
    UsageCategory = Administration;
    SourceTable = "Dimension Correction";
    CardPageId = "Dimension Correction Draft";
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                Editable = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the identifier of the correction.';
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies information about the correction. For example, this might provide a reason for the correction.';
                }

                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the status of the correction.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Entry No.");
        Rec.Ascending(false);
    end;
}
