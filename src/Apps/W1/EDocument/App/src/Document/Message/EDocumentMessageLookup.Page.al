// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// The modal that replaces per-implementer page extensions for "Send X" actions. Every Type
/// that returns true from IsApplicableFor for the (parent, direction, trigger) combination
/// appears here automatically.
/// </summary>
page 6138 "E-Document Message Lookup"
{
    PageType = List;
    SourceTable = "E-Doc. Msg. Type Buffer";
    SourceTableTemporary = true;
    Caption = 'Send Message';
    Editable = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    ToolTip = 'The message type the implementer registered.';
                }
                field(Caption; Rec.Caption)
                {
                    ApplicationArea = All;
                    Caption = 'Caption';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
            }
        }
    }

    /// <summary>
    /// Populate the lookup from the parent E-Document + direction + trigger source.
    /// </summary>
    procedure Populate(Parent: Record "E-Document"; Direction: Enum "E-Document Direction"; TriggerSource: Enum "E-Doc. Msg. Trigger Source")
    var
        MsgType: Enum "E-Document Message Type";
        Type: Interface IEDocumentMessageType;
        Ord: Integer;
    begin
        foreach Ord in Enum::"E-Document Message Type".Ordinals() do begin
            MsgType := Enum::"E-Document Message Type".FromInteger(Ord);
            Type := MsgType;
            if Type.IsApplicableFor(Parent, Direction, TriggerSource) then
                Add(MsgType);
        end;
    end;

    local procedure Add(MsgType: Enum "E-Document Message Type")
    begin
        Rec.Init();
        Rec."Message Type" := MsgType;
        Rec.Caption := CopyStr(Format(MsgType), 1, MaxStrLen(Rec.Caption));
        Rec.Description := CopyStr(StrSubstNo('Message type ordinal %1', MsgType.AsInteger()), 1, MaxStrLen(Rec.Description));
        Rec.Insert();
    end;

    /// <summary>
    /// Returns the selected message type after the page closed with LookupOK.
    /// </summary>
    procedure GetSelectedMessageType(): Enum "E-Document Message Type"
    begin
        exit(Rec."Message Type");
    end;
}
