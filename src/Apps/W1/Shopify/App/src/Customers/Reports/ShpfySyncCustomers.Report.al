// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Telemetry;

/// <summary>
/// Report Shpfy Sync Customers (ID 30100).
/// </summary>
report 30100 "Shpfy Sync Customers"
{
    ApplicationArea = All;
    Caption = 'Shopify Sync Customers';
    UsageCategory = Tasks;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Shop; "Shpfy Shop")
        {
            RequestFilterFields = Code;

            trigger OnAfterGetRecord()
            begin
                Codeunit.Run(Codeunit::"Shpfy Sync Customers", Shop)
            end;
        }
    }

    trigger OnPreReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000QWA', 'Shopify', 'Shopify sync customers executed.');
    end;
}
