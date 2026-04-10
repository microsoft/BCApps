namespace System.Automation;

page 1543 "WF Event/Response Comb. Matrix"
{
    Caption = 'WF Event/Response Comb. Matrix';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Workflow Event";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                FreezeColumn = Description;
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Caption = 'Preceding Event';
                    ToolTip = 'Specifies the workflow event.';
                }
                field(Cell1; MATRIX_CellData[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[1];
                    Visible = Field1Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(1);
                    end;
                }
                field(Cell2; MATRIX_CellData[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[2];
                    Visible = Field2Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(2);
                    end;
                }
                field(Cell3; MATRIX_CellData[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[3];
                    Visible = Field3Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(3);
                    end;
                }
                field(Cell4; MATRIX_CellData[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[4];
                    Visible = Field4Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(4);
                    end;
                }
                field(Cell5; MATRIX_CellData[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[5];
                    Visible = Field5Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(5);
                    end;
                }
                field(Cell6; MATRIX_CellData[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[6];
                    Visible = Field6Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(6);
                    end;
                }
                field(Cell7; MATRIX_CellData[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[7];
                    Visible = Field7Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(7);
                    end;
                }
                field(Cell8; MATRIX_CellData[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[8];
                    Visible = Field8Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(8);
                    end;
                }
                field(Cell9; MATRIX_CellData[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[9];
                    Visible = Field9Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(9);
                    end;
                }
                field(Cell10; MATRIX_CellData[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[10];
                    Visible = Field10Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(10);
                    end;
                }
                field(Cell11; MATRIX_CellData[11])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[11];
                    Visible = Field11Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(11);
                    end;
                }
                field(Cell12; MATRIX_CellData[12])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + MATRIX_Caption[12];
                    Visible = Field12Visible;

                    trigger OnValidate()
                    begin
                        UpdateMatrixData(12);
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
        PopulateMatrix();
    end;

    trigger OnAfterGetRecord()
    begin
        PopulateMatrix();
    end;

    trigger OnOpenPage()
    begin
        Field1Visible := true;
        Field2Visible := true;
        Field3Visible := true;
        Field4Visible := true;
        Field5Visible := true;
        Field6Visible := true;
        Field7Visible := true;
        Field8Visible := true;
        Field9Visible := true;
        Field10Visible := true;
        Field11Visible := true;
        Field12Visible := true;
    end;

    var
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        MATRIX_Caption: array[12] of Text;
        MATRIX_CellData: array[12] of Boolean;
        MATRIX_ColumnCount: Integer;
        Field1Visible: Boolean;
        Field2Visible: Boolean;
        Field3Visible: Boolean;
        Field4Visible: Boolean;
        Field5Visible: Boolean;
        Field6Visible: Boolean;
        Field7Visible: Boolean;
        Field8Visible: Boolean;
        Field9Visible: Boolean;
        Field10Visible: Boolean;
        Field11Visible: Boolean;
        Field12Visible: Boolean;

    procedure SetMatrixColumns(ColumnCaptions: array[32] of Text; ColumnSetLength: Integer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ColumnCaptions) do
            MATRIX_Caption[i] := ColumnCaptions[i];

        MATRIX_ColumnCount := ColumnSetLength;

        ShowHideColumns();
    end;

    procedure ShowHideColumns()
    begin
        Field1Visible := MATRIX_ColumnCount >= 1;
        Field2Visible := MATRIX_ColumnCount >= 2;
        Field3Visible := MATRIX_ColumnCount >= 3;
        Field4Visible := MATRIX_ColumnCount >= 4;
        Field5Visible := MATRIX_ColumnCount >= 5;
        Field6Visible := MATRIX_ColumnCount >= 6;
        Field7Visible := MATRIX_ColumnCount >= 7;
        Field8Visible := MATRIX_ColumnCount >= 8;
        Field9Visible := MATRIX_ColumnCount >= 9;
        Field10Visible := MATRIX_ColumnCount >= 10;
        Field11Visible := MATRIX_ColumnCount >= 11;
        Field12Visible := MATRIX_ColumnCount >= 12;
    end;

    local procedure PopulateMatrix()
    var
        WFEventResponseCombination: Record "WF Event/Response Combination";
        WorkflowResponse: Record "Workflow Response";
        i: Integer;
    begin
        for i := 1 to ArrayLen(MATRIX_Caption) do begin
            WorkflowResponse.SetRange(Description, MATRIX_Caption[i]);
            if WorkflowResponse.FindFirst() then
                if WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse."Function Name",
                     WFEventResponseCombination."Predecessor Type"::"Event", Rec."Function Name") or (not WorkflowResponse.HasPredecessors())
                then
                    MATRIX_CellData[i] := true
                else
                    MATRIX_CellData[i] := false;
        end;
    end;

    local procedure UpdateMatrixData(ColumnNo: Integer)
    var
        WorkflowResponse: Record "Workflow Response";
        WFEventResponseCombination: Record "WF Event/Response Combination";
    begin
        WorkflowResponse.SetRange(Description, MATRIX_Caption[ColumnNo]);
        WorkflowResponse.FindFirst();

        if MATRIX_CellData[ColumnNo] then begin
            WorkflowResponseHandling.AddResponsePredecessor(WorkflowResponse."Function Name", Rec."Function Name");
            WorkflowResponse.MakeIndependent();
        end else begin
            if not WorkflowResponse.HasPredecessors() then
                WorkflowResponse.MakeDependentOnAllEvents();

            if WFEventResponseCombination.Get(WFEventResponseCombination.Type::Response, WorkflowResponse."Function Name",
                 WFEventResponseCombination."Predecessor Type"::"Event", Rec."Function Name")
            then
                WFEventResponseCombination.Delete();
        end;
    end;
}

