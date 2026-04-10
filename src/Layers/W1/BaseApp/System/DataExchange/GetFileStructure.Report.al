namespace System.IO;

report 1235 "Get File Structure"
{
    Caption = 'Get File Structure';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(FileType; FileType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'File Type';
                    OptionCaption = ' ,,Xml,,Json';
                    ToolTip = 'Specifies the file type whose structure will be reused to fill the Data Column Definitions FastTab. XML and Json are supported.';

                    trigger OnValidate()
                    begin
                        CheckFileType(DataExchDef);
                    end;
                }
                field(FilePath; FilePath)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Path';
                    ExtendedDatatype = URL;
                    ToolTip = 'Specifies the path or URL of the file that will be processed with this data exchange definition.';
                }
                field(DataExchDefCode; DataExchLineDef."Data Exch. Def Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data Exch. Def. Code';
                    Editable = false;
                    ToolTip = 'Specifies the data exchange definition for the file that will be processed.';
                }
                field("Code"; DataExchLineDef.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Line Definition Code';
                    Editable = false;
                    ToolTip = 'Specifies the value in the Code field on the Line Definitions FastTab.';
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        CheckFileType(DataExchDef);

        case FileType of
            FileType::Xsd:
                ;
            FileType::Xml:
                SuggestColDefinitionXML.GenerateDataExchColDef(FilePath, DataExchLineDef);
            FileType::Csv:
                ;
            FileType::Json:
                SuggestColDefinitionJson.GenerateDataExchColDef(FilePath, DataExchLineDef);
        end;
    end;

    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDef: Record "Data Exch. Def";
        SuggestColDefinitionXML: Codeunit "Suggest Col. Definition - XML";
        SuggestColDefinitionJson: Codeunit "Suggest Col. Definition - Json";
        FileType: Option " ",Xsd,Xml,Csv,Json;
        FilePath: Text;
        FileTypeCannotBeSelectedErr: Label ' You cannot select %1 when File Type is %2 in %3.', Comment = '%1 is XML, JSON, etc, %2 is simlar to %1, and %3 will be Data Exch. Definition. ';
        FileTypeNotSupportedErr: Label ' File type %1 is not supported.', Comment = '%1 is XML, JSON, etc';

    procedure Initialize(NewDataExchLineDef: Record "Data Exch. Line Def")
    begin
        DataExchLineDef := NewDataExchLineDef;
        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");

        SetFileType(DataExchDef);
    end;

    local procedure CheckFileType(DataExchDef: Record "Data Exch. Def")
    begin
        case DataExchDef."File Type" of
            DataExchDef."File Type"::Xml:
                if not (FileType in [FileType::Xml]) then
                    Error(FileTypeCannotBeSelectedErr, FileType, DataExchDef."File Type", DataExchDef.TableCaption);
            DataExchDef."File Type"::Json:
                if not (FileType in [FileType::Json]) then
                    Error(FileTypeCannotBeSelectedErr, FileType, DataExchDef."File Type", DataExchDef.TableCaption);
        end;
    end;

    local procedure SetFileType(DataExchDef: Record "Data Exch. Def")
    begin
        case DataExchDef."File Type" of
            DataExchDef."File Type"::Xml:
                FileType := FileType::Xml;
            DataExchDef."File Type"::Json:
                FileType := FileType::Json;
            else
                Error(FileTypeNotSupportedErr, DataExchDef."File Type");
        end;
    end;
}

