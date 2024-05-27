// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

tableextension 130458 "Test Input Method Line" extends "Test Method Line"
{
    fields
    {
        field(1000; "Data Input"; Text[250])
        {
            Caption = 'Data Input';
            ToolTip = 'Data input for the test method line';
            TableRelation = "Test Input".Name;
            DataClassification = CustomerContent;
        }
    }
}