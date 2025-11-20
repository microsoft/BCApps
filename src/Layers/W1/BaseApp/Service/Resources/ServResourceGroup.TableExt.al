// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Service.Document;

tableextension 6457 "Serv. Resource Group" extends "Resource Group"
{
    fields
    {
        field(5900; "Qty. on Service Order"; Decimal)
        {
            CalcFormula = sum("Service Order Allocation"."Allocated Hours" where(Posted = const(false),
                                                                                  "Resource Group No." = field("No."),
                                                                                  "Allocation Date" = field("Date Filter"),
                                                                                  Status = const(Active)));
            Caption = 'Qty. on Service Order';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
    }
}
