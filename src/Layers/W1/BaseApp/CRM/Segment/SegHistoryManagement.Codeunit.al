// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

codeunit 5061 SegHistoryManagement
{

    trigger OnRun()
    begin
    end;

    var
        SegHist: Record "Segment History";
        SegHeader: Record "Segment Header";

    procedure InsertLine(SegmentNo: Code[20]; ContactNo: Code[20]; LineNo: Integer)
    begin
        InitLine(SegmentNo, ContactNo, LineNo);
        SegHist."Action Taken" := SegHist."Action Taken"::Insertion;
        SegHist.Insert();
    end;

    procedure DeleteLine(SegmentNo: Code[20]; ContactNo: Code[20]; LineNo: Integer)
    begin
        InitLine(SegmentNo, ContactNo, LineNo);
        SegHist."Action Taken" := SegHist."Action Taken"::Deletion;
        SegHist.Insert();
    end;

    local procedure InitLine(SegmentNo: Code[20]; ContactNo: Code[20]; LineNo: Integer)
    begin
        SegHeader.Get(SegmentNo);
        SegHeader.CalcFields("No. of Criteria Actions");
        SegHist.Init();
        SegHist."Segment No." := SegmentNo;
        SegHist."Segment Action No." := SegHeader."No. of Criteria Actions";
        SegHist."Segment Line No." := LineNo;
        SegHist."Contact No." := ContactNo;

        OnAfterInitLine(SegmentNo, SegHist);
    end;

    procedure GoBack(SegmentNo: Code[20])
    var
        SegLine: Record "Segment Line";
        SegCriteriaLine: Record "Segment Criteria Line";
        NextLineNo: Integer;
    begin
        SegHist.LockTable();
        SegHeader.Get(SegmentNo);
        SegHeader.CalcFields("No. of Criteria Actions");

        SegLine.Reset();
        SegLine.SetRange("Segment No.", SegmentNo);
        if SegLine.FindLast() then
            NextLineNo := SegLine."Line No." + 10000
        else
            NextLineNo := 10000;

        SegHist.SetRange("Segment No.", SegmentNo);
        SegHist.SetRange("Segment Action No.", SegHeader."No. of Criteria Actions");
        if SegHist.Find('+') then begin
            SegHist.SetRange("Segment Action No.", SegHist."Segment Action No.");
            repeat
                case SegHist."Action Taken" of
                    SegHist."Action Taken"::Insertion:
                        begin
                            SegLine.Reset();
                            SegLine.SetRange("Segment No.", SegHist."Segment No.");
                            SegLine.SetRange("Contact No.", SegHist."Contact No.");
                            SegLine.DeleteAll(true);
                        end;
                    SegHist."Action Taken"::Deletion:
                        begin
                            SegLine.Init();
                            SegLine."Segment No." := SegmentNo;
                            SegLine."Line No." := NextLineNo;
                            SegLine.Validate("Contact No.", SegHist."Contact No.");
                            SegLine.Insert(true);
                            NextLineNo := NextLineNo + 10000;
                        end;
                end;
            until SegHist.Next(-1) = 0;
            SegHist.DeleteAll();
        end;

        SegCriteriaLine.SetRange("Segment No.", SegmentNo);
        if SegCriteriaLine.Find('+') then
            repeat
                SegCriteriaLine.Delete();
            until (SegCriteriaLine.Type = SegCriteriaLine.Type::Action) or (SegCriteriaLine.Next(-1) = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitLine(SegmentNo: Code[20]; var SegmentHistory: Record "Segment History")
    begin
    end;
}

