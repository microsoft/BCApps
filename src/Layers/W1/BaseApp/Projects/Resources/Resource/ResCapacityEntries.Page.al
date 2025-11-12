// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

page 224 "Res. Capacity Entries"
{
    ApplicationArea = Jobs;
    Caption = 'Resource Capacity Entries';
    DataCaptionFields = "Resource No.", "Resource Group No.";
    Editable = false;
    PageType = List;
    SourceTable = "Res. Capacity Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date for which the capacity entry is valid.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the corresponding resource.';
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the corresponding resource group assigned to the resource.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the capacity that is calculated and recorded. The capacity is in the unit of measure.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
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

