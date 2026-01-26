// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11307 "Representative List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Representatives';
    CardPageID = "Representative Card";
    Editable = false;
    PageType = List;
    SourceTable = Representative;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1170000000)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier for the representative.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the VAT declaration representative.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address that is associated with the VAT declaration representative.';
                }
                field(Phone; Rec.Phone)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the phone number of the VAT declaration representative.';
                }
                field("Identification Type"; Rec."Identification Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification type that is associated with the VAT declaration representative. Identification types include NVAT and TIN.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Representative")
            {
                Caption = '&Representative';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Representative Card";
                    RunPageLink = ID = field(ID);
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the representative.';
                }
            }
        }
    }
}

