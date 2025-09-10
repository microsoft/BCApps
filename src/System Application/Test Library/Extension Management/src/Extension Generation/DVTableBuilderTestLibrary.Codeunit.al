// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Apps.ExtensionGeneration;

codeunit 135107 "DV Table Builder Test Library"
{
    procedure GetMockProxyTableSchema(): Text
    var
        Result: Text;
        ResInStream: InStream;
    begin
        NavApp.GetResource('MockProxyTableSchema.txt', ResInStream, TextEncoding::UTF8);
        ResInStream.ReadText(Result);
        exit(Result);
    end;

    procedure GetMockProxyTableFields(): Dictionary of [Text, Text]
    var
        Result: Dictionary of [Text, Text];
    begin
        Result.Add('Mock Field 1', 'mockfield1');
        Result.Add('Mock Field 2', 'mockfield2');
        Result.Add('Mock Field 3', 'mockfield3');
        exit(Result);
    end;
}