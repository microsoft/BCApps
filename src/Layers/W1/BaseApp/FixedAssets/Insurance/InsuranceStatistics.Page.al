// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

page 5646 "Insurance Statistics"
{
    Caption = 'Insurance Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Insurance;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Annual Premium"; Rec."Annual Premium")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Policy Coverage"; Rec."Policy Coverage")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Total Value Insured"; Rec."Total Value Insured")
                {
                    ApplicationArea = FixedAssets;
                }
#pragma warning disable AA0100
                field("""Policy Coverage"" - ""Total Value Insured"""; Rec."Policy Coverage" - Rec."Total Value Insured")
#pragma warning restore AA0100
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Over/Under Insured';
                    ToolTip = 'Specifies if the fixed asset is insured at the right value.';
                }
            }
        }
    }

    actions
    {
    }
}

