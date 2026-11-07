// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 1309 "O365 Getting Started"
{
    Caption = 'O365 Getting Started';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(2; "Display Target"; Code[20])
        {
            Caption = 'Display Target';
        }
        field(10; "Current Page"; Integer)
        {
            Caption = 'Current Page';
            InitValue = 1;
        }
        field(11; "Tour in Progress"; Boolean)
        {
            Caption = 'Tour in Progress';
        }
        field(12; "Tour Completed"; Boolean)
        {
            Caption = 'Tour Completed';
        }
    }

    keys
    {
        key(Key1; "User ID", "Display Target")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ClientTypeManagement: Codeunit "Client Type Management";

    procedure AlreadyShown(): Boolean
    begin
        exit(Get(UserId, ClientTypeManagement.GetCurrentClientType()));
    end;

    procedure MarkAsShown()
    begin
        Init();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Display Target" := Format(ClientTypeManagement.GetCurrentClientType());
        Insert();
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnO365DemoCompanyInitialize()
    begin
    end;
}

