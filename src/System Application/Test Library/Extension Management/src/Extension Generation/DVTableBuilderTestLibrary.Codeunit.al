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

    procedure GetMockProxyTableFields(): List of [Text]
    var
        Result: List of [Text];
    begin
        Result.Add('mockfield1');
        Result.Add('mockfield2');
        Result.Add('mockfield3');
        Result.Add('mockfield4');
        Result.Add('mockfield5');
        exit(Result);
    end;
}