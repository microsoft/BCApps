// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using Microsoft.Service.Item;

table 6014 "Service Order Allocat. Archive"
{
    Caption = 'Service Order Allocation Archive';
    DrillDownPageID = "Service Order Allocat. Archive";
    LookupPageID = "Service Order Allocat. Archive";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; Status; Option)
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the entry, such as active, non-active, or cancelled.';
            OptionCaption = 'Nonactive,Active,Finished,Canceled,Reallocation Needed';
            OptionMembers = Nonactive,Active,Finished,Canceled,"Reallocation Needed";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number of the service order associated with this entry.';
        }
        field(4; "Allocation Date"; Date)
        {
            Caption = 'Allocation Date';
            ToolTip = 'Specifies the date when the resource allocation should start.';
        }
        field(5; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            ToolTip = 'Specifies the number of the resource allocated to the service task in this entry.';
            TableRelation = Resource;
        }
        field(6; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            ToolTip = 'Specifies the number of the resource group allocated to the service task in this entry.';
            TableRelation = "Resource Group";
        }
        field(7; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
            ToolTip = 'Specifies the number of the service item line linked to this entry.';
            TableRelation = "Service Item Line Archive"."Line No." where("Document Type" = field("Document Type"),
                                                                         "Document No." = field("Document No."),
                                                                         "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                                                         "Version No." = field("Version No."));
        }
        field(8; "Allocated Hours"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Allocated Hours';
            ToolTip = 'Specifies the hours allocated to the resource or resource group for the service task in this entry.';
            DecimalPlaces = 0 : 5;
        }
        field(9; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            ToolTip = 'Specifies the time when you want the allocation to start.';
        }
        field(10; "Finishing Time"; Time)
        {
            Caption = 'Finishing Time';
            ToolTip = 'Specifies the time when you want the allocation to finish.';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the service order allocation.';
        }
        field(12; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(13; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            ToolTip = 'Specifies the number of the service item.';
            TableRelation = "Service Item"."No.";
        }
        field(14; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(16; "Service Item Serial No."; Code[50])
        {
            Caption = 'Service Item Serial No.';
            ToolTip = 'Specifies the serial number of the service item in this entry.';
        }
        field(18; "Service Started"; Boolean)
        {
            Caption = 'Service Started';
        }
        field(19; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the type of the document (Order or Quote) from which the allocation entry was created.';
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5048; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Doc. No. Occurrence", "Version No.", "Allocation Date", "Resource No.", Status, "Resource Group No.")
        {
            SumIndexFields = "Allocated Hours";
        }
    }
}