// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

tableextension 130458 "Test Input Method Line" extends "Test Method Line"
{
    fields
    {
        field(1000; "Data Input Group Code"; Code[100])
        {
            Caption = 'Data Input Group Code';
            ToolTip = 'Specifies the code for the data input group.';
            DataClassification = CustomerContent;
            TableRelation = "Test Input Group".Code;
        }
        field(1001; "Data Input"; Code[100])
        {
            Caption = 'Data Input';
            ToolTip = 'Specifies the data input code for the test method line';
            DataClassification = CustomerContent;
            TableRelation = "Test Input".Code where("Test Input Group Code" = field("Data Input Group Code"));
        }
    }
}