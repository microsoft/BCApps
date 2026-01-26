// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Vendor;

page 5005272 "Delivery Reminder List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Delivery Reminder';
    CardPageID = "Delivery Reminder";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Delivery Reminder Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the delivery reminder header you are setting up.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor who you want to post a delivery reminder for.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor who the delivery reminder is for.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the address.';
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city name of the address.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Reminder")
            {
                Caption = '&Reminder';
                Image = Reminder;
                action("V&endor")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'V&endor';
                    Image = Vendor;
                    RunObject = Page "Vendor List";
                    RunPageLink = "No." = field("Vendor No.");
                    ToolTip = 'View detailed information for the vendor.';
                }
                action("Co&mment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mment';
                    Image = ViewComments;
                    RunObject = Page "Delivery Reminder Comment Line";
                    RunPageLink = "No." = field("No.");
                    RunPageView = sorting("Document Type", "No.", "Line No.")
                                  where("Document Type" = const("Delivery Reminder"));
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(reporting)
        {
            action("Delivery Reminder - Test")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delivery Reminder - Test';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Delivery Reminder - Test";
                ToolTip = 'Preview the delivery reminders before you issue them. The program checks whether there are any posting dates and/or document dates missing, whether there is anything to issue, and so on. ';
            }
        }
        area(Promoted)
        {
        }
    }
}

