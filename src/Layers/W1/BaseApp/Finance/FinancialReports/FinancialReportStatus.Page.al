// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8395 "Financial Report Status"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Statuses';
    PageType = List;
    SourceTable = "Financial Report Status";
    UsageCategory = Lists;
    AboutTitle = 'About Financial Report Status';
    AboutText = 'Status codes help you organize the lifecycle of your financial report, row, and column definitions by hiding work-in-progress and retired definitions from users.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
                field(Description; Rec.Description) { }
                field(Blocked; Rec.Blocked) { }
            }
        }
    }
}