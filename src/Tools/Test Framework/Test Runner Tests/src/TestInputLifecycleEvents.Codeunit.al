// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130484 "Test Input Lifecycle Events"
{
    EventSubscriberInstance = Manual;

    var
        SuiteName: Code[10];
        PlaceholderName: Text;
        SkipMethod: Boolean;
        BeforeValue: Text;
        AfterValue: Text;

    procedure Configure(NewSuiteName: Code[10]; Name: Text; Skip: Boolean)
    begin
        SuiteName := NewSuiteName;
        PlaceholderName := Name;
        SkipMethod := Skip;
        Clear(BeforeValue);
        Clear(AfterValue);
    end;

    procedure GetBeforeValue(): Text
    begin
        exit(BeforeValue);
    end;

    procedure GetAfterValue(): Text
    begin
        exit(AfterValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure BeforeMethod(var CurrentTestMethodLine: Record "Test Method Line"; var Skip: Boolean)
    var
        DataTools: Codeunit "Test Input Data Tools";
    begin
        if CurrentTestMethodLine."Test Suite" <> SuiteName then
            exit;

        BeforeValue := DataTools.ResolveText('$Placeholder-' + PlaceholderName + '$');
        DataTools.SetPlaceholder(PlaceholderName, 'setup');
        Skip := SkipMethod;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterTestMethodRun', '', false, false)]
    local procedure AfterMethod(var CurrentTestMethodLine: Record "Test Method Line")
    var
        DataTools: Codeunit "Test Input Data Tools";
    begin
        if CurrentTestMethodLine."Test Suite" = SuiteName then
            AfterValue := DataTools.ResolveText('$Placeholder-' + PlaceholderName + '$');
    end;
}
