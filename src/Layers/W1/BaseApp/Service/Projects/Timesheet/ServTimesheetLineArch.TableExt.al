// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Service.Document;

tableextension 6465 "Serv. Time Sheet Line Arch." extends "Time Sheet Line Archive"
{
    fields
    {
        modify("Service Order No.")
        {
            TableRelation = if (Posted = const(false)) "Service Header"."No." where("Document Type" = const(Order));
        }
        field(14; "Service Order Line No."; Integer)
        {
            Caption = 'Service Order Line No.';
            DataClassification = CustomerContent;
        }
    }
}
