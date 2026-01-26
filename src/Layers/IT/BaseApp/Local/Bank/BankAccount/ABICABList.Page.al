// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

page 12179 "ABI/CAB List"
{
    Caption = 'ABI/CAB List';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "ABI/CAB Codes";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ABI; Rec.ABI)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the bank as assigned by the ABI ( Associazione Bancaria Italiana / Italian Bank Association).';
                }
                field(CAB; Rec.CAB)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the bank''s branch or agency.';
                }
                field("Bank Description"; Rec."Bank Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank to which the ABI code applies.';
                }
                field("Agency Description"; Rec."Agency Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank agency to which the CAB code applies.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the bank agency.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county of the bank agency.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the bank agency.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the bank where the vendor has the bank account.';
                }
            }
        }
    }

    actions
    {
    }
}

