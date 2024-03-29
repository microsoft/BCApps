// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 2 "No. Series Where-Used List"
{
    Caption = 'No. Series Where-Used List';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = List;
    SourceTable = "No. Series Where-Used";

    layout
    {
        area(content)
        {
            repeater(records)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object number of the setup table where the No. series is used.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Table Name of the setup table where the No. series is used.';
                }
                field(Line; Rec.Line)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a reference to Line in the setup table, where the No. series is used.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the field in the setup table where the No. series is used.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Details';
                Image = ViewDetails;
                ToolTip = 'View more details on the selected record.';

                trigger OnAction()
                var
                    CalcNoSeriesWhereUsed: Codeunit "Calc. No. Series Where-Used";
                begin
                    Clear(CalcNoSeriesWhereUsed);
                    CalcNoSeriesWhereUsed.ShowSetupForm(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowDetails_Promoted; ShowDetails)
                {
                }
            }
        }
    }
}