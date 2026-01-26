// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Navigate;

page 5005276 "Deliv. Reminder Ledger Entries"
{
    Caption = 'Deliv. Reminder Ledger Entries';
    DataCaptionExpression = CaptionString;
    Editable = false;
    PageType = List;
    SourceTable = "Delivery Reminder Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Reminder No."; Rec."Reminder No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the delivery reminder.';
                }
                field("Reminder Line No."; Rec."Reminder Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number from the No. field on the delivery reminder line.';
                }
                field("Reminder Level"; Rec."Reminder Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminder level on the delivery reminder line.';
                }
                field("Days overdue"; Rec."Days overdue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the day overdue on the delivery reminder line.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor who you want to post a delivery reminder for.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reminded purchase order.';
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the reminded purchase order line.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry type.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the item, or a number that identifies the G/L account, used when posting the line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reminded quantity.';
                }
                field("Reorder Quantity"; Rec."Reorder Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reorder quantity.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining quantity.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the delivery reminder.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document date of the delivery reminder.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the delivery reminder.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a consecutive number for each new entry.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Reminder No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        CaptionString := '';

        CurrentFilter := Rec.GetFilter("Order No.");
        if CurrentFilter <> '' then
            CaptionString :=
              Text1140000 + CurrentFilter;

        CurrentFilter := Rec.GetFilter("Vendor No.");
        if CurrentFilter <> '' then begin
            if CaptionString <> '' then
                CaptionString := CaptionString + Text1140001;
            CaptionString :=
              CaptionString + ' ' + CurrentFilter;
        end;

        exit(Rec.Find(Which));
    end;

    var
        Text1140000: Label 'PurchOrder ';
        Text1140001: Label ' Customer';
        Navigate: Page Navigate;
        CaptionString: Text[100];
        CurrentFilter: Text[30];
}

