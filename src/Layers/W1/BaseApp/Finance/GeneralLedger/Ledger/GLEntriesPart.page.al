// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;

page 19 "G/L Entries Part"
{
    PageType = ListPart;
    Caption = 'G/L Entries';
    SourceTable = "G/L Entry";
    SourceTableView = sorting("G/L Account No.");
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(entries)
            {
                field(AccNo; Rec."G/L Account No.")
                {
                    ApplicationArea = All;
                    Width = 8;
                    ToolTip = 'Specifies the G/L account number for this entry.';
                }
                field(AccName; Rec."G/L Account Name")
                {
                    ApplicationArea = All;
                    Visible = true;
                    Width = 13;
                    ToolTip = 'Specifies the G/L account name for this entry.';

                    trigger OnDrillDown()
                    var
                        GLAccount: Record "G/L Account";
                    begin
                        GLAccount.SetRange("No.", Rec."G/L Account No.");
                        Page.Run(Page::"G/L Account Card", GLAccount);
                    end;
                }
                field(Descr; Rec.Description)
                {
                    ApplicationArea = All;
                    Width = 13;
                    Visible = false;
                    ToolTip = 'Specifies the posting description for this entry.';

                    trigger OnDrillDown()
                    begin
                        ShowNavigate();
                    end;
                }
                field(Amt; Rec.Amount)
                {
                    ApplicationArea = All;
                    Visible = AmountVisible;
                    Width = 5;
                    ToolTip = 'Specifies the net amount for this entry.';

                    trigger OnDrillDown()
                    begin
                        ShowNavigate();
                    end;
                }
                field(DebAmt; Rec."Debit Amount")
                {
                    ApplicationArea = All;
                    Visible = DebCredAmountVisible;
                    Width = 5;
                    ToolTip = 'Specifies the debit amount for this entry.';

                    trigger OnDrillDown()
                    begin
                        ShowNavigate();
                    end;
                }
                field(CredAmt; Rec."Credit Amount")
                {
                    ApplicationArea = All;
                    Visible = DebCredAmountVisible;
                    Width = 5;
                    ToolTip = 'Specifies the credit amount for this entry.';

                    trigger OnDrillDown()
                    begin
                        ShowNavigate();
                    end;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(FindEntries)
            {
                Caption = 'Find Entries';
                Image = Navigate;
                ApplicationArea = All;
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                Scope = Repeater;

                trigger OnAction()
                begin
                    ShowNavigate();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Rec.SecurityFiltering := Rec.SecurityFiltering::Filtered;
        GLSetup.SetLoadFields("Show Amounts");
        GLSetup.Get();
        AmountVisible := GLSetup."Show Amounts" in [GLSetup."Show Amounts"::"Amount Only", GLSetup."Show Amounts"::"All Amounts"];
        DebCredAmountVisible := GLSetup."Show Amounts" in [GLSetup."Show Amounts"::"Debit/Credit Only", GLSetup."Show Amounts"::"All Amounts"];
    end;

    var
        AmountVisible: Boolean;
        DebCredAmountVisible: Boolean;

    local procedure ShowNavigate()
    var
        Navigate: Page Navigate;
    begin
        Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
        Navigate.Run();
    end;
}
