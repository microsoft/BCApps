// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Inventory.Analysis;

report 7117 "Run Sales Analysis Col. Temp."
{
    ApplicationArea = SalesAnalysis;
    Caption = 'Sales Analysis Column Templates';
    ProcessingOnly = true;
    UsageCategory = Administration;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        AnalysisColumnTemplate.FilterGroup := 2;
        AnalysisColumnTemplate.SetRange("Analysis Area", AnalysisColumnTemplate."Analysis Area"::Sales);
        AnalysisColumnTemplate.FilterGroup := 0;
        PAGE.RunModal(0, AnalysisColumnTemplate);
    end;

    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
}

