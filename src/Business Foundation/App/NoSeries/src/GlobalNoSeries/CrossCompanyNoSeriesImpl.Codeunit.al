// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 284 "Cross-Company No. Series Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "No. Series Tenant" = rim;

    procedure CreateNoSeries(NoSeriesCode: Code[10]; NoSeriesDescription: Text[50]; LastUsedNo: Code[10])
    var
        NoSeriesTenant: Record "No. Series Tenant";
    begin
        NoSeriesTenant.Validate(Code, NoSeriesCode);
        NoSeriesTenant.Validate(Description, NoSeriesDescription);
        NoSeriesTenant.Validate("Last Used number", LastUsedNo);
        NoSeriesTenant.Insert(true);
    end;

    procedure GetNextNo(NoSeriesTenant: Record "No. Series Tenant") NextAvailableCode: Code[20]
    begin
        NextAvailableCode := CopyStr(IncStr(NoSeriesTenant.Code + NoSeriesTenant."Last Used number"), 1, MaxStrLen(NextAvailableCode));
        NoSeriesTenant.Validate("Last Used number", IncStr(NoSeriesTenant."Last Used number"));
        NoSeriesTenant.Modify();
        exit(NextAvailableCode);
    end;

    procedure GetNextNo(NoSeriesCode: Code[10]): Code[20]
    var
        NoSeriesTenant: Record "No. Series Tenant";
    begin
        NoSeriesTenant.Get(NoSeriesCode);
        exit(GetNextNo(NoSeriesTenant));
    end;

    procedure Exist(NoSeriesCode: Code[10]): Boolean
    var
        NoSeriesTenant: Record "No. Series Tenant";
    begin
        exit(NoSeriesTenant.Get(NoSeriesCode));
    end;
}
