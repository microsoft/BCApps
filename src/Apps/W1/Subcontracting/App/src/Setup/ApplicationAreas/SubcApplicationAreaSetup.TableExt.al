// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.ApplicationAreas;

using System.Environment.Configuration;

tableextension 99001571 "Subc. Application Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(99001500; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
            DataClassification = CustomerContent;
        }
    }
}
