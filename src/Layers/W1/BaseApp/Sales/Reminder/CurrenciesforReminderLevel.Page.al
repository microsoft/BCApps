// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays and manages currency-specific fee amounts for a reminder level.
/// </summary>
page 478 "Currencies for Reminder Level"
{
    Caption = 'Currencies for Reminder Level';
    PageType = List;
    SourceTable = "Currency for Reminder Level";

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
                    ApplicationArea = Suite;
                }
                field("Add. Fee per Line"; Rec."Add. Fee per Line")
                {
                    ApplicationArea = Suite;
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

