
#if not CLEANSCHEMA31
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
#if not CLEAN28
    ObsoleteReason = 'Obsolete table, only used for storing the new experience flag.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
#else
    ObsoleteReason = 'This table is obsolete and should not be used.';
    ObsoleteState = Removed;
    ObsoleteTag = '31.0';
#endif

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
#endif