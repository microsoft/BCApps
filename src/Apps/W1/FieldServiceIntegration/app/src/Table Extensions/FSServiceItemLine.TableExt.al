// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.DynamicsFieldService;

using Microsoft.Integration.Dataverse;
using Microsoft.Service.Document;

tableextension 6620 "FS Service Item Line" extends "Service Item Line"
{
    fields
    {
#pragma warning disable AS0099 // Preserve existing field IDs for compatibility.
        field(12000; "Coupled to FS"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Field Service';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Service Item Line")));
        }
        field(12001; "FS Bookings"; Boolean)
        {
            Caption = 'Field Service Bookings';
            DataClassification = CustomerContent;
        }
#pragma warning restore AS0099
    }
}
