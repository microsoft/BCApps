// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Utilities;

using System.Utilities;

codeunit 135068 "Regex Performance Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        RegexPerformanceUrlMatchTxt: Label '^https*://(?<storageAccount>(?:bcartifacts|bcinsider))\.[\w\.]+/(?<type>(?:Sandbox|OnPrem))/(?<version>(?:(?:\d+)*(?:\.\d+)*(?:\.\d+)*(?:\.\d+)*))/(?<country>\w{2})', Locked = true;

    [Test]
    procedure RegexPerformanceStaticCalls()
    var
        TempRegexOptions: Record "Regex Options";
        Regex: Codeunit Regex;
    begin
        TempRegexOptions.Compiled := true;
        TempRegexOptions.IgnoreCase := true;

        RegexPerformanceCall(Regex, TempRegexOptions, false);
    end;

    [Test]
    procedure RegexPerformanceInstanceCalls()
    var
        TempRegexOptions: Record "Regex Options";
        Regex: Codeunit Regex;
    begin
        TempRegexOptions.Compiled := true;
        TempRegexOptions.IgnoreCase := true;
        Regex.Regex(RegexPerformanceUrlMatchTxt, TempRegexOptions);

        RegexPerformanceCall(Regex, TempRegexOptions, true);
    end;

    local procedure RegexPerformanceCall(var ThisRegex: Codeunit Regex; TempRegexOptions: Record "Regex Options"; RunOnInstance: Boolean)
    var
        TempMatches: Record Matches;
        TempGroups: Record Groups;
        Counter: Integer;
        UrlTxt: Label 'https://bcartifacts.azureedge.net/onprem/18.3.27240.27480/de', Locked = true;
    begin
        for counter := 0 to 100 do begin
            case RunOnInstance of
                true:
                    ThisRegex.Match(UrlTxt, TempMatches);
                false:
                    ThisRegex.Match(UrlTxt, RegexPerformanceUrlMatchTxt, TempRegexOptions, TempMatches);
            end;

            if TempMatches.Success then
                ThisRegex.Groups(TempMatches, TempGroups);
        end;
    end;

}