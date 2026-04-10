// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

page 5395 "Dataverse Entity Changes API"
{
    APIVersion = 'v1.0';
    EntityCaption = 'Dataverse Entity Change';
    EntitySetCaption = 'Dataverse Entity Changes';
    DelayedInsert = true;
    DeleteAllowed = false;
    ModifyAllowed = false;
    InsertAllowed = true;
    EntityName = 'dataverseEntityChange';
    EntitySetName = 'dataverseEntityChanges';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Dataverse Entity Change";
    Extensible = false;
    APIGroup = 'dataverse';
    APIPublisher = 'microsoft';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(entityName; Rec."Entity Name")
                {
                    Caption = 'Entity Name';
                }
            }
        }
    }

    actions
    {
    }
}





