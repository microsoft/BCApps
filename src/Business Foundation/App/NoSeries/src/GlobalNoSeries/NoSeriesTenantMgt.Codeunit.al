// remove

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Provides an interface for interacting with Tenant No. Series.
/// These No. Series are used for functionality cross-company, for numbers per company, see No. Series.
/// </summary>
codeunit 283 NoSeriesTenantMgt
{
    Permissions = tabledata "No. Series Tenant" = rimd;

    procedure InitNoSeries(NoSeriesCode: Code[10]; NoSeriesDescription: Text[50]; LastUsedNo: Code[10])
    var
        NoSeriesTenant: Record "No. Series Tenant";
    begin
        NoSeriesTenant.Validate(Code, NoSeriesCode);
        NoSeriesTenant.Validate(Description, NoSeriesDescription);
        NoSeriesTenant.Validate("Last Used number", LastUsedNo);
        NoSeriesTenant.Insert(true);
    end;

    procedure GetNextAvailableCode(NoSeriesTenant: Record "No. Series Tenant") NextAvailableCode: Code[20]
    begin
        NextAvailableCode := CopyStr(IncStr(NoSeriesTenant.Code + NoSeriesTenant."Last Used number"), 1, MaxStrLen(NextAvailableCode));
        NoSeriesTenant.Validate("Last Used number", IncStr(NoSeriesTenant."Last Used number"));
        NoSeriesTenant.Modify();
        exit(NextAvailableCode);
    end;
}