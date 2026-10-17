// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50151 "Filename Proof Document"
{
    // A stand-in document, and the only way to prove language invariance in this container.
    //
    // The W1 container carries no Danish or German translations, so every Base Application
    // field caption reads identically in all three languages - a cross-language proof against
    // those captions would pass while proving nothing at all. This table's captions are
    // translated by the .xlf files shipped beside it, so its captions genuinely differ per
    // language and a pattern authored against the Danish caption cannot possibly resolve by
    // name in a German session. If it still resolves, it resolved by field number.

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

            // Deliberately carries NO relation to the Language table, though it holds a language
            // code. A pattern suggests its language field from the one field that relates to
            // Language, and suggests nothing where a table has two - so relating this one would
            // stop the suggestion on this table and quietly change what the translated-caption
            // proofs measure. This field is never a field an administrator points a pattern at;
            // it is read by Filename Proof Kind Source and by nothing else.
            //
            // The language BUSINESS CENTRAL answers in for this document, as distinct from the
            // one above, which is the language a pattern is told to build the name in.
            //
            // On every real table the two are the same field, which is why a mismatch between
            // them cannot be built on a posted invoice without writing a language code into a
            // field that means something else. Here they are separate, so the case the kind-of-
            // document placeholder declines on can be constructed deliberately and without touching
            // any company data. Filename Proof Kind Source is what hands this one to Business
            // Central, through the event Report Distribution Management raises for a table it
            // does not know.
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
