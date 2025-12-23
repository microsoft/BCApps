// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Telemetry;

/// <summary>
/// Report Shpfy Sync Companies (ID 30114).
/// </summary>
report 30114 "Shpfy Sync Companies"
{
    ApplicationArea = All;
    Caption = 'Shopify Sync Companies';
    UsageCategory = Tasks;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Shop; "Shpfy Shop")
        {
            RequestFilterFields = Code;

            trigger OnAfterGetRecord()
            begin
                Codeunit.Run(Codeunit::"Shpfy Sync Companies", Shop);
            end;
        }
    }

    trigger OnPreReport()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUsage('0000QW9', 'Shopify', 'Shopify sync companies executed.');
    end;
}
