// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.BOM.Tree;

report 152 "Calculate Low Level Code"
{
    ApplicationArea = Planning;
    Caption = 'Calculate Low Level Code';
    ToolTip = 'Calculate the low-level codes for items in production BOMs. Low-level codes determine the sequence in which materials are planned during MRP runs. Top level items have code 0.';
    ProcessingOnly = true;
    UsageCategory = Tasks;
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

    trigger OnInitReport()
    begin
        Codeunit.Run(Codeunit::"Low-Level Code Calculator");
    end;
}

