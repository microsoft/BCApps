// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// Table that contains the available Tenant No. Series and their properties.
/// These No. Series are used for functionality cross-company, for numbers per company, see No. Series.
/// </summary>
table 1263 "No. Series Tenant"
{
    Caption = 'No. Series Tenant';
    DataClassification = CustomerContent;
    DataPerCompany = false;
    MovedFrom = '437dbf0e-84ff-417a-965d-ed2bb9650972';
    ReplicateData = false;
    InherentEntitlements = rX;
    InherentPermissions = rX;

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

#if not CLEAN24
    [Obsolete('This procedure has been moved to codeunit Cross-Company No. Series', '24.0')]
    [Scope('OnPrem')]
    procedure InitNoSeries(NoSeriesCode: Code[10]; NoSeriesDescription: Text[50]; LastUsedNo: Code[10])
    var
        CrossCompanyNoSeries: Codeunit "Cross-Company No. Series";
    begin
        CrossCompanyNoSeries.CreateNoSeries(NoSeriesCode, NoSeriesDescription, LastUsedNo);
    end;

    [Obsolete('This procedure has been moved to codeunit Cross-Company No. Series', '24.0')]
    [Scope('OnPrem')]
    procedure GetNextAvailableCode() NextAvailableCode: Code[20]
    var
        CrossCompanyNoSeries: Codeunit "Cross-Company No. Series";
    begin
        exit(CrossCompanyNoSeries.GetNextNo(Rec));
    end;
#endif
}
