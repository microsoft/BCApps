// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Purchases.Vendor;

report 5005340 "Create Delivery Reminder"
{
    Caption = 'Create Delivery Reminder';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "Buy-from Vendor No.", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "Buy-from Vendor No.", "No.";
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Outstanding Quantity" = filter(<> 0));
                RequestFilterFields = Type, "No.";

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, "Line No.");

                    VendorChanged := "Purchase Header"."Buy-from Vendor No." <> LastVendorNo;
                    OnAfterGetVendorChanged("Purchase Header", "Purchase Line", VendorChanged);
                    if VendorChanged then
                        Clear(CreateDeliveryReminder);
                    if CreateDeliveryReminder.Remind("Purchase Line", DeliveryReminderTerms, DeliveryReminderLevel, DateOfTheCurrentDay) then begin
                        if VendorChanged then begin
                            if DeliveryReminderHeader."Vendor No." <> '' then begin
                                CreateDeliveryReminder.HeaderReminderLevelRefresh(DeliveryReminderHeader);
                                CreateDeliveryReminder.UpdateLines(DeliveryReminderHeader);
                            end;
                            CreateDeliveryReminder.CreateDelivReminHeader(
                              DeliveryReminderHeader, "Purchase Header", DeliveryReminderTerms, DeliveryReminderLevel, DateOfTheCurrentDay);
                            LastVendorNo := "Purchase Header"."Buy-from Vendor No.";
                            ReminderCounter := ReminderCounter + 1;
                        end;
                        CreateDeliveryReminder.CreateDelivRemindLine(
                          DeliveryReminderHeader, "Purchase Header", "Purchase Line", DeliveryReminderTerms, DeliveryReminderLevel, DateOfTheCurrentDay);
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                if "Buy-from Vendor No." = '' then
                    CurrReport.Skip();
                Vendor.Get("Buy-from Vendor No.");
                if Vendor."Delivery Reminder Terms" = '' then
                    CurrReport.Skip();

                DeliveryReminderTerms.Get(Vendor."Delivery Reminder Terms");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if DeliveryReminderHeader."Vendor No." <> '' then begin
            CreateDeliveryReminder.HeaderReminderLevelRefresh(DeliveryReminderHeader);
            CreateDeliveryReminder.UpdateLines(DeliveryReminderHeader);
        end;

        Window.Close();

        Message(Text1140002, ReminderCounter);
    end;

    trigger OnPreReport()
    begin
        LastVendorNo := '';
        DateOfTheCurrentDay := WorkDate();
        ReminderCounter := 0;

        Window.Open(
          Text1140000 +
          Text1140001);
    end;

    var
        Text1140000: Label 'Changing Purch. Order   #1#########\';
        Text1140001: Label 'Changing Line          #2######';
        Text1140002: Label '%1 Delivery Reminders had been created.';
        DeliveryReminderHeader: Record "Delivery Reminder Header";
        DeliveryReminderTerms: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        Vendor: Record Vendor;
        CreateDeliveryReminder: Codeunit "Create Delivery Reminder";
        Window: Dialog;
        ReminderCounter: Integer;
        LastVendorNo: Code[20];
        VendorChanged: Boolean;
        DateOfTheCurrentDay: Date;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetVendorChanged(PurchaseHeader:Record "Purchase Header"; PurchaseLine:Record "Purchase Line"; var VendorChanged:Boolean)
    begin
    end;
}

