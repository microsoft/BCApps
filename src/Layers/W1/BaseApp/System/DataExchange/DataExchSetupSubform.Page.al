namespace System.IO;

using System.Reflection;

page 1265 "Data Exch. Setup Subform"
{
    Caption = 'Field Mapping';
    PageType = ListPart;
    SourceTable = "Data Exch. Field Mapping Buf.";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Rec.Depth;
                IndentationControls = CaptionField;
                field(CaptionField; Rec.Caption)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Caption';
                    Enabled = IsRecordOfTypeField;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the caption of the field in Dynamics 365 that the node in the currency exchange rate file must map to.';

                    trigger OnAssistEdit()
                    begin
                        Rec.CaptionAssistEdit();
                    end;
                }
                field(SourceField; Rec.Source)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source';
                    ShowMandatory = SourceMandatory;
                    ToolTip = 'Specifies the XPath to the XML node that must be mapped to the specified field in Microsoft Dynamics 365.';

                    trigger OnAssistEdit()
                    begin
                        Rec.SourceAssistEdit(TempXMLBuffer);
                    end;
                }
                field("Default Value"; Rec."Default Value")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsRecordOfTypeField;
                    ToolTip = 'Specifies another value than the data in the field that will be exported, because you selected the Use Default Value check box. This field is only relevant for export.';
                }
                field("Transformation Rule"; Rec."Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a rule for transforming imported text to a supported value before it can be mapped to a specified field in Microsoft Dynamics 365. When you choose a value in this field, the same value is entered in the Transformation Rule field in the Data Exch. Field Mapping table and vice versa.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DataExchDef)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Data Exchange Definition';
                Image = Setup;
                RunObject = Page "Data Exch Def Card";
                RunPageLink = Code = field("Data Exchange Def Code");
                ToolTip = 'Set up a data exchange definition that enables you to exchange data, such as by sending electronic documents or importing bank files.';

                trigger OnAction()
                var
                    DataExchDef: Record "Data Exch. Def";
                begin
                    DataExchDef.Get(DataExchDefCode);
                    PAGE.RunModal(PAGE::"Data Exch Def Card", DataExchDef);
                    UpdateData();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        IsRecordOfTypeField := Rec.Type = Rec.Type::Field;
        SetStyle();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetStyle();
        Rec.Depth := 1;
    end;

    var
        TempSuggestedField: Record "Field" temporary;
        TempXMLBuffer: Record "XML Buffer" temporary;
        IsRecordOfTypeField: Boolean;
        DataExchDefCode: Code[20];
        StyleTxt: Text;
        SourceMandatory: Boolean;

    procedure UpdateData()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        Rec.DeleteAll();
        Clear(Rec);

        if DataExchDef.Get(DataExchDefCode) then begin
            Rec.InsertFromDataExchDefinition(Rec, DataExchDef, TempSuggestedField);
            Rec.SetRange("Data Exchange Def Code", DataExchDefCode);
            Rec.SetRange("Data Exchange Line Def Code", Rec."Data Exchange Line Def Code");
            Rec.SetRange("Table ID", Rec."Table ID");
            if Rec.FindFirst() then;
        end;
    end;

    procedure SetDataExchDefCode(NewDataExchDefCode: Code[20])
    begin
        DataExchDefCode := NewDataExchDefCode;
    end;

    procedure SetSuggestedField(var TempNewSuggestedField: Record "Field" temporary)
    begin
        if TempNewSuggestedField.FindSet() then begin
            TempSuggestedField.DeleteAll();

            repeat
                TempSuggestedField.Copy(TempNewSuggestedField);
                TempSuggestedField.Insert();
            until TempNewSuggestedField.Next() = 0;
        end;
    end;

    procedure SetXMLDefinition(var XMLBuffer: Record "XML Buffer")
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.DeleteAll();

        if XMLBuffer.FindSet() then
            repeat
                TempXMLBuffer.Copy(XMLBuffer);
                TempXMLBuffer.Insert();
            until XMLBuffer.Next() = 0;
    end;

    local procedure SetStyle()
    begin
        case Rec.Type of
            Rec.Type::Table:
                StyleTxt := 'Strong'
            else
                StyleTxt := '';
        end;
    end;

    procedure SetSourceToBeMandatory(NewSourceMandatory: Boolean)
    begin
        SourceMandatory := NewSourceMandatory;
    end;
}

