// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting.FileNaming;

codeunit 149530 "Filename Naming Capture"
{
    // Records the name a real delivery produced, so a test need not name the run again afterwards -
    // which matters where naming uses what the run recorded (a financial report's subject and period).

    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        Names: Dictionary of [Integer, Text];

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Subscribers", 'OnAfterNamingDelivery', '', false, false)]
    local procedure CaptureName(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
        Names.Set(ReportId, FileName);
    end;

    internal procedure Reset()
    begin
        Clear(Names);
    end;

    internal procedure HasNameFor(ReportId: Integer): Boolean
    begin
        exit(Names.ContainsKey(ReportId));
    end;

    // Takes the name and forgets it.
    internal procedure TakeName(ReportId: Integer) FileName: Text
    begin
        if not Names.Get(ReportId, FileName) then
            exit('');
        Names.Remove(ReportId);
    end;

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
