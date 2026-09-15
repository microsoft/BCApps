// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

table 9091 "Postcode Service Config"
{
    Caption = 'Postcode Service Config';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; ServiceKey; Text[250])
        {
            Caption = 'ServiceKey';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure SaveServiceKey(ServiceKeyText: Text)
    begin
        Rec.ServiceKey := CopyStr(ServiceKeyText, 1, MaxStrLen(Rec.ServiceKey));
        Rec.Modify();
    end;

    procedure GetServiceKey(): Text
    begin
        exit(Rec.ServiceKey);
    end;
}

