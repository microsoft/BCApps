// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using System.Reflection;

table 7205 "CRM Shipping Method"
{
    Caption = 'Dataverse Shipping Method';
    Description = 'Shipping agent';
    Access = Internal;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Option Id"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Code"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Option Id")
        {
            Clustered = true;
        }
        key(Key2; "Code")
        {
        }
    }

    procedure Load(): Boolean
    var
        TableMetadata: Record "Table Metadata";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        OptionSetMetadataDictionary: Dictionary of [Integer, Text];
        OptionValue: Integer;
    begin
        if TableMetadata.Get(Database::"CRM Account") then
            OptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(TableMetadata.ExternalName, 'address1_shippingmethodcode');
        if OptionSetMetadataDictionary.Count() = 0 then
            exit(true);

        foreach OptionValue in OptionSetMetadataDictionary.Keys() do begin
            Clear(Rec);
            Rec."Option Id" := OptionValue;
            Rec."Code" := CopyStr(OptionSetMetadataDictionary.Get(OptionValue), 1, MaxStrLen(Rec."Code"));
            Rec.Insert();
        end;

        if not Rec.FindFirst() then
            exit(false);

        exit(true);
    end;
}