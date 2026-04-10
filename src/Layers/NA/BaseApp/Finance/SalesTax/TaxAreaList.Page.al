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
                field("Country/Region"; Rec."Country/Region")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the country/region of this tax area. Tax jurisdictions of the same country/region can only then be assigned to this tax area.';
                }
                field("Use External Tax Engine"; Rec."Use External Tax Engine")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies that you have purchased an external, third party sales tax engine, which calculates the sales tax rather than using the standard sales tax engine included in the product. Select the check box if this tax area code will indicate to the product that this external sales tax engine is to be used when this tax area code is used. Clear the check box to indicate that the standard, internal sales tax engine is to be used when this tax area code is used.';
                }
                field("Round Tax"; Rec."Round Tax")
                {
                    ToolTip = 'Specifies a rounding option for the tax area. This value is used to round United States sales tax to the nearest decimal. If a rounding value is selected, this value is used in the Sales Tax Amount Line table.';
                    Visible = false;
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

