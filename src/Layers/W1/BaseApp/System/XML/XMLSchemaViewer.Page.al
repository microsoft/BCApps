namespace System.Xml;

using System.IO;

page 9610 "XML Schema Viewer"
{
    ApplicationArea = Basic, Suite;
    Caption = 'SEPA Schema Viewer';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SaveValues = true;
    SourceTable = "XML Schema Element";
    SourceTableView = sorting("XML Schema Code", "Sort Key");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control10)
            {
                ShowCaption = false;
                field(XMLSchemaCode; XMLSchemaCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'XML Schema Code';
                    TableRelation = "XML Schema".Code where(Indentation = const(0));
                    ToolTip = 'Specifies the XML schema file whose schema content is displayed on the lines in the XML Schema Viewer window.';

                    trigger OnValidate()
                    begin
                        if XMLSchemaCode = '' then
                            Clear(XMLSchema)
                        else
                            XMLSchema.Get(XMLSchemaCode);
                        Rec.SetRange("XML Schema Code", XMLSchemaCode);
                        CurrPage.Update(false);
                    end;
                }
                group(Control25)
                {
                    ShowCaption = false;
                    field(NewObjectNo; NewObjectNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New XMLport No.';
                        ToolTip = 'Specifies the number of the XMLport that is created from this XML schema when you choose the Generate XMLport action in the XML Schema Viewer window.';

                        trigger OnValidate()
                        begin
                            SetInternalVariables();
                        end;
                    }
                }
            }
            repeater(Group)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = "Node Name";
                ShowAsTree = true;
                field("Node Name"; Rec."Node Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleExpression;
                    ToolTip = 'Specifies the name of the node on the imported file.';
                }
                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the node is included in the related XMLport.';

                    trigger OnValidate()
                    begin
                        SetStyleExpression();
                    end;
                }
                field(Choice; Rec.Choice)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the node has two or more sibling nodes that function as options.';
                }
                field("Node Type"; Rec."Node Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a type. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the data and provides additional explanation of the tags in the Node Name.';
                }
                field(MinOccurs; Rec.MinOccurs)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the lowest number of times that the node appears in the XML schema. If the value in this field is 1 or higher, then the node is considered mandatory to create a valid XMLport.';
                }
                field(MaxOccurs; Rec.MaxOccurs)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the highest number of times that the node appears in the XML schema.';
                }
                field("Simple Data Type"; Rec."Simple Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the base (unstructured) type of the schema element, such as the Decimal and Date strings.';
                }
            }
        }
        area(factboxes)
        {
            part("Allowed Values"; "XML Schema Restrictions Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Allowed Values';
                SubPageLink = "XML Schema Code" = field("XML Schema Code"),
                              "Element ID" = field(ID);
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(GenerateDataExchSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Generate Data Exchange Definition';
                Image = Export;
                ToolTip = 'Initialize a data exchange definition based on the selected data elements, which you then complete in the Data Exchange Framework.';

                trigger OnAction()
                var
                    XSDParser: Codeunit "XSD Parser";
                begin
                    XSDParser.CreateDataExchDefForCAMT(Rec);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show All';
                Image = AllLines;
                ToolTip = 'Show all elements.';

                trigger OnAction()
                var
                    XSDParser: Codeunit "XSD Parser";
                begin
                    XSDParser.ShowAll(Rec);
                end;
            }
            action(HideNonMandatory)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Hide Nonmandatory';
                Image = ShowSelected;
                ToolTip = 'Do not show the elements that are marked as non-mandatory.';

                trigger OnAction()
                var
                    XSDParser: Codeunit "XSD Parser";
                begin
                    XSDParser.HideNotMandatory(Rec);
                end;
            }
            action(HideNonSelected)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Hide Nonselected';
                Image = ShowSelected;
                ToolTip = 'Do not show the elements that are marked as non-selected.';

                trigger OnAction()
                var
                    XSDParser: Codeunit "XSD Parser";
                begin
                    XSDParser.HideNotSelected(Rec);
                end;
            }
            action(SelectAll)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select All Mandatory Elements';
                Image = SelectEntries;
                ToolTip = 'Mark all elements that are mandatory.';

                trigger OnAction()
                var
                    XSDParser: Codeunit "XSD Parser";
                begin
                    XSDParser.SelectMandatory(Rec);
                end;
            }
            action(DeselectAll)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel the Selections';
                Image = SelectEntries;
                ToolTip = 'Deselect all elements.';

                trigger OnAction()
                var
                    XSDParser: Codeunit "XSD Parser";
                begin
                    if Confirm(DeselectQst) then
                        XSDParser.DeselectAll(Rec);
                end;
            }
            action(DataExchangeDefinitions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Data Exchange Definitions';
                Image = XMLFile;
                RunObject = Page "Data Exch Def List";
                ToolTip = 'View or edit the data exchange definitions that exist in the database to enable import/export of data to or from specific data files.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(GenerateDataExchSetup_Promoted; GenerateDataExchSetup)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'View', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ShowAll_Promoted; ShowAll)
                {
                }
                actionref(HideNonMandatory_Promoted; HideNonMandatory)
                {
                }
                actionref(HideNonSelected_Promoted; HideNonSelected)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Selection', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(SelectAll_Promoted; SelectAll)
                {
                }
                actionref(DeselectAll_Promoted; DeselectAll)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(DataExchangeDefinitions_Promoted; DataExchangeDefinitions)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        NewObjectNo := NewObjectNoInternal;
        SetStyleExpression();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyleExpression();
    end;

    trigger OnOpenPage()
    begin
        if XMLSchemaCodeInternal <> '' then
            XMLSchemaCode := XMLSchemaCodeInternal;
        XMLSchema.Code := XMLSchemaCode;
        if XMLSchema.Find('=<>') then;
        XMLSchemaCode := XMLSchema.Code;
        Rec.SetRange("XML Schema Code", XMLSchema.Code);
        SetInternalVariables();
    end;

    var
        XMLSchema: Record "XML Schema";
        XMLSchemaCode: Code[20];
        XMLSchemaCodeInternal: Code[20];
        NewObjectNo: Integer;
        NewObjectNoInternal: Integer;
        DeselectQst: Label 'Do you want to deselect all elements?';
        StyleExpression: Text;

    procedure SetXMLSchemaCode(NewXMLSchemaCode: Code[20])
    begin
        XMLSchemaCodeInternal := NewXMLSchemaCode;
    end;

    local procedure SetInternalVariables()
    begin
        NewObjectNoInternal := NewObjectNo;
    end;

    local procedure SetStyleExpression()
    var
        ChildXMLSchemaElement: Record "XML Schema Element";
    begin
        StyleExpression := '';
        if (Rec."Defintion XML Schema Code" <> '') or (Rec."Definition XML Schema ID" <> 0) then begin
            StyleExpression := 'Subordinate';
            exit;
        end;

        ChildXMLSchemaElement.SetRange("XML Schema Code", Rec."XML Schema Code");
        ChildXMLSchemaElement.SetRange("Parent ID", Rec.ID);
        if not ChildXMLSchemaElement.IsEmpty() then
            StyleExpression := 'Strong';
    end;
}

