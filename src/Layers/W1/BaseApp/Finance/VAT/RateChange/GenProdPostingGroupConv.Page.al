// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

/// <summary>
/// Configuration page for general product posting group conversion mappings during VAT rate changes.
/// Provides interface for defining old-to-new general product posting group conversions and validation rules.
/// </summary>
page 552 "Gen. Prod. Posting Group Conv."
{
    AdditionalSearchTerms = 'posting setup,general product posting group conversion';
    ApplicationArea = Basic, Suite;
    Caption = 'Gen. Prod. Posting Group Conv.';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "VAT Rate Change Conversion";
    SourceTableView = where(Type = const("Gen. Prod. Posting Group"));
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("From Code"; Rec."From Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current general product posting group that will be changed in connection with the VAT rate conversion.';
                }
                field("To Code"; Rec."To Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Converted Date"; Rec."Converted Date")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

