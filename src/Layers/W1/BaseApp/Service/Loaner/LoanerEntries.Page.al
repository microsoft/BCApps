// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Loaner;

page 5924 "Loaner Entries"
{
    ApplicationArea = Service;
    Caption = 'Loaner Entries';
    DataCaptionFields = "Loaner No.";
    Editable = false;
    PageType = List;
    SourceTable = "Loaner Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the document type of the entry is a quote or order.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service document specifying the service item you have replaced with the loaner.';
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item that you have replaced with the loaner.';
                }
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item line for which you have lent the loaner.';
                }
                field("Loaner No."; Rec."Loaner No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the loaner.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item group code of the service item that you have replaced with the loaner.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer to whom you have lent the loaner.';
                }
                field("Date Lent"; Rec."Date Lent")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you lent the loaner.';
                }
                field("Time Lent"; Rec."Time Lent")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when you lent the loaner.';
                }
                field("Date Received"; Rec."Date Received")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you received the loaner.';
                }
                field("Time Received"; Rec."Time Received")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when you received the loaner.';
                }
                field(Lent; Rec.Lent)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the loaner is lent.';
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

