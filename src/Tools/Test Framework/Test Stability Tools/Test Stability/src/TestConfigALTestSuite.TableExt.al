// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestTools.TestRunner;

tableextension 130482 "Test Config. AL Test Suite" extends "AL Test Suite"
{
    fields
    {
        field(130482; "Created From Suite"; Code[10])
        {
            Caption = 'Created From Suite';
            DataClassification = CustomerContent;
            TableRelation = "AL Test Suite".Name;
            Editable = false;
        }
        field(130483; Configuration; Code[20])
        {
            Caption = 'Configuration';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(TestConfiguration; "Created From Suite", Configuration)
        {
        }
    }

    trigger OnAfterDelete()
    var
        TestConfiguration: Record "Test Configuration";
    begin
        if Rec.IsTemporary() then
            exit;
        TestConfiguration.SetRange("Test Suite", Rec.Name);
        TestConfiguration.DeleteAll(true);
    end;
}
