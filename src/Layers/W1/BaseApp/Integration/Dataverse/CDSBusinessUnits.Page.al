// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;

page 7203 "CDS Business Units"
{
    Caption = 'Dataverse Business Units', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "CRM Businessunit";
    SourceTableTemporary = true;
    SourceTableView = sorting(Name);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(BusinessUnitId; Rec.BusinessUnitId)
                {
                    ApplicationArea = Suite;
                    Caption = 'Id';
                    ToolTip = 'Specifies the ID of the business unit.';
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the Name of the business unit.';
                }
            }
        }
    }
}
