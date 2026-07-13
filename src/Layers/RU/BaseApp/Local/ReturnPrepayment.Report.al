#pragma warning disable AA0247
report 12453 "Return Prepayment"
{
    Caption = 'Return Prepayment';
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
                group(Options)
                {
                    Caption = 'Options';
                    field("CVLedgEntryBuf.""Posting Date"""; CVLedgEntryBuf."Posting Date")
                    {
                        ApplicationArea = Basic, Suite, Prepayments;
                        Caption = 'Posting Date';
                        Editable = false;
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                    field("CVLedgEntryBuf.""Document No."""; CVLedgEntryBuf."Document No.")
                    {
                        ApplicationArea = Basic, Suite, Prepayments;
                        Caption = 'Document No.';
                        Editable = false;
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(ControlPostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite, Prepayments;
                        Caption = 'New Posting Date';
                    }
                    field(ControlDocNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite, Prepayments;
                        Caption = 'New Document No.';
                        ToolTip = 'Specifies the new document number for the prepayment.';
                    }
                    field(ControlDescription; PostDescription)
                    {
                        ApplicationArea = Basic, Suite, Prepayments;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the description that will be added to the resulting posting.';
                    }
                    field(Correction; Correction)
                    {
                        ApplicationArea = Basic, Suite, Prepayments;
                        Caption = 'Correction';
                    }
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

    trigger OnPreReport()
    begin
        VATPrepmtPost.Initialize(PostingType, PostingDate, PostDescription, DocumentNo, EntryType);
        CVLedgEntryBuf.Positive := not Correction;
        VATPrepmtPost.PostPrepayment(CVLedgEntryBuf);
        if CurrReport.UseRequestPage then
            Message(Text12402, DocumentNo, PostingDate);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        PostingType: Option "Set as Prepayment","Reset as Payment";
        PostingDate: Date;
        DocumentNo: Code[20];
        PostDescription: Text[30];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12401: Label 'Payment %1 on %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12402: Label 'Payment %1 on %2 was successfully posted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VATPrepmtPost: Codeunit "VAT Prepayment-Post";
        EntryType: Option Sale,Purchase;
        Correction: Boolean;

    [Scope('OnPrem')]
    procedure InitializeRequest(EntryNo: Integer; Type: Option Sale,Purchase)
    begin
        EntryType := Type;
        if Type = Type::Sale then begin
            CustLedgEntry.Get(EntryNo);
            CustLedgEntry.CalcFields("Original Amt. (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
            CustLedgEntry.TestField("Remaining Amt. (LCY)", CustLedgEntry."Original Amt. (LCY)");
            CVLedgEntryBuf.TransferFields(CustLedgEntry);
            CVLedgEntryBuf."Remaining Amount" := CustLedgEntry."Remaining Amount";
            CVLedgEntryBuf."Remaining Amt. (LCY)" := CustLedgEntry."Remaining Amt. (LCY)";
        end else begin
            VendLedgEntry.Get(EntryNo);
            VendLedgEntry.CalcFields("Original Amt. (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
            VendLedgEntry.TestField("Remaining Amt. (LCY)", VendLedgEntry."Original Amt. (LCY)");
            CVLedgEntryBuf."Entry No." := VendLedgEntry."Entry No.";
            CVLedgEntryBuf."CV No." := VendLedgEntry."Vendor No.";
            CVLedgEntryBuf."Posting Date" := VendLedgEntry."Posting Date";
            CVLedgEntryBuf."Document Type" := VendLedgEntry."Document Type";
            CVLedgEntryBuf."Document No." := VendLedgEntry."Document No.";
            CVLedgEntryBuf.Description := VendLedgEntry.Description;
            CVLedgEntryBuf."Currency Code" := VendLedgEntry."Currency Code";
            CVLedgEntryBuf.Amount := VendLedgEntry.Amount;
            CVLedgEntryBuf."Remaining Amount" := VendLedgEntry."Remaining Amount";
            CVLedgEntryBuf."Remaining Amt. (LCY)" := VendLedgEntry."Remaining Amt. (LCY)";
            CVLedgEntryBuf."Amount (LCY)" := VendLedgEntry."Amount (LCY)";
            CVLedgEntryBuf."Bill-to/Pay-to CV No." := VendLedgEntry."Buy-from Vendor No.";
            CVLedgEntryBuf."CV Posting Group" := VendLedgEntry."Vendor Posting Group";
            CVLedgEntryBuf."Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
            CVLedgEntryBuf."Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
            CVLedgEntryBuf."User ID" := VendLedgEntry."User ID";
            CVLedgEntryBuf."Source Code" := VendLedgEntry."Source Code";
            CVLedgEntryBuf."Reason Code" := VendLedgEntry."Reason Code";
            CVLedgEntryBuf."Transaction No." := VendLedgEntry."Transaction No.";
            CVLedgEntryBuf."Document Date" := VendLedgEntry."Document Date";
            CVLedgEntryBuf."External Document No." := VendLedgEntry."External Document No.";
            CVLedgEntryBuf."Original Currency Factor" := VendLedgEntry."Original Currency Factor";
            CVLedgEntryBuf.Prepayment := VendLedgEntry.Prepayment;
            CVLedgEntryBuf."Agreement No." := VendLedgEntry."Agreement No.";
            CVLedgEntryBuf."Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        end;
        PostingType := PostingType::"Reset as Payment";
        PostDescription := Text12401;
        DocumentNo := CVLedgEntryBuf."Document No.";
        PostingDate := WorkDate();
    end;
}

