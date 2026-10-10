// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

page 31144 "EET Cash Registers CZL"
{
    Caption = 'EET Cash Registers';
    DataCaptionFields = "Business Premises Code";
    PageType = List;
    SourceTable = "EET Cash Register CZL";
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Business Premises Code"; Rec."Business Premises Code")
                {
                    Visible = BusinessPremisesCodeVisibility;
                }
                field("Code"; Rec.Code)
                {
                }
                field("Register Type"; Rec."Cash Register Type")
                {
                }
                field("Register No."; Rec."Cash Register No.")
                {
                }
                field("Register Name"; Rec."Cash Register Name")
                {
                }
                field("Receipt Serial Nos."; Rec."Receipt Serial Nos.")
                {
                }
                field("Certificate Code"; Rec."Certificate Code")
                {
                }
                field("Authorizing Taxpayer ID"; Rec."Authorizing Taxpayer ID")
                {
                }
                field("Multiple Taxpayer Auth."; Rec."Multiple Taxpayer Auth.")
                {
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("EET Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'EET Entries';
                    Image = LedgerEntries;
                    RunObject = page "EET Entries CZL";
                    RunPageLink = "Business Premises Code" = field("Business Premises Code"),
                                  "Cash Register Code" = field(Code);
                    RunPageView = sorting("Business Premises Code", "Cash Register Code");
                    ShortcutKey = 'Ctrl+F7';
                    ToolTip = 'Displays a list of EET entries for the selected cash register.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("EET Entries_Promoted"; "EET Entries")
                {
                }
            }
        }
    }

    var
        BusinessPremisesCodeVisibility: Boolean;

    trigger OnOpenPage()
    begin
        BusinessPremisesCodeVisibility := Rec.GetFilter("Business Premises Code") = '';
    end;
}

