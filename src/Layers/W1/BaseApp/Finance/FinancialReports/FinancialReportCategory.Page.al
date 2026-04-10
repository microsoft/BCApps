// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8392 "Financial Report Category"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Category';
    PageType = Card;
    SourceTable = "Financial Report Category";
    UsageCategory = None;
    AboutTitle = 'About Financial Report Category';
    AboutText = 'Organize your financial reports with financial report categories, helping you find and manage financial reports.';

    layout
    {
        area(content)
        {
            group(Group)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(WhereUsed)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Where Used';
                Image = Track;
                ToolTip = 'View or edit financial reports in which the category is used.';
                trigger OnAction()
                begin
                    Rec.OpenWhereUsed();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(WhereUsed_Promoted; WhereUsed) { }
            }
        }
    }
}