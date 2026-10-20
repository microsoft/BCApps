// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// The Payables Agent setup as consumers see it. Loaded and saved only by "PA Setup", which knows where each value is
/// stored for the active Payables Agent version ("Payables Agent Setup" and, for v1, the Outlook Setup) and which
/// values are derived. Contains only what consumers need; storage details (such as the E-Document Service) stay
/// behind "PA Setup".
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
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        #region Configured: chosen by the user through the setup, saved by "PA Setup".ApplySetup
        field(2; "Monitor Outlook"; Boolean)
        {
            Caption = 'Monitor Outlook';
            DataClassification = SystemMetadata;
        }
        field(3; "Email Review Policy"; Enum "PA Email Review Policy")
        {
            Caption = 'Email Review Policy';
            DataClassification = SystemMetadata;
        }
        field(4; "Email Account Id"; Guid)
        {
            Caption = 'Email Account Id';
            DataClassification = SystemMetadata;
        }
        field(5; "Email Folder"; Text[2048])
        {
            Caption = 'Email Folder';
            DataClassification = CustomerContent;
        }
        field(6; "Email Folder Id"; Text[2048])
        {
            Caption = 'Email Folder Id';
            DataClassification = SystemMetadata;
        }
        field(7; "Email Monitoring Consent"; Boolean)
        {
            Caption = 'Email Monitoring Consent';
            DataClassification = CustomerContent;
        }
        #endregion
        #region Maintained: kept up to date by the app (agent lookup, activation, instructions, mailbox sync)
        field(20; "User Security Id"; Guid)
        {
            Caption = 'User Security Id';
            DataClassification = SystemMetadata;
        }
        field(21; "Last Activated"; DateTime)
        {
            Caption = 'Last Activated';
            DataClassification = SystemMetadata;
        }
        field(22; "Applied Instr. Config Hash"; Text[64])
        {
            Caption = 'Applied Instructions Configuration Hash';
            DataClassification = SystemMetadata;
        }
        field(23; "Last Sync At"; DateTime)
        {
            Caption = 'Last Sync At';
            DataClassification = SystemMetadata;
        }
        #endregion
        #region Derived: computed by "PA Setup" when loading (from the Payables Agent version), never saved
        field(30; "Agent Profile"; Text[30])
        {
            Caption = 'Agent Profile';
            DataClassification = SystemMetadata;
        }
        field(31; "Agent Permission Set"; Code[20])
        {
            Caption = 'Agent Permission Set';
            DataClassification = SystemMetadata;
        }
        field(32; "Supports Additional Fields"; Boolean)
        {
            Caption = 'Supports Additional Fields';
            DataClassification = SystemMetadata;
        }
        #endregion
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
