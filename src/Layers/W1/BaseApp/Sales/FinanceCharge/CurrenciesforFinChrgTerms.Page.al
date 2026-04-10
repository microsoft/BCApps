// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Displays and manages currency-specific additional fees for finance charge terms.
/// </summary>
page 477 "Currencies for Fin. Chrg Terms"
{
    Caption = 'Currencies for Fin. Chrg Terms';
    DataCaptionFields = "Fin. Charge Terms Code";
    PageType = List;
    SourceTable = "Currency for Fin. Charge Terms";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Additional Fee"; Rec."Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

