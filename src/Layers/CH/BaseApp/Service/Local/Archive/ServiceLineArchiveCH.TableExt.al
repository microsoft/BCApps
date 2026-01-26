// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

tableextension 11552 "Service Line Archive CH" extends "Service Line Archive"
{
    fields
    {
        field(3010501; "Customer Line Reference"; Integer)
        {
            Caption = 'Customer Line Reference';
            DataClassification = CustomerContent;
        }
    }
}