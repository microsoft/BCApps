// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

page 7608 "Where-Used Base Calendar"
{
    Caption = 'Where-Used Base Calendar';
    DataCaptionFields = "Base Calendar Code";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Where Used Base Calendar";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Suite;
                    Caption = 'Source Type';
                    ToolTip = 'Specifies whether this customized calendar entry was set up for your company, a customer, vendor, location, shipping agent, or a service.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Source Code';
                    ToolTip = 'Specifies the source identity of the business partner the customized calendar is set up for.';
                }
                field("Additional Source Code"; Rec."Additional Source Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Additional Source Code';
                    ToolTip = 'Specifies the code of the shipping agent service if the Source Type field contains Shipping Agent.';
                }
                field("Source Name"; Rec."Source Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Source Name';
                    ToolTip = 'Specifies the source name associated with this entry.';
                }
                field("Customized Changes Exist"; Rec."Customized Changes Exist")
                {
                    ApplicationArea = Suite;
                    Caption = 'Customized Changes Exist';
                    ToolTip = 'Specifies that this entry has used the base calendar to create a customized calendar.';
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

