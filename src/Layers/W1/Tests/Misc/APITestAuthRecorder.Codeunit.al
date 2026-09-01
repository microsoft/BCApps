// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

codeunit 139495 "API Test Auth Recorder"
{
    Access = Internal;
    SingleInstance = true;

    var
        Calls: List of [Text];
        NoRecordedCallErr: Label 'No API test authentication call was recorded.';

    internal procedure RecordCall(Call: Text)
    begin
        Calls.Add(Call);
    end;

    internal procedure DequeueCall(): Text
    var
        Call: Text;
    begin
        if Calls.Count() = 0 then
            Error(NoRecordedCallErr);

        Call := Calls.Get(1);
        Calls.RemoveAt(1);
        exit(Call);
    end;

    internal procedure Count(): Integer
    begin
        exit(Calls.Count());
    end;

    internal procedure Reset()
    begin
        Clear(Calls);
    end;
}
