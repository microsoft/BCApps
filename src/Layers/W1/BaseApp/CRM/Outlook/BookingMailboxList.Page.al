// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Booking;

page 6704 "Booking Mailbox List"
{
    Caption = 'Booking Mailbox List';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Booking Mailbox";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Service Address"; Rec.SmtpAddress)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SMTP address of the Bookings mailbox.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the Bookings mailbox.';
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the full name of the Bookings mailbox.';
                }
            }
        }
    }

    actions
    {
    }

    procedure SetMailboxes(var TempBookingMailbox: Record "Booking Mailbox" temporary)
    begin
        TempBookingMailbox.Reset();
        if TempBookingMailbox.FindSet() then
            repeat
                Rec.Init();
                Rec.TransferFields(TempBookingMailbox);
                Rec.Insert();
            until TempBookingMailbox.Next() = 0;
    end;
}

