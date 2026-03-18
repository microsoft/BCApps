namespace System.Visualization;

using System.IO;
using System.Reflection;
using System.Utilities;

page 9182 "Generic Charts"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Generic Charts';
    CardPageID = "Generic Chart Setup";
    PageType = List;
    SourceTable = Chart;
    SourceTableView = sorting(ID);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control7)
            {
                ShowCaption = false;
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ID';
                    ToolTip = 'Specifies the unique ID of the chart.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the record.';
                }
                field("BLOB.HASVALUE"; Rec.BLOB.HasValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Data';
                    ToolTip = 'Specifies the data that is shown in the chart.';
                }
                field("GenericChartMgt.GetDescription(Rec)"; GenericChartMgt.GetDescription(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    MultiLine = true;
                    ToolTip = 'Specifies a description of the chart.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control13; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control14; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Import Chart")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import Chart';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import a generic chart in XML format.';

                    trigger OnAction()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        FileMgt: Codeunit "File Management";
                        RecordRef: RecordRef;
                        ChartExists: Boolean;
                    begin
                        ChartExists := Rec.BLOB.HasValue;
                        if FileMgt.BLOBImport(TempBlob, '*.xml') = '' then
                            exit;

                        if ChartExists then
                            if not Confirm(ReplaceChartDefinitionQst, false, Rec.TableCaption(), Rec.ID) then
                                exit;

                        RecordRef.GetTable(Rec);
                        TempBlob.ToRecordRef(RecordRef, Rec.FieldNo(BLOB));
                        RecordRef.SetTable(Rec);
                        CurrPage.SaveRecord();
                    end;
                }
                action("E&xport Chart")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport Chart';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export a generic chart in XML format. You can rename the file, modify the chart definition using an XML editor, and then import the new chart into another client.';

                    trigger OnAction()
                    var
                        TempBlob: Codeunit "Temp Blob";
                        FileMgt: Codeunit "File Management";
                    begin
                        Rec.CalcFields(BLOB);
                        if Rec.BLOB.HasValue() then begin
                            TempBlob.FromRecord(Rec, Rec.FieldNo(BLOB));
                            FileMgt.BLOBExport(TempBlob, '*.xml', true);
                        end;
                    end;
                }
                action("Copy Chart")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Chart';
                    Ellipsis = true;
                    Image = Copy;
                    ToolTip = 'Copy the selected generic chart to create a new generic chart.';

                    trigger OnAction()
                    var
                        CopyGenericChart: Page "Copy Generic Chart";
                    begin
                        if Rec.BLOB.HasValue() then
                            Rec.CalcFields(BLOB);
                        CopyGenericChart.SetSourceChart(Rec);
                        CopyGenericChart.RunModal();
                    end;
                }
                action("Delete Chart")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Delete Chart';
                    Image = Delete;
                    ToolTip = 'Delete the selected generic chart.';

                    trigger OnAction()
                    begin
                        if Rec.BLOB.HasValue() then
                            if Confirm(DeleteChartDefinitionQst, false, Rec.TableCaption(), Rec.ID) then begin
                                Rec.CalcFields(BLOB);
                                Clear(Rec.BLOB);
                                CurrPage.SaveRecord();
                            end;
                    end;
                }
            }
        }
    }

    var
        GenericChartMgt: Codeunit "Generic Chart Mgt";

#pragma warning disable AA0470
        ReplaceChartDefinitionQst: Label 'Do you want to replace the existing definition for %1 %2?', Comment = 'Do you want to replace the existing definition for Chart 36-06?';
        DeleteChartDefinitionQst: Label 'Are you sure that you want to delete the definition for %1 %2?', Comment = 'Are you sure that you want to delete the definition for Chart 36-06?';
#pragma warning restore AA0470
}

