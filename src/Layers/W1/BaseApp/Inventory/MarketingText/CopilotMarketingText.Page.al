// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;

using System.Text;

page 5836 "Copilot Marketing Text"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Draft Marketing Text with Copilot';
    DataCaptionExpression = OutputCaption;
    DelayedInsert = true;
    SourceTableTemporary = true;
    PageType = PromptDialog;
    Extensible = false;
    SourceTable = "Marketing Text Suggestion";
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2226375';

    layout
    {
        area(PromptOptions)
        {
            field(Tone; Tone)
            {
                Caption = 'Tone';
                ApplicationArea = All;
                ToolTip = 'Specifies the style of the generated text';

                trigger OnValidate()
                begin
                end;
            }

            field(TextFormat; TextFormat)
            {
                Caption = 'Format';
                ApplicationArea = All;
                ToolTip = 'Specifies the length and format of the generated text';

                trigger OnValidate()
                begin
                end;
            }

            field(Emphasis; Emphasis)
            {
                Caption = 'Emphasis';
                ApplicationArea = All;
                ToolTip = 'Specifies a quality to emphasize in the generated text';

                trigger OnValidate()
                begin
                end;
            }
        }

        area(Prompt)
        {
            field(PromptCaption; PromptCaption)
            {
                Editable = false;
                ShowCaption = false;
            }

            part(AttributesPart; "Marketing Text Attributes Part")
            {
                Caption = 'Item Attributes';
                Editable = true;
            }
        }

        area(Content)
        {
            group(EntityText)
            {
                ShowCaption = false;
                field(ItemText; EntityTextContent)
                {
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    ShowCaption = false;

                    trigger OnValidate()
                    begin
                        SetText(EntityTextContent);
                        Rec.Modify();
                    end;
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Tooltip = 'Generate a suggestion based on the input prompt';
                trigger OnAction()
                begin
                    SetSelectedFacts();
                    GenerateText(CopilotGeneratingTxt);
                end;
            }
            systemaction(Regenerate)
            {
                Tooltip = 'Regenerate a suggestion based on the input prompt';
                trigger OnAction()
                begin
                    GenerateText(CopilotRevisingTxt);
                end;
            }
            systemaction(Cancel)
            {
                ToolTip = 'Discards all suggestions and dismisses the dialog';
            }
            systemaction(Ok)
            {
                Caption = 'Keep it';
                ToolTip = 'Accepts the current suggestion and dismisses the dialog';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if not HasLoaded then begin
            BuildInitialData();
            HasLoaded := true;
        end;

        if Rec.IsEmpty() then
            exit;

        EntityTextContent := GetText();
        Tone := Rec.Voice;
        TextFormat := Rec.TextFormat;
        Emphasis := Rec.Emphasis;
        OutputCaption := Rec.PageCaption;
        if xRec.No <> Rec.No then
            SelectedAttributesFromRecord();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        DialogCloseAction := CloseAction;
    end;

    procedure SetTone(NewTone: Enum "Entity Text Tone")
    begin
        Tone := NewTone;
    end;

    procedure SetItemFacts(NewFacts: Dictionary of [Text, Text])
    begin
        AllFacts := NewFacts;
    end;

    procedure SetItemName(NewName: Text)
    begin
        ItemName := NewName;
    end;

    procedure GetMarketingText(): Text
    begin
        exit(EntityTextContent);
    end;

    procedure SetTextFormat(NewTextFormat: Enum "Entity Text Format")
    begin
        TextFormat := NewTextFormat;
    end;

    procedure SetTextEmphasis(NewTextEmphasis: Enum "Entity Text Emphasis")
    begin
        Emphasis := NewTextEmphasis;
    end;

    procedure SetPromptMode(NewMode: PromptMode)
    begin
        CurrPage.PromptMode := NewMode;
    end;

    procedure GetClosingAction(): Action
    begin
        exit(DialogCloseAction);
    end;

    local procedure BuildInitialData()
    begin
        BuildInitialFacts();
        BuildAttributeString();
        if AllFacts.ContainsKey(ProductNameTxt) then
            ItemName := AllFacts.Get(ProductNameTxt)
        else
            ItemName := '';

        PromptCaption := StrSubstNo(PromptCaptionTxt, ItemName);
        OutputCaption := StrSubstNo(CaptionTxt, ItemName, Attributes);
    end;

    local procedure BuildInitialFacts()
    var
        MarketingTextCod: Codeunit "Marketing Text";
        FactKey: Text;
        FactCount: Integer;
        MaxFacts: Integer;
    begin
        MaxFacts := MarketingTextCod.GetMaximumFacts();
        foreach FactKey in AllFacts.Keys() do
            if FactKey <> ProductNameTxt then begin
                if FactCount < MaxFacts then begin
                    Facts.Add(FactKey, AllFacts.Get(FactKey));
                    CurrPage.AttributesPart.Page.AddAttribute(FactKey, AllFacts.Get(FactKey), true);
                end
                else
                    CurrPage.AttributesPart.Page.AddAttribute(FactKey, AllFacts.Get(FactKey), false);

                FactCount += 1;
            end;
    end;

    local procedure BuildAttributeString()
    var
        Attribute: Text;
        FactValues: List of [Text];
        ItemCategoryVal: Text;
    begin
        Clear(Attributes);
        FactValues := Facts.Values();
        if Facts.ContainsKey(ItemCategoryTxt) then begin
            Facts.Get(ItemCategoryTxt, Attributes);
            ItemCategoryVal := Attributes;
            if FactValues.Count > 1 then
                Attributes += ': ';
        end;

        foreach Attribute in FactValues do
            if not (Attribute = ItemCategoryVal) then
                Attributes += Attribute + ', ';

        Attributes := DelChr(Attributes, '>', ', ');
    end;

    local procedure SetSelectedAttributesToBlob()
    var
        JsonArray: JsonArray;
        JsonTxt: Text;
        Attribute: Text;
        OutStr: OutStream;
    begin
        Rec.SelectedAttributes.CreateOutStream(OutStr);
        foreach Attribute in Facts.Keys() do
            JsonArray.Add(Attribute);
        JsonArray.WriteTo(JsonTxt);
        OutStr.WriteText(JsonTxt);
    end;

    local procedure SelectedAttributesFromRecord()
    var
        JsonArray: JsonArray;
        InStr: InStream;
        Attribute: JsonToken;
        SelectedAttrList: List of [Text];
    begin
        Rec.CalcFields(SelectedAttributes);
        Rec.SelectedAttributes.CreateInStream(InStr);
        JsonArray.ReadFrom(InStr);

        foreach Attribute in JsonArray do
            SelectedAttrList.Add(Attribute.AsValue().AsText());
        CurrPage.AttributesPart.Page.SetSelectedAttributes(SelectedAttrList);
    end;

    local procedure SetSelectedFacts()
    begin
        Clear(Facts);
        Facts := CurrPage.AttributesPart.Page.GetSelectedAttributes();
        BuildAttributeString();
        OutputCaption := StrSubstNo(CaptionTxt, ItemName, Attributes);
    end;

    local procedure SetText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Rec.GeneratedText.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    local procedure GetText(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Rec.CalcFields(GeneratedText);
        Rec.GeneratedText.CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);

        exit(Result);
    end;

    local procedure GenerateText(ProgressText: Text)
    var
        ProgressDialog: Dialog;
    begin
        ProgressDialog.Open(ProgressText);
        if not HasLoaded then begin
            BuildInitialData();
            HasLoaded := true;
        end;

        if AllFacts.ContainsKey(ProductNameTxt) and not Facts.ContainsKey(ProductNameTxt) then
            Facts.Add(ProductNameTxt, AllFacts.Get(ProductNameTxt));
        EntityTextContent := EntityText.GenerateText(Facts, Tone, TextFormat, Emphasis);

        Rec.Init();
        SetSelectedAttributesToBlob();
        Rec.No := Rec.Count + 1;
        Rec.Voice := Tone;
        Rec.TextFormat := TextFormat;
        Rec.Emphasis := Emphasis;
        Rec.PageCaption := CopyStr(OutputCaption, 1, MaxStrLen(Rec.PageCaption));
        SetText(EntityTextContent);
        Rec.Insert();
        ProgressDialog.Close();
    end;

    var
        EntityText: Codeunit "Entity Text";
        DialogCloseAction: Action;
        Tone: Enum "Entity Text Tone";
        TextFormat: Enum "Entity Text Format";
        Emphasis: Enum "Entity Text Emphasis";
        PromptCaption: Text;
        PromptCaptionTxt: Label 'Describe ''%1'' using the attributes included here:', Comment = '%1 = item description (name)';
        EntityTextContent: Text;
        ItemName: Text;
        Attributes: Text;
        HasLoaded: Boolean;
        CopilotGeneratingTxt: Label 'Drafting marketing text';
        CopilotRevisingTxt: Label 'Revising text...';
        AllFacts: Dictionary of [Text, Text];
        Facts: Dictionary of [Text, Text];
        OutputCaption: Text;
        CaptionTxt: Label 'Describe ''%1'' by ''%2''', Comment = '%1 = item description (name), %2 = string of facts used to describe it';
        ProductNameTxt: Label 'Product Name', Locked = true;
        ItemCategoryTxt: Label 'Item Category', Locked = true;
}