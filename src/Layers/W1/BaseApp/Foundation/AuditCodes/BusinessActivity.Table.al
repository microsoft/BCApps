// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

table 395 "Business Activity"
{
    Caption = 'Business Activity Code';
    DataClassification = CustomerContent;
    LookupPageID = "Business Activities";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;

            trigger OnValidate()
            var
                BusinessActivityCodeMgt: Codeunit "Business Activity Code Mgt.";
            begin
                BusinessActivityCodeMgt.Validate(Code);
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }
}