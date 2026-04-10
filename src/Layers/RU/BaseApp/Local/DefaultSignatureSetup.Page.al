#pragma warning disable AA0247
page 12465 "Default Signature Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Default Signature Setup';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Default Signature Setup";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1470000)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table ID associated with the default signature setup information.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                        Objects: Page Objects;
                    begin
                        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                        AllObjWithCaption.SetFilter("Object ID", '36|38|5740|12450|12470');
                        Objects.SetTableView(AllObjWithCaption);
                        if Rec."Table ID" <> 0 then begin
                            AllObjWithCaption."Object Type" := AllObjWithCaption."Object Type"::Table;
                            AllObjWithCaption."Object ID" := Rec."Table ID";
                            AllObjWithCaption.Find();
                            Objects.SetRecord(AllObjWithCaption);
                        end;
                        Objects.LookupMode := true;
                        if Objects.RunModal() = ACTION::LookupOK then begin
                            Objects.GetRecord(AllObjWithCaption);
                            Rec."Table ID" := AllObjWithCaption."Object ID";
                            Rec.CalcFields("Table Name");
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        TableIDOnAfterValidate();
                    end;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the table name associated with the default signature setup information.';
                }
                field(DocumentTypeName; DocumentTypeName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies the type of the related document.';

                    trigger OnAssistEdit()
                    var
                        Selection: Integer;
                    begin
                        case Rec."Table ID" of
                            DATABASE::"Sales Header",
                            DATABASE::"Purchase Header",
                            DATABASE::"Invt. Document Header",
                            DATABASE::"FA Document Header":
                                begin
                                    Selection := StrMenu(GetDocumetTypeString(Rec."Table ID"), Rec."Document Type" + 1);
                                    if Selection <> 0 then begin
                                        Rec."Document Type" := Selection - 1;
                                        DocumentTypeName := GetDocumentTypeDesc(Rec."Table ID", Rec."Document Type");
                                    end;
                                end;
                        end;
                    end;
                }
                field("Employee Type"; Rec."Employee Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee type associated with the default signature setup information.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the default signature setup information is mandatory.';
                }
                field("Warrant Description"; Rec."Warrant Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant description associated with the default signature setup information.';
                }
                field("Warrant No."; Rec."Warrant No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant number associated with the default signature setup information.';
                }
                field("Warrant Date"; Rec."Warrant Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warrant date associated with the default signature setup information.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocumentTypeName := GetDocumentTypeDesc(Rec."Table ID", Rec."Document Type");
    end;

    trigger OnAfterGetRecord()
    begin
        DocumentTypeName := GetDocumentTypeDesc(Rec."Table ID", Rec."Document Type");
    end;

    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ItemDocumentHeader: Record "Invt. Document Header";
        FADocumentHeader: Record "FA Document Header";
        DocumentTypeName: Text[30];

    [Scope('OnPrem')]
    procedure GetDocumetTypeString(TableID: Integer): Text[250]
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        case TableID of
            DATABASE::"Sales Header":
                begin
                    RecRef.GetTable(SalesHeader);
                    FieldRef := RecRef.FieldIndex(SalesHeader.FieldNo("Document Type"));
                    exit(FieldRef.OptionCaption);
                end;
            DATABASE::"Purchase Header":
                begin
                    RecRef.GetTable(PurchaseHeader);
                    FieldRef := RecRef.FieldIndex(SalesHeader.FieldNo("Document Type"));
                    exit(FieldRef.OptionCaption);
                end;
            DATABASE::"Invt. Document Header":
                begin
                    RecRef.GetTable(ItemDocumentHeader);
                    FieldRef := RecRef.FieldIndex(SalesHeader.FieldNo("Document Type"));
                    exit(FieldRef.OptionCaption);
                end;
            DATABASE::"FA Document Header":
                begin
                    RecRef.GetTable(FADocumentHeader);
                    FieldRef := RecRef.FieldIndex(SalesHeader.FieldNo("Document Type"));
                    exit(FieldRef.OptionCaption);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDocumentTypeDesc(TableID: Integer; DocumentType: Integer): Text[30]
    begin
        case TableID of
            DATABASE::"Sales Header":
                exit(Format("Sales Document Type".FromInteger(DocumentType)));
            DATABASE::"Purchase Header":
                exit(Format("Purchase Document Type".FromInteger(DocumentType)));
            DATABASE::"Invt. Document Header":
                exit(Format("Invt. Doc. Document Type".FromInteger(DocumentType)));
            DATABASE::"FA Document Header":
                begin
                    FADocumentHeader."Document Type" := DocumentType;
                    exit(Format(FADocumentHeader."Document Type"));
                end;
        end;
    end;

    local procedure TableIDOnAfterValidate()
    begin
        if Rec."Table ID" <> 0 then
            Rec.CalcFields("Table Name");
    end;
}

