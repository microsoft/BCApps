// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.PowerBIReports;

using System.Integration.PowerBI;

tableextension 36962 "PBI Deployment Buffer Ext." extends "Power BI Deployment Buffer"
{
    fields
    {
        field(36950; Deploy; Boolean)
        {
            Caption = 'Deploy';
            DataClassification = SystemMetadata;
        }
    }
}
