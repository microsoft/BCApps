#if not CLEANSCHEMA28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument.Processing.Import;

table 6113 "EDoc Historical Matching Setup"
{
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    ObsoleteReason = 'Replaced with experiment-based matching.';
#if not CLEAN28
    ObsoleteTag = '28.0';
    ObsoleteState = Pending;
#else
    ObsoleteTag = '33.0';
    ObsoleteState = Removed;
#endif

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
        }
        #pragma warning disable AS0105
        field(2; "Vendor Matching Scope"; Enum "EDoc Vendor Matching Scope")
        {
            DataClassification = SystemMetadata;
            InitValue = "Same Vendor";
        }
        field(3; "Line Matching Scope"; Enum "EDoc Line Matching Scope")
        {
            DataClassification = SystemMetadata;
            InitValue = "Same Product Description";
        }
        #pragma warning restore AS0105
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    #pragma warning disable AS0105
    internal procedure GetSetup()
    begin
        if Rec.FindFirst() then
            exit;

        Rec."Line Matching Scope" := "EDoc Line Matching Scope"::"Same Product Description";
        Rec."Vendor Matching Scope" := "EDoc Vendor Matching Scope"::"Same Vendor";
        Rec.Insert();
    end;
    #pragma warning restore AS0105
}
#endif