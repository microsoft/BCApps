// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Service.Document;

tableextension 6463 "Serv. Time Sheet Detail Arch." extends "Time Sheet Detail Archive"
{
    fields
    {
        field(13; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            DataClassification = CustomerContent;
            TableRelation = if (Posted = const(false)) "Service Header"."No." where("Document Type" = const(Order));
        }
        field(14; "Service Order Line No."; Integer)
        {
            Caption = 'Service Order Line No.';
            DataClassification = CustomerContent;
        }
    }
}
