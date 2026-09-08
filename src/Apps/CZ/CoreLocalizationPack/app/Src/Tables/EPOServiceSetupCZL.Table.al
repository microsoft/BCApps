// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Integration;
using System.Privacy;

table 11724 "EPO Service Setup CZL"
{
    Caption = 'EPO Service Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
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
            InitValue = 2000;
            MinValue = 2000;
            DataClassification = SystemMetadata;
        }
        field(15; Enabled; Boolean)
        {

            Caption = 'Enabled';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
            begin
                if Enabled then begin
                    if not CustomerConsentMgt.ConfirmUserConsent() then begin
                        Enabled := false;
                        exit;
                    end;
                    TestField("Open Form Endpoint");
                end;
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
        EPOAPIMgt: Codeunit "EPO API Mgt. CZL";

    procedure SetURLToDefault()
    begin
        TestField(Enabled, false);
        Validate("Open Form Endpoint", EPOAPIMgt.GetDefaultOpenFormUrl());
    end;

    procedure GetOrInit()
    begin
        if Get() then
            exit;
        Init();
        Insert(true);
    end;

    local procedure CheckUrl(Url: Text[250])
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
    begin
        HttpWebRequestMgt.CheckUrl(Url);
    end;
}

