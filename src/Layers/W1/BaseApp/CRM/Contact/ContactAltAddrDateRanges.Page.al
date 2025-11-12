// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

page 5059 "Contact Alt. Addr. Date Ranges"
{
    Caption = 'Contact Alt. Addr. Date Ranges';
    DataCaptionFields = "Contact No.", "Contact Alt. Address Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Contact Alt. Addr. Date Range";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date from which the alternate address is valid. There are certain rules for how dates should be entered.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day on which the alternate address is valid. There are certain rules for how dates should be entered.';
                }
                field("Contact Alt. Address Code"; Rec."Contact Alt. Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the contact alternate address to which the date range applies.';
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

