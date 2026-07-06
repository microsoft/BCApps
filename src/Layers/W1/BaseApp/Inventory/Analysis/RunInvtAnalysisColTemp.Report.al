// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

report 7119 "Run Invt. Analysis Col. Temp."
{
    ApplicationArea = InventoryAnalysis;
    Caption = 'Inventory Analysis Column Templates';
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
        AnalysisColumnTemplate.SetRange("Analysis Area", AnalysisColumnTemplate."Analysis Area"::Inventory);
        AnalysisColumnTemplate.FilterGroup := 0;
        PAGE.RunModal(0, AnalysisColumnTemplate);
    end;

    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
}

