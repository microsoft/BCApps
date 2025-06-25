#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// This object contains the obsoleted elements of the "No. Series" table.
/// </summary>
tableextension 309 NoSeriesLineObsolete extends "No. Series Line"
{
    fields
    {
        field(11; "Allow Gaps in Nos."; Boolean)
        {
            Caption = 'Allow Gaps in Nos.';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The specific implementation is defined by the Implementation field and whether the implementation may produce gaps can be determined through the implementation interface or the procedure MayProduceGaps.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
        field(10000; Series; Code[10]) // NA (MX) Functionality
        {
            Caption = 'Series';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
        field(10001; "Authorization Code"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Code';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
        field(10002; "Authorization Year"; Integer) // NA (MX) Functionality
        {
            Caption = 'Authorization Year';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series module cannot reference tax features.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
    }


}
#endif