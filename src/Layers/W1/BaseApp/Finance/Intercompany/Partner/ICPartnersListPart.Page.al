// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

page 622 "IC Partners List Part"
{
    ApplicationArea = Intercompany;
    SourceTable = "IC Partner";
    PageType = ListPart;
    Caption = 'Intercompany Partners';
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Control)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany partner code.';
                    trigger OnDrillDown()
                    var
                        ICPartnerCard: Page "IC Partner Card";
                    begin
                        ICPartnerCard.SetRecord(Rec);
                        ICPartnerCard.Run();
                    end;
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
    }
    actions
    {
        area(Processing)
        {
            action(SetupICPartner)
            {
                ApplicationArea = Intercompany;
                Caption = 'Add';
                Image = Add;
                RunObject = Page "IC Partner Card";
                RunPageMode = Create;
                Tooltip = 'Create and configure a new intercompany partner.';
            }
            action(RemoveICPartner)
            {
                ApplicationArea = Intercompany;
                Caption = 'Remove';
                Image = Delete;
                Scope = Repeater;
                Tooltip = 'Remove an intercompany partner.';
                trigger OnAction()
                begin
                    Rec.Delete(true);
                end;
            }
        }
    }
}
