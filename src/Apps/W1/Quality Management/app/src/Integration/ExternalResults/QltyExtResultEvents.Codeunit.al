// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.ExternalResults;

/// <summary>
/// Integration events raised during external quality result import.
/// </summary>
codeunit 20590 "Qlty. Ext. Result Events"
{
    Access = Public;

    /// <summary>
    /// Raised before the lab API is called, exposing the raw credentials so
    /// subscribers can override them.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnBeforeCallLabApi(Endpoint: Text; ApiKey: Text; var BearerToken: Text)
    begin
    end;

    /// <summary>
    /// Raised so subscribers can adjust the parsed result before it is stored.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnAfterParseResult(var ResultValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnImportCompleted(CustomerNo: Code[20]; EntryCount: Integer)
    begin
    end;
}
