// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

table 3353 "MX PAC Web Service Detail"
{
    Caption = 'MX PAC Web Service Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Setup Id"; Code[10])
        {
            Caption = 'Setup Id';
            TableRelation = "MX Connection Setup".Id;
            DataClassification = CustomerContent;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionMembers = "Request Stamp",Cancel,CancelRequest;
            OptionCaption = 'Request Stamp,Cancel,CancelRequest';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ApplyDefaultsFromSetup();
            end;
        }
        field(21; "Method Name"; Text[50])
        {
            Caption = 'Method Name';
            DataClassification = CustomerContent;
        }
        field(22; Address; Text[250])
        {
            Caption = 'Address';
            ExtendedDatatype = URL;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Setup Id", Type)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        ApplyDefaultsFromSetup();
    end;

    local procedure ApplyDefaultsFromSetup()
    var
        MXConnectionSetup: Record "MX Connection Setup";
    begin
        if "Setup Id" = '' then
            exit;

        if not MXConnectionSetup.Get("Setup Id") then
            exit;

        case MXConnectionSetup."Send Mode" of
            MXConnectionSetup."Send Mode"::Test:
                Address := InterfacturaServiceUrlLbl;
            MXConnectionSetup."Send Mode"::Production:
                Address := InterfacturaServiceUrlLbl;
        end;

        case Type of
            Type::"Request Stamp":
                "Method Name" := GeneraTimbreMethodLbl;
            Type::Cancel:
                "Method Name" := CancelaTimbreMethodLbl;
            Type::CancelRequest:
                "Method Name" := ConsultaEstatusMethodLbl;
        end;
    end;

    var
        InterfacturaServiceUrlLbl: Label 'https://qaservicios.interfactura.com/TimbreServicios/TimbreServicios.asmx', Locked = true;
        GeneraTimbreMethodLbl: Label 'GeneraTimbre', Locked = true;
        CancelaTimbreMethodLbl: Label 'CancelaTimbre', Locked = true;
        ConsultaEstatusMethodLbl: Label 'ConsultaEstatusCancelacion', Locked = true;
}