// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// Wrapper of Payables Agent Setup that includes other related information when loaded.
/// </summary>
table 3310 "PA Detailed Setup"
{
    Caption = 'Payables Agent Setup';
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    TableType = Temporary;
    DataClassification = CustomerContent;
    Extensible = false;

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
        }
        #region Setup-instance dependent
        field(2; "Email Review Policy"; Enum "PA Email Review Policy")
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Email Account Id"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Email Folder"; Text[2048])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Email Folder Id"; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
        field(6; "Last Sync At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Email Monitoring Consent"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        #endregion
        #region Environmental
        field(10; "Agent Profile"; Text[30])
        {
            DataClassification = SystemMetadata;
        }

        #endregion
        // TODOPAV1V2: Better names here for teh regions, I want to signal that one is possible to change via setup, and the other is more based in other things, like fex the v1v2 flag
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}