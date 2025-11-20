// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

page 6001 "Service Order Allocations"
{
    Caption = 'Service Order Allocations';
    DataCaptionFields = "Document Type", "Document No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Order Allocation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the document (Order or Quote) from which the allocation entry was created.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order associated with this entry.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the status of the entry, such as active, non-active, or cancelled.';
                }
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item line linked to this entry.';
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item.';
                    Visible = false;
                }
                field("Allocation Date"; Rec."Allocation Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the resource allocation should start.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the resource allocated to the service task in this entry.';
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the resource group allocated to the service task in this entry.';
                    Visible = false;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the hours allocated to the resource or resource group for the service task in this entry.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when you want the allocation to start.';
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when you want the allocation to finish.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description for the service order allocation.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

