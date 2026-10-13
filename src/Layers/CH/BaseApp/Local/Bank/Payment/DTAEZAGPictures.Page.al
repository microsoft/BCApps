// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 3010543 "DTA EZAG Pictures"
{
    Caption = 'DTA EZAG Pictures';
    PageType = Card;
    SourceTable = "DTA Setup";

    layout
    {
        area(content)
        {
#pragma warning disable AW0009 // Accepted: The fields remain Blob/Bitmap; migrating existing data to Media or MediaSet requires a breaking schema and data upgrade. Tracked by AB#640773.
            field("EZAG Bar Code"; Rec."EZAG Bar Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Elektronischer Zahlungsauftrag (EZAG) bar code that is associated with the bank code for DTA processing.';
            }
            field("EZAG Post Logo"; Rec."EZAG Post Logo")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the Elektronischer Zahlungsauftrag (EZAG) post logo that is associated with the bank code for DTA processing.';
            }
#pragma warning restore AW0009
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if Rec."DTA/EZAG" <> Rec."DTA/EZAG"::EZAG then
            Error(Text003);
    end;

    var
        Text003: Label 'You can only add Pictures for EZAG.';
}

