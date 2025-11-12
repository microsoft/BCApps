// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

report 323 "ECSL Report Request Page"
{
    Caption = 'ECSL Report Request Page';
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
#pragma warning disable AA0100
                field("""VAT Report Header"".""Period Year"""; "VAT Report Header"."Period Year")
#pragma warning restore AA0100
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Period Year';
                    ToolTip = 'Specifies the period for the EU Sales Report.';
                }
#pragma warning disable AA0100
                field("""VAT Report Header"".""Period Type"""; "VAT Report Header"."Period Type")
#pragma warning restore AA0100
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Period Type';
                    ToolTip = 'Specifies the type of period for the EU Sales Report you want to view.';
                }
#pragma warning disable AA0100
                field("""VAT Report Header"".""Period No."""; "VAT Report Header"."Period No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Period No.';
                    ToolTip = 'Specifies the number of the period for the EU Sales Report you want to view.';
                }
#pragma warning disable AA0100
                field("""VAT Report Header"".""Start Date"""; "VAT Report Header"."Start Date")
#pragma warning restore AA0100
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Start Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the start date for the EU Sales Report you want to view.';
                }
#pragma warning disable AA0100
                field("""VAT Report Header"".""End Date"""; "VAT Report Header"."End Date")
#pragma warning restore AA0100
                {
                    ApplicationArea = BasicEU;
                    Caption = 'End Date';
                    Importance = Additional;
                    ToolTip = 'Specifies the end date for the report.';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }
}

