#if not CLEANSCHEMA31
#pragma warning disable AS0105
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 6107 "E-Documents Setup"
{
    Access = Internal;
    InherentEntitlements = RIX;
    InherentPermissions = RX;
    ReplicateData = false;
    ObsoleteReason = 'This table is obsolete and should not be used.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "New E-Document Experience"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    procedure IsNewEDocumentExperienceActive(): Boolean
    begin
        exit(true);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"E-Documents Setup", 'I')]
    internal procedure InsertNewExperienceSetup()
    begin
        // Only to be used by tests.
        if Rec.FindFirst() then
            exit;
        Rec."New E-Document Experience" := true;
        Rec.Insert();
    end;

}
#pragma warning restore AS0105
#endif