// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

tableextension 6479 "Serv. Warehouse Source Filter" extends "Warehouse Source Filter"
{
    fields
    {
        field(110; "Service Orders"; Boolean)
        {
            Caption = 'Service Orders';
            DataClassification = CustomerContent;
            InitValue = true;

            trigger OnValidate()
            begin
                if Type = Type::Outbound then
                    CheckOutboundServiceDocumentChosen();
            end;
        }
    }

    local procedure CheckOutboundServiceDocumentChosen()
    begin
        if not ("Sales Orders" or "Purchase Return Orders" or "Outbound Transfers" or "Service Orders") then
            Error(MustBeChosenErr, FieldCaption("Source Document"));
    end;
}
