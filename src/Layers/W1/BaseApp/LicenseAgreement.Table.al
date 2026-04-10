// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

table 140 "License Agreement"
{
    Caption = 'License Agreement';
    InherentEntitlements = rX;
    InherentPermissions = rX;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Message for Accepting User"; Text[250])
        {
            Caption = 'Message for Accepting User';
        }
        field(3; "Effective Date"; Date)
        {
            Caption = 'Effective Date';

            trigger OnValidate()
            begin
                if "Effective Date" <> xRec."Effective Date" then begin
                    "Effective Date Changed By" := UserId;
                    "Effective Date Changed On" := CurrentDateTime;
                    Validate(Accepted, false);
                end;
            end;
        }
        field(4; "Effective Date Changed By"; Text[65])
        {
            Caption = 'Effective Date Changed By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(5; "Effective Date Changed On"; DateTime)
        {
            Caption = 'Effective Date Changed On';
            Editable = false;
        }
        field(6; Accepted; Boolean)
        {
            Caption = 'Accepted';

            trigger OnValidate()
            begin
                if Accepted then begin
                    "Accepted By" := UserId;
                    "Accepted On" := CurrentDateTime;
                end else begin
                    "Accepted By" := '';
                    "Accepted On" := CreateDateTime(0D, 0T);
                end;
            end;
        }
        field(7; "Accepted By"; Text[65])
        {
            Caption = 'Accepted By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(8; "Accepted On"; DateTime)
        {
            Caption = 'Accepted On';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
    end;

    var
        NoPartnerAgreementErr: Label 'The partner has not provided the agreement.';

    procedure ShowEULA()
    begin
        Error(NoPartnerAgreementErr)
    end;

    procedure GetActive(): Boolean
    begin
        exit(("Effective Date" <> 0D) and ("Effective Date" <= Today))
    end;
}

