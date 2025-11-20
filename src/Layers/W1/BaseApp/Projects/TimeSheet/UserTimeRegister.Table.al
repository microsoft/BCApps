// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Security.AccessControl;
using System.Security.User;

table 51 "User Time Register"
{
    Caption = 'User Time Register';
    LookupPageID = "User Time Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
        }
        field(3; Minutes; Decimal)
        {
            Caption = 'Minutes';
            DecimalPlaces = 0 : 0;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "User ID", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

