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
                    ToolTip = 'Specifies the number of the service item on the filed service contract line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service item group associated with the filed service item line.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the service item on the filed service item line.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item number linked to the service item in the filed contract.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the service item group associated with this service item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
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
                    ToolTip = 'Specifies the calculated cost of the item line in the filed service contract or filed service contract quote.';
                }
                field("Line Value"; Rec."Line Value")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the value on the service item line in the service contract.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount of the discount on the contract line in the filed service contract or filed contract quote.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field(Profit; Rec.Profit)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the profit on the contract line in the filed service contract or filed contract quote.';
                }
                field("Invoiced to Date"; Rec."Invoiced to Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the contract was last invoiced.';
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time that elapses until service starts on the service item.';
                }
                field("Last Planned Service Date"; Rec."Last Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the last planned service on this item.';
                }
                field("Next Planned Service Date"; Rec."Next Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the next planned service on this item.';
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the last actual service on this item.';
                }
                field("Last Preventive Maint. Date"; Rec."Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the last time preventative service was performed on this item.';
                }
                field("Credit Memo Date"; Rec."Credit Memo Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you can create a credit memo for the item that needs to be removed from the service contract.';
                }
                field("Contract Expiration Date"; Rec."Contract Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service item should be removed from the service contract.';
                }
                field("New Line"; Rec."New Line")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that this service contract line is a new line.';
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
