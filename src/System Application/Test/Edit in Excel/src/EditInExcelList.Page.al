// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Excel;

using System.Integration.Excel;
page 132525 "Edit in Excel List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Edit in Excel Settings";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(Id; Rec.Id)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Record ID';
                }
                field("No"; Rec.Id)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Record ID';
                }
                field("Use Centralized deployments"; Rec."Use Centralized deployments")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if Edit in Excel should use centralized deployments';
                }
                // If this page does not expose an OData field Date_Filter then the Edit In Excel
                // filter tests will fail because the filter is just removed.
                field("Date Filter"; Rec.Id)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Record ID';
                }
                field("Country/Region Code"; Rec.Id)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Record ID';
                }
            }
        }
    }
}