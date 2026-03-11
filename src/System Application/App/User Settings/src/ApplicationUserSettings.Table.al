// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

/// <summary>
/// Table that stores user settings the Application defines.
/// </summary>
table 9222 "Application User Settings"
{
    Access = Public;
    InherentEntitlements = rimX;
    InherentPermissions = rimX;
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// The user security ID of the user to whom the settings apply.
        /// </summary>
        field(1; "User Security ID"; Guid)
        {
            DataClassification = EndUserIdentifiableInformation;
        }

        /// <summary>
        /// Specifies whether teaching tips are enabled.
        /// </summary>
        field(2; "Teaching Tips"; Boolean)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// Specifies whether the legacy action bar is enabled.
        /// </summary>
        field(3; "Legacy Action Bar"; Boolean)
        {
            DataClassification = CustomerContent;
            InitValue = false;
        }
    }

    keys
    {
        key(PK; "User Security ID")
        {
            Clustered = true;
        }
    }
}