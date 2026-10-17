// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50180 "Filename Naming Capture"
{
    // Records the name the feature gives on a route, as it gives it, through the feature's own
    // OnAfterNamingDelivery. Bound manually by the tests that use it, so nothing else is affected.
    //
    // A test can then assert on the name a real delivery produced instead of naming the run again
    // afterwards - which matters where naming takes what the run recorded, as a financial report's
    // subject and period are taken.

    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        Names: Dictionary of [Integer, Text];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Subscribers", 'OnAfterNamingDelivery', '', false, false)]
    local procedure CaptureName(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
        Names.Set(ReportId, FileName);
    end;

    /// <summary>
    /// Forgets every name captured so far.
    /// </summary>
    internal procedure Reset()
    begin
        Clear(Names);
    end;

    /// <summary>
    /// Whether a name was captured for the report.
    /// </summary>
    internal procedure HasNameFor(ReportId: Integer): Boolean
    begin
        exit(Names.ContainsKey(ReportId));
    end;

    /// <summary>
    /// The name last captured for the report, with its extension, and forgets it.
    /// </summary>
    internal procedure TakeName(ReportId: Integer) FileName: Text
    begin
        if not Names.Get(ReportId, FileName) then
            exit('');
        Names.Remove(ReportId);
    end;

    /// <summary>
    /// The name last captured for the report without its extension, and forgets it.
    /// </summary>
    internal procedure TakeNameWithoutExtension(ReportId: Integer) FileName: Text
    var
        DotPosition: Integer;
    begin
        FileName := TakeName(ReportId);
        DotPosition := FileName.LastIndexOf('.');
        if DotPosition > 0 then
            FileName := CopyStr(FileName, 1, DotPosition - 1);
    end;
}
