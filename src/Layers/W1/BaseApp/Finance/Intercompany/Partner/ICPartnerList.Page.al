// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.Setup;
using System.Text;
using System.Utilities;

page 608 "IC Partner List"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Partners';
    CardPageID = "IC Partner Card";
    Editable = false;
    PageType = List;
    SourceTable = "IC Partner";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany partner code.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the name of the intercompany partner.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the country or region of this intercompany partner. It will be used as default for documents with no country specified.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                }
                field("Inbox Type"; Rec."Inbox Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies what type of inbox the intercompany partner has. File Location. You send the partner a file containing intercompany transactions. Database: The partner is set up as another company in the same database. Email: You send the partner transactions by email.';
                }
                field("Inbox Details"; Rec."Inbox Details")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the details of the intercompany partner''s inbox.';
                }
                field("Auto. Accept Transactions"; Rec."Auto. Accept Transactions")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies if transactions from this partner will be accepted automatically.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the customer number that this intercompany partner is linked to.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the vendor number that this intercompany partner is linked to.';
                }
                field("Receivables Account"; Rec."Receivables Account")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the general ledger account to use when you post receivables from customers in this posting group.';
                }
                field("Payables Account"; Rec."Payables Account")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the general ledger account to use when you post payables due to vendors in this posting group.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("IC &Partner")
            {
                Caption = 'IC &Partner';
                Image = ICPartner;
                action("Dimensions-Single")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions-Single';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(413),
                                  "No." = field(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to intercompany transactions to distribute costs and analyze transaction history.';
                }
            }
        }
        area(processing)
        {
            action("Intercompany Setup")
            {
                ApplicationArea = Intercompany;
                Caption = 'Intercompany Setup';
                Image = Intercompany;
                RunObject = Page "Intercompany Setup";
                ToolTip = 'View or edit the intercompany setup for the current company.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Intercompany Setup_Promoted"; "Intercompany Setup")
                {
                }
                actionref("Dimensions-Single_Promoted"; "Dimensions-Single")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ICSetup: Record "IC Setup";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ICSetup.Get();
        if ICSetup."IC Partner Code" = '' then
            if ConfirmManagement.GetResponse(SetupICQst, true) then
                Page.RunModal(Page::"Intercompany Setup");

        ICSetup.Find();
        if ICSetup."IC Partner Code" = '' then
            Error('');
    end;

    var
        SetupICQst: Label 'Intercompany information is not set up for your company.\\Do you want to set it up now?';

    procedure GetSelectionFilter(): Text
    var
        Partner: Record "IC Partner";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Partner);
        exit(SelectionFilterManagement.GetSelectionFilterForICPartner(Partner));
    end;
}

