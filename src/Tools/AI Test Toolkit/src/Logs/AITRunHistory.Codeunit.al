// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149036 "AIT Run History"
{
    Access = Internal;

    procedure GetHistory(Code: Code[100]; LineNo: Integer; AITViewBy: Enum "AIT Run History - View By"; var TempAITRunHistory: Record "AIT Run History" temporary)
    var
        AITRunHistory: Record "AIT Run History";
        SeenTags: List of [Text[20]];
    begin
        TempAITRunHistory.DeleteAll();
        AITRunHistory.SetRange("Test Suite Code", Code);

        if AITViewBy = AITViewBy::Version then
            if AITRunHistory.FindSet() then
                repeat
                    TempAITRunHistory.TransferFields(AITRunHistory);
                    TempAITRunHistory.Insert();
                until AITRunHistory.Next() = 0;

        if AITViewBy = AITViewBy::Tag then
            if AITRunHistory.FindSet() then
                repeat
                    if not SeenTags.Contains(AITRunHistory.Tag) then begin
                        TempAITRunHistory.TransferFields(AITRunHistory);
                        TempAITRunHistory.Insert();
                    end;
                    SeenTags.Add(AITRunHistory.Tag);
                until AITRunHistory.Next() = 0;

        if (LineNo <> 0) then
            TempAITRunHistory.SetRange("Line No. Filter", LineNo)
    end;
}