// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using System.Integration;

tableextension 46898 "BC14 Data Migration Error Ext" extends "Data Migration Error"
{
    fields
    {
        field(46850; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = SystemMetadata;
        }
        field(46851; "Source Table Name"; Text[250])
        {
            Caption = 'Source Table Name';
            DataClassification = SystemMetadata;
        }
        field(46852; "Source Record Key"; Text[250])
        {
            Caption = 'Source Record Key';
            DataClassification = CustomerContent;
        }
        field(46853; "Error Code"; Code[20])
        {
            Caption = 'Error Code';
            DataClassification = SystemMetadata;
        }
        field(46854; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
            DataClassification = SystemMetadata;
            InitValue = 0;
        }
        field(46855; "Last Retry On"; DateTime)
        {
            Caption = 'Last Retry On';
            DataClassification = SystemMetadata;
        }
        field(46856; "Resolved On"; DateTime)
        {
            Caption = 'Resolved On';
            DataClassification = SystemMetadata;
        }
        field(46857; "Resolved By"; Code[50])
        {
            Caption = 'Resolved By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(46859; "Created On"; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
        }
        field(46860; "Company Name"; Text[30])
        {
            Caption = 'Company';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(BC14SourceKey; "Source Table ID", "Source Record Key")
        {
        }
    }
}
