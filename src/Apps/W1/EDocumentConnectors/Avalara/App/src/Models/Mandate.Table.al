// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Model of Avalara Mandate
/// https://developer.avalara.com/api-reference/e-invoicing/einvoice/models/Mandate/
/// </summary>
table 6371 Mandate
{
    Caption = 'Mandate';

    DataClassification = SystemMetadata;
    DrillDownPageId = "Mandate List";
    Extensible = true;
    TableType = Temporary;

    fields
    {
        field(1; "Country Mandate"; Code[50])
        {
            Caption = 'Country Mandate';
            NotBlank = true;
        }
        field(2; "Country Code"; Code[20])
        {
            Caption = 'Country Mandate';
        }
        field(3; Description; Text[2048])
        {
            Caption = 'Description';
        }
        field(4; "Invoice Format"; Text[50])
        {
            Caption = 'Invoice Format';
        }
        field(5; "Credit Note Format"; Text[50])
        {
            Caption = 'Credit Note Format';
        }
        field(6; "ubl-order"; Text[50])
        {
            Caption = 'ubl-order Format';
        }
        field(7; "ubl-orderresponse"; Text[50])
        {
            Caption = 'ubl-orderresponse';
        }
        field(8; "ubl-applicationresponse"; Text[50])
        {
            Caption = 'ubl-applicationresponse';
        }
        field(9; "ubl-orderagreement"; Text[50])
        {
            Caption = 'ubl-orderagreement';
        }
    }

    keys
    {
        key(Key1; "Country Mandate")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Country Mandate", "Country Code", Description)
        {
        }
        fieldgroup(Drilldown; "Country Mandate", "Country Code", Description)
        {
        }
    }
}