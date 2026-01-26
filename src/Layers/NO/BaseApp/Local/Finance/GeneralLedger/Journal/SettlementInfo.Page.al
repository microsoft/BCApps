// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

page 15000011 "Settlement Info"
{
    Caption = 'Settlement Info';
    PageType = Card;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Remittance Handling Ref."; Rec."Remittance Handling Ref.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference that the bank identifies for foreign payments.';
                }
                field("Remittance Warning"; Rec."Remittance Warning")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the journal line contains a warning.';
                }
                field("Remittance Warning Text"; Rec."Remittance Warning Text")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the description of the warning, if applicable.';
                }
            }
        }
    }

    actions
    {
    }
}

