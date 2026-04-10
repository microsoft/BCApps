// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Displays detailed matching information for payment reconciliation entries.
/// Shows match criteria and confidence levels to help users understand automatic matching results.
/// </summary>
page 1289 "Additional Match Details"
{
    Caption = 'Additional Match Details';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Payment Matching Details";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Message; Rec.Message)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    Width = 250;
                }
            }
        }
    }

    actions
    {
    }
}

