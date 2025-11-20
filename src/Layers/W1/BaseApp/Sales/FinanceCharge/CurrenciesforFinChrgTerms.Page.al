// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

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
                    ToolTip = 'Specifies the code for the currency in which you want to define finance charge terms.';
                }
                field("Additional Fee"; Rec."Additional Fee")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a fee amount in foreign currency. The currency of this amount is determined by the currency code.';
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

