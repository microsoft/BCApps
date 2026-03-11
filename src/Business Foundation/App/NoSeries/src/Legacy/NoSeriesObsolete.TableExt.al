#if not CLEANSCHEMA27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

/// <summary>
/// This object contains the obsoleted elements of the "No. Series" table.
/// </summary>
tableextension 308 NoSeriesObsolete extends "No. Series"
{
    fields
    {
#pragma warning disable AL0432
        field(12100; "No. Series Type"; Integer)
#pragma warning restore AL0432
        {
            DataClassification = CustomerContent;
            Caption = 'No. Series Type';
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The field is used in IT localization only.';
            ObsoleteTag = '24.0';
            ObsoleteState = Moved;
            MovedTo = '437dbf0e-84ff-417a-965d-ed2bb9650972';
        }
    }

}
#endif