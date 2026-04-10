// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

codeunit 7354 "BaseApp ID"
{
    SingleInstance = true;

    procedure Get(): Guid
    var
        EmptyGuid: Guid;
    begin
        if Info.Id() = EmptyGuid then
            NavApp.GetCurrentModuleInfo(Info);

        exit(Info.Id());
    end;

    var
        Info: ModuleInfo;
}