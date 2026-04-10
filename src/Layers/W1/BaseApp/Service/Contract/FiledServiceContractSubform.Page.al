// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6074 "Filed Service Contract Subform"
{
    AutoSplitKey = false;
    Caption = 'Lines';
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Filed Contract Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = true;
                ShowCaption = false;
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time interval after work on the service order starts.';
                }
                field("Line Cost"; Rec."Line Cost")
                {
                    ApplicationArea = Service;
                }
                field("Line Value"; Rec."Line Value")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                }
                field(Profit; Rec.Profit)
                {
                    ApplicationArea = Service;
                }
                field("Invoiced to Date"; Rec."Invoiced to Date")
                {
                    ApplicationArea = Service;
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                }
                field("Last Planned Service Date"; Rec."Last Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Next Planned Service Date"; Rec."Next Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Preventive Maint. Date"; Rec."Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                }
                field("Credit Memo Date"; Rec."Credit Memo Date")
                {
                    ApplicationArea = Service;
                }
                field("Contract Expiration Date"; Rec."Contract Expiration Date")
                {
                    ApplicationArea = Service;
                }
                field("New Line"; Rec."New Line")
                {
                    ApplicationArea = Service;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Comments")
                {
                    ApplicationArea = Comments;
                    Caption = '&Comments';
                    Image = ViewComments;
                    ToolTip = 'View comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowComments();
                    end;
                }
            }
        }
    }
}
