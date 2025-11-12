// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

page 5659 "Depreciation Table Card"
{
    Caption = 'Depreciation Table Card';
    PageType = ListPlus;
    SourceTable = "Depreciation Table Header";
    AboutTitle = 'About Depreciation Table Card';
    AboutText = 'In the **Depreciation Table Card** you specify the information about the period length, total number of units the asset is expected to produce in its lifetime against which this depreciation table will be used.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'For Depreciation Table creation';
                    AboutText = 'Specify the unique code and description to create a depreciation table with period length and total number of units the asset is expected to produce in its lifetime.';
                    ToolTip = 'Specifies a code for the depreciation table.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the depreciation table.';
                }
                field("Period Length"; Rec."Period Length")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the length of period that each of the depreciation table lines will apply to.';
                }
                field("Total No. of Units"; Rec."Total No. of Units")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the total number of units the asset is expected to produce in its lifetime.';
                }
            }
            part(Control9; "Depreciation Table Lines")
            {
                ApplicationArea = FixedAssets;
                AboutTitle = 'About Depreciation Table Line';
                AboutText = 'In the **Depreciation Table Line**, you specify information about the number of depreciation periods, depreciation percentage to apply to the period and the no. of units produced by the asset during the period.';
                SubPageLink = "Depreciation Table Code" = field(Code);
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CreateSumOfDigitsTable)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Create Sum of Digits Table';
                    Image = NewSum;
                    ToolTip = 'Define a depreciation table for the Sum of Digits depreciation method. Example: If a fixed asset is depreciated over 4 years, then the depreciation for each year is calculated like this: Sum of Digits = 1 + 2 + 3 + 4 = 10. 1. year = 4/10 2. year = 3/10 3. year = 2/10 4. year = 1/10';

                    trigger OnAction()
                    var
                        CreateSumOfDigitsTable: Report "Create Sum of Digits Table";
                    begin
                        Rec.TestField(Code);
                        Clear(CreateSumOfDigitsTable);
                        CreateSumOfDigitsTable.SetTableCode(Rec.Code);
                        CreateSumOfDigitsTable.RunModal();
                        Clear(CreateSumOfDigitsTable);
                    end;
                }
            }
        }
    }
}

