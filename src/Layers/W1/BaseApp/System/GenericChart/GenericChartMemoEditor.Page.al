namespace System.Visualization;

using System.Globalization;

page 9189 "Generic Chart Memo Editor"
{
    Caption = 'Generic Chart Memo Editor';
    PageType = List;
    ShowFilter = false;
    SourceTable = "Generic Chart Memo Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Languages)
            {
                Caption = 'Languages';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Language Name"; Rec."Language Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the language name of the chart memo.';
                }
            }
            group(Memo)
            {
                Caption = 'Memo';
                field(MemoText; MemoText)
                {
                    ApplicationArea = Basic, Suite;
                    ColumnSpan = 2;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies the text of the chart memo.';

                    trigger OnValidate()
                    begin
                        Rec.SetMemoText(MemoText)
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        MemoText := Rec.GetMemoText();
    end;

    var
        MemoText: Text;

    procedure AssistEdit(var TempGenericChartMemoBuf: Record "Generic Chart Memo Buffer" temporary; MemoCode: Code[10]): Text
    var
        Language: Codeunit Language;
    begin
        Rec.Copy(TempGenericChartMemoBuf, true);
        Rec.SetRange(Code, MemoCode);
        if Rec.Get(MemoCode, Language.GetUserLanguageCode()) then;
        CurrPage.RunModal();
        exit(Rec.GetMemo(MemoCode, Language.GetUserLanguageCode()))
    end;
}

