// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Integration.Graph;

page 9166 "Support Contact Info. Entity"
{
    APIGroup = 'admin';
    APIPublisher = 'microsoft';
    Caption = 'supportContactInformation', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'supportContactInformation';
    EntitySetName = 'supportContactInformation';
    InsertAllowed = false;
    ODataKeyFields = ID;
    PageType = API;
    Permissions = TableData "Support Contact Information" = rim;
    SaveValues = true;
    SourceTable = "Support Contact Information";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;

                    trigger OnValidate()
                    var
                        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
                    begin
                        if xRec.ID <> Rec.ID then
                            GraphMgtGeneralTools.ErrorIdImmutable();
                    end;
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'name', Locked = true;
                }
                field(email; Rec.Email)
                {
                    ApplicationArea = All;
                    Caption = 'email', Locked = true;
                }
                field(url; Rec.URL)
                {
                    ApplicationArea = All;
                    Caption = 'url', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        SupportContactInformation: Record "Support Contact Information";
    begin
        if SupportContactInformation.IsEmpty() then begin
            SupportContactInformation.Init();
            SupportContactInformation.Insert(true);
        end;
    end;
}

