// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Displays and manages a standard sales code with its associated lines.
/// </summary>
page 170 "Standard Sales Code Card"
{
    Caption = 'Standard Sales Lines Card';
    PageType = ListPlus;
    SourceTable = "Standard Sales Code";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
            }
            part(StdSalesLines; "Standard Sales Code Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Standard Sales Code" = field(Code);
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

