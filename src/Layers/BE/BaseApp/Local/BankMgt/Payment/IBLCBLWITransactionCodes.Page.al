// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 2000002 "IBLC/BLWI Transaction Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'IBLC/BLWI Transaction Codes';
    PageType = List;
    SourceTable = "IBLC/BLWI Transaction Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction Code"; Rec."Transaction Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the transaction code.';
                }
            }
        }
    }

    actions
    {
    }
}

