// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 1263 "No. Series Tenant"
{
    Caption = 'No. Series Tenant';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = SystemMetadata;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Last Used number"; Code[10])
        {
            Caption = 'Last Used number';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN24
    [Obsolete('Moved to NoSeriesManagement codeunit', '24.0')]
    [Scope('OnPrem')]
    procedure InitNoSeries(NoSeriesCode: Code[10]; NoSeriesDescription: Text[50]; LastUsedNo: Code[10])
    var
        NoSeriesTenantMgt: Codeunit NoSeriesTenantMgt;
    begin
        NoSeriesTenantMgt.InitNoSeries(NoSeriesCode, NoSeriesDescription, LastUsedNo);
    end;

    [Obsolete('Moved to NoSeriesManagement codeunit', '24.0')]
    [Scope('OnPrem')]
    procedure GetNextAvailableCode() NextAvailableCode: Code[20]
    var
        NoSeriesTenantMgt: Codeunit NoSeriesTenantMgt;
    begin
        NextAvailableCode := NoSeriesTenantMgt.GetNextAvailableCode(Rec);
    end;
#endif
}

