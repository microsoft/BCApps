// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

/// <summary>
/// List page for managing tax area line assignments and jurisdiction relationships.
/// Displays jurisdiction codes and calculation order within tax areas.
/// </summary>
page 465 "Tax Area Line"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Tax Area Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Jurisdiction Description"; Rec."Jurisdiction Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Calculation Order"; Rec."Calculation Order")
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

