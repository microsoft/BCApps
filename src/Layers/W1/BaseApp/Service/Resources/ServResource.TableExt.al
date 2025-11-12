// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.BaseApp;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;

tableextension 6456 "Serv. Resource" extends Resource
{
    fields
    {
        field(5900; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = sum("Service Order Allocation"."Allocated Hours" where(Posted = const(false),
                                                                                  "Resource No." = field("No."),
                                                                                  "Allocation Date" = field("Date Filter"),
                                                                                  Status = const(Active)));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5901; "Service Zone Filter"; Code[10])
        {
            Caption = 'Service Zone Filter';
            DataClassification = CustomerContent;
            TableRelation = "Service Zone";
        }
        field(5902; "In Customer Zone"; Boolean)
        {
            CalcFormula = exist("Resource Service Zone" where("Resource No." = field("No."),
                                                               "Service Zone Code" = field("Service Zone Filter")));
            Caption = 'In Customer Zone';
            Editable = false;
            FieldClass = FlowField;
        }
    }
}
