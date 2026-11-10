// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8380 "MCP Client Config. Mappings"
{
    Caption = 'MCP Client Configuration Mappings';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "MCP Client Config. Mapping";
    PopulateAllFields = true;
    DelayedInsert = true;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Mappings)
            {
                field("Identifier Type"; Rec."Identifier Type") { }
                field("Match Operator"; Rec."Match Operator") { }
                field(Pattern; Rec.Pattern) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RemoveMapping)
            {
                Caption = 'Remove';
                ToolTip = 'Remove the selected client mapping from this MCP configuration.';
                Image = RemoveLine;
                AccessByPermission = tabledata "MCP Client Config. Mapping" = D;
                Enabled = Rec."Entry No." <> 0;

                trigger OnAction()
                begin
                    CheckScope();
                    if not Confirm(StrSubstNo(RemoveMappingQst, Rec.Pattern), false) then
                        exit;
                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if IsNullGuid(ConfigurationId) then
            ConfigurationId := Rec."Configuration ID";
        Rec.Validate("Configuration ID", ConfigurationId);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CheckScope();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CheckScope();
    end;

    var
        ConfigurationId: Guid;
        RemoveMappingQst: Label 'Remove the client mapping for %1?', Comment = '%1 = client identifier pattern';

    internal procedure SetConfiguration(ConfigSystemId: Guid)
    begin
        ConfigurationId := ConfigSystemId;
        Rec.FilterGroup(2);
        Rec.SetRange("Configuration ID", ConfigSystemId);
        Rec.FilterGroup(0);
        if not Rec.FindFirst() then begin
            Rec.Init();
            Rec."Entry No." := 0;
            Rec."Configuration ID" := ConfigSystemId;
        end;
        CurrPage.Update(false);
    end;

    local procedure CheckScope()
    begin
        Rec.TestField("Configuration ID", ConfigurationId);
    end;
}
