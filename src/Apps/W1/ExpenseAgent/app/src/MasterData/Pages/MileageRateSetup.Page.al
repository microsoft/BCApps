// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7128 "Mileage Rate Setup"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Mileage Rate Setup";
    Caption = 'Mileage Rate Setup';
    RefreshOnActivate = true;
    DelayedInsert = true;
    AdditionalSearchTerms = 'Mileage Rate, Mileage Reimbursement, Distance Rate, Kilometer Rate, Mile Rate, Effective Rate';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                }
                field("Vehicle Type"; Rec."Vehicle Type")
                {
                }
                field("Starting Date"; Rec."Starting Date")
                {
                }
                field("Ending Date"; Rec."Ending Date")
                {
                }
                field("Rate"; Rec."Rate")
                {
                }
                field("Currency Code"; Rec."Currency Code")
                {
                }
            }
        }
    }
}
