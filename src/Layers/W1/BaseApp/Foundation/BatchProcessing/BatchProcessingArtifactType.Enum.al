// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

enum 58 "Batch Processing Artifact Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(1; " ")
    {
        Caption = ' ';
    }
    value(2; "IC Output File")
    {
        Caption = 'Intercompany output file';
    }
}
