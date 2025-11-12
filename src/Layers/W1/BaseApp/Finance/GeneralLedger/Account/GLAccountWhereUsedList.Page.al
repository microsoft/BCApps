// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

page 99 "G/L Account Where-Used List"
{
    Caption = 'G/L Account Where-Used List';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = List;
    SourceTable = "G/L Account Where-Used";
    AboutTitle = 'About G/L Account Where-Used';
    AboutText = 'The G/L Account Where-Used page shows the setup tables that use the given G/L account. Each line refers to one line in a setup table. The page can list several lines from the same setup table if, for example, more than one posting group in a posting setup table uses the account. You can explore details for a line by choosing the Show Details action.';
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object number of the setup table where the G/L account is used.';
                    Visible = false;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Table Name of the setup table where the G/L account is used.';
                }
                field(Line; Rec.Line)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a reference to Line in the setup table, where the G/L account is used. For example, the reference could be a posting group code.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the field in the setup table where the G/L account is used.';
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
        area(processing)
        {
            action(ShowDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Show Details';
                Image = ViewDetails;
                ToolTip = 'View more details on the selected record.';

                trigger OnAction()
                var
                    CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
                begin
                    Clear(CalcGLAccWhereUsed);
                    CalcGLAccWhereUsed.ShowSetupForm(Rec);
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

