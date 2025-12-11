// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.ApplicationAreas;

using System.Environment.Configuration;

tableextension 20402 "Qlty. Application Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(20400; "Quality Management"; Boolean)
        {
            Caption = 'Quality Management';
            DataClassification = CustomerContent;
        }
    }
}
