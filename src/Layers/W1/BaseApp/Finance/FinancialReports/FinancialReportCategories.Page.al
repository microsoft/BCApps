// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8391 "Financial Report Categories"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Categories';
    CardPageId = "Financial Report Category";
    PageType = List;
    SourceTable = "Financial Report Category";
    UsageCategory = Lists;
    AboutTitle = 'About Financial Report Categories';
    AboutText = 'Organize your financial reports with financial report categories, helping you find and manage financial reports.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                ShowCaption = false;
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
                field(Description; Rec.Description) { }
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