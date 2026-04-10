// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

/// <summary>
/// List page displaying all configured tax areas with lookup and selection capabilities.
/// Provides overview of tax area codes and descriptions for user selection.
/// </summary>
page 469 "Tax Area List"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Areas';
    CardPageID = "Tax Area";
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Tax Area";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesTax;
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

