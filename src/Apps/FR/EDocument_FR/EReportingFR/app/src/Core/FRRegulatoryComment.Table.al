// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

table 10971 "FR Regulatory Comment"
{
    Access = Internal;
    Caption = 'French Regulatory Comment';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "FR Reg. Comment Doc. Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Comment Type"; Enum "FR Regulatory Comment Type")
        {
            Caption = 'Comment Type';
        }
        field(5; "Comment Text"; Text[250])
        {
            Caption = 'Comment Text';
        }
    }

    keys
    {
        key(PK; "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}