// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

page 5478 "Synthetic Relation Details"
{
    PageType = Card;
    SourceTable = "Synth. Relation Mapping Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Synthetic Relation Details';
    DataCaptionExpression = '';

    layout
    {
        area(Content)
        {
            field("Synth. Relation Name"; Rec."Synth. Relation Name")
            {
                ApplicationArea = All;
                Caption = 'Name';
                ToolTip = 'Specifies the name of the synthetic relation.';
            }
            field("Rel. Native Entity Name"; Rec."Rel. Native Entity Name")
            {
                ApplicationArea = All;
                Caption = 'Native Entity Name';
                ToolTip = 'Specifies the name of the native entity.';
            }
            field("Rel. Virtual Entity Name"; Rec."Rel. Virtual Entity Name")
            {
                ApplicationArea = All;
                Caption = 'Virtual Entity Name';
                ToolTip = 'Specifies the name of the virtual entity.';
            }
            field("Syncd. Field 1 External Name"; Rec."Syncd. Field 1 External Name")
            {
                ApplicationArea = All;
                Caption = 'Native Field Name 1';
                ToolTip = 'Specifies the name of the native field used for the relation.';
            }
            field("Virtual Table Column 1 Name"; Rec."Virtual Table Column 1 Name")
            {
                ApplicationArea = All;
                Caption = 'Virtual Table''s Column Name 1';
                ToolTip = 'Specifies the name of the field in the virtual table used for the relation.';
            }
            field("Syncd. Field 2 External Name"; Rec."Syncd. Field 2 External Name")
            {
                ApplicationArea = All;
                Caption = 'Native Field Name 2';
                ToolTip = 'Specifies the name of the native field used for the relation.';
            }
            field("Virtual Table Column 2 Name"; Rec."Virtual Table Column 2 Name")
            {
                ApplicationArea = All;
                Caption = 'Virtual Table''s Column Name 2';
                ToolTip = 'Specifies the name of the field in the virtual table used for the relation.';
            }
            field("Syncd. Field 3 External Name"; Rec."Syncd. Field 3 External Name")
            {
                ApplicationArea = All;
                Caption = 'Native Field Name 3';
                ToolTip = 'Specifies the name of the native field used for the relation.';
            }
            field("Virtual Table Column 3 Name"; Rec."Virtual Table Column 3 Name")
            {
                ApplicationArea = All;
                Caption = 'Virtual Table''s Column Name 3';
                ToolTip = 'Specifies the name of the field in the virtual table used for the relation.';
            }
        }
    }

    internal procedure SetRelation(var SynthRelationMappingBuffer: Record "Synth. Relation Mapping Buffer")
    begin
        Rec.Copy(SynthRelationMappingBuffer);
        Rec.Insert();
    end;
}
