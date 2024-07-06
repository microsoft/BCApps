// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130459 "Expand Data Driven Tests"
{
    EventSubscriberInstance = Manual;

    internal procedure SetDataDrivenTests(var NewTempTestMethodLine: Record "Test Method Line" temporary)
    begin
        NewTempTestMethodLine.Reset();
        if not NewTempTestMethodLine.FindSet() then
            exit;
        repeat
            TempTestMethodLine.TransferFields(NewTempTestMethodLine, true);
            TempTestMethodLine.Insert();
        until NewTempTestMethodLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Get Methods", 'OnBeforeAddTestMethodLine', '', false, false)]
    local procedure BeforeAddTestMethodLine(var TestMethodLine: Record "Test Method Line"; var Handled: Boolean)
    begin
        Handled := true;
        TempTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        TempTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Get Methods", 'OnAfterAddTestMethodLine', '', false, false)]
    local procedure ExpandDataDrivenTests(var TestMethodLine: Record "Test Method Line"; var MaxLineNo: Integer)
    begin
        TempTestMethodLine.Reset();
        TempTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        TempTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");

        if TempTestMethodLine.IsEmpty() then
            exit;

        // Only codeunit should be inserted, other lines need to be expanded
        if TestMethodLine."Line Type" = TestMethodLine."Line Type"::Codeunit then begin
            TestMethodLine."Data Input Group Code" := TempTestMethodLine."Data Input Group Code";
            TestMethodLine.Insert(true);
            exit;
        end;

        TempTestMethodLine.SetRange("Line Type", TempTestMethodLine."Line Type"::Function);
        if TempTestMethodLine.IsEmpty() then begin
            TempTestMethodLine.SetRange("Line Type", TempTestMethodLine."Line Type"::Codeunit);

            if TempTestMethodLine.IsEmpty() then
                exit;
        end;

        if TempTestMethodLine.FindSet() then
            repeat
                TestMethodLine."Line No." := MaxLineNo;
                MaxLineNo += 10000;
                TestMethodLine."Data Input" := TempTestMethodLine."Data Input";
                TestMethodLine."Data Input Group Code" := TempTestMethodLine."Data Input Group Code";
                TestMethodLine.Insert(true);
            until TempTestMethodLine.Next() = 0;
    end;

    var
        TempTestMethodLine: Record "Test Method Line" temporary;
}