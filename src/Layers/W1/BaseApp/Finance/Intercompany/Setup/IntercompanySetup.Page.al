// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.DataExchange;

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
