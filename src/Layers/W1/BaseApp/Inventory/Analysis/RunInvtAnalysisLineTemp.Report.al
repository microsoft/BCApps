// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

report 7116 "Run Invt. Analysis Line Temp."
{
    ApplicationArea = InventoryAnalysis;
    Caption = 'Inventory Analysis Line Templates';
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
        AnalysisLineTemplate.FilterGroup := 2;
        AnalysisLineTemplate.SetRange("Analysis Area", AnalysisLineTemplate."Analysis Area"::Inventory);
        AnalysisLineTemplate.FilterGroup := 0;
        PAGE.RunModal(0, AnalysisLineTemplate);
    end;

    var
        AnalysisLineTemplate: Record "Analysis Line Template";
}

