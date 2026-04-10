// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

codeunit 7777 "Connectivity Apps Mgt."
{
    procedure IsBankingAppAvailable(): Boolean
    var
        Result: Boolean;
    begin
        OnIsBankingAppAvailable(Result);
        exit(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsBankingAppAvailable(var Result: Boolean)
    begin
    end;
}