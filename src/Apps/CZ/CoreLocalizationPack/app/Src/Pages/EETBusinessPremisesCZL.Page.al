// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

page 31143 "EET Business Premises CZL"
{
    Caption = 'EET Registrating Units';
    PageType = List;
    SourceTable = "EET Business Premises CZL";
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Identification; Rec.Identification)
                {
                }
                field("Certificate Code"; Rec."Certificate Code")
                {
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action("Cash Registers")
            {
                Caption = 'Cash Registers';
                Image = ElectronicPayment;
                RunObject = page "EET Cash Registers CZL";
                RunPageLink = "Business Premises Code" = field(Code);
                ToolTip = 'Displays a list of PoS devices assigned to the registrating unit.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref("Cash Registers_Promoted"; "Cash Registers")
                {
                }
            }
        }
    }
}
