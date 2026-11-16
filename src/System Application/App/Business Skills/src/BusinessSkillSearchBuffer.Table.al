// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI.BusinessSkills;

/// <summary>
/// Holds one request-local title/description candidate per eligible skill for native semantic ranking.
/// Retains canonical identity, revision, and catalog snapshot metadata without projecting instruction text.
/// </summary>
table 4161 "Business Skill Search Buffer"
{
    Access = Internal;
    TableType = Temporary;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Candidate ID"; Guid) { }
        field(2; "Skill ID"; BigInteger) { }
        field(3; "Skill System ID"; Guid) { }
        field(4; "Skill Revision"; Text[30]) { }
        field(6; Title; Text[250]) { }
        field(10; Description; Text[2048]) { }
        field(11; "Catalog Snapshot"; Text[64]) { }
    }

    keys
    {
        key(PK; "Candidate ID") { Clustered = true; }
        key(Skill; "Skill ID") { Unique = true; }
    }
}