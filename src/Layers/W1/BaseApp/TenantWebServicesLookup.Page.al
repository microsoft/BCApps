// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration;

page 6712 "Tenant Web Services Lookup"
{
    Caption = 'Tenant Web Services Lookup';
    Editable = false;
    PageType = List;
    SourceTable = "Tenant Web Service";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Object Type of the data set.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object ID for the data set.';
                }
                field("Service Name"; Rec."Service Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data set name.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        WebServiceManagement.LoadRecordsFromTenantWebServiceColumns(Rec);
    end;

    var
        WebServiceManagement: Codeunit "Web Service Management";
}

