// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

tableextension 10603 "Service Line NO" extends "Service Line"
{
    fields
    {
        field(10600; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if (Type = Type::" ") and ("Account Code" <> '') then
                    Error(CannotEnterErr, FieldCaption("Account Code"), FieldCaption(Type), Type);
            end;
        }
    }

    var
        CannotEnterErr: Label 'You cannot enter %1 if %2 is "%3".', Comment = '%1 - Account Code, %2 - Type, %3 - Type value';
}