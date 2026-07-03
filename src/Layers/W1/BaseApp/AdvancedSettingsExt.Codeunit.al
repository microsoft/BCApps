// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

codeunit 9203 "Advanced Settings Ext."
{
    Access = Public;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeOpenCompanySettings(var PageID: Integer; var Handled: Boolean)
    begin
    end;
}
