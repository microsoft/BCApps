// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

tableextension 7000131 "SII Finance Cue" extends "Finance Cue"
{
    fields
    {
        field(10700; "Missing SII Entries"; Integer)
        {
            Caption = 'Missing SII Entries';
            DataClassification = SystemMetadata;
        }
        field(10701; "Days Since Last SII Check"; Integer)
        {
            Caption = 'Days Since Last SII Check';
            DataClassification = SystemMetadata;
        }
    }
}