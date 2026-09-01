#pragma warning disable AA0247
report 12488 "Copy FA Document"
{
    Caption = 'Copy FA Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocType; DocType)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document Type';
                        OptionCaption = 'Writeoff,Release,Movement,Posted Writeoff,Posted Release,Posted Movement';
                        ToolTip = 'Specifies the type of the related document.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                            ValidateDocNo();
                        end;
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;

                        trigger OnValidate()
                        begin
                            ValidateDocNo();
                        end;
                    }
                    field(IncludeHeader; IncludeHeader)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you want to copy information from the document header you are copying.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DocNo <> '' then begin
                case DocType of
                    DocType::Writeoff,
                  DocType::Release,
                  DocType::Movement:
                        if FromFADocHeader.Get(DocType, DocNo) then
                            ;
                    DocType::"Posted Writeoff",
                  DocType::"Posted Release",
                  DocType::"Posted Movement":
                        if FromPostedFADocHeader.Get(DocType - 3, DocNo) then
                            FromFADocHeader.TransferFields(FromPostedFADocHeader);
                end;
                if FromFADocHeader."No." = '' then
                    DocNo := '';
            end;
            ValidateDocNo();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CopyFADocMgt.SetProperties(IncludeHeader, false);
        CopyFADocMgt.CopyFADoc(DocType, DocNo, FADocHeader);
    end;

    var
        FADocHeader: Record "FA Document Header";
        FromFADocHeader: Record "FA Document Header";
        FromPostedFADocHeader: Record "Posted FA Doc. Header";
        CopyFADocMgt: Codeunit "Copy FA Document Mgt.";
        DocType: Option Writeoff,Release,Movement,"Posted Writeoff","Posted Release","Posted Movement";
        DocNo: Code[20];
        IncludeHeader: Boolean;

    [Scope('OnPrem')]
    procedure SetFADocHeader(var NewFADocHeader: Record "FA Document Header")
    begin
        FADocHeader := NewFADocHeader;
    end;

    local procedure ValidateDocNo()
    begin
        if DocNo = '' then
            FromFADocHeader.Init()
        else
            if FromFADocHeader."No." = '' then begin
                FromFADocHeader.Init();
                case DocType of
                    DocType::Writeoff,
                  DocType::Release,
                  DocType::Movement:
                        FromFADocHeader.Get(DocType, DocNo);
                    DocType::"Posted Writeoff",
                    DocType::"Posted Release",
                    DocType::"Posted Movement":
                        begin
                            FromPostedFADocHeader.Get(DocType - 3, DocNo);
                            FromFADocHeader.TransferFields(FromPostedFADocHeader);
                        end;
                end;
            end;
        FromFADocHeader."No." := '';
    end;

    local procedure LookupDocNo()
    begin
        case DocType of
            DocType::Writeoff,
            DocType::Release,
            DocType::Movement:
                begin
                    FromFADocHeader.FilterGroup := 0;
                    FromFADocHeader.SetRange("Document Type", DocType);
                    if FADocHeader."Document Type" = DocType then
                        FromFADocHeader.SetFilter("No.", '<>%1', FADocHeader."No.");
                    FromFADocHeader.FilterGroup := 2;
                    FromFADocHeader."Document Type" := DocType;
                    FromFADocHeader."No." := DocNo;
                    if PAGE.RunModal(0, FromFADocHeader) = ACTION::LookupOK then
                        DocNo := FromFADocHeader."No.";
                end;
            DocType::"Posted Writeoff",
            DocType::"Posted Release",
            DocType::"Posted Movement":
                begin
                    FromPostedFADocHeader."Document Type" := DocType - 3;
                    FromPostedFADocHeader."No." := DocNo;
                    if PAGE.RunModal(0, FromPostedFADocHeader) = ACTION::LookupOK then
                        DocNo := FromPostedFADocHeader."No.";
                end;
        end;
        ValidateDocNo();
    end;

    [Scope('OnPrem')]
    procedure GetFADocHeader(var ToFADocHeader: Record "FA Document Header")
    begin
        ToFADocHeader := FADocHeader;
    end;
}

