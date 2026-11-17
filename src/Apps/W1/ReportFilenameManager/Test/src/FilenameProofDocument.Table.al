// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using System.Globalization;

table 149501 "Filename Proof Document"
{
    // A stand-in document for language selection and stable field bindings.
    // The Number caption differs from its AL field name without requiring a translation pack.

    Caption = 'Filename Proof Document';
    DataClassification = SystemMetadata;
    Access = Internal;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Number';
        }
        field(2; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(3; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(4; "Document Language Code"; Code[10])
        {
            Caption = 'Document Language Code';

            // The language Business Central answers in for this document, kept separate from
            // "Language Code" (the pattern's language) so a mismatch can be built; on real tables
            // they are one field. Read only by Filename Proof Kind Source. Deliberately has no
            // relation to Language: a pattern suggests its language field only when exactly one
            // field relates to Language.
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
