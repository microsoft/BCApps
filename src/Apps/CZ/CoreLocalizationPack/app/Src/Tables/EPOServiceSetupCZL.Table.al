// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Integration;

table 11724 "EPO Service Setup CZL"
{
    Caption = 'EPO Service Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Open Form Endpoint"; Text[250])
        {
            Caption = 'Open Form Endpoint';
            ExtendedDatatype = URL;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckUrl(Rec."Open Form Endpoint");
            end;
        }
        field(10; "Limit Response Time"; Integer)
        {
            Caption = 'Limit Response Time';
            DataClassification = CustomerContent;
            InitValue = 2000;
            MinValue = 2000;
        }
        field(15; Enabled; Boolean)
        {

            Caption = 'Enabled';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Enabled then
                    TestField("Open Form Endpoint");
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
        SetURLToDefault();
    end;

    var
        BaseUrlTok: Label 'https://mojedane.gov.cz/dpr/', Locked = true;
        OpenFormUriTok: Label 'epo_podani?otevriFormular=1', Locked = true;

    procedure SetURLToDefault()
    begin
        TestField(Enabled, false);
        Validate("Open Form Endpoint", GetDefaultOpenFormUrl());
    end;

    local procedure CheckUrl(Url: Text[250])
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        HttpWebRequestMgt.CheckUrl(Url);
    end;

    procedure GetDefaultOpenFormUrl(): Text
    begin
        exit(BaseUrlTok + OpenFormUriTok);
    end;
}

