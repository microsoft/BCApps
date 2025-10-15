// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument.Processing.Import;

#pragma warning disable AL0432
table 6113 "EDoc Historical Matching Setup"
{
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    ObsoleteTag = '27.1';
    ObsoleteReason = 'Replaced with experiment-based matching.';
    ObsoleteState = Removed;

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
        }
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
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    internal procedure GetSetup()
    begin
        if Rec.FindFirst() then
            exit;

        Rec."Line Matching Scope" := "EDoc Line Matching Scope"::"Same Product Description";
        Rec."Vendor Matching Scope" := "EDoc Vendor Matching Scope"::"Same Vendor";
        Rec.Insert();
    end;
}
#pragma warning restore AL0432