// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Finance.Currency;
using System.Security.Encryption;

table 3318 "MX Connection Setup"
{
    Caption = 'Interfactura Connection Setup';

    fields
    {
        field(1; Id; Code[10])
        {
            Caption = 'Id';
            DataClassification = CustomerContent;
        }
        field(20; "Send Mode"; Option)
        {
            Caption = 'Send Mode';
            OptionMembers = Test,Production;
            OptionCaption = 'Test,Production';
            DataClassification = CustomerContent;
        }
        field(25; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if not Enabled then
                    exit;

                if ("PAC Certificate" = '') or ("SAT Certificate" = '') then
                    Error(CannotEnableWithoutCertificateErr);

                ValidatePrerequisites();
            end;
        }
        field(26; "PAC Certificate"; Code[20])
        {
            Caption = 'PAC Certificate';
            TableRelation = "Isolated Certificate";
            DataClassification = CustomerContent;
        }
        field(32; "SAT Certificate"; Code[20])
        {
            Caption = 'SAT Certificate';
            TableRelation = "Isolated Certificate";
            DataClassification = CustomerContent;
        }
        field(27; "Send PDF Report"; Boolean)
        {
            Caption = 'Send PDF Report';
            DataClassification = CustomerContent;
        }
        field(28; "Disable CFDI Payment Details"; Boolean)
        {
            Caption = 'Disable CFDI Payment Details';
            DataClassification = CustomerContent;
        }
        field(29; "USD Currency Code"; Code[10])
        {
            Caption = 'USD Currency Code';
            TableRelation = Currency;
            DataClassification = CustomerContent;
        }
        field(30; "Cancel on Time Expiration"; Boolean)
        {
            Caption = 'Cancel on Time Expiration';
            DataClassification = CustomerContent;
        }
        field(31; "Multiple SAT Certificates"; Boolean)
        {
            Caption = 'Multiple SAT Certificates';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        "Send Mode" := "Send Mode"::Test;
    end;

    procedure ValidatePrerequisites()
    var
        MXPACWebServiceDetail: Record "MX PAC Web Service Detail";
    begin
        ValidatePACWebServiceDetailExistsAndComplete(MXPACWebServiceDetail.Type::"Request Stamp");
        ValidatePACWebServiceDetailExistsAndComplete(MXPACWebServiceDetail.Type::Cancel);
        ValidatePACWebServiceDetailExistsAndComplete(MXPACWebServiceDetail.Type::CancelRequest);
    end;

    local procedure ValidatePACWebServiceDetailExistsAndComplete(RequestType: Option "Request Stamp",Cancel,CancelRequest)
    var
        MXPACWebServiceDetail: Record "MX PAC Web Service Detail";
    begin
        if not MXPACWebServiceDetail.Get(Id, RequestType) then
            Error(MissingPACWebServiceDetailErr, Format(RequestType));

        MXPACWebServiceDetail.TestField("Method Name");
        MXPACWebServiceDetail.TestField(Address);
    end;

    var
        CannotEnableWithoutCertificateErr: Label 'You cannot enable Interfactura without configuring both PAC Certificate and SAT Certificate.';
        MissingPACWebServiceDetailErr: Label 'PAC Web Service Detail for %1 is missing.';
}