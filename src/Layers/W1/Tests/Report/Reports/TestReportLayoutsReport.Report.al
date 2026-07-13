// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information. 
// ------------------------------------------------------------------------------------------------

report 139595 TestReportLayoutsReport
{
    UsageCategory = Administration;
    ApplicationArea = All;
    DefaultRenderingLayout = MYLAYOUT;

    dataset
    {
        dataitem(DataItemName; "Test Table A")
        {
            column(ColumnName; MyField)
            {

            }
        }
    }

    rendering
    {
        layout(MYLAYOUT)
        {
            Type = RDLC;
            LayoutFile = 'Layouts/TestReportLayoutsReport.rdl';
        }
        // Second extension-installed layout so tests can exercise multi-layout scenarios
        // (e.g. mixed global/company scope in a batch status change - CP0529-338).
        layout(MYLAYOUT2)
        {
            Type = RDLC;
            LayoutFile = 'Layouts/TestReportLayoutsReport.rdl';
        }
    }
}