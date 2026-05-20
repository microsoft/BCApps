// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

using Microsoft.Intercompany;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using System.Threading;

/// <summary>
/// Main configuration page for intercompany setup and partner management.
/// Provides comprehensive interface for configuring intercompany parameters, partners, and system integration.
/// </summary>
page 653 "Intercompany Setup"
{
    Caption = 'Intercompany Setup';
    PageType = Card;
    ApplicationArea = Intercompany;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'IC Setup';
    SourceTable = "IC Setup";
    DeleteAllowed = false;
    InsertAllowed = false;
    AboutTitle = 'Intercompany Setup';
    AboutText = 'In this page you can edit your intercompany connection setup, register new partner companies and setup the mappings between each.';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC Partner Code';
                    ToolTip = 'Specifies your company''s intercompany partner code.';
                    AboutTitle = 'Intercompany Partner Code';
                    AboutText = 'Other companies require this code to configure you as an IC Partner, it should be unique across your partner companies.';
                }
                field("IC Inbox Type"; Rec."IC Inbox Type")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC Inbox Type';
                    ToolTip = 'Specifies what type of intercompany inbox you have, either File Location or Database.';

                    trigger OnValidate()
                    begin
                        UsingDatabaseInbox := (Rec."IC Inbox Type" = Rec."IC Inbox Type"::Database);
                        CurrPage.Update();
                    end;
                }
                group(SynchronisationGroup)
                {
                    ShowCaption = false;
                    Visible = true;
                    Enabled = UsingDatabaseInbox;
                    field(SynchronisationPartnerNo; Rec."Partner Code for Acc. Syn.")
                    {
                        ApplicationArea = Intercompany;
                        Caption = 'Synchronisation Partner';
                        ToolTip = 'Specifies the partner you want to synchronise with. The selected partner will be used during the synchronisation of your Intercompany Chart of Account and Intercompany Dimensions.';
                    }
                }
                field("IC Inbox Details"; Rec."IC Inbox Details")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'IC Inbox Details';
                    ToolTip = 'Specifies details about the location of your intercompany inbox, which can transfer intercompany transactions into your company.';
                }
                field("Auto. Send Transactions"; Rec."Auto. Send Transactions")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Auto. Send Transactions';
                    ToolTip = 'Specifies that as soon as transactions arrive in the intercompany outbox, they will be sent to the intercompany partner.';
                }
                field("Transaction Notifications"; Rec."Transaction Notifications")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Transaction Notifications';
                    ToolTip = 'Specifies whether the system should send you notifications when a new transaction is sent to the intercompany outbox.';
                }
                field("Default IC Gen. Jnl. Template"; Rec."Default IC Gen. Jnl. Template")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Default IC Gen. Jnl. Template';
                    ToolTip = 'Specifies the journal template name that will be used to create journal lines as soon as transactions arrive in the intercompany inbox.';
                }
                field("Default IC Gen. Jnl. Batch"; Rec."Default IC Gen. Jnl. Batch")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Default IC Gen. Jnl. Batch';
                    ToolTip = 'Specifies the journal batch that will be used to create journal lines as soon as transactions arrive in the intercompany inbox.';
                }
                field("Log API Requests"; Rec."Log API Requests")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Log API Requests';
                    ToolTip = 'Specifies whether to log outgoing and incoming intercompany API requests for troubleshooting.';
                    Importance = Additional;
                }
            }
            part("IC Partners List Part"; "IC Partners List Part")
            {
            }
        }
        area(FactBoxes)
        {
            part(Diagnostics; "Intercompany Setup Diagnostics")
            {
                ApplicationArea = Intercompany;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(SetupICPartner)
            {
                Caption = 'Add IC Partner';
                Image = AddContacts;
                RunPageMode = Create;
                RunObject = Page "IC Partner Card";
                ToolTip = 'Setup a new intercompany partner.';
            }
            action(ICChartOfAccounts)
            {
                Caption = 'IC Chart of Accounts';
                Image = JournalSetup;
                RunObject = Page "IC Chart of Accounts";
                RunPageMode = View;
                ToolTip = 'Define the shared chart of accounts to use across different companies.';
            }
            action(ICDimensions)
            {
                Caption = 'IC Dimensions';
                Image = Dimensions;
                RunObject = Page "IC Dimensions";
                RunPageMode = View;
                ToolTip = 'Define the shared dimensions to use across different companies.';
            }
            action(ConnectionDetails)
            {
                Caption = 'Connection Details';
                Image = CompanyInformation;
                RunObject = Page "IC Connection Details";
                RunPageMode = View;
                ToolTip = 'Access the connection details that your intercompany partners will use to connect to your company if they''re in different environments.';
            }
            group(Troubleshooting)
            {
                Caption = 'Troubleshooting';
                Image = Troubleshoot;
                action(APILogEntries)
                {
                    Caption = 'API Log Entries';
                    Image = Log;
                    RunObject = Page "IC API Log Entries";
                    ToolTip = 'View logged intercompany API requests and responses for troubleshooting.';
                }
                action(JobQueueErrors)
                {
                    Caption = 'Job Queue Errors';
                    Image = ErrorLog;
                    ToolTip = 'View job queue log entries with errors for intercompany background tasks.';

                    trigger OnAction()
                    var
                        JobQueueLogEntry: Record "Job Queue Log Entry";
                    begin
                        JobQueueLogEntry.SetRange("Object Type to Run", JobQueueLogEntry."Object Type to Run"::Codeunit);
                        JobQueueLogEntry.SetFilter("Object ID to Run", '%1|%2|%3|%4|%5',
                            Codeunit::"IC New Notification JR",
                            Codeunit::"IC Read Notification JR",
                            Codeunit::"IC Sync. Completed JR",
                            Codeunit::"IC Auto Accept JR",
                            Codeunit::"IC Inbox Outbox Subs. Runner");
                        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::Error);
                        Page.Run(Page::"Job Queue Log Entries", JobQueueLogEntry);
                    end;
                }
                action(OutgoingNotifications)
                {
                    Caption = 'Outgoing Notifications';
                    Image = SendTo;
                    RunObject = Page "IC Outgoing Notifications";
                    ToolTip = 'View outgoing intercompany notifications and their delivery status.';
                }
                action(IncomingNotifications)
                {
                    Caption = 'Incoming Notifications';
                    Image = ReceiveLoaner;
                    RunObject = Page "IC Incoming Notifications";
                    ToolTip = 'View incoming intercompany notifications and their processing status.';
                }
            }
        }
        area(Promoted)
        {
            actionref(SetupICPartnerRef; SetupICPartner)
            {
            }
            actionref(ICChartOfAccountsRef; ICChartOfAccounts)
            {
            }
            actionref(ICDimensionsRef; ICDimensions)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        UsingDatabaseInbox := (Rec."IC Inbox Type" = Rec."IC Inbox Type"::Database);
    end;

    var
        UsingDatabaseInbox: Boolean;
}
