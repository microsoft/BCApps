// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

page 5617 "FA Locations"
{
    AdditionalSearchTerms = 'fixed asset locations departments sites offices';
    ApplicationArea = FixedAssets;
    Caption = 'FA Locations';
    PageType = List;
    SourceTable = "FA Location";
    UsageCategory = Administration;
    AnalysisModeEnabled = false;

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
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies where the fixed asset is located.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("OKATO Code"; Rec."OKATO Code")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the OKATO code associated with the fixed asset location.';
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

