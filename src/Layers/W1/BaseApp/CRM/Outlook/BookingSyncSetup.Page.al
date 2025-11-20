// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Booking;

using Microsoft.CRM.Outlook;
using System.Environment;
using System.Security.AccessControl;

page 6702 "Booking Sync. Setup"
{
    Caption = 'Booking Sync. Setup';
    DataCaptionExpression = Rec."Booking Mailbox Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Booking Sync";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Bookings Company"; Rec."Booking Mailbox Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bookings Company';
                    ToolTip = 'Specifies the Bookings company with which to synchronize customers and services.';

                    trigger OnValidate()
                    var
                        BookingMailbox: Record "Booking Mailbox";
                        BookingMailboxList: Page "Booking Mailbox List";
                    begin
                        if Format(Rec."Last Customer Sync") + Format(Rec."Last Service Sync") <> '' then
                            if not Confirm(ChangeCompanyQst) then begin
                                Rec."Booking Mailbox Name" := xRec."Booking Mailbox Name";
                                exit;
                            end;

                        O365SyncManagement.GetBookingMailboxes(Rec, TempBookingMailbox, Rec."Booking Mailbox Name");

                        if TempBookingMailbox.Count = 0 then
                            Error(NoMailboxErr);

                        if TempBookingMailbox.Count = 1 then begin
                            Rec."Booking Mailbox Address" := TempBookingMailbox.SmtpAddress;
                            Rec."Booking Mailbox Name" := TempBookingMailbox."Display Name";
                        end else begin
                            BookingMailboxList.SetMailboxes(TempBookingMailbox);
                            BookingMailboxList.LookupMode(true);
                            if BookingMailboxList.RunModal() in [ACTION::LookupOK, ACTION::OK] then begin
                                BookingMailboxList.GetRecord(BookingMailbox);
                                Rec."Booking Mailbox Address" := BookingMailbox.SmtpAddress;
                                Rec."Booking Mailbox Name" := BookingMailbox."Display Name";
                            end else
                                Rec."Booking Mailbox Name" := xRec."Booking Mailbox Name";
                        end;

                        if Rec."Booking Mailbox Name" <> xRec."Booking Mailbox Name" then begin
                            Clear(Rec."Last Customer Sync");
                            Clear(Rec."Last Service Sync");
                            Rec.Modify();
                            CurrPage.Update();
                        end;

                        Session.LogMessage('0000ACL', SetupTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
                    end;
                }
                field(SyncUser; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Synchronization User';
                    Editable = false;
                    Enabled = false;
                    ToolTip = 'Specifies the user on behalf of which to run the synchronize operation.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enable Background Synchronization';
                    ToolTip = 'Specifies whether to allow synchronization to occur periodically in the background.';
                }
            }
            group(Synchronize)
            {
                Caption = 'Synchronize';
                field("Sync Customers"; Rec."Sync Customers")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to synchronize Bookings customers.';
                    Visible = not GraphSyncEnabled;
                }
                field("Customer Templ. Code"; Rec."Customer Templ. Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Customer Template';
                    ToolTip = 'Specifies the customer template to use when creating new Customers from the Bookings company.';
                    Visible = NewCustTemplateCodeVisible;
                }
                field("Sync Services"; Rec."Sync Services")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to synchronize services.';
                }
                field("Item Template Code"; Rec."Item Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Item Template';
                    ToolTip = 'Specifies the template to use when creating new service items from the Bookings company.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                Image = "Action";
                action("Validate Exchange Connection")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Validate Exchange Connection';
                    Image = ValidateEmailLoggingSetup;
                    ToolTip = 'Test that the provided exchange server connection works.';

                    trigger OnAction()
                    begin
                        if O365SyncManagement.IsO365Setup(false) then
                            O365SyncManagement.ValidateExchangeConnection(ExchangeAccountUserName, ExchangeSync);
                    end;
                }
                action(SyncWithBookings)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sync with Bookings';
                    Image = Refresh;
                    ToolTip = 'Synchronize changes made in Bookings since the last sync date and last modified date.';

                    trigger OnAction()
                    var
                        O365SyncManagement: Codeunit "O365 Sync. Management";
                    begin
                        Clear(O365SyncManagement);
                        if O365SyncManagement.IsO365Setup(false) then begin
                            if Rec."Sync Customers" then
                                O365SyncManagement.SyncBookingCustomers(Rec);
                            if Rec."Sync Services" then
                                O365SyncManagement.SyncBookingServices(Rec);
                        end;
                    end;
                }
                action(SetSyncUser)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Sync. User';
                    Enabled = not IsSyncUser;
                    Image = User;
                    ToolTip = 'Set the synchronization user to be you.';

                    trigger OnAction()
                    begin
                        if Confirm(SetSyncUserQst) then begin
                            Rec.Validate("User ID", UserId);
                            GetExchangeAccount();
                        end;
                    end;
                }
                action("Invoice Appointments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoice Appointments';
                    Image = NewInvoice;
                    ToolTip = 'View Booking appointments and create invoices for your customers.';
                    Visible = IsSaaS;

                    trigger OnAction()
                    var
                        BookingManager: Codeunit "Booking Manager";
                    begin
                        BookingManager.InvoiceBookingItems();
                    end;
                }
            }
            group("Filter")
            {
                Caption = 'Filter';
                action(SetCustomerSyncFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Customer Sync Filter';
                    Image = ContactFilter;
                    ToolTip = 'Set a filter to use when syncing customers.';

                    trigger OnAction()
                    var
                        BookingCustomerSync: Codeunit "Booking Customer Sync.";
                    begin
                        Rec.CalcFields("Customer Filter");
                        BookingCustomerSync.GetRequestParameters(Rec);
                    end;
                }
                action(SetServiceSyncFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Service Sync Filter';
                    Image = "Filter";
                    ToolTip = 'Set a filter to use when syncing service items.';

                    trigger OnAction()
                    var
                        BookingServiceSync: Codeunit "Booking Service Sync.";
                    begin
                        Rec.CalcFields("Item Filter");
                        BookingServiceSync.GetRequestParameters(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Invoice Appointments_Promoted"; "Invoice Appointments")
                {
                }
                actionref("Validate Exchange Connection_Promoted"; "Validate Exchange Connection")
                {
                }
                actionref(SyncWithBookings_Promoted; SyncWithBookings)
                {
                }
                actionref(SetSyncUser_Promoted; SetSyncUser)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Filter', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(SetCustomerSyncFilter_Promoted; SetCustomerSyncFilter)
                {
                }
                actionref(SetServiceSyncFilter_Promoted; SetServiceSyncFilter)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        CheckExistingSetup();
        GetExchangeAccount();
        IsSyncUser := Rec."User ID" = UserId;
        IsSaaS := EnvironmentInfo.IsSaaS();
        SetCustTemplateCodesVisibility();
    end;

    var
        ExchangeSync: Record "Exchange Sync";
        TempBookingMailbox: Record "Booking Mailbox" temporary;
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ExchangeAccountUserName: Text[250];
        ChangeCompanyQst: Label 'The synchronization has been run against the current company. The process will no longer synchronize customer and service records with the current company, and synchronize against the new selected company. Do you want to continue?';
        SetSyncUserQst: Label 'Setting the synchronization user will assign your Exchange email and password as the credentials that are used to synchronize customers and service items to Bookings for this company. Any user already assigned as the synchronization user will be replaced with your User ID. Do you want to continue?';
        ExchangeSyncErr: Label 'Exchange sync. must be setup before using Bookings Sync.';
        NoMailboxErr: Label 'No matching mailboxes found.';
        BookingsSetupErr: Label 'Cannot open the Bookings Sync. Setup page. Make sure that your company is set up in the Bookings application in Office 365.';
        SetupTelemetryTxt: Label 'Bookings sync has been set up.', Locked = true;
        IsSyncUser: Boolean;
        GraphSyncEnabled: Boolean;
        IsSaaS: Boolean;
        NewCustTemplateCodeVisible: Boolean;

    local procedure CheckExistingSetup()
    begin
        if not ExchangeSync.Get(UserId) or not O365SyncManagement.IsO365Setup(false) then
            Error(ExchangeSyncErr);

        if not Rec.Get() then begin
            Rec.Init();
            Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
            O365SyncManagement.GetBookingMailboxes(Rec, TempBookingMailbox, '');

            if TempBookingMailbox.Count = 0 then
                Error(BookingsSetupErr);

            if TempBookingMailbox.Count = 1 then begin
                Rec."Booking Mailbox Address" := TempBookingMailbox.SmtpAddress;
                Rec."Booking Mailbox Name" := TempBookingMailbox."Display Name";
            end;
            Rec.Insert(true);
        end;
    end;

    local procedure GetExchangeAccount()
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            ExchangeAccountUserName := User."Authentication Email";
    end;

    local procedure SetCustTemplateCodesVisibility()
    begin
        NewCustTemplateCodeVisible := not GraphSyncEnabled;
    end;
}
