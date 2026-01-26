// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
#if not CLEANSCHEMA27
tableextension 12147 GeneralLedgerSetupIT extends "General Ledger Setup"
{
    fields
    {
        field(12147; "Use Legacy No. Series Lines"; Boolean)
        {
            Caption = 'Use Legacy No. Series Lines';
            ToolTip = 'Specifies whether to use the legacy No. Series Lines Sales and No. Series Line Purchase tables. Disabling this setting may affect installed extensions.';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The No. Series Lines Sales and No. Series Line Purchase tables are obslete and will be removed in a future release.';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
            InitValue = true;
        }
    }
}
#endif